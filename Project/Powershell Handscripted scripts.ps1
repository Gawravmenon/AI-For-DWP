[CmdletBinding(DefaultParameterSetName = "Cleanup")]
param(
    # Path to scan for files.
    [Parameter(ParameterSetName = "Cleanup")]
    [string]$TargetPath = ".",

    # Files older than this many days are eligible. Default 0 means older than now.
    [Parameter(ParameterSetName = "Cleanup")]
    [ValidateRange(0, 36500)]
    [int]$OlderThanDays = 0,

    # Optional file name pattern filter.
    [Parameter(ParameterSetName = "Cleanup")]
    [string]$Filter = "*",

    # Preview mode. Lists files that would be deleted (moved to quarantine) and makes no changes.
    [Parameter(ParameterSetName = "Cleanup")]
    [switch]$DryRun,

    # Quarantine path used for safe delete and rollback support.
    [Parameter(ParameterSetName = "Cleanup")]
    [string]$QuarantineRoot,

    # Rollback mode switch.
    [Parameter(ParameterSetName = "Rollback", Mandatory = $true)]
    [switch]$Rollback,

    # Optional manifest path for rollback. If omitted, latest manifest in QuarantineRoot is used.
    [Parameter(ParameterSetName = "Rollback")]
    [string]$ManifestPath,

    # Optional quarantine path for rollback mode.
    [Parameter(ParameterSetName = "Rollback")]
    [string]$RollbackQuarantineRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# This section prepares timestamped paths and runtime constants.
$timeStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resolvedTargetPath = $null
if ($PSCmdlet.ParameterSetName -eq "Cleanup") {
    $resolvedTargetPath = (Resolve-Path -Path $TargetPath).Path
    if ([string]::IsNullOrWhiteSpace($QuarantineRoot)) {
        $QuarantineRoot = Join-Path $resolvedTargetPath ".cleanup-quarantine"
    }
} else {
    if ([string]::IsNullOrWhiteSpace($RollbackQuarantineRoot)) {
        if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
            $RollbackQuarantineRoot = Join-Path (Get-Location).Path ".cleanup-quarantine"
        } else {
            $RollbackQuarantineRoot = Split-Path -Path (Split-Path -Path $ManifestPath -Parent) -Parent
        }
    }
}

# This section creates log locations and a logger that writes every action with date and time.
if ($PSCmdlet.ParameterSetName -eq "Cleanup") {
    $logDir = Join-Path $QuarantineRoot "logs"
} else {
    $logDir = Join-Path $RollbackQuarantineRoot "logs"
}
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$logPath = Join-Path $logDir ("cleanup-{0}.log" -f $timeStamp)

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level.ToUpperInvariant(), $Message
    Add-Content -Path $logPath -Value $line

    switch ($Level.ToUpperInvariant()) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "DRYRUN" { Write-Host $line -ForegroundColor DarkYellow }
        default  { Write-Host $line -ForegroundColor Cyan }
    }
}

# This section checks lock state so locked files are skipped, logged, and do not stop the script.
function Test-FileLocked {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($null -ne $stream) {
            $stream.Close()
            $stream.Dispose()
        }
        return [pscustomobject]@{ IsLocked = $false; Error = "" }
    }
    catch {
        return [pscustomobject]@{ IsLocked = $true; Error = $_.Exception.Message }
    }
}

# This section generates a stable quarantine path for each source file to support idempotence.
function Get-QuarantinePath {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$QuarantineBase
    )

    $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($SourcePath.ToLowerInvariant())
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = ($sha.ComputeHash($hashBytes) | ForEach-Object { $_.ToString("x2") }) -join ""
    }
    finally {
        $sha.Dispose()
    }

    $leaf = Split-Path -Path $SourcePath -Leaf
    $fileName = "{0}-{1}" -f $hash.Substring(0, 12), $leaf
    return Join-Path (Join-Path $QuarantineBase "files") $fileName
}

# This section appends one manifest entry per move for rollback and repeat-run safety.
function Add-ManifestEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Manifest,
        [Parameter(Mandatory = $true)][hashtable]$Entry
    )

    ($Entry | ConvertTo-Json -Compress) | Add-Content -Path $Manifest
}

# This section loads JSON-lines manifest entries safely.
function Read-ManifestEntries {
    param([Parameter(Mandatory = $true)][string]$Manifest)

    $entries = @()
    if (-not (Test-Path -Path $Manifest)) {
        return $entries
    }

    Get-Content -Path $Manifest | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_)) {
            $entries += ($_ | ConvertFrom-Json)
        }
    }

    return $entries
}

if ($PSCmdlet.ParameterSetName -eq "Cleanup") {
    # This section initializes cleanup folders, manifest, and summary counters.
    $filesDir = Join-Path $QuarantineRoot "files"
    $manifestDir = Join-Path $QuarantineRoot "manifests"
    New-Item -Path $filesDir -ItemType Directory -Force | Out-Null
    New-Item -Path $manifestDir -ItemType Directory -Force | Out-Null

    $manifestPathRun = Join-Path $manifestDir ("manifest-{0}.jsonl" -f $timeStamp)
    New-Item -Path $manifestPathRun -ItemType File -Force | Out-Null

    $cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)
    $summary = [ordered]@{
        Mode = if ($DryRun) { "DryRun" } else { "Cleanup" }
        TargetPath = $resolvedTargetPath
        CutoffTime = $cutoff
        Filter = $Filter
        Scanned = 0
        Eligible = 0
        MovedToQuarantine = 0
        AlreadyProcessed = 0
        LockedSkipped = 0
        Errors = 0
    }

    Write-Log -Level "INFO" -Message "Starting cleanup. TargetPath=$resolvedTargetPath OlderThanDays=$OlderThanDays Cutoff=$cutoff Filter=$Filter DryRun=$DryRun"

    # This section gathers candidate files while excluding quarantine internals.
    $allFiles = Get-ChildItem -Path $resolvedTargetPath -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notlike "$QuarantineRoot*" -and
            $_.Name -like $Filter
        }

    # This section applies age filtering.
    $eligibleFiles = $allFiles | Where-Object { $_.LastWriteTime -lt $cutoff }

    $summary.Scanned = @($allFiles).Count
    $summary.Eligible = @($eligibleFiles).Count

    if ($DryRun) {
        # This section prints the exact list of files that would be deleted.
        Write-Log -Level "DRYRUN" -Message "Files that would be deleted (moved to quarantine):"
        foreach ($file in $eligibleFiles) {
            Write-Log -Level "DRYRUN" -Message $file.FullName
        }
    } else {
        # This section processes each file independently with per-file try/catch handling.
        foreach ($file in $eligibleFiles) {
            try {
                $destPath = Get-QuarantinePath -SourcePath $file.FullName -QuarantineBase $QuarantineRoot

                # This keeps the run idempotent by skipping files already moved on prior runs.
                if (-not (Test-Path -Path $file.FullName) -and (Test-Path -Path $destPath)) {
                    $summary.AlreadyProcessed++
                    Write-Log -Level "INFO" -Message "Already processed in a previous run. Skipping: $($file.FullName)"
                    continue
                }

                $lockCheck = Test-FileLocked -Path $file.FullName
                if ($lockCheck.IsLocked) {
                    $summary.LockedSkipped++
                    Write-Log -Level "WARN" -Message "Locked file skipped: $($file.FullName). Reason: $($lockCheck.Error)"
                    continue
                }

                Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
                $summary.MovedToQuarantine++

                Add-ManifestEntry -Manifest $manifestPathRun -Entry @{
                    action = "move"
                    source = $file.FullName
                    quarantine = $destPath
                    movedAt = (Get-Date).ToString("o")
                    size = $file.Length
                    lastWriteTime = $file.LastWriteTime.ToString("o")
                }

                Write-Log -Level "INFO" -Message "Moved to quarantine: $($file.FullName) -> $destPath"
            }
            catch {
                $summary.Errors++
                Write-Log -Level "ERROR" -Message "Failed processing file: $($file.FullName). Error: $($_.Exception.Message)"
            }
        }
    }

    # This section writes and prints summary output.
    $summaryPath = Join-Path $manifestDir ("summary-{0}.json" -f $timeStamp)
    $summary | ConvertTo-Json -Depth 4 | Out-File -FilePath $summaryPath -Encoding utf8

    Write-Log -Level "INFO" -Message "Summary: Scanned=$($summary.Scanned), Eligible=$($summary.Eligible), Moved=$($summary.MovedToQuarantine), AlreadyProcessed=$($summary.AlreadyProcessed), LockedSkipped=$($summary.LockedSkipped), Errors=$($summary.Errors)"
    Write-Log -Level "INFO" -Message "Run manifest: $manifestPathRun"
    Write-Log -Level "INFO" -Message "Run summary: $summaryPath"
    Write-Log -Level "INFO" -Message "Run log: $logPath"
}
else {
    # This section performs rollback using the specified or latest manifest.
    $manifestToUse = $ManifestPath
    if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
        $manifestDir = Join-Path $RollbackQuarantineRoot "manifests"
        if (-not (Test-Path -Path $manifestDir)) {
            throw "Rollback manifest directory not found: $manifestDir"
        }

        $manifestToUse = Get-ChildItem -Path $manifestDir -File -Filter "manifest-*.jsonl" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1 |
            ForEach-Object { $_.FullName }

        if ([string]::IsNullOrWhiteSpace($manifestToUse)) {
            throw "No manifest files were found in $manifestDir"
        }
    }

    Write-Log -Level "INFO" -Message "Starting rollback using manifest: $manifestToUse"

    $entries = Read-ManifestEntries -Manifest $manifestToUse
    $summary = [ordered]@{
        Mode = "Rollback"
        Manifest = $manifestToUse
        Entries = @($entries).Count
        Restored = 0
        AlreadyRestored = 0
        MissingQuarantineFile = 0
        Errors = 0
    }

    foreach ($entry in $entries) {
        try {
            $source = [string]$entry.source
            $quarantine = [string]$entry.quarantine

            if (Test-Path -Path $source) {
                $summary.AlreadyRestored++
                Write-Log -Level "INFO" -Message "Already restored. Skipping: $source"
                continue
            }

            if (-not (Test-Path -Path $quarantine)) {
                $summary.MissingQuarantineFile++
                Write-Log -Level "WARN" -Message "Quarantine file missing, cannot restore: $quarantine"
                continue
            }

            $parent = Split-Path -Path $source -Parent
            if (-not (Test-Path -Path $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }

            Move-Item -Path $quarantine -Destination $source -Force -ErrorAction Stop
            $summary.Restored++
            Write-Log -Level "INFO" -Message "Restored: $source"
        }
        catch {
            $summary.Errors++
            Write-Log -Level "ERROR" -Message "Failed rollback entry. Source=$($entry.source). Error: $($_.Exception.Message)"
        }
    }

    Write-Log -Level "INFO" -Message "Rollback summary: Entries=$($summary.Entries), Restored=$($summary.Restored), AlreadyRestored=$($summary.AlreadyRestored), MissingQuarantineFile=$($summary.MissingQuarantineFile), Errors=$($summary.Errors)"
    Write-Log -Level "INFO" -Message "Run log: $logPath"
}
