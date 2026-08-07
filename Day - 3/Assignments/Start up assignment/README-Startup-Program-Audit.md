# Startup Program Audit Script (PowerShell 5.1)

This folder contains a safe startup-program audit/removal script for Windows endpoints:

- Script: `Startup-Program-Audit.ps1`

The script scans standard startup folders and removes startup files by moving them to a quarantine folder (not permanent deletion). This allows rollback.

## What the script does

- Supports dry run mode to show what would be removed.
- Targets files older than a configurable number of days (`-OlderThanDays`, default `0`).
- Skips locked files and logs the skip.
- Uses per-file `try/catch` so one failure does not stop the run.
- Logs every action to a timestamped log file.
- Prints an end-of-run summary.
- Supports rollback from a manifest.
- Is idempotent for repeated runs.

## Parameters

- `-DryRun`
  - No changes are made.
  - Logs and prints files that would be removed from startup.

- `-OlderThanDays <int>`
  - Only files with `LastWriteTime` older than this value are targeted.
  - Default: `0`.

- `-Rollback`
  - Restores files from a previous quarantine manifest.

- `-RollbackManifest <path>`
  - Optional path to a specific manifest CSV.
  - If omitted in rollback mode, the script uses the most recent manifest under the quarantine root.

- `-LogDirectory <path>`
  - Optional custom folder for timestamped logs.

- `-QuarantineRoot <path>`
  - Optional custom root folder where quarantined files and manifests are stored.

## Usage examples

### 1) Dry run (no changes)

```powershell
.\Startup-Program-Audit.ps1 -DryRun
```

### 2) Remove startup files older than 30 days

```powershell
.\Startup-Program-Audit.ps1 -OlderThanDays 30
```

### 3) Roll back using the most recent manifest

```powershell
.\Startup-Program-Audit.ps1 -Rollback
```

### 4) Roll back using a specific manifest

```powershell
.\Startup-Program-Audit.ps1 -Rollback -RollbackManifest "C:\Path\To\manifest.csv"
```

## Output locations

By default, output is written under the script folder:

- Logs: `.\logs\StartupProgramAudit_yyyyMMdd_HHmmss.log`
- Quarantine runs: `.\quarantine\Run_yyyyMMdd_HHmmss\`
- Rollback manifest: `.\quarantine\Run_yyyyMMdd_HHmmss\manifest.csv`

## Safety notes

- Files are moved out of startup folders into quarantine, not permanently deleted.
- Locked files are skipped.
- Errors are logged and processing continues.
- Running the script multiple times does not reprocess files that are already removed from startup.
