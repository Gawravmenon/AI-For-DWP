# L2/L3 Knowledge Base - AVD Session Disconnects (POOL-FIN-01)

Version header: v 1.0 | 07/08/2026 | Status: Draft

## Background
Azure Virtual Desktop (AVD) delivers finance user desktops from pooled session hosts. If the desktop shell process fails on one host, users can sign in but are immediately disconnected and reconnected, causing repeated work interruption during business hours. Fast host isolation and evidence-led comparison are required to prevent wider impact.

## Symptom
### What users report
- "I can sign in, then it disconnects and reconnects in a loop."
- "It happens to multiple users at the same time."

### What the engineer observes
- Repeated `Event ID 40` disconnects after successful `Event ID 21` logons.
- Repeated `Event ID 1000` Application Error entries for `dwm.exe` faulting in `igdumd64.dll` (`Exception code 0xc0000005`).
- Repeated `Event ID 9009` in Desktop Window Manager operational log.
- Pattern isolated to `SHFIN-01-A` in `POOL-FIN-01`; comparison host (`SHFIN-02-A`) stays healthy.

## Root Cause
Host-side graphics stack regression after overnight image update on `SHFIN-01-A` caused `dwm.exe` to crash in `igdumd64.dll`, which terminated the desktop shell and dropped active AVD sessions.

### Evidence that confirms root cause
- `Application` log: `Event ID 1000` with `Faulting application name = dwm.exe`, `Faulting module name = igdumd64.dll`, `Exception code = 0xc0000005`.
- `Desktop Window Manager/Operational` log: `Event ID 9009` (`DWM exited`, code `0x40010004`).
- `TerminalServices-LocalSessionManager/Operational` log: `Event ID 21` followed by `Event ID 40` for same user/session timeline.
- Comparison: `SHFIN-02-A` (known-good baseline) does not show the same event sequence in the same time window.

## Detection
Target: confirm or rule out this incident pattern in under 3 minutes before remediation.

### Fast Command Path (Recommended)

1. Open elevated PowerShell on affected host `SHFIN-01-A`.
Command:
```powershell
$since = (Get-Date).AddHours(-6)
```
Expected: Time window variable is set for event queries.

2. Query Application log (`Event Viewer > Windows Logs > Application`) for `Event ID 1000` and fault details.
Command:
```powershell
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$since } |
Where-Object {
		$_.Message -match 'Faulting application name:\s*dwm.exe' -and
		$_.Message -match 'Faulting module name:\s*igdumd64.dll' -and
		$_.Message -match 'Exception code:\s*0xc0000005'
} |
Select-Object -First 10 TimeCreated, Id, ProviderName, Message
```
Expected: One or more events match `dwm.exe` + `igdumd64.dll` + `0xc0000005`.

3. Query DWM operational log (`Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`) for `Event ID 9009`.
Command:
```powershell
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$since } |
Select-Object -First 20 TimeCreated, Id, ProviderName, Message
```
Expected: `Event ID 9009` entries appear in the same time window.

4. Query LocalSessionManager operational log (`Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`) for session sequence.
Command:
```powershell
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=$since } |
Select-Object -First 40 TimeCreated, Id, ProviderName, Message
```
Expected: For affected users, `Event ID 21` (logon) is followed by `Event ID 40` (disconnect).

5. Run healthy baseline control check on `POOL-FIN-02` for `Event ID 9011` (unaffected control).
Command (run on a known healthy session host in `POOL-FIN-02`):
```powershell
$since = (Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$since } |
Select-Object -First 20 TimeCreated, Id, ProviderName, Message
```
Expected: `Event ID 9011` is present on control host and there is no repeated `1000/9009/40` failure sequence.

6. If you need to quickly identify a host from `POOL-FIN-02`, use Azure CLI.
Command:
```bash
az desktopvirtualization session-host list \
	--resource-group <RG_NAME> \
	--host-pool-name POOL-FIN-02 \
	--query "[].name" -o table
```
Expected: Returns candidate healthy control host(s) for Step 5.

### Event Viewer Path (UI Validation)

7. In Event Viewer on `SHFIN-01-A`, open exact log location `Windows Logs > Application`.
Field checks in `General` tab for `Event ID 1000`:
- `Faulting application name`: `dwm.exe`
- `Faulting module name`: `igdumd64.dll`
- `Exception code`: `0xc0000005`
Expected: All three fields match.

8. In Event Viewer on `SHFIN-01-A`, open exact log location `Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational` and filter `Event ID 9009`.
Expected: `9009` events align with disconnect window.

9. In Event Viewer on control host from `POOL-FIN-02`, open exact log location `Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational` and filter `Event ID 9011`.
Expected: `9011` appears as unaffected control baseline.

### Confirm This Is The Issue

Treat this as confirmed only when all are true:
- Affected host shows `Application` log `Event ID 1000` with `igdumd64.dll` for `dwm.exe`.
- Affected host shows `Event ID 9009` in DWM Operational log in same window.
- Affected host shows repeated `21 -> 40` user session sequence.
- Control host in `POOL-FIN-02` shows `Event ID 9011` baseline behavior and does not show repeated `1000/9009/40` failure pattern.

## Resolution

Use either the Portal Path or Command Path. Portal path names are authoritative.

### Quick Variables (for commands)
```powershell
$rg = "<AVD_RESOURCE_GROUP>"
$pool = "POOL-FIN-01"
$affectedVm = "SHFIN-01-A"
$affectedSessionHost = "<SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD>"
```

1. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Properties`.
Action: Set option `Allow new sessions` to `No` and select `Save`.
Command path:
```bash
az desktopvirtualization session-host update --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --name <SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD> --allow-new-session false
```
Expected result: New connections stop landing on `SHFIN-01-A`.

2. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions`.
Action: Set filter `Session host = SHFIN-01-A`, send message, then sign out all sessions on this host.
Command path:
```bash
az desktopvirtualization user-session list --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --query "[?contains(name,'<SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD>')].name" -o table
```
Expected result: Zero active sessions remain on `SHFIN-01-A`.

3. Open Azure Portal path `Azure Portal > Virtual machines > SHFIN-01-A > Overview`.
Action: Record option values under `Essentials`: `Provisioning state`, `Power state`, and `Image`.
Command path:
```bash
az vm show --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A --query "{provisioningState:provisioningState,imageReference:storageProfile.imageReference}" -o json
az vm get-instance-view --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv
```
Expected result: Baseline state and image details are captured.

4. Open Azure Portal path `Azure Portal > Virtual machines > SHFIN-01-A > Operations > Reapply`.
Action: Select `Reapply` to reapply VM state from current model.
Command path:
```bash
az vm reapply --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A
```
Expected result: Reapply operation starts.

5. Open Azure Portal path `Azure Portal > Virtual machines > SHFIN-01-A > Operations > Reimage + reboot`.
Action: Select `Reimage` and confirm.
Command path:
```bash
az vm reimage --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A
```
Expected result: VM is rebuilt from source image and reboots.

6. Open Azure Portal path `Azure Portal > Virtual machines > SHFIN-01-A > Overview`.
Action: Select `Refresh` until `Provisioning state = Succeeded` and `Power state = VM running`.
Command path:
```bash
az vm show --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A --query provisioningState -o tsv
az vm get-instance-view --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv
```
Expected result: VM is healthy at compute layer.

7. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Properties`.
Action: Confirm status `Available`, set `Allow new sessions = Yes`, and select `Save`.
Command path:
```bash
az desktopvirtualization session-host update --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --name <SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD> --allow-new-session true
```
Expected result: Host is available and accepting users.

## Verification

1. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
Action: Check option columns `Status`, `Agent status`, and `Allow new sessions` for `SHFIN-01-A`.
Command path:
```bash
az desktopvirtualization session-host show --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --name <SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD> --query "{status:status,allowNewSession:allowNewSession,sessions:sessions}" -o json
```
Expected result: `Status = Available` and `allowNewSession = true`.

2. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions`.
Action: Run two test logons and verify each test user session state shows `Active` for 15 minutes.
Command path:
```bash
az desktopvirtualization user-session list --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --query "[].{Name:name,State:sessionState,User:userPrincipalName}" -o table
```
Expected result: No forced reconnect cycle for test users.

3. On `SHFIN-01-A`, open exact log path `Event Viewer > Windows Logs > Application`.
Action: Filter options `Event IDs = 1000`, `Logged = Last 1 hour`; check `General` for `Faulting module name = igdumd64.dll`.
Command path:
```powershell
$since=(Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$since } |
Where-Object { $_.Message -match 'dwm.exe|igdumd64.dll' } |
Select-Object TimeCreated, Id, Message
```
Expected result: No new matching `1000` events after remediation timestamp.

4. On `SHFIN-01-A`, open exact log path `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`.
Action: Filter options `Event IDs = 9009`, `Logged = Last 1 hour`.
Command path:
```powershell
$since=(Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$since } |
Select-Object TimeCreated, Id, Message
```
Expected result: No new `9009` events.

5. On `SHFIN-01-A`, open exact log path `Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational`.
Action: Filter options `Event IDs = 40`, `Logged = Last 1 hour`.
Command path:
```powershell
$since=(Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=40; StartTime=$since } |
Select-Object TimeCreated, Id, Message
```
Expected result: No repeated disconnect pattern.

## Rollback
If user impact increases after re-enabling `SHFIN-01-A`, execute in this order:

1. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Properties`.
Action: Set option `Allow new sessions = No` and select `Save`.
Command path:
```bash
az desktopvirtualization session-host update --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --name <SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD> --allow-new-session false
```
Expected result: Immediate containment of new sessions.

2. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions`.
Action: Filter option `Session host = SHFIN-01-A` and sign out all sessions.
Command path:
```bash
az desktopvirtualization user-session list --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --query "[?contains(name,'<SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD>')].name" -o table
```
Expected result: Zero active sessions on affected host.

3. Open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
Action: Verify at least one other host has `Status = Available`.
Command path:
```bash
az desktopvirtualization session-host list --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --query "[].{Host:name,Status:status,AllowNewSession:allowNewSession}" -o table
```
Expected result: User reconnect target exists.

4. On `SHFIN-01-A`, open exact log paths `Event Viewer > Windows Logs > Application` and `Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational`.
Action: Filter options `Event IDs = 1000` and `9009`, `Logged = Last 30 minutes`; export events.
Command path:
```powershell
$since=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$since } | Export-Csv C:\Temp\rollback-app1000.csv -NoTypeInformation
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$since } | Export-Csv C:\Temp\rollback-dwm9009.csv -NoTypeInformation
```
Expected result: Fresh rollback evidence is captured.

5. Open Azure Portal path `Azure Portal > Virtual machines > SHFIN-01-A > Operations > Reimage + reboot`.
Action: Select `Reimage` to roll back to known-good source baseline.
Command path:
```bash
az vm reimage --resource-group <AVD_RESOURCE_GROUP> --name SHFIN-01-A
```
Expected result: Host is rebuilt and restarted.

6. If Step 5 fails, open Azure Portal path `Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts`.
Action: Remove `SHFIN-01-A` from host pool registration and add replacement host from approved known-good baseline image.
Command path:
```bash
az desktopvirtualization session-host delete --resource-group <AVD_RESOURCE_GROUP> --host-pool-name POOL-FIN-01 --name <SHFIN-01-A_FQDN_AS_REGISTERED_IN_AVD> --yes
```
Expected result: Unstable host is removed and service stability is restored on replacement capacity.

## Preventive
Implement these specific controls (do not skip any layer):

1. `AVD-SMOKE-01` pre-deployment gate. Owner: release engineer. Timing: before deployment. Mode: automated. [REQUIRES: CI/CD gate + pre-prod pool telemetry]
Pass if 2 test sign-ins stay active 15 minutes and `Event ID 1000` (`dwm.exe`/`igdumd64.dll`) = 0 and `Event ID 9009` = 0; fail otherwise.
If fail: block publish to production, open defect to image owner, and attach test logs to change record.

2. `AVD-COMPARE-02` baseline compare gate. Owner: image owner. Timing: before deployment. Mode: manual (automatable via pipeline script). [REQUIRES: approved OS/driver matrix]
Pass if candidate OS build + display driver version exactly match approved matrix and known-good baseline; fail on any mismatch.
If fail: stop release, require risk exception from change manager, and update candidate image.

3. In-flight monitoring alert. Owner: DWP engineer. Timing: during deployment. Mode: automated. [REQUIRES: Azure Monitor rule + action group]
Signal/threshold: on any rollout host, alert when `Event ID 1000` (message contains `dwm.exe` or `igdumd64.dll`) >= 1 OR `Event ID 9009` >= 2 in 10 minutes OR `Event ID 40` >= 3 in 10 minutes.
If fail: auto-page on-call, freeze rollout at current stage, and set `Allow new sessions = No` on impacted host(s).

4. Staged rollout control. Owner: change manager. Timing: during deployment. Mode: manual (automatable via deployment rings).
Pass Stage 1 (1 canary host, 30 min), Stage 2 (25 percent hosts, 30 min), Stage 3 (100 percent) only if no threshold breach from Control 3.
If fail: halt progression to next stage and execute rollback trigger control immediately.

5. Rollback-ready known-good image alias. Owner: image owner. Timing: before deployment and weekly health check. Mode: manual + automated validation. [REQUIRES: image alias governance]
Pass if weekly test deployment from alias reaches `Provisioning state = Succeeded` and pilot session has zero `1000/9009` for 15 minutes.
If fail: mark alias unusable, assign new known-good alias before next change window.

6. Change template checklist enforcement. Owner: change manager. Timing: before deployment approval. Mode: manual (automatable via ITSM required fields). [REQUIRES: ITSM form rules]
Pass if comparison evidence attached, event log screenshots attached, rollback owner assigned, and rollback command block prefilled.
If fail: reject approval and return change to DWP engineer for completion.

7. Post-deployment validation gate. Owner: DWP engineer. Timing: after deployment. Mode: manual (automatable with scripted validation). [REQUIRES: validation script job]
Pass if for 60 minutes: no new `Event ID 1000`/`9009` on remediated hosts, no repeated `Event ID 40`, and control baseline (`POOL-FIN-02`) continues to show `Event ID 9011` with no failure sequence.
If fail: keep impacted hosts drained, reopen incident, and execute rollback within the same change window.

8. Rollback trigger threshold control. Owner: DWP engineer + change manager. Timing: during and after deployment. Mode: manual trigger (automatable alert-to-runbook).
Trigger rollback when any one condition occurs: `1000` with `igdumd64.dll` >= 1, or `9009` >= 2/10 min, or `40` >= 3/10 min on same host, or >= 2 users report reconnect loops in 15 minutes.
If fail threshold met: execute rollback Steps 1-3 within 3 minutes, then start host rebuild/replacement path.

9. Knowledge and checklist update control. Owner: service desk lead. Timing: after deployment/incident closure. Mode: manual (automatable via KB workflow). [REQUIRES: KB governance workflow]
Pass if runbook + known error + L1 article version incremented and published within 2 business days, and service desk briefing completed.
If fail: keep problem record open and block closure until documentation updates are complete.

## Related
- `RCA-AVD-Session-Disconnects-POOL-FIN-01-20240315`
- `Runbook-AVD-Session-Disconnects-POOL-FIN-01`
- `AVD-Session-Disconnects-Evidence-Assessment`
- `Known-Error-AVD-BlackScreen-POOL-FIN-01-20260807`
- `RCA-AVD-BlackScreen-POOL-FIN-01-20260807`
