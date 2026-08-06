[CmdletBinding()]
param(
    # Targets one or more folders that contain temp files to evaluate.
    [Parameter()]
    [string[]]$TargetPath = @(
        [System.IO.Path]::GetTempPath(),
        (Join-Path $env:WINDIR 'Temp')
    ),

    # Only files older than this number of days are processed.
    [Parameter()]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$DaysOld = 0,

    # Shows which files would be deleted without making any changes.
    [Parameter()]
    [switch]$DryRun,

    # Restores files from the latest rollback set, or from the set you specify.
    [Parameter()]
    [switch]$Rollback,

    # Optional rollback folder to restore from when using -Rollback.
    [Parameter()]
    [string]$RollbackPath
)

# This section sets up the script-wide folders used for logs and rollback data.
$script:StateRoot = Join-Path $env:LOCALAPPDATA 'DWP-TempCleanup'
$script:LogRoot = Join-Path $script:StateRoot 'Logs'
$script:RollbackRoot = Join-Path $script:StateRoot 'Rollback'
$script:Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogFile = Join-Path $script:LogRoot "TempCleanup_$($script:Timestamp).log"
$script:RollbackSet = if ($Rollback) { $null } else { Join-Path $script:RollbackRoot "Run_$($script:Timestamp)" }
$script:ManifestFile = if ($Rollback) { $null } else { Join-Path $script:RollbackSet 'manifest.json' }

# This section tracks the script summary so the final report is consistent.
$script:Summary = [ordered]@{
    TargetPaths        = 0
    EnumeratedFiles    = 0
    EligibleFiles      = 0
    DryRunCandidates   = 0
    DeletedFiles       = 0
    RestoredFiles      = 0
    LockedFiles        = 0
    SkippedNewFiles    = 0
    SkippedExisting    = 0
    Errors             = 0
}

# This section creates the working folders that the script needs before it starts.
function Initialize-WorkFolders {
    $folders = @($script:LogRoot, $script:RollbackRoot)
    if (-not $Rollback) {
        $folders += $script:RollbackSet
    }

    foreach ($folder in $folders) {
        if (-not (Test-Path -LiteralPath $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
}

# This section writes timestamped messages to both the console and the log file.
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

# This section safely checks whether a file is locked or otherwise unavailable.
function Test-FileAvailable {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        $stream.Close()
        $true
    }
    catch {
        $false
    }
}

# This section returns a normalized list of target folders with duplicates removed.
function Get-NormalizedTargetPaths {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths
    )

    $resolvedPaths = foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        try {
            [System.IO.Path]::GetFullPath($path.Trim())
        }
        catch {
            Write-Log -Level 'WARN' -Message "Ignoring invalid path value '$path'."
        }
    }

    $resolvedPaths | Sort-Object -Unique
}

# This section enumerates candidate temp files that are older than the configured cutoff.
function Get-EligibleFiles {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths,

        [Parameter(Mandatory)]
        [datetime]$Cutoff
    )

    $eligibleFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

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
                if ($item.LastWriteTime -lt $Cutoff) {
                    $eligibleFiles.Add($item)
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

    return $eligibleFiles
}

# This section builds the file record that is written to the rollback manifest.
function New-RollbackRecord {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory)]
        [string]$BackupFolder
    )

    $backupName = '{0}{1}' -f ([guid]::NewGuid().ToString('N')), $File.Extension
    $backupPath = Join-Path $BackupFolder $backupName

    [pscustomobject]@{
        OriginalPath  = $File.FullName
        BackupPath    = $backupPath
        LastWriteTime  = $File.LastWriteTime.ToString('o')
        SizeBytes     = $File.Length
        DeletedAt     = (Get-Date).ToString('o')
    }
}

# This section writes the rollback manifest so deleted files can be restored later.
function Save-RollbackManifest {
    param(
        [Parameter(Mandatory)]
        [object[]]$Records,

        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    $json = $Records | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $ManifestPath -Value $json -Encoding UTF8
}

# This section deletes a file safely by backing it up first and recording the action.
function Remove-TempFileSafely {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory)]
        [string]$RollbackFolder,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Records
    )

    $record = $null

    try {
        if (-not (Test-FileAvailable -Path $File.FullName)) {
            $script:Summary.LockedFiles++
            Write-Log -Level 'WARN' -Message "Skipped locked or inaccessible file '$($File.FullName)'."
            return
        }

        $record = New-RollbackRecord -File $File -BackupFolder $RollbackFolder
        Copy-Item -LiteralPath $File.FullName -Destination $record.BackupPath -Force -ErrorAction Stop
        Remove-Item -LiteralPath $File.FullName -Force -ErrorAction Stop

        $Records.Add($record) | Out-Null
        $script:Summary.DeletedFiles++
        Write-Log -Message "Deleted '$($File.FullName)' after backing it up to '$($record.BackupPath)'."
    }
    catch {
        $script:Summary.Errors++
        Write-Log -Level 'ERROR' -Message "Failed to delete '$($File.FullName)'. $($_.Exception.Message)"

        if ($record -and (Test-Path -LiteralPath $record.BackupPath)) {
            try {
                Remove-Item -LiteralPath $record.BackupPath -Force -ErrorAction Stop
            }
            catch {
                $script:Summary.Errors++
                Write-Log -Level 'WARN' -Message "Could not remove temporary backup '$($record.BackupPath)'. $($_.Exception.Message)"
            }
        }
    }
}

# This section restores files from a previously created rollback set.
function Invoke-RollbackRestore {
    param(
        [Parameter()]
        [string]$SpecifiedRollbackPath
    )

    $rollbackFolder = $SpecifiedRollbackPath
    if ([string]::IsNullOrWhiteSpace($rollbackFolder)) {
        $latest = Get-ChildItem -LiteralPath $script:RollbackRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $latest) {
            throw 'No rollback set was found.'
        }

        $rollbackFolder = $latest.FullName
    }

    $manifestPath = Join-Path $rollbackFolder 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Rollback manifest not found at '$manifestPath'."
    }

    $records = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $records) {
        Write-Log -Level 'WARN' -Message "Rollback manifest '$manifestPath' is empty."
        return
    }

    foreach ($record in @($records)) {
        try {
            if (Test-Path -LiteralPath $record.OriginalPath) {
                $script:Summary.SkippedExisting++
                Write-Log -Level 'WARN' -Message "Skipped restore for existing file '$($record.OriginalPath)'."
                continue
            }

            if (-not (Test-Path -LiteralPath $record.BackupPath)) {
                $script:Summary.Errors++
                Write-Log -Level 'ERROR' -Message "Backup file '$($record.BackupPath)' is missing."
                continue
            }

            $destinationFolder = Split-Path -Path $record.OriginalPath -Parent
            if (-not [string]::IsNullOrWhiteSpace($destinationFolder) -and -not (Test-Path -LiteralPath $destinationFolder)) {
                New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
            }

            Copy-Item -LiteralPath $record.BackupPath -Destination $record.OriginalPath -Force -ErrorAction Stop
            $script:Summary.RestoredFiles++
            Write-Log -Message "Restored '$($record.OriginalPath)' from '$($record.BackupPath)'."
        }
        catch {
            $script:Summary.Errors++
            Write-Log -Level 'ERROR' -Message "Failed to restore '$($record.OriginalPath)'. $($_.Exception.Message)"
        }
    }
}

# This section starts the script and decides whether to clean files or roll them back.
Initialize-WorkFolders

try {
    if ($Rollback) {
        Write-Log -Message 'Rollback mode started.'
        Invoke-RollbackRestore -SpecifiedRollbackPath $RollbackPath
    }
    else {
        $normalizedTargets = Get-NormalizedTargetPaths -Paths $TargetPath
        $cutoffDate = (Get-Date).AddDays(-$DaysOld)
        $records = New-Object System.Collections.Generic.List[object]

        Write-Log -Message "Cleanup started. DryRun=$DryRun DaysOld=$DaysOld Cutoff=$($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Log -Message "Target paths: $($normalizedTargets -join ', ')"

        $eligibleFiles = Get-EligibleFiles -Paths $normalizedTargets -Cutoff $cutoffDate
        $script:Summary.EligibleFiles = $eligibleFiles.Count

        if ($DryRun) {
            foreach ($file in $eligibleFiles) {
                $script:Summary.DryRunCandidates++
                Write-Log -Message "Dry run candidate: $($file.FullName)"
                Write-Output ('{0} | LastWriteTime={1}' -f $file.FullName, $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
            }
        }
        else {
            foreach ($file in $eligibleFiles) {
                Remove-TempFileSafely -File $file -RollbackFolder $script:RollbackSet -Records $records
            }

            if ($records.Count -gt 0) {
                Save-RollbackManifest -Records $records.ToArray() -ManifestPath $script:ManifestFile
                Write-Log -Message "Rollback manifest saved to '$script:ManifestFile'."
            }
            else {
                Write-Log -Message 'No files were deleted, so no rollback manifest was created.'
            }
        }
    }
}
catch {
    $script:Summary.Errors++
    Write-Log -Level 'ERROR' -Message "The script stopped because of an unrecoverable error. $($_.Exception.Message)"
}
finally {
    # This section prints a final summary so the engineer can review the outcome quickly.
    Write-Log -Message 'Summary report follows.'
    Write-Log -Message "Target paths processed: $($script:Summary.TargetPaths)"
    Write-Log -Message "Files enumerated: $($script:Summary.EnumeratedFiles)"
    Write-Log -Message "Files older than cutoff: $($script:Summary.EligibleFiles)"
    Write-Log -Message "Dry-run candidates: $($script:Summary.DryRunCandidates)"
    Write-Log -Message "Files deleted: $($script:Summary.DeletedFiles)"
    Write-Log -Message "Files restored: $($script:Summary.RestoredFiles)"
    Write-Log -Message "Locked or inaccessible files skipped: $($script:Summary.LockedFiles)"
    Write-Log -Message "Newer files skipped: $($script:Summary.SkippedNewFiles)"
    Write-Log -Message "Existing files skipped during rollback: $($script:Summary.SkippedExisting)"
    Write-Log -Message "Errors logged: $($script:Summary.Errors)"
    Write-Log -Message "Log file: $script:LogFile"

    if (-not $Rollback) {
        Write-Log -Message "Rollback folder: $script:RollbackSet"
    }
}