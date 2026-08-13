# L2/L3 Knowledge Base — Finance Team Cannot Access Shared Drives

Version header: v 1.0 | 13/08/2026 | Status: Draft

## Background

Finance users rely on mapped drives `S:` and `P:` for shared documents, templates, reconciliations, and operational processing. On Windows 11 migrated devices, the most common failure pattern is not a file server outage but a sign-in timing problem: the drive mapping process runs before the endpoint has stable domain network connectivity.

## Symptom

### What users report
- "My Finance drive is missing."
- "I signed in fine but the shared folders are gone."
- "It works later if I retry, but not straight after login."

### What the engineer observes
- `S:` and `P:` are absent or show disconnected state in `net use`.
- The UNC path to the share works after network stabilises.
- `gpresult` shows the user still receives the correct mapping policy.
- Group Policy processing occurred before stable network readiness at sign-in.
- Pattern is concentrated on Windows 11 migrated endpoints.

## Root Cause

Mapped drive delivery for Finance users was processed before the endpoint had completed network and domain initialization at user logon. That caused the Group Policy Preference or logon script that creates `S:` and `P:` to fail intermittently, especially on Windows 11 migrated devices with faster sign-in behavior.

### Evidence that confirms root cause
- Affected devices are Windows 11 migrated endpoints.
- User policy assignment remains present in `gpresult`.
- UNC path works when tested manually, proving the share and permissions are generally intact.
- The failure is strongest immediately after restart or first sign-in.
- The issue is resolved after enabling `Always wait for the network at computer startup and logon` and re-testing after reboot.

## Detection

Target: confirm or rule out mapped-drive timing failure in under 10 minutes.

### Fast Command Path

1. Open elevated Command Prompt on the affected device.
Command:
```cmd
net use
```
Expected: `S:` and `P:` are missing or disconnected.

2. Confirm the share itself is reachable.
Command:
```powershell
Test-Path \\corpfs01\Finance
Test-Path \\corpfs01\FinanceProjects
```
Expected: One or both commands return `True` even when drive mappings are absent.

3. Confirm policy assignment.
Command:
```cmd
gpresult /r /scope:user
```
Expected: Finance mapping policy or user policy is present.

4. Check current network profile and domain reachability.
Command:
```powershell
Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity
nltest /dsgetdc:<yourdomain>
```
Expected: Domain network is reachable by the time the manual check runs.

5. Review recent Group Policy operational events.
Command:
```powershell
$since = (Get-Date).AddHours(-6)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-GroupPolicy/Operational'; StartTime=$since } |
Select-Object -First 40 TimeCreated, Id, LevelDisplayName, Message
```
Expected: Policy processing can be correlated with the sign-in window.

### Event Viewer Path

6. Open `Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`.
Action: Filter to `Last 12 hours` and review events around sign-in.
Expected: Group Policy activity is visible for the incident window.

7. Open `Event Viewer > Windows Logs > System`.
Action: Filter for event sources `Netlogon`, `Microsoft-Windows-NlaSvc`, and `GroupPolicy`.
Expected: Network/domain readiness events can be compared to policy timing.

8. If available in your environment, review the drive mapping preference item under the relevant GPO.
Path: `Group Policy Management > <GPO> > User Configuration > Preferences > Windows Settings > Drive Maps`.
Expected: Drive letters and UNC paths are correct.

### Confirm This Is The Issue

Treat this as confirmed when all are true:
- Windows 11 migrated device is affected.
- UNC path works or works after network stabilises.
- Mapping policy remains assigned.
- Problem repeats after reboot or first sign-in.
- Enabling wait-for-network policy resolves the issue after reboot.

## Resolution

Use the exact console paths below.

1. On an admin workstation, open `Group Policy Management`.
Path: `Windows + R > gpmc.msc > OK`.
Expected result: Group Policy Management Console opens.

2. Browse to the relevant GPO.
Path: `Forest > Domains > <your domain> > Group Policy Objects > <Windows 11 baseline or Finance drive mapping GPO>`.
Expected result: The correct GPO is selected.

3. Open the logon policy location.
Path: `Computer Configuration > Policies > Administrative Templates > System > Logon`.
Expected result: Logon policy settings list is visible.

4. Edit the network-wait setting.
Setting: `Always wait for the network at computer startup and logon`.
Action: Set to `Enabled`, then select `Apply` and `OK`.
Expected result: Computer policy is updated to process logon after network readiness.

5. Review the drive mapping item if needed.
Path: `User Configuration > Preferences > Windows Settings > Drive Maps`.
Action: Confirm `S:` and `P:` use the correct UNC paths and intended action (`Update` or `Replace` according to your standard).
Expected result: Mapping definitions are correct.

6. Apply the policy on a test device.
Command:
```cmd
gpupdate /force
shutdown /r /t 0
```
Expected result: Device restarts with fresh computer and user policy.

7. Sign in with a Finance test account after reboot.
Action: Open `File Explorer > This PC` immediately after sign-in.
Expected result: `S:` and `P:` appear automatically.

## Verification

1. Open `File Explorer > This PC` on the test or remediated device.
Expected result: Finance mapped drives are visible.

2. Open both mapped drives.
Expected result: Contents load without delay or access denied errors.

3. Run:
```cmd
net use
```
Expected result: `S:` and `P:` show status `OK`.

4. Run:
```powershell
Test-Path \\corpfs01\Finance
Test-Path \\corpfs01\FinanceProjects
```
Expected result: Both return `True`.

5. Open `Event Viewer > Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`.
Expected result: Recent policy processing completes without errors that block drive mapping.

6. Reboot once more and retest immediate sign-in.
Expected result: Mapping remains consistent after a second reboot.

## Rollback

If the policy change must be reversed:

1. Open `Group Policy Management`.
Path: `Windows + R > gpmc.msc > OK`.

2. Browse to `Forest > Domains > <your domain> > Group Policy Objects > <modified GPO>`.

3. Go to `Computer Configuration > Policies > Administrative Templates > System > Logon`.

4. Open `Always wait for the network at computer startup and logon`.
Action: Return the setting to its prior state, then select `Apply` and `OK`.

5. On a test device, run:
```cmd
gpupdate /force
shutdown /r /t 0
```
Expected result: Device restarts with the rolled-back configuration.

6. If rollback is required because mappings still fail, escalate with evidence from `net use`, `gpresult`, Group Policy operational logs, and UNC path testing.

## Notes

- If UNC access fails as well, do not keep treating the issue as a mapped-drive timing problem.
- If only one user is affected, confirm AD group membership and stored credentials before changing shared policy.
- Use the RCA document for business impact and full causal narrative.