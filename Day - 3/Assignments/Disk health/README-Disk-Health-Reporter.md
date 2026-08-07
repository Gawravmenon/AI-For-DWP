# Disk Health Reporter (PowerShell 5.1)

## Purpose

This script provides a safe disk health and optimization status report for Windows endpoints.

- It is read-only for disk optimization actions.
- It never runs defragmentation or optimize-volume actions.
- Optional cleanup mode can remove old files only when explicitly enabled.

Script file:
- `Disk-Health-Reporter.ps1`

## Key Features

- Disk health status collection (physical disks and volumes)
- Optimization schedule status reporting (ScheduledDefrag task state)
- Dry run preview mode for candidate file deletion
- Configurable age filter (`-DaysOld`, default `0`)
- Locked file detection and skip with warning logs
- Per-file try/catch error handling
- Timestamped logging for all actions
- End-of-run summary output
- Rollback support for cleanup actions
- Idempotent behavior (safe repeated execution)

## Parameters

- `-TargetPath <string[]>`
  - One or more directories to scan for cleanup candidates.
  - Default: user temp and Windows temp folders.

- `-DaysOld <int>`
  - Only files older than this number of days are eligible.
  - Default: `0`

- `-DryRun`
  - Prints files that would be deleted.
  - Does not delete files.

- `-EnableCleanup`
  - Enables actual deletion workflow (backup then delete).
  - Without this switch, script is report-only.

- `-Rollback`
  - Restores files from a rollback set.

- `-RollbackId <string>`
  - Optional rollback folder name to restore (for example: `Run_20260807_143000`).
  - If omitted, latest rollback set is used.

## Behavior Modes

1. Report-only mode (default)
   - Collects and logs disk/volume/optimization status.
   - No file deletion.

2. Dry run mode (`-DryRun`)
   - Reports telemetry and prints which files would be deleted.
   - No file deletion.

3. Cleanup mode (`-EnableCleanup`)
   - Reports telemetry.
   - Backs up eligible files to rollback folder.
   - Deletes eligible files.
   - Writes rollback manifest.

4. Cleanup dry run (`-EnableCleanup -DryRun`)
   - Same candidate selection as cleanup mode.
   - Prints deletions only.

5. Rollback mode (`-Rollback`)
   - Restores files from rollback manifest.

## Examples

Report-only:
```powershell
.\Disk-Health-Reporter.ps1
```

Dry run preview for files older than 7 days:
```powershell
.\Disk-Health-Reporter.ps1 -DryRun -DaysOld 7
```

Cleanup files older than 14 days in custom paths:
```powershell
.\Disk-Health-Reporter.ps1 -EnableCleanup -DaysOld 14 -TargetPath 'C:\Temp','C:\Windows\Temp'
```

Rollback latest cleanup run:
```powershell
.\Disk-Health-Reporter.ps1 -Rollback
```

Rollback a specific run:
```powershell
.\Disk-Health-Reporter.ps1 -Rollback -RollbackId 'Run_20260807_143000'
```

## Logging and State

The script creates these folders beside the script:

- `logs\` for timestamped run logs
- `rollback\` for backup content and manifest
- `state\` reserved for future state extensions

A new log file is created per run with date and time in the filename.

## Idempotency Notes

- Re-running report-only or dry run has no destructive side effects.
- Cleanup only affects files currently matching filters.
- Rollback skips files already present at original paths.
- Duplicate candidate fingerprints are skipped in the same run.

## Safety Notes

- Disk optimization status is only read and reported.
- No optimize or defrag command is executed by this script.
- Locked files are skipped and logged; processing continues.
