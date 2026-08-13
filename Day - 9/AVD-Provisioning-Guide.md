# Azure Virtual Desktop Session Host Provisioning - Day 9

## Executive Summary

This document details the complete process for provisioning an Azure Virtual Desktop (AVD) session host to the POOL-FIN-01 host pool. The process involves infrastructure setup, agent installation, and troubleshooting of deployment issues.

**Current Status:** Session host VM running but agent installation incomplete due to MSI binary extraction failure.

---

## 1. Infrastructure Overview

### Host Pool Configuration
- **Name:** POOL-FIN-01
- **Type:** Pooled
- **Load Balancer:** BreadthFirst
- **Max Sessions per Host:** 5
- **Current Hosts Registered:** 0 (TARGET: at least 1)

### Application Group
- **Name:** POOL-FIN-01-DAG
- **Type:** Desktop
- **Workspace:** FinBridge-Workspace

### Workspace
- **Name:** FinBridge-Workspace
- **Connected App Group:** POOL-FIN-01-DAG

### Azure Environment
- **Subscription:** labs10 (e9d6a1e0-74ba-4519-8a8c-2cd97b40a046)
- **Resource Group:** dwpai-lab-rg (eastus)
- **Identity:** traininguser58@zippyops.in (Owner role)

---

## 2. Session Host VM Details

### VM Configuration
- **Name:** dwp-p38-win
- **Size:** Standard_B2ms
- **OS:** Windows 11 Enterprise multi-session (build 26100.8875.260711)
- **Power State:** Running
- **Public IP:** 20.51.132.150 (static)
- **Private IP:** 10.0.0.4
- **VNET:** dwpai-lab-vnet
- **Subnet:** default (10.0.0.0/24)

### Security Configuration
- **Entra ID Join:** Yes (joined to tenant)
- **Trusted Launch:** Enabled
  - Secure Boot: Enabled
  - vTPM: Enabled
- **Managed Identity:** System-assigned
- **Extensions:**
  - AADLoginForWindows: Succeeded ✅
  - CustomScriptExtension: Updating (ABANDONED - switched to direct run-command)

---

## 3. Registration Token Management

### Token Retrieval Command
```bash
az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg \
  -n POOL-FIN-01 \
  --query token -o tsv
```

### Token Details
- **Status:** Valid and refreshable on demand
- **BrokerUri:** https://rdbbroker-g-us-r1.wvd.microsoft.com/
- **Expiration:** Configurable (default 30 days from creation)
- **Usage:** Required for agent registration during MSI installation

---

## 4. Provisioning Steps

### Phase 1: Infrastructure Setup (COMPLETED ✅)

#### 1.1 Azure Subscription Authentication
```bash
az login --use-device-code
# Login as traininguser58@zippyops.in
```

#### 1.2 Create Host Pool
```bash
az desktopvirtualization hostpool create \
  -g dwpai-lab-rg \
  -n POOL-FIN-01 \
  --host-pool-type Pooled \
  --load-balancer-type BreadthFirst \
  --max-session-limit 5 \
  --description "Finance Department AVD Pool"
```

#### 1.3 Create Application Group
```bash
az desktopvirtualization applicationgroup create \
  -g dwpai-lab-rg \
  -n POOL-FIN-01-DAG \
  --host-pool-name POOL-FIN-01 \
  --application-group-type Desktop
```

#### 1.4 Create Workspace
```bash
az desktopvirtualization workspace create \
  -g dwpai-lab-rg \
  -n FinBridge-Workspace \
  --friendly-name "Finance Bridge Workspace"
```

#### 1.5 Link Workspace to Application Group
```bash
az desktopvirtualization workspace update \
  -g dwpai-lab-rg \
  -n FinBridge-Workspace \
  --add app-groups "/subscriptions/e9d6a1e0-74ba-4519-8a8c-2cd97b40a046/resourcegroups/dwpai-lab-rg/providers/microsoft.desktopvirtualization/applicationgroups/POOL-FIN-01-DAG"
```

#### 1.6 Create Session Host VM
```bash
az vm create \
  -g dwpai-lab-rg \
  -n dwp-p38-win \
  --image Win11EntMulti \
  --size Standard_B2ms \
  --nsg dwpai-lab-nsg \
  --public-ip-sku Standard \
  --assign-identity \
  --enable-secure-boot \
  --enable-vtpm
```

#### 1.7 Entra ID Join VM
```bash
az vm extension set \
  -g dwpai-lab-rg \
  --vm-name dwp-p38-win \
  -n AADLoginForWindows \
  --publisher Microsoft.Azure.ActiveDirectory \
  --enable-auto-upgrade
```

#### 1.8 Assign RBAC Permissions
```bash
az role assignment create \
  --role "Desktop Virtualization User" \
  --assignee traininguser58@zippyops.in \
  --scope "/subscriptions/e9d6a1e0-74ba-4519-8a8c-2cd97b40a046/resourcegroups/dwpai-lab-rg/providers/microsoft.desktopvirtualization/applicationgroups/POOL-FIN-01-DAG"
```

### Phase 2: Agent Provisioning (IN PROGRESS ⏳)

#### 2.1 Obtain Registration Token
```powershell
$token = $(az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg \
  -n POOL-FIN-01 \
  --query token -o tsv)
Write-Host "Token obtained: $($token.Substring(0, 50))..."
```

#### 2.2 Download and Install Agent MSI Files
Use **install-avd-agent.ps1** script (see section 5) to:
1. Download RDAgent MSI (~96.5 MB)
2. Download RDAgentBootLoader MSI (~17.9 MB)
3. Install both with registration token

**Command:**
```powershell
.\install-avd-agent.ps1 -RegistrationToken $token
```

#### 2.3 Verify Service Installation
```powershell
Get-Service RDAgent, RDAgentBootLoader | Select-Object Name, Status, StartType
```

**Expected Output:**
```
Name                    Status StartType
----                    ------ ---------
RDAgent                Running   Automatic
RDAgentBootLoader       Running   Automatic
```

#### 2.4 Verify Binary Installation
```powershell
$binaries = @(
    'C:\Program Files\FSLogix\Apps\Agents\RDAgent.exe',
    'C:\Program Files\FSLogix\Apps\RDAgentBootLoader.exe'
)
foreach ($binary in $binaries) {
    Test-Path $binary | Write-Host "$binary : $_"
}
```

**Expected Result:** Both should return `True`

---

## 5. Scripts

### 5.1 install-avd-agent.ps1

**Purpose:** Download and install AVD agent components with registration token.

**Location:** Day - 9/install-avd-agent.ps1

**Parameters:**
- `-RegistrationToken` (Mandatory): JWT token from host pool registration

**Features:**
- Uses `curl.exe` for reliable downloads (avoids PowerShell 5.1 IE engine issues)
- Unblocks downloaded files to prevent execution policy issues
- Installs both RDAgent and RDAgentBootLoader MSIs
- Passes registration token to RDAgent MSI for automatic pool registration
- Waits for both installers to complete
- Returns service status after installation

**Usage:**
```powershell
$token = $(az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)
.\install-avd-agent.ps1 -RegistrationToken $token
```

**See:** [install-avd-agent.ps1](install-avd-agent.ps1)

### 5.2 install-avd-agent-tokenized.ps1

**Purpose:** Variant that accepts token as piped input via environment variable.

**Location:** Day - 9/install-avd-agent-tokenized.ps1

**Usage:**
```powershell
az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv | `
  Set-Content env:AVD_TOKEN
.\install-avd-agent-tokenized.ps1
```

---

## 6. Troubleshooting Guide

### Issue 1: "Windows PowerShell IE Engine Not Available"

**Symptom:**
```
response content cannot be parsed because Internet Explorer engine is not available
```

**Root Cause:** 
PowerShell 5.1 `Invoke-WebRequest` cmdlet uses deprecated IE engine for HTTP requests.

**Solution:**
Replace `Invoke-WebRequest` with native Windows tool `curl.exe`:
```powershell
curl.exe -L 'https://go.microsoft.com/fwlink/?linkid=2310011' -o 'agent.msi'
```

**Status:** ✅ RESOLVED - All scripts updated to use `curl.exe`

---

### Issue 2: Custom Script Extension Hung in "Updating" State

**Symptom:**
- Extension status shows "Updating" indefinitely
- No progress after 15+ minutes
- Unable to complete agent installation

**Root Cause:**
- Extension script likely hangs during download or execution
- Extension timeout reached without completion
- Azure portal shows no error details

**Solution:**
Abandon Custom Script Extension approach. Use direct guest-side command execution via `az vm run-command invoke`:

```bash
az vm run-command invoke \
  -g dwpai-lab-rg \
  -n dwp-p38-win \
  --command-id RunPowerShellScript \
  --scripts <PowerShell_script_here>
```

**Advantages:**
- Better error visibility and logging
- Synchronous execution with output capture
- No extension timeout issues
- Full PowerShell environment available

**Status:** ✅ RESOLVED - Switched to run-command approach

---

### Issue 3: VM Deallocated (Operation Blocked)

**Symptom:**
```
(OperationNotAllowed) The operation requires the VM to be running (or set to run)
```

**Root Cause:**
VM was deallocated (powerState: null), not in running state.

**Solution:**
Start the VM before running commands:
```bash
az vm start -g dwpai-lab-rg -n dwp-p38-win --no-wait
```

Monitor status:
```bash
az vm get-instance-view -g dwpai-lab-rg -n dwp-p38-win \
  --query "powerState" -o tsv
```

**Status:** ✅ RESOLVED - VM successfully started

---

### Issue 4: MSI Installation Fails Silently (CRITICAL)

**Symptom:**
- `msiexec /quiet` exits with code 0 (success)
- Services (RDAgent, RDAgentBootLoader) created and show Status 4 (Running)
- **BUT** executable binaries missing from disk:
  - `C:\Program Files\FSLogix\Apps\Agents\RDAgent.exe` - NOT FOUND
  - `C:\Program Files\FSLogix\Apps\RDAgentBootLoader.exe` - NOT FOUND
- Session host does not appear in host pool (0/1 hosts registered)

**Root Cause (Working Theory):**
- `/quiet` flag suppresses UI but may also suppress file extraction
- MSI creates service entries in registry but fails to extract/copy binaries
- Services cannot function without actual executable files
- Host cannot register with pool because agent process cannot run

**Diagnostic Steps:**
```powershell
# 1. Check service registry entries
reg query 'HKLM\SYSTEM\CurrentControlSet\Services\RDAgent' /v ImagePath
# Should show: C:\Program Files\FSLogix\Apps\Agents\RDAgent.exe

# 2. Verify binaries exist
Test-Path 'C:\Program Files\FSLogix\Apps\Agents\RDAgent.exe'
# Should return: $true

# 3. Check for running RDAgent process
Get-Process -Name RDAgent -ErrorAction SilentlyContinue
# Should show running process

# 4. Retrieve MSI installation logs
Get-Content 'C:\Logs\agent-install.log' -Tail 100
Get-Content 'C:\Logs\boot-install.log' -Tail 100
# Should contain error messages if installation failed
```

**Resolution Options (In Priority Order):**

**Option A: Run MSI with Verbose Logging**
```powershell
$token = $(az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)

# Uninstall previous attempts
msiexec.exe /x '{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}' /quiet

# Reinstall with verbose logging
msiexec.exe /i 'C:\Temp\agent.msi' /l*v 'C:\Logs\agent-verbose.log' REGISTRATIONTOKEN=$token
msiexec.exe /i 'C:\Temp\boot.msi' /l*v 'C:\Logs\boot-verbose.log'

# Retrieve logs to identify error
Get-Content 'C:\Logs\agent-verbose.log' | Select-String -Pattern 'Error|error|ERROR|Failed|failed'
```

**Option B: Verify Prerequisites**
```powershell
# Check disk space
Get-Volume C: | Select-Object SizeRemaining

# Verify C:\Program Files\ permissions
icacls 'C:\Program Files\'

# Check Windows Installer service
Get-Service msiserver | Select-Object Name, Status

# Verify temp directory accessibility
Test-Path env:TEMP; Test-Path $env:TEMP

# Check UAC status (should be off or set to not prompt for admin)
```

**Option C: Manual Installation**
If MSI continues to fail:
1. Extract MSI contents manually
2. Copy extracted files to correct directory
3. Create registry entries manually
4. Start services and verify process runs

**Option D: Alternative Registration Method**
If all MSI approaches fail:
1. Use PowerShell DSC (Desired State Configuration)
2. Deploy agent via Windows Package Manager (winget)
3. Manual registry-based registration if agent binaries available

**Status:** ⏳ IN PROGRESS - Awaiting log file analysis

---

### Issue 5: Session Host Not Appearing in Pool

**Symptom:**
```
az desktopvirtualization hostpool list-session-hosts -g dwpai-lab-rg -n POOL-FIN-01
# Returns: [] (empty array)
# Expected: At least one host with status "Available" or "Unavailable"
```

**Root Cause:**
Dependent on Issue 4 - MSI installation failure prevents agent registration.

**Verification Steps:**
```powershell
# 1. Verify RDAgent service is running
Get-Service RDAgent | Select-Object Name, Status

# 2. Verify RDAgent.exe process exists and is running
Get-Process -Name RDAgent -ErrorAction SilentlyContinue

# 3. Check Azure portal for host list (may have 1-2 minute lag)

# 4. Monitor agent logs for registration events
Get-EventLog -LogName System -Source RDAgent -Newest 20

# 5. Check agent configuration file
Get-Content 'C:\Program Files\FSLogix\Apps\Agent\RDAgent.config' -ErrorAction SilentlyContinue
```

**Expected Outcome After Fix:**
1. RDAgent.exe process runs on VM
2. Process connects to broker URI
3. Host registers with pool
4. Portal shows: "1 session host registered"
5. AVD client shows available connection

**Status:** ⏳ BLOCKED - Waiting for agent installation fix

---

## 7. Verification Checklist

Use this checklist to verify successful provisioning:

- [ ] Infrastructure created
  - [ ] Host Pool POOL-FIN-01 exists
  - [ ] App Group POOL-FIN-01-DAG exists
  - [ ] Workspace FinBridge-Workspace exists
  - [ ] Workspace linked to App Group

- [ ] Session Host VM
  - [ ] VM dwp-p38-win exists
  - [ ] Power state: Running
  - [ ] Entra ID joined
  - [ ] AADLoginForWindows extension: Succeeded
  - [ ] System-assigned identity present
  - [ ] Public IP assigned (20.51.132.150)

- [ ] Agent Installation
  - [ ] MSI files downloaded successfully
  - [ ] RDAgent service created
  - [ ] RDAgentBootLoader service created
  - [ ] **RDAgent.exe binary exists** ← CRITICAL
  - [ ] **RDAgentBootLoader.exe binary exists** ← CRITICAL
  - [ ] Both services Status: Running
  - [ ] Both services StartType: Automatic

- [ ] Host Pool Registration
  - [ ] Session host appears in pool (not hollow entry)
  - [ ] Host status: Available (or Unavailable → Available after drain timeout)
  - [ ] Portal shows: "1 session hosts registered"

- [ ] User Access
  - [ ] User assigned "Desktop Virtualization User" role on app group
  - [ ] User can see workspace in AVD client
  - [ ] User can launch desktop session

- [ ] Operational
  - [ ] AVD client connects successfully
  - [ ] User session starts
  - [ ] Desktop applications load and run

---

## 8. Key Learnings

### What Worked
✅ `curl.exe` for HTTP downloads (avoids IE engine issue in PowerShell 5.1)
✅ Direct `az vm run-command invoke` for guest-side execution (better control/logging)
✅ Azure infrastructure creation via CLI (reliable, repeatable)
✅ Entra ID join with managed identity (seamless auth)

### What Didn't Work
❌ PowerShell `Invoke-WebRequest` in Windows PowerShell 5.1
❌ Custom Script Extension (hung indefinitely, poor diagnostics)
❌ msiexec /quiet (suppresses output but may suppress file extraction)
❌ Assuming service "Running" status = agent fully functional

### Critical Discovery
**Services can exist and report "Running" without actual binaries on disk.** This is a hollow service entry that provides no functionality. Must verify executable files exist before declaring success.

---

## 9. Next Steps

### Immediate (CRITICAL)
1. [ ] Retrieve and analyze full MSI installation logs
   - Command: `Get-Content 'C:\Logs\agent-install.log' | Out-String`
   - Search for: Error codes, failure messages, missing prerequisites

2. [ ] Identify MSI failure root cause
   - Check logs for specific errors (access denied, disk space, registry, etc.)
   - Correlate with system state (permissions, disk, registry accessibility)

3. [ ] Apply targeted fix based on root cause
   - If access denied: Run with elevated permissions
   - If disk space: Clear temp/cache
   - If registry: Verify user permissions
   - If product not found: Verify MSI integrity

### High Priority
4. [ ] Verify agent binaries extract and install correctly
   - Re-run installation with verbose logging
   - Confirm RDAgent.exe exists at C:\Program Files\FSLogix\Apps\Agents\
   - Monitor process via Get-Process or Task Manager

5. [ ] Confirm RDAgent process runs and connects
   - Verify RDAgent.exe process in Task Manager
   - Monitor network connections to broker (netstat)
   - Check application event logs for registration events

6. [ ] Verify host registration
   - Check portal for session host in pool
   - Verify host status transitions to "Available"
   - Test client connection

### Medium Priority
7. [ ] Document final working configuration
   - Record successful installation command
   - Note any prerequisites or special configurations
   - Create runbook for future deployments

8. [ ] Test end-to-end user scenario
   - User connects via AVD client
   - Desktop loads successfully
   - Applications run without issues

---

## 10. Contact & References

### Azure Documentation
- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [AVD Session Host Agent](https://learn.microsoft.com/en-us/azure/virtual-desktop/agent-overview)
- [AVD Registration Token](https://learn.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-azure-resource-manager)

### Useful Commands
```bash
# List session hosts in pool
az desktopvirtualization hostpool list-session-hosts \
  -g dwpai-lab-rg -n POOL-FIN-01

# Get host pool details
az desktopvirtualization hostpool show \
  -g dwpai-lab-rg -n POOL-FIN-01

# Get VM details
az vm show -g dwpai-lab-rg -n dwp-p38-win --query "{PowerState:powerState,Location:location}"

# Monitor extension status
az vm extension list -g dwpai-lab-rg -n dwp-p38-win -o table
```

---

**Document Version:** 1.0  
**Date:** 2026-08-13  
**Status:** In Progress - Awaiting MSI log analysis and agent binary verification
