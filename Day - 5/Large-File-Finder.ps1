<#
.SYNOPSIS
Safely finds and optionally removes large files with rollback support.

.DESCRIPTION
This PowerShell 5.1 script scans one or more paths for files at or above a size threshold,
filters by file age, and reports results. By default, the script is read-only.
Use -DryRun to preview delete candidates or -Execute to move candidates into a rollback
quarantine folder (safe delete pattern). Use -Rollback to restore files from a manifest.
#>

[CmdletBinding(DefaultParameterSetName = 'Scan', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    # Paths to scan recursively for large files.
    [Parameter(ParameterSetName = 'Scan')]
    [string[]]$Path = @('C:\Users'),

    # Size threshold in MB for large file detection.
    [Parameter(ParameterSetName = 'Scan')]
    [double]$ThresholdMB = 100,

    # Only include files older than this many days.
    [Parameter(ParameterSetName = 'Scan')]
    [int]$OlderThanDays = 0,

    # Preview mode: show what would be deleted without changing files.
    [Parameter(ParameterSetName = 'Scan')]
    [switch]$DryRun,

    # Execute mode: move candidate files into quarantine for rollback.
    [Parameter(ParameterSetName = 'Scan')]
    [switch]$Execute,

    # Root folder used for rollback manifests and quarantined files.
    [Parameter(ParameterSetName = 'Scan')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$RollbackRoot,

    # Directory where timestamped log files are written.
    [Parameter(ParameterSetName = 'Scan')]
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$LogDirectory,

    # Roll back previously quarantined files using a manifest.
    [Parameter(ParameterSetName = 'Rollback', Mandatory = $true)]
    [switch]$Rollback,

    # Manifest path used for rollback; defaults to latest manifest when omitted.
    [Parameter(ParameterSetName = 'Rollback')]
    [string]$ManifestPath
)

# Section: Resolve script-relative defaults safely for PowerShell 5.1.
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }

if (-not $RollbackRoot) {
    $RollbackRoot = Join-Path -Path $env:ProgramData -ChildPath 'DWP\LargeFileRollback'
}
if (-not $LogDirectory) {
    $LogDirectory = Join-Path -Path $scriptDirectory -ChildPath 'logs'
}

# Section: Prepare runtime folders and timestamped log/manifest names.
$null = New-Item -Path $RollbackRoot -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item -Path $LogDirectory -ItemType Directory -Force -ErrorAction SilentlyContinue

$timeStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logFile = Join-Path -Path $LogDirectory -ChildPath ("LargeFileFinder-{0}.log" -f $timeStamp)

# Section: Centralized logging helper for console + file logging.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFile -Value $line
    Write-Host $line
}

# Section: Check whether a file is locked by another process.
function Test-FileLocked {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $stream = $null
    try {
        $stream = [System.IO.File]::Open(
            $LiteralPath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::None
        )
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    finally {
        if ($stream) {
            $stream.Dispose()
        }
    }
}

# Section: Build a deterministic quarantine path for idempotent processing.
function Get-QuarantinePath {
    param(
        [Parameter(Mandatory = $true)][string]$OriginalPath,
        [Parameter(Mandatory = $true)][string]$RootPath
    )

    $sanitized = $OriginalPath -replace '[:\\/]', '_'
    return Join-Path -Path $RootPath -ChildPath (Join-Path -Path 'quarantine' -ChildPath $sanitized)
}

# Section: Print an end-of-run summary in a consistent format.
function Show-Summary {
    param([Parameter(Mandatory = $true)][hashtable]$Summary)

    Write-Host ''
    Write-Host '===== Summary ====='
    $Summary.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }
}

# Section: Perform rollback using a manifest produced by execute mode.
function Invoke-Rollback {
    param(
        [string]$RollbackRoot,
        [string]$ManifestPath
    )

    if (-not $ManifestPath) {
        $latest = Get-ChildItem -Path $RollbackRoot -Filter 'manifest-*.json' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $latest) {
            throw "No rollback manifest found under '$RollbackRoot'."
        }

        $ManifestPath = $latest.FullName
    }

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Manifest path not found: $ManifestPath"
    }

    Write-Log -Message "Rollback started. Manifest: $ManifestPath"

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $summary = @{
        Manifest = $ManifestPath
        EntriesTotal = 0
        Restored = 0
        SkippedNotMoved = 0
        SkippedOriginalExists = 0
        MissingQuarantineFile = 0
        Errors = 0
    }

    foreach ($entry in $manifest.Entries) {
        $summary.EntriesTotal++

        if ($entry.ActionResult -ne 'Moved') {
            $summary.SkippedNotMoved++
            continue
        }

        try {
            if (Test-Path -LiteralPath $entry.OriginalPath) {
                $summary.SkippedOriginalExists++
                Write-Log -Level 'WARN' -Message "Skip restore (already exists): $($entry.OriginalPath)"
                $entry.ActionResult = 'RestoreSkippedOriginalExists'
                continue
            }

            if (-not (Test-Path -LiteralPath $entry.QuarantinePath)) {
                $summary.MissingQuarantineFile++
                Write-Log -Level 'WARN' -Message "Skip restore (missing quarantine file): $($entry.QuarantinePath)"
                continue
            }

            $originalDir = Split-Path -Path $entry.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $originalDir)) {
                $null = New-Item -Path $originalDir -ItemType Directory -Force
            }

            if ($PSCmdlet.ShouldProcess($entry.OriginalPath, "Restore from $($entry.QuarantinePath)")) {
                Move-Item -LiteralPath $entry.QuarantinePath -Destination $entry.OriginalPath -Force -ErrorAction Stop
                $summary.Restored++
                $entry.ActionResult = 'Restored'
                $entry.RestoredAtUtc = (Get-Date).ToUniversalTime().ToString('o')
                Write-Log -Message "Restored: $($entry.OriginalPath)"
            }
        }
        catch {
            $summary.Errors++
            $entry.ActionResult = 'RestoreError'
            $entry.Error = $_.Exception.Message
            Write-Log -Level 'ERROR' -Message "Restore failed for $($entry.OriginalPath): $($_.Exception.Message)"
        }
    }

    $postRollbackManifest = [System.IO.Path]::ChangeExtension($ManifestPath, '.post-rollback.json')
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $postRollbackManifest -Encoding UTF8
    Write-Log -Message "Post-rollback manifest written: $postRollbackManifest"

    Show-Summary -Summary $summary
}

# Section: Validate input and dispatch either scan mode or rollback mode.
try {
    if ($ThresholdMB -lt 0) {
        throw 'ThresholdMB must be 0 or greater.'
    }

    if ($OlderThanDays -lt 0) {
        Write-Log -Level 'WARN' -Message 'OlderThanDays was negative. Using 0 to keep behavior safe.'
        $OlderThanDays = 0
    }

    if ($Rollback) {
        Invoke-Rollback -RollbackRoot $RollbackRoot -ManifestPath $ManifestPath
        return
    }

    Write-Log -Message "Scan started. ThresholdMB=$ThresholdMB, OlderThanDays=$OlderThanDays, DryRun=$DryRun, Execute=$Execute"

    $thresholdBytes = [int64]($ThresholdMB * 1MB)
    $cutoffDate = (Get-Date).AddDays(-$OlderThanDays)

    $manifestPathOut = Join-Path -Path $RollbackRoot -ChildPath ("manifest-{0}.json" -f $timeStamp)
    $manifest = [ordered]@{
        CreatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        Mode = if ($DryRun) { 'DryRun' } elseif ($Execute) { 'Execute' } else { 'ReportOnly' }
        ThresholdMB = $ThresholdMB
        OlderThanDays = $OlderThanDays
        Paths = $Path
        Entries = @()
    }

    $summary = @{
        PathsRequested = $Path.Count
        FilesScanned = 0
        Candidates = 0
        DryRunWouldDelete = 0
        Quarantined = 0
        ReportOnly = 0
        LockedSkipped = 0
        PathErrors = 0
        FileErrors = 0
        ReclaimedMB = 0
        Manifest = $manifestPathOut
        LogFile = $logFile
    }

    foreach ($targetPath in $Path) {
        if (-not (Test-Path -LiteralPath $targetPath)) {
            $summary.PathErrors++
            Write-Log -Level 'WARN' -Message "Path not found, skipping: $targetPath"
            continue
        }

        Write-Log -Message "Scanning path: $targetPath"

        try {
            $files = Get-ChildItem -LiteralPath $targetPath -File -Recurse -Force -ErrorAction Stop
        }
        catch {
            $summary.PathErrors++
            Write-Log -Level 'ERROR' -Message "Failed scanning path '$targetPath': $($_.Exception.Message)"
            continue
        }

        foreach ($file in $files) {
            $summary.FilesScanned++

            # Skip rollback folder to avoid re-processing quarantined files.
            if ($file.FullName.StartsWith($RollbackRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            if ($file.Length -lt $thresholdBytes) {
                continue
            }

            if ($file.LastWriteTime -gt $cutoffDate) {
                continue
            }

            $summary.Candidates++

            $entry = [ordered]@{
                OriginalPath = $file.FullName
                SizeMB = [math]::Round(($file.Length / 1MB), 2)
                LastWriteTime = $file.LastWriteTime.ToString('s')
                QuarantinePath = $null
                ActionResult = $null
                Error = $null
            }

            try {
                if (Test-FileLocked -LiteralPath $file.FullName) {
                    $summary.LockedSkipped++
                    $entry.ActionResult = 'SkippedLocked'
                    Write-Log -Level 'WARN' -Message "Locked file skipped: $($file.FullName)"
                    $manifest.Entries += [pscustomobject]$entry
                    continue
                }

                if ($DryRun) {
                    $summary.DryRunWouldDelete++
                    $entry.ActionResult = 'DryRunWouldDelete'
                    Write-Host ("DRY RUN -> Would delete: {0} ({1} MB)" -f $file.FullName, $entry.SizeMB)
                    Write-Log -Message "Dry run candidate: $($file.FullName)"
                    $manifest.Entries += [pscustomobject]$entry
                    continue
                }

                if (-not $Execute) {
                    $summary.ReportOnly++
                    $entry.ActionResult = 'ReportOnlyCandidate'
                    Write-Host ("CANDIDATE -> {0} ({1} MB)" -f $file.FullName, $entry.SizeMB)
                    Write-Log -Message "Report-only candidate: $($file.FullName)"
                    $manifest.Entries += [pscustomobject]$entry
                    continue
                }

                $quarantinePath = Get-QuarantinePath -OriginalPath $file.FullName -RootPath $RollbackRoot
                $entry.QuarantinePath = $quarantinePath

                if (Test-Path -LiteralPath $quarantinePath) {
                    $entry.ActionResult = 'AlreadyQuarantined'
                    Write-Log -Level 'WARN' -Message "Already quarantined, idempotent skip: $($file.FullName)"
                    $manifest.Entries += [pscustomobject]$entry
                    continue
                }

                $quarantineDir = Split-Path -Path $quarantinePath -Parent
                if (-not (Test-Path -LiteralPath $quarantineDir)) {
                    $null = New-Item -Path $quarantineDir -ItemType Directory -Force
                }

                if ($PSCmdlet.ShouldProcess($file.FullName, "Move to quarantine '$quarantinePath'")) {
                    Move-Item -LiteralPath $file.FullName -Destination $quarantinePath -Force -ErrorAction Stop
                    $summary.Quarantined++
                    $summary.ReclaimedMB += $entry.SizeMB
                    $entry.ActionResult = 'Moved'
                    Write-Log -Message "Moved to quarantine: $($file.FullName)"
                }
                else {
                    $entry.ActionResult = 'WhatIfSkipped'
                }

                $manifest.Entries += [pscustomobject]$entry
            }
            catch {
                $summary.FileErrors++
                $entry.ActionResult = 'Error'
                $entry.Error = $_.Exception.Message
                Write-Log -Level 'ERROR' -Message "File processing failed '$($file.FullName)': $($_.Exception.Message)"
                $manifest.Entries += [pscustomobject]$entry
                continue
            }
        }
    }

    $manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPathOut -Encoding UTF8
    Write-Log -Message "Manifest written: $manifestPathOut"

    Show-Summary -Summary $summary
}
catch {
    Write-Log -Level 'ERROR' -Message "Fatal error: $($_.Exception.Message)"
    throw
}
