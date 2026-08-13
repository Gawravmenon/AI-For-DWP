# Azure Virtual Desktop Provisioning - Day 9

## Overview

This directory contains comprehensive documentation and scripts for provisioning an Azure Virtual Desktop (AVD) session host. The complete workflow involves infrastructure setup, agent installation, and troubleshooting.

---

## 📋 Files in This Directory

### Documentation

#### `AVD-Provisioning-Guide.md` ⭐ **START HERE**
Complete step-by-step guide covering:
- Infrastructure overview (host pool, app group, workspace, VM)
- Registration token management
- Full provisioning workflow with commands
- Troubleshooting guide for common issues
- Verification checklist
- Next steps and key learnings

**Use this as your primary reference document.**

---

### Installation Scripts

#### `install-avd-agent.ps1`
**Primary installation script** for AVD agent components.

- **Input:** Registration token as parameter
- **What it does:** Downloads and installs RDAgent and RDAgentBootLoader MSIs
- **Usage:**
  ```powershell
  $token = $(az desktopvirtualization hostpool retrieve-registration-token `
    -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)
  .\install-avd-agent.ps1 -RegistrationToken $token
  ```
- **Features:**
  - Uses curl.exe for reliable downloads
  - Passes registration token to MSI for auto-registration
  - Waits for installation to complete
  - Reports service status

#### `install-avd-agent-tokenized.ps1`
**Alternative installation script** that reads token from environment variable.

- **Input:** Registration token via `$env:AVD_REGISTRATION_TOKEN`
- **Usage:**
  ```powershell
  $token = $(az desktopvirtualization hostpool retrieve-registration-token `
    -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)
  $env:AVD_REGISTRATION_TOKEN = $token
  .\install-avd-agent-tokenized.ps1
  ```
- **Preferred for:** Piped workflows or environments with secrets management

---

### Troubleshooting Scripts

#### `Diagnose-AVD-Agent.ps1`
**Diagnostic utility** for checking agent installation status.

- **Purpose:** Identify installation issues when services exist but host doesn't appear in pool
- **What it checks:**
  - Service status (RDAgent, RDAgentBootLoader)
  - Binary files existence on disk
  - Running processes
  - Pool registration configuration
  - MSI installation logs
  
- **Usage:**
  ```powershell
  # All checks
  .\Diagnose-AVD-Agent.ps1 -All
  
  # Specific checks
  .\Diagnose-AVD-Agent.ps1 -CheckBinaries
  .\Diagnose-AVD-Agent.ps1 -RetrieveLogs
  ```

- **Output:** Color-coded status with recommendations

#### `Remediate-AVD-Installation.ps1`
**Troubleshooting script** to fix installation failures.

- **Purpose:** Re-install agents with verbose logging when installation fails
- **What it does:**
  1. Verifies prerequisites (disk space, permissions, services)
  2. Uninstalls previous failed versions
  3. Re-installs with verbose logging
  4. Captures detailed error logs
  5. Analyzes logs for errors
  
- **Usage:**
  ```powershell
  $token = $(az desktopvirtualization hostpool retrieve-registration-token `
    -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)
  .\Remediate-AVD-Installation.ps1 -RegistrationToken $token
  ```

- **Features:**
  - Requires admin privileges
  - Creates detailed logs in C:\Logs\
  - Provides step-by-step remediation
  - Optional VM restart

---

### Configuration Files

#### `avd-customscript-settings-template.json`
Template configuration for Azure VM Custom Script Extension.

- **Status:** ⚠️ NOT RECOMMENDED (this approach was abandoned during testing)
- **Why:** Extension hung indefinitely with poor error reporting
- **Use case:** Reference only if considering CSE approach
- **Fields:**
  - `fileUris`: Storage account blob URI for script
  - `commandToExecute`: PowerShell command with token parameter

**Note:** Direct `az vm run-command invoke` is preferred over Custom Script Extension.

---

## 🚀 Quick Start

### 1. **Initial Provisioning**
If you're starting from scratch:

1. Read [AVD-Provisioning-Guide.md](AVD-Provisioning-Guide.md) Section 4, Phase 1 (Infrastructure Setup)
2. Execute infrastructure commands via Azure CLI
3. Run `.\install-avd-agent.ps1` with registration token

### 2. **Troubleshooting Installation**
If agent won't install or host doesn't appear in pool:

1. Run `.\Diagnose-AVD-Agent.ps1 -All` to identify issues
2. If binaries missing (CRITICAL): Run `.\Remediate-AVD-Installation.ps1`
3. Review generated logs in C:\Logs\ for specific errors
4. Consult [AVD-Provisioning-Guide.md](AVD-Provisioning-Guide.md) Section 6 for detailed issue resolution

### 3. **Verification**
After installation completes:

1. Run `.\Diagnose-AVD-Agent.ps1 -All` to verify success
2. Check Azure portal for session host in pool
3. Follow verification checklist in guide (Section 7)

---

## ⚠️ Common Issues & Solutions

### Issue: "Services exist but host not in pool"
- **Symptom:** RDAgent service shows "Running" but host never appears in pool
- **Cause:** Binaries missing on disk (MSI installation failed silently)
- **Solution:** 
  1. Run `.\Diagnose-AVD-Agent.ps1 -CheckBinaries` to confirm
  2. Run `.\Remediate-AVD-Installation.ps1` to re-install with verbose logging
  3. Review C:\Logs\*.log files for specific errors

### Issue: "PowerShell Invoke-WebRequest fails"
- **Error:** "response content cannot be parsed because Internet Explorer engine is not available"
- **Cause:** PowerShell 5.1 uses deprecated IE engine for HTTP
- **Solution:** All scripts use `curl.exe` instead ✅

### Issue: "Custom Script Extension hung"
- **Symptom:** Extension stuck in "Updating" state indefinitely
- **Solution:** Use `az vm run-command invoke` instead (scripts already do this)

### Issue: "Insufficient disk space"
- **Check:** `(Get-Volume C:).SizeRemaining`
- **Requirement:** At least 1 GB free for MSI extraction
- **Solution:** Clean up temp files, remove old installers

---

## 🔍 Diagnostic Commands

### Check Registration Status
```powershell
az desktopvirtualization hostpool list-session-hosts \
  -g dwpai-lab-rg \
  -n POOL-FIN-01
```

### Get Latest Registration Token
```powershell
az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg \
  -n POOL-FIN-01 \
  --query token -o tsv
```

### Monitor VM Status
```powershell
az vm get-instance-view -g dwpai-lab-rg -n dwp-p38-win \
  --query "powerState" -o tsv
```

### Run Command on VM
```powershell
az vm run-command invoke \
  -g dwpai-lab-rg \
  -n dwp-p38-win \
  --command-id RunPowerShellScript \
  --scripts 'Get-Service RDAgent'
```

---

## 📊 Current Status (As of 2026-08-13)

### Infrastructure ✅ COMPLETE
- Host Pool (POOL-FIN-01): Created
- App Group (POOL-FIN-01-DAG): Created
- Workspace (FinBridge-Workspace): Created
- VM (dwp-p38-win): Running

### Agent Installation ⏳ IN PROGRESS
- **Issue:** Services created but binaries missing from disk
- **Blocker:** MSI installation fails to extract files
- **Next Step:** Analyze MSI logs and identify root cause
- **Workaround:** Run Remediate-AVD-Installation.ps1 with verbose logging

### Host Pool Registration ❌ BLOCKED
- **Current:** 0 hosts registered
- **Expected:** 1 host (dwp-p38-win)
- **Dependent On:** Completing agent binary installation

---

## 📚 References

- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [AVD Session Host Agent Overview](https://learn.microsoft.com/en-us/azure/virtual-desktop/agent-overview)
- [Troubleshooting AVD Issues](https://learn.microsoft.com/en-us/azure/virtual-desktop/troubleshoot-agent)

---

## 📝 Key Commands Reference

### Azure CLI - Get Token
```bash
az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv
```

### PowerShell - Install Agent
```powershell
.\install-avd-agent.ps1 -RegistrationToken $token
```

### PowerShell - Diagnose Issues
```powershell
.\Diagnose-AVD-Agent.ps1 -All
```

### PowerShell - Fix Installation
```powershell
.\Remediate-AVD-Installation.ps1 -RegistrationToken $token
```

---

## 🎯 Next Actions

1. **Immediate:** Run Diagnose-AVD-Agent.ps1 to verify current state
2. **If issues found:** Run Remediate-AVD-Installation.ps1 to fix
3. **After remediation:** Monitor pool for host registration (1-2 minutes)
4. **Verify:** Follow completion checklist in AVD-Provisioning-Guide.md

---

**Document Generated:** 2026-08-13  
**Status:** In Progress - Agent Installation Troubleshooting  
**Owner:** Training Exercise
