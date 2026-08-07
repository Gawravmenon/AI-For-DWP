# Large File Finder (PowerShell 5.1)

This script helps DWP endpoint engineers safely find and clean up large files.
It is read-only by default.

## File

- `Large-File-Finder.ps1`

## Safety Model

- Default behavior is report-only (no file changes).
- `-DryRun` shows which files would be deleted.
- `-Execute` performs safe delete by moving files into a quarantine folder.
- Rollback is supported with `-Rollback` by restoring files from a manifest.
- Locked files are skipped and logged without stopping execution.

## Parameters

- `-Path <string[]>`
  - One or more paths to scan recursively.
  - Default: `C:\Users`

- `-ThresholdMB <double>`
  - Large-file threshold in MB.
  - Default: `100`

- `-OlderThanDays <int>`
  - Only target files older than this many days.
  - Default: `0`

- `-DryRun`
  - Prints files that would be deleted.
  - No file changes are made.

- `-Execute`
  - Moves files to quarantine (safe delete pattern).
  - Generates a rollback manifest.

- `-Rollback`
  - Restores files from a rollback manifest.

- `-ManifestPath <string>`
  - Optional path to a specific manifest for rollback.
  - If omitted during rollback, latest manifest in rollback root is used.

- `-RollbackRoot <string>`
  - Root path for quarantine and manifests.
  - Default: `C:\ProgramData\DWP\LargeFileRollback`

- `-LogDirectory <string>`
  - Folder for timestamped logs.
  - Default: `logs` folder next to the script.

## Common Examples

### 1) Report only (default)

```powershell
.\Large-File-Finder.ps1 -Path "C:\Users\jsmith\Downloads"
```

### 2) Dry run (show what would be deleted)

```powershell
.\Large-File-Finder.ps1 -Path "C:\Users\jsmith\Downloads" -ThresholdMB 250 -OlderThanDays 30 -DryRun
```

### 3) Execute cleanup (safe delete with rollback)

```powershell
.\Large-File-Finder.ps1 -Path "C:\Users\jsmith\Downloads" -ThresholdMB 250 -OlderThanDays 30 -Execute
```

### 4) Rollback using latest manifest

```powershell
.\Large-File-Finder.ps1 -Rollback
```

### 5) Rollback using a specific manifest

```powershell
.\Large-File-Finder.ps1 -Rollback -ManifestPath "C:\ProgramData\DWP\LargeFileRollback\manifest-20260807-112233.json"
```

## Output Artifacts

- Log file (timestamped):
  - `logs\LargeFileFinder-yyyyMMdd-HHmmss.log`
- Manifest file (timestamped):
  - `C:\ProgramData\DWP\LargeFileRollback\manifest-yyyyMMdd-HHmmss.json`
- Post-rollback manifest:
  - `<manifest-name>.post-rollback.json`

## Idempotency Notes

- Re-running in report or dry-run mode is non-destructive.
- In execute mode, files already moved to quarantine are skipped.
- In rollback mode, files that already exist in original location are skipped.

## Recommended Operational Flow

1. Run report-only to review candidates.
2. Run with `-DryRun` to preview deletion list.
3. Run with `-Execute` during an approved change window.
4. If needed, run `-Rollback` with the generated manifest.
