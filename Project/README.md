# AI - PowerShell Script README

## Overview

This PowerShell script is a **diagnostic evidence collection tool** designed to investigate app deployment issues on Windows endpoints, specifically targeting scenarios where Friday app deployments may cause sign-in installation/retry load problems.

The script systematically gathers evidence from multiple sources (registry, event logs, Intune Management Extension logs, system baseline) and outputs structured data to help identify root causes of deployment-related failures.

## Purpose

This script is intended for IT support engineers and system administrators to:
- Collect comprehensive evidence from a device experiencing app deployment issues
- Analyze Intune Management Extension (IME) logs for installation failures and retries
- Identify deployment-related event logs within a specific time window
- Generate causality indicators suggesting whether a deployment event occurred
- Create a structured evidence archive for troubleshooting and RCA (Root Cause Analysis)

## Prerequisites

- **PowerShell 5.0 or later** (PowerShell 7.x recommended)
- **Administrator privileges** (required to access event logs and registry)
- **Windows 10/11 or Windows Server 2016+**
- Access to the following:
  - Windows Event Logs
  - Registry (Uninstall keys)
  - Intune Management Extension logs (if applicable)
  - `dsregcmd` and `quser` commands

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `DryRun` | switch | N/A | Preview mode: shows what would be collected without writing files |
| `OutputRoot` | string | `$env:ProgramData\Floor6Evidence` | Root directory where evidence folder will be created |
| `StartTime` | datetime | 3 days before current date at 12:00 | Begin time window for log collection |
| `EndTime` | datetime | Current date/time | End time window for log collection |
| `AppNameKeyword` | string | `"document"` | Filter keyword to match specific applications |

## Usage Examples

### Basic Usage (Default Parameters)
```powershell
.\AI - Powershell script.ps1
```
Collects evidence for the past 3 days, looking for apps matching "document"

### Dry Run Preview
```powershell
.\AI - Powershell script.ps1 -DryRun
```
Shows what would be collected without actually writing files

### Custom Time Window
```powershell
$start = (Get-Date).AddDays(-7).AddHours(12)
$end = Get-Date
.\AI - Powershell script.ps1 -StartTime $start -EndTime $end
```
Collects evidence from 7 days ago at noon until now

### Custom App Keyword
```powershell
.\AI - Powershell script.ps1 -AppNameKeyword "Teams"
```
Filters installed apps for those matching "Teams"

### Custom Output Location
```powershell
.\AI - Powershell script.ps1 -OutputRoot "C:\Evidence"
```
Saves evidence to `C:\Evidence\Floor6-AppDeploymentEvidence-{ComputerName}-{Timestamp}`

## Output Files

The script creates a timestamped folder structure with the following files:

| File | Description |
|------|-------------|
| `00-EvidenceSummary.json` | High-level summary of all findings |
| `01-Baseline.json` | Device baseline (OS, hardware, user info) |
| `02-dsreg-status.txt` | Entra/AAD device registration status |
| `03-AllInstalledApps.csv` | All installed applications from registry |
| `04-KeywordMatchedApps.csv` | Applications filtered by keyword |
| `05-IME-KeywordHits.txt` | Intune Management Extension log hits (limited to 3000 lines) |
| `06-DM-EDP-Admin.evtx.txt` | Device Management Enterprise Diagnostics events |
| `07-Application-MSI.evtx.txt` | MSI Installer and app error events |
| `08-System-Services.evtx.txt` | Service Control Manager and GroupPolicy events |
| `09-LogonPerformance.evtx.txt` | Performance diagnostic events related to logon |
| `10-Winlogon.evtx.txt` | Winlogon operational events |
| `11-AAD-Operational.evtx.txt` | Azure AD operational events |
| `12-QUser.txt` | Current user sign-in sessions |
| `13-CausalityIndicators.json` | Structured analysis indicators |

## Output Location

Evidence is saved to:
```
{OutputRoot}\Floor6-AppDeploymentEvidence-{ComputerName}-{YYYYMMdd-HHmmss}\
```

Example:
```
C:\ProgramData\Floor6Evidence\Floor6-AppDeploymentEvidence-DESKTOP-ABC123-20260814-143022\
```

## Key Features

✅ **Structured Evidence Collection**
- Captures device baseline for context
- Collects evidence from 7 different event log sources
- Extracts registry data for installed applications

✅ **Intune-Focused Diagnostics**
- Specifically targets Intune Management Extension logs
- Searches for installation, retry, and failure keywords
- Counts matching log entries for quick assessment

✅ **Smart Filtering**
- Filters event logs by provider and event ID
- Application logs filtered for MSI and app-related events
- System logs filtered for service and policy changes

✅ **Causality Analysis**
- Generates structured indicators suggesting deployment likelihood
- Provides explanations for positive findings
- Identifies rule-out signals (no evidence in time window)

✅ **Dry Run Mode**
- Preview what would be collected without writing files
- Useful for testing parameters before actual collection

## JSON Output Structure

### Evidence Summary (00-EvidenceSummary.json)
```json
{
  "ComputerName": "DESKTOP-ABC123",
  "UserName": "jdoe",
  "StartTime": "2026-08-11T12:00:00",
  "EndTime": "2026-08-14T15:30:00",
  "AppNameKeyword": "document",
  "IsDryRun": false,
  "Findings": {
    "KeywordMatchedInstalledApps": 3,
    "IMELogFilesFound": 5,
    "IMEKeywordHits": 42,
    "TotalEventRecordsCollected": 287,
    "CausalityIndicators": { ... }
  }
}
```

### Causality Indicators (13-CausalityIndicators.json)
```json
{
  "DeploymentLikely": true,
  "Why": [
    "Intune Management Extension logs contain install/retry/failure or app-keyword hits..."
  ],
  "RuleOutSignals": [ ]
}
```

## Troubleshooting

### "Access Denied" Errors
- Run PowerShell as Administrator
- Verify you have permissions to read event logs

### No Event Logs Collected
- Verify the `StartTime` and `EndTime` parameters are correct
- Check that events actually exist in the specified time window
- Some logs may not have entries in the time period

### IME Logs Not Found
- Intune Management Extension may not be installed
- Path is `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`
- This is expected in non-Intune environments

### JSON Files Cannot Be Read
- Files are UTF-8 encoded; use UTF-8 compatible editors
- Use `Get-Content -Encoding UTF8` in PowerShell

## Script Behavior

- **StrictMode**: Script runs with `Set-StrictMode -Version Latest` for safer execution
- **Error Handling**: Script stops on first error (unless in DryRun mode)
- **Encoding**: All output files use UTF-8 encoding
- **Timestamps**: Script appends timestamp to folder name for uniqueness

## Performance Considerations

- Large time windows may take longer due to event log queries
- IME logs are limited to first 3000 matching lines
- CSV exports sort results alphabetically
- Event log filtering reduces memory usage

## Security Notes

- Script accesses system-level logs and registry
- No sensitive data is intentionally filtered
- Review output for PII before sharing evidence
- dsregcmd output may contain device identifiers

## Support & Feedback

For issues or questions:
1. Review the output summary JSON file first
2. Check causality indicators for quick assessment
3. Examine event logs for specific errors
4. Review IME logs for installation failures

---

**Version**: 1.0  
**Last Updated**: 2026-08-14  
**Target OS**: Windows 10/11, Server 2016+
