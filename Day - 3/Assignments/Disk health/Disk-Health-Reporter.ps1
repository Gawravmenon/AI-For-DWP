[CmdletBinding()]
param(
    # This section defines folders that contain files eligible for cleanup when cleanup mode is enabled.
    [Parameter()]
    [string[]]$TargetPath = @(
        [System.IO.Path]::GetTempPath(),
        (Join-Path $env:WINDIR 'Temp')
    ),

    # This section defines the minimum age in days for files to be considered for cleanup.
    [Parameter()]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$DaysOld = 0,

    # This section enables preview mode and only prints files that would be deleted.
    [Parameter()]
    [switch]$DryRun,

    # This section enables actual cleanup behavior (copy to rollback store, then delete).
    [Parameter()]
    [switch]$EnableCleanup,

    # This section restores files from a prior cleanup run using manifest data.
    [Parameter()]
    [switch]$Rollback,

    # This section allows choosing a specific rollback run folder name (for example: Run_20260807_143000).
    [Parameter()]
    [string]$RollbackId
)

# This section resolves script-relative paths in a PowerShell 5.1-safe way.
$scriptPath = $MyInvocation.MyCommand.Path
$scriptRoot = Split-Path -Path $scriptPath -Parent

# This section defines fixed working folders and files used for logs and rollback state.
$script:StateRoot = Join-Path $scriptRoot 'state'
$script:LogRoot = Join-Path $scriptRoot 'logs'
$script:RollbackRoot = Join-Path $scriptRoot 'rollback'
$script:RunStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:RunId = "Run_$($script:RunStamp)"
$script:LogFile = Join-Path $script:LogRoot "DiskHealthReporter_$($script:RunStamp).log"
$script:CurrentRollbackFolder = if ($Rollback) { $null } else { Join-Path $script:RollbackRoot $script:RunId }
$script:CurrentManifestPath = if ($Rollback) { $null } else { Join-Path $script:CurrentRollbackFolder 'manifest.json' }

# This section creates a shared summary object printed at the end of every execution.
$script:Summary = [ordered]@{
    Mode                     = 'ReportOnly'
    TargetPaths              = 0
    EnumeratedFiles          = 0
    EligibleFiles            = 0
    DryRunCandidates         = 0
    DeletedFiles             = 0
    RestoredFiles            = 0
    LockedFiles              = 0
    SkippedNewFiles          = 0
    SkippedDuplicateEntries  = 0
    SkippedExistingOnRestore = 0
    DiskHealthRows           = 0
    VolumeRows               = 0
    Errors                   = 0
    LogFile                  = $script:LogFile
}

# This section creates required folders so logging and rollback features can run safely.
function Initialize-WorkFolders {
    $folders = @($script:StateRoot, $script:LogRoot, $script:RollbackRoot)
    if (-not $Rollback) {
        $folders += $script:CurrentRollbackFolder
    }

    foreach ($folder in $folders) {
        if (-not (Test-Path -LiteralPath $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
}

# This section writes timestamped logs to both console and log file.
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
}

# This section checks whether a file can be opened exclusively, which indicates it is not locked.
function Test-FileAvailable {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $stream.Close()
        return $true
    }
    catch {
        return $false
    }
}

# This section normalizes and deduplicates input target paths.
function Get-NormalizedTargetPaths {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths
    )

    $normalized = foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        try {
            [System.IO.Path]::GetFullPath($path.Trim())
        }
        catch {
            Write-Log -Level 'WARN' -Message "Ignoring invalid path '$path'."
        }
    }

    $normalized | Sort-Object -Unique
}

# This section gathers file candidates older than the cutoff and suppresses run-stopping errors.
function Get-EligibleFiles {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths,

        [Parameter(Mandatory)]
        [datetime]$Cutoff
    )

    $results = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($path in $Paths) {
        $script:Summary.TargetPaths++

        if (-not (Test-Path -LiteralPath $path)) {
            Write-Log -Level 'WARN' -Message "Target path '$path' does not exist."
            continue
        }

        try {
            $items = Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction Stop
            foreach ($item in $items) {
                $script:Summary.EnumeratedFiles++

                $fingerprint = '{0}|{1}|{2}' -f $item.FullName.ToLowerInvariant(), $item.Length, $item.LastWriteTimeUtc.Ticks
                if (-not $seen.Add($fingerprint)) {
                    $script:Summary.SkippedDuplicateEntries++
                    continue
                }

                if ($item.LastWriteTime -lt $Cutoff) {
                    $results.Add($item)
                }
                else {
                    $script:Summary.SkippedNewFiles++
                }
            }
        }
        catch {
            $script:Summary.Errors++
            Write-Log -Level 'ERROR' -Message "Failed to enumerate '$path'. $($_.Exception.Message)"
        }
    }

    return $results
}

# This section creates a rollback record entry for one file.
function New-RollbackRecord {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory)]
        [string]$BackupFolder
    )

    $backupName = '{0}{1}' -f ([guid]::NewGuid().ToString('N')), $File.Extension
    $backupPath = Join-Path $BackupFolder $backupName

    return [pscustomobject]@{
        OriginalPath = $File.FullName
        BackupPath   = $backupPath
        SizeBytes    = $File.Length
        LastWriteUtc = $File.LastWriteTimeUtc.ToString('o')
        RemovedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    }
}

# This section writes manifest metadata to support deterministic rollback.
function Save-RollbackManifest {
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]$Records,

        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [Parameter(Mandatory)]
        [int]$ConfiguredDays,

        [Parameter(Mandatory)]
        [string[]]$ConfiguredPaths
    )

    $manifest = [pscustomobject]@{
        RunId        = $script:RunId
        CreatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        DaysOld      = $ConfiguredDays
        TargetPath   = $ConfiguredPaths
        Records      = $Records
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8
}

# This section performs safe deletion for one file with per-file error handling.
function Remove-FileWithRollback {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory)]
        [string]$RollbackFolder,

        [Parameter(Mandatory)]
        [switch]$PreviewOnly,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Records
    )

    try {
        if (-not (Test-FileAvailable -Path $File.FullName)) {
            $script:Summary.LockedFiles++
            Write-Log -Level 'WARN' -Message "Skipped locked file '$($File.FullName)'."
            return
        }

        if ($PreviewOnly) {
            $script:Summary.DryRunCandidates++
            Write-Log -Message "DRYRUN would delete '$($File.FullName)'."
            return
        }

        $record = New-RollbackRecord -File $File -BackupFolder $RollbackFolder
        Copy-Item -LiteralPath $File.FullName -Destination $record.BackupPath -Force -ErrorAction Stop
        Remove-Item -LiteralPath $File.FullName -Force -ErrorAction Stop

        $Records.Add($record) | Out-Null
        $script:Summary.DeletedFiles++
        Write-Log -Message "Deleted '$($File.FullName)' after backup to '$($record.BackupPath)'."
    }
    catch {
        $script:Summary.Errors++
        Write-Log -Level 'ERROR' -Message "Failed processing '$($File.FullName)'. $($_.Exception.Message)"
    }
}

# This section resolves the rollback folder to use, either specific or latest available.
function Resolve-RollbackFolder {
    param(
        [Parameter()]
        [string]$DesiredRunId
    )

    if (-not [string]::IsNullOrWhiteSpace($DesiredRunId)) {
        $target = Join-Path $script:RollbackRoot $DesiredRunId
        if (-not (Test-Path -LiteralPath $target)) {
            throw "Rollback folder '$DesiredRunId' was not found."
        }
        return $target
    }

    $latest = Get-ChildItem -LiteralPath $script:RollbackRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latest) {
        throw 'No rollback folder exists yet.'
    }

    return $latest.FullName
}

# This section restores files from a prior cleanup run and keeps the process idempotent.
function Invoke-RollbackRestore {
    param(
        [Parameter()]
        [string]$DesiredRunId
    )

    $folder = Resolve-RollbackFolder -DesiredRunId $DesiredRunId
    $manifestPath = Join-Path $folder 'manifest.json'

    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Manifest file not found in '$folder'."
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Log -Message "Starting rollback using '$folder'."

    foreach ($record in $manifest.Records) {
        try {
            if (-not (Test-Path -LiteralPath $record.BackupPath)) {
                Write-Log -Level 'WARN' -Message "Backup missing for '$($record.OriginalPath)'."
                continue
            }

            if (Test-Path -LiteralPath $record.OriginalPath) {
                $script:Summary.SkippedExistingOnRestore++
                Write-Log -Level 'WARN' -Message "Skipped restore because file already exists '$($record.OriginalPath)'."
                continue
            }

            $parent = Split-Path -Path $record.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            Copy-Item -LiteralPath $record.BackupPath -Destination $record.OriginalPath -Force -ErrorAction Stop
            $script:Summary.RestoredFiles++
            Write-Log -Message "Restored '$($record.OriginalPath)'."
        }
        catch {
            $script:Summary.Errors++
            Write-Log -Level 'ERROR' -Message "Failed to restore '$($record.OriginalPath)'. $($_.Exception.Message)"
        }
    }
}

# This section gathers disk and optimization-related status using read-only commands only.
function Get-DiskTelemetry {
    $result = [ordered]@{
        PhysicalDisks       = @()
        Volumes             = @()
        DefragTaskStatus    = $null
        DefragTaskAvailable = $false
    }

    try {
        if (Get-Command -Name Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            $result.PhysicalDisks = Get-PhysicalDisk | Select-Object FriendlyName, SerialNumber, HealthStatus, OperationalStatus, MediaType,
                @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } }
        }
        else {
            $legacyDisks = Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop
            $result.PhysicalDisks = $legacyDisks | Select-Object Model,
                @{ Name = 'SerialNumber'; Expression = { $_.SerialNumber } },
                @{ Name = 'HealthStatus'; Expression = { 'Unknown-LegacyProvider' } },
                @{ Name = 'OperationalStatus'; Expression = { 'Unknown-LegacyProvider' } },
                @{ Name = 'MediaType'; Expression = { $_.MediaType } },
                @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } }
        }

        $script:Summary.DiskHealthRows = @($result.PhysicalDisks).Count
    }
    catch {
        $script:Summary.Errors++
        Write-Log -Level 'ERROR' -Message "Failed to collect physical disk details. $($_.Exception.Message)"
    }

    try {
        if (Get-Command -Name Get-Volume -ErrorAction SilentlyContinue) {
            $result.Volumes = Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus,
                @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
                @{ Name = 'FreeGB'; Expression = { [math]::Round($_.SizeRemaining / 1GB, 2) } }
        }
        else {
            $legacyVolumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop
            $result.Volumes = $legacyVolumes | Select-Object DeviceID,
                @{ Name = 'FileSystemLabel'; Expression = { $_.VolumeName } },
                @{ Name = 'FileSystem'; Expression = { $_.FileSystem } },
                @{ Name = 'HealthStatus'; Expression = { 'Unknown-LegacyProvider' } },
                @{ Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
                @{ Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } }
        }

        $script:Summary.VolumeRows = @($result.Volumes).Count
    }
    catch {
        $script:Summary.Errors++
        Write-Log -Level 'ERROR' -Message "Failed to collect volume details. $($_.Exception.Message)"
    }

    try {
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Defrag\' -TaskName 'ScheduledDefrag' -ErrorAction Stop
        $taskInfo = Get-ScheduledTaskInfo -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag\' -ErrorAction Stop

        $result.DefragTaskAvailable = $true
        $result.DefragTaskStatus = [pscustomobject]@{
            TaskState    = $task.State
            LastRunTime  = $taskInfo.LastRunTime
            LastTaskCode = $taskInfo.LastTaskResult
            NextRunTime  = $taskInfo.NextRunTime
        }
    }
    catch {
        Write-Log -Level 'WARN' -Message "Could not read ScheduledDefrag task state. $($_.Exception.Message)"
    }

    return $result
}

# This section writes disk and optimization data to console and log in a readable format.
function Write-DiskTelemetryReport {
    param(
        [Parameter(Mandatory)]
        $Telemetry
    )

    Write-Log -Message 'Disk Health Report:'
    foreach ($disk in $Telemetry.PhysicalDisks) {
        $diskName = if ($disk.PSObject.Properties.Match('FriendlyName').Count -gt 0) { $disk.FriendlyName } else { $disk.Model }
        Write-Log -Message ("Disk: {0} | Health: {1} | OpStatus: {2} | Media: {3} | SizeGB: {4}" -f $diskName, $disk.HealthStatus, $disk.OperationalStatus, $disk.MediaType, $disk.SizeGB)
    }

    Write-Log -Message 'Volume Capacity Report:'
    foreach ($volume in $Telemetry.Volumes) {
        $drive = if ($volume.PSObject.Properties.Match('DriveLetter').Count -gt 0) { $volume.DriveLetter } else { $volume.DeviceID }
        Write-Log -Message ("Volume: {0} | FS: {1} | Health: {2} | SizeGB: {3} | FreeGB: {4}" -f $drive, $volume.FileSystem, $volume.HealthStatus, $volume.SizeGB, $volume.FreeGB)
    }

    if ($Telemetry.DefragTaskAvailable -and $Telemetry.DefragTaskStatus) {
        Write-Log -Message ("Optimize Schedule: State={0}, LastRun={1}, LastResult={2}, NextRun={3}" -f $Telemetry.DefragTaskStatus.TaskState, $Telemetry.DefragTaskStatus.LastRunTime, $Telemetry.DefragTaskStatus.LastTaskCode, $Telemetry.DefragTaskStatus.NextRunTime)
    }
    else {
        Write-Log -Level 'WARN' -Message 'Optimize schedule status unavailable on this endpoint.'
    }

    Write-Log -Message 'Important: This script never runs defragmentation or optimize actions.'
}

# This section prints a consistent end-of-run summary block.
function Write-Summary {
    Write-Host ''
    Write-Host '========== Summary =========='
    foreach ($entry in $script:Summary.GetEnumerator()) {
        Write-Host ('{0}: {1}' -f $entry.Key, $entry.Value)
    }
    Write-Host '============================='
}

# This section contains the main workflow and ensures safe control flow.
try {
    Initialize-WorkFolders

    if ($Rollback) {
        $script:Summary.Mode = 'Rollback'
        Write-Log -Message 'Mode selected: Rollback'
        Invoke-RollbackRestore -DesiredRunId $RollbackId
        Write-Summary
        return
    }

    if ($EnableCleanup) {
        $script:Summary.Mode = if ($DryRun) { 'CleanupDryRun' } else { 'Cleanup' }
    }
    elseif ($DryRun) {
        $script:Summary.Mode = 'DryRunPreview'
    }

    $telemetry = Get-DiskTelemetry
    Write-DiskTelemetryReport -Telemetry $telemetry

    $normalizedTargets = Get-NormalizedTargetPaths -Paths $TargetPath
    $cutoff = (Get-Date).AddDays(-$DaysOld)
    Write-Log -Message "File age filter: older than $DaysOld day(s); cutoff $cutoff"

    $eligible = Get-EligibleFiles -Paths $normalizedTargets -Cutoff $cutoff
    $script:Summary.EligibleFiles = @($eligible).Count

    if (-not $EnableCleanup -and -not $DryRun) {
        Write-Log -Message 'Report-only mode complete. Use -DryRun to preview cleanup or -EnableCleanup to execute cleanup with rollback.'
        Write-Summary
        return
    }

    $records = New-Object 'System.Collections.Generic.List[object]'

    foreach ($file in $eligible) {
        Remove-FileWithRollback -File $file -RollbackFolder $script:CurrentRollbackFolder -PreviewOnly:$DryRun -Records $records
    }

    if (-not $DryRun) {
        Save-RollbackManifest -Records $records -ManifestPath $script:CurrentManifestPath -ConfiguredDays $DaysOld -ConfiguredPaths $normalizedTargets
        Write-Log -Message "Rollback manifest saved to '$($script:CurrentManifestPath)'."
    }

    Write-Summary
}
catch {
    $script:Summary.Errors++
    Write-Log -Level 'ERROR' -Message "Unhandled script error. $($_.Exception.Message)"
    Write-Summary
    throw
}
