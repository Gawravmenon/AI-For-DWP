# Temp Cleanup Script

This folder contains a safe PowerShell 5.1 cleanup tool for a DWP engineer to remove temp files from Windows endpoints.

## Script

- [Temp-Cleanup.ps1](Temp-Cleanup.ps1) cleans temp files or restores them from rollback data.

## What It Does

- Supports a dry run so you can see which files would be deleted before making changes.
- Targets only files older than a configurable age threshold.
- Skips locked or inaccessible files and logs the failure without stopping the run.
- Uses per-file try/catch handling so one bad file does not interrupt the rest.
- Writes every action to a timestamped log file.
- Creates rollback data for deleted files so they can be restored later.
- Prints a summary report at the end of each run.
- Avoids repeat damage by only acting on the current state of the file system, which makes the process idempotent.

## Parameters

### `-TargetPath`

One or more folders to scan.

Default targets:

- The current user temp folder
- `C:\Windows\Temp`

### `-DaysOld`

Only files with a `LastWriteTime` older than this many days are processed.

Default: `0`

Using `0` means the script will consider any file older than the moment the script runs.

### `-DryRun`

Shows the files that would be deleted and prints them to the console without deleting anything.

### `-Rollback`

Restores files from the latest rollback set, or from a specific rollback set when used with `-RollbackPath`.

### `-RollbackPath`

Optional path to a specific rollback folder.

## Logging And Rollback

- Log files are written to `%LOCALAPPDATA%\DWP-TempCleanup\Logs`.
- Rollback folders are written to `%LOCALAPPDATA%\DWP-TempCleanup\Rollback`.
- Each cleanup run creates a unique rollback folder and a `manifest.json` file.
- If deletion fails partway through, the script attempts to remove any temporary backup it created for that file.

## Usage Examples

Run a dry run:

```powershell
.\Temp-Cleanup.ps1 -DryRun
```

Clean files older than 3 days:

```powershell
.\Temp-Cleanup.ps1 -DaysOld 3
```

Scan a custom folder:

```powershell
.\Temp-Cleanup.ps1 -TargetPath 'C:\Temp' -DaysOld 7
```

Scan multiple folders:

```powershell
.\Temp-Cleanup.ps1 -TargetPath 'C:\Temp', 'D:\Scratch' -DaysOld 2
```

Restore the latest rollback set:

```powershell
.\Temp-Cleanup.ps1 -Rollback
```

Restore from a specific rollback folder:

```powershell
.\Temp-Cleanup.ps1 -Rollback -RollbackPath 'C:\Users\labuser\AppData\Local\DWP-TempCleanup\Rollback\Run_20260805_120000'
```

## Operational Notes

- Run PowerShell as administrator if you need to process protected locations such as `C:\Windows\Temp`.
- The script does not stop when it meets a locked file; it records the event and continues.
- If a file already exists during rollback, the restore is skipped so the script remains safe to run again.