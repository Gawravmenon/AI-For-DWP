# Powershell Handscripted scripts

This script safely removes old files by moving them to a quarantine folder, supports dry-run previews, logs every action, and supports rollback.

## File
- Powershell Handscripted scripts.ps1

## What it does
- Dry run mode prints every file that would be deleted.
- Age filter targets only files older than a configurable number of days.
- Locked files are skipped and logged without stopping execution.
- Per-file try/catch ensures one failure does not stop the whole run.
- Every action is logged to a timestamped log file.
- End-of-run summary is printed and stored.
- Rollback restores files using a manifest.
- Idempotence is maintained by quarantine mapping and safe skip logic.

## Parameters
- TargetPath
  - Path to scan for files.
  - Default: current directory.

- OlderThanDays
  - Only files with LastWriteTime older than now minus this number are targeted.
  - Default: 0.

- Filter
  - File name pattern.
  - Default: *

- DryRun
  - When set, lists files that would be deleted and makes no changes.

- QuarantineRoot
  - Where files, manifests, and logs are stored for cleanup runs.
  - Default: .cleanup-quarantine under TargetPath.

- Rollback
  - Switch to restore files from a manifest.

- ManifestPath
  - Optional explicit manifest to use for rollback.
  - If omitted, latest manifest in quarantine is used.

- RollbackQuarantineRoot
  - Optional quarantine root for rollback mode.

## Output structure
- .cleanup-quarantine/files/
  - Moved files.
- .cleanup-quarantine/manifests/
  - Per-run manifest and summary files.
- .cleanup-quarantine/logs/
  - Timestamped run logs.

## Examples
### 1. Preview only

powershell
.\Powershell Handscripted scripts.ps1 -TargetPath "C:\Temp" -OlderThanDays 30 -Filter "*.log" -DryRun

### 2. Cleanup run

powershell
.\Powershell Handscripted scripts.ps1 -TargetPath "C:\Temp" -OlderThanDays 30 -Filter "*.log"

### 3. Rollback latest run

powershell
.\Powershell Handscripted scripts.ps1 -Rollback -RollbackQuarantineRoot "C:\Temp\.cleanup-quarantine"

### 4. Rollback specific manifest

powershell
.\Powershell Handscripted scripts.ps1 -Rollback -ManifestPath "C:\Temp\.cleanup-quarantine\manifests\manifest-20260814-103000.jsonl"

## Notes
- The script excludes the quarantine folder from cleanup scanning.
- In cleanup mode, deleting is implemented as move-to-quarantine to enable rollback.
- Re-running cleanup is safe and idempotent for already moved files.
