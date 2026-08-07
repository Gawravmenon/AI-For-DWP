<#
.SYNOPSIS
Audits and safely removes startup program files from Windows startup folders.

.DESCRIPTION
This script scans common startup folders, targets files older than a configurable
number of days, and removes them from startup by moving them into a quarantine
folder so they can be restored later.

Key safety features:
- Dry run mode (prints files that would be removed)
- Per-file try/catch handling
- Locked-file detection and skip behavior
- Timestamped action logging
- Rollback support via manifest file
- Idempotent behavior across repeated runs

.NOTES
PowerShell version: 5.1
#>

[CmdletBinding()]
param(
    # When set, no files are changed. The script prints what would be removed.
    [switch]$DryRun,

    # Targets files with LastWriteTime older than this many days. Default 0 means all existing files.
    [ValidateRange(0, 36500)]
    [int]$OlderThanDays = 0,

    # When set, restores files from a previous quarantine manifest.
    [switch]$Rollback,

    # Optional explicit manifest path for rollback. If omitted, the latest manifest is used.
    [string]$RollbackManifest,

    # Directory where timestamped log files are written.
    [string]$LogDirectory,

    # Root directory used to store quarantined files and manifests.
    [string]$QuarantineRoot
)

# Section: Resolve runtime paths and initialize metadata.
$scriptBasePath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
if (-not $scriptBasePath) {
    $scriptBasePath = (Get-Location).Path
}

if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
    $LogDirectory = Join-Path -Path $scriptBasePath -ChildPath 'logs'
}

if ([string]::IsNullOrWhiteSpace($QuarantineRoot)) {
    $QuarantineRoot = Join-Path -Path $scriptBasePath -ChildPath 'quarantine'
}

# Section: Create required directories and initialize run metadata.
$script:RunTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogFileName = "StartupProgramAudit_$script:RunTimestamp.log"
$script:LogFilePath = Join-Path -Path $LogDirectory -ChildPath $script:LogFileName

if (-not (Test-Path -Path $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $QuarantineRoot)) {
    New-Item -Path $QuarantineRoot -ItemType Directory -Force | Out-Null
}

# Section: Logging helper that writes every action to both console and log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'ACTION', 'SUMMARY')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $script:LogFilePath -Value $line
}

# Section: Helper to detect whether a file is locked by another process.
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $stream = $null
    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        return $false
    }
    catch [System.IO.IOException] {
        return $true
    }
    catch {
        # Access or other non-lock issues are handled during action attempt.
        return $false
    }
    finally {
        if ($stream) {
            $stream.Close()
            $stream.Dispose()
        }
    }
}

# Section: Helper to produce unique, file-system-safe quarantine file names.
function Get-QuarantineFileName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalPath
    )

    $safe = $OriginalPath -replace '[:\\/]', '_'
    return $safe
}

# Section: Rollback workflow restores files from a prior manifest and exits.
if ($Rollback) {
    Write-Log -Level 'INFO' -Message 'Rollback mode selected.'

    $manifestPathToUse = $null

    if ($RollbackManifest) {
        $manifestPathToUse = $RollbackManifest
    }
    else {
        $latestManifest = Get-ChildItem -Path $QuarantineRoot -Recurse -Filter 'manifest.csv' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($latestManifest) {
            $manifestPathToUse = $latestManifest.FullName
        }
    }

    if (-not $manifestPathToUse -or -not (Test-Path -Path $manifestPathToUse)) {
        Write-Log -Level 'ERROR' -Message 'No rollback manifest found. Provide -RollbackManifest or ensure quarantine manifests exist.'
        Write-Host "Log file: $script:LogFilePath"
        return
    }

    Write-Log -Level 'INFO' -Message "Using rollback manifest: $manifestPathToUse"

    $rollbackSummary = [ordered]@{
        TotalEntries    = 0
        Restored        = 0
        AlreadyRestored = 0
        MissingInBackup = 0
        Errors          = 0
    }

    $manifestRows = Import-Csv -Path $manifestPathToUse
    $rollbackSummary.TotalEntries = ($manifestRows | Measure-Object).Count

    foreach ($row in $manifestRows) {
        try {
            $sourcePath = $row.SourcePath
            $backupPath = $row.QuarantinePath

            if (-not (Test-Path -Path $backupPath)) {
                $rollbackSummary.MissingInBackup++
                Write-Log -Level 'WARN' -Message "Backup missing, cannot restore: $backupPath"
                continue
            }

            if (Test-Path -Path $sourcePath) {
                $rollbackSummary.AlreadyRestored++
                Write-Log -Level 'INFO' -Message "Already restored (idempotent skip): $sourcePath"
                continue
            }

            $sourceDir = Split-Path -Path $sourcePath -Parent
            if (-not (Test-Path -Path $sourceDir)) {
                New-Item -Path $sourceDir -ItemType Directory -Force | Out-Null
            }

            Move-Item -Path $backupPath -Destination $sourcePath -Force -ErrorAction Stop
            $rollbackSummary.Restored++
            Write-Log -Level 'ACTION' -Message "Restored: $sourcePath"
        }
        catch {
            $rollbackSummary.Errors++
            Write-Log -Level 'ERROR' -Message "Rollback failed for '$($row.SourcePath)': $($_.Exception.Message)"
        }
    }

    Write-Log -Level 'SUMMARY' -Message 'Rollback summary:'
    Write-Log -Level 'SUMMARY' -Message "TotalEntries=$($rollbackSummary.TotalEntries), Restored=$($rollbackSummary.Restored), AlreadyRestored=$($rollbackSummary.AlreadyRestored), MissingInBackup=$($rollbackSummary.MissingInBackup), Errors=$($rollbackSummary.Errors)"
    Write-Host "Log file: $script:LogFilePath"
    return
}

# Section: Build startup folder targets for current user and all users.
$startupPaths = @(
    (Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\Start Menu\Programs\StartUp'),
    (Join-Path -Path $env:APPDATA -ChildPath 'Microsoft\Windows\Start Menu\Programs\Startup')
)

# Section: Compute age cutoff and initialize summary counters.
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
$quarantineRunPath = Join-Path -Path $QuarantineRoot -ChildPath "Run_$script:RunTimestamp"
$manifestPath = Join-Path -Path $quarantineRunPath -ChildPath 'manifest.csv'

$summary = [ordered]@{
    StartupPathsChecked   = 0
    StartupPathsMissing   = 0
    FilesScanned          = 0
    FilesOlderThanCutoff  = 0
    FilesDryRunListed     = 0
    FilesMovedToQuarantine= 0
    FilesSkippedLocked    = 0
    FilesSkippedByAge     = 0
    FileErrors            = 0
}

Write-Log -Level 'INFO' -Message "Run started. DryRun=$DryRun, OlderThanDays=$OlderThanDays, Cutoff=$cutoffDate"

if (-not $DryRun) {
    New-Item -Path $quarantineRunPath -ItemType Directory -Force | Out-Null
    # Create an empty manifest with headers so rollback is predictable and idempotent.
    "SourcePath,QuarantinePath,OriginalLastWriteTime,ProcessedAt" | Set-Content -Path $manifestPath
    Write-Log -Level 'INFO' -Message "Quarantine path: $quarantineRunPath"
    Write-Log -Level 'INFO' -Message "Manifest path: $manifestPath"
}

# Section: Iterate startup folders and process each file with per-file error handling.
foreach ($path in $startupPaths) {
    $summary.StartupPathsChecked++

    if (-not (Test-Path -Path $path)) {
        $summary.StartupPathsMissing++
        Write-Log -Level 'WARN' -Message "Startup path not found, skipping: $path"
        continue
    }

    Write-Log -Level 'INFO' -Message "Scanning startup path: $path"

    $files = Get-ChildItem -Path $path -File -Force -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $summary.FilesScanned++

        try {
            if ($file.LastWriteTime -gt $cutoffDate) {
                $summary.FilesSkippedByAge++
                Write-Log -Level 'INFO' -Message "Skipped by age: $($file.FullName)"
                continue
            }

            $summary.FilesOlderThanCutoff++

            if (Test-FileLocked -Path $file.FullName) {
                $summary.FilesSkippedLocked++
                Write-Log -Level 'WARN' -Message "File locked, skipped: $($file.FullName)"
                continue
            }

            if ($DryRun) {
                $summary.FilesDryRunListed++
                Write-Log -Level 'ACTION' -Message "[DryRun] Would remove from startup: $($file.FullName)"
                continue
            }

            $quarantineName = Get-QuarantineFileName -OriginalPath $file.FullName
            $quarantineDestination = Join-Path -Path $quarantineRunPath -ChildPath $quarantineName

            if (Test-Path -Path $quarantineDestination) {
                # Idempotent safety: if destination exists, skip to avoid accidental overwrite.
                $summary.FileErrors++
                Write-Log -Level 'ERROR' -Message "Quarantine destination already exists, skipped: $quarantineDestination"
                continue
            }

            Move-Item -Path $file.FullName -Destination $quarantineDestination -Force -ErrorAction Stop

            $manifestLine = '"{0}","{1}","{2}","{3}"' -f `
                $file.FullName.Replace('"', '""'), `
                $quarantineDestination.Replace('"', '""'), `
                $file.LastWriteTime.ToString('o'), `
                (Get-Date).ToString('o')

            Add-Content -Path $manifestPath -Value $manifestLine

            $summary.FilesMovedToQuarantine++
            Write-Log -Level 'ACTION' -Message "Removed from startup (quarantined): $($file.FullName)"
        }
        catch {
            $summary.FileErrors++
            Write-Log -Level 'ERROR' -Message "Failed processing file '$($file.FullName)': $($_.Exception.Message)"
        }
    }
}

# Section: Print and log final summary for operational reporting.
Write-Log -Level 'SUMMARY' -Message 'Run summary:'
Write-Log -Level 'SUMMARY' -Message "StartupPathsChecked=$($summary.StartupPathsChecked), StartupPathsMissing=$($summary.StartupPathsMissing)"
Write-Log -Level 'SUMMARY' -Message "FilesScanned=$($summary.FilesScanned), FilesOlderThanCutoff=$($summary.FilesOlderThanCutoff), FilesSkippedByAge=$($summary.FilesSkippedByAge)"
Write-Log -Level 'SUMMARY' -Message "FilesDryRunListed=$($summary.FilesDryRunListed), FilesMovedToQuarantine=$($summary.FilesMovedToQuarantine), FilesSkippedLocked=$($summary.FilesSkippedLocked), FileErrors=$($summary.FileErrors)"

if (-not $DryRun) {
    Write-Log -Level 'INFO' -Message "Rollback manifest created at: $manifestPath"
}

Write-Host "Log file: $script:LogFilePath"
