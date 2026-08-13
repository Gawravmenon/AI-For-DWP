# Runbook — Finance Team Cannot Access Shared Drives

## Version Header

| Field | Value |
|------|-------|
| Title | Runbook — Finance Team Cannot Access Shared Drives |
| Version | 1.0 |
| Date | 13/08/2026 |
| Author | DWP Analyst |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

**Incident Pattern:** Finance users on Windows 11 migrated endpoints sign in successfully but mapped drives `S:` and `P:` are missing or inaccessible because drive mapping runs before network readiness.
**Primary Scope:** Finance user endpoints and sessions using domain-based drive mapping.
**Source RCA:** `RCA-SharedDriveAccessDenied-S-Finance-20260813`.
**Runbook Date:** 2026-08-13
**Audience:** DWP service desk and EUC engineers performing structured diagnosis and remediation.

---

## 1. Prerequisites

Complete this checklist before starting.

### A. Access Checklist
- [ ] Confirm you can sign in to the affected device with support access or work alongside the user.
- [ ] Confirm you can open `gpedit.msc` on a test or authorised endpoint if local policy validation is needed.
- [ ] Confirm you can open Group Policy Management Console (`gpmc.msc`) if domain policy review is required.
- [ ] Confirm you can reach the target file server or DFS namespace used for Finance shares.
- [ ] Confirm you can update the incident ticket during testing.

### B. Tool Checklist
- [ ] Command Prompt is available.
- [ ] Windows PowerShell is available.
- [ ] Event Viewer is available.
- [ ] File Explorer is available.
- [ ] `gpresult` and `net use` commands can run.

### C. Mandatory End-User Inputs Checklist
- [ ] Username and device name.
- [ ] Exact drive letters affected (`S:`, `P:`, or both).
- [ ] First failure time.
- [ ] Whether the issue started after restart, VPN reconnect, or first sign-in of the day.
- [ ] Whether the user can access the share by UNC path if provided.
- [ ] Whether multiple Finance users are affected.

### D. Environment Facts Checklist
- [ ] Device is Windows 11 or recently migrated.
- [ ] User is a Finance user expected to receive mapped drives.
- [ ] UNC targets for the drives are known, for example `\\corpfs01\Finance` and `\\corpfs01\FinanceProjects`.

---

## 2. Procedure

Perform the steps in order.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On the affected device, press `Windows + R`, enter `winver`, and select `OK`. | Windows version dialog confirms the device is Windows 11. |
| 2 | Press `Windows + E` to open File Explorer, then select `This PC`. | You can see whether `S:` and `P:` are present. |
| 3 | In the File Explorer address bar, enter the exact UNC path for the Finance share, for example `\\corpfs01\Finance`, then press `Enter`. | If the UNC path opens, the share is reachable and the issue is likely mapping-related. |
| 4 | Press `Windows + R`, enter `cmd`, then press `Ctrl + Shift + Enter` to open elevated Command Prompt. | Elevated Command Prompt opens. |
| 5 | Run `net use`. | Output shows current mapped drives and confirms whether `S:` or `P:` are missing or disconnected. |
| 6 | In the same Command Prompt, run `gpresult /r /scope:user`. | Output confirms the user-side policies applied to the session. |
| 7 | Press `Windows + R`, enter `eventvwr.msc`, and select `OK`. | Event Viewer opens. |
| 8 | In Event Viewer, go to `Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`. | Group Policy operational log is open. |
| 9 | In the right pane, select `Filter Current Log...`, set `Logged` to `Last 12 hours`, then select `OK`. | Recent Group Policy processing events are easier to review. |
| 10 | Review recent events around the user logon time for drive mapping or policy processing failures. | You identify whether user policy processed before resources were available. |
| 11 | In Event Viewer, go to `Windows Logs > System`. | System log is open. |
| 12 | Select `Filter Current Log...`, set `Event sources` to `Netlogon`, `GroupPolicy`, and `Microsoft-Windows-NlaSvc`, set `Logged` to `Last 12 hours`, then select `OK`. | Network and domain-readiness events for the same window are visible. |
| 13 | If UNC access works but mappings are missing, run `gpupdate /force`. | User and computer policy refresh starts. |
| 14 | Sign the user out from `Start > profile icon > Sign out`, then sign back in after the policy refresh completes. | A fresh sign-in tests whether mappings now build correctly. |
| 15 | After sign-in, open `This PC` again and confirm whether `S:` and `P:` are present. | Drives appear if policy timing is corrected. |
| 16 | If mappings still fail across multiple Finance users, open `Group Policy Management` on an authorised admin workstation. | Domain policy review can begin. |
| 17 | In `Group Policy Management`, go to `Forest > Domains > <your domain> > Group Policy Objects`, then open the GPO that controls Finance drive mappings or Windows 11 baseline settings. | The relevant GPO is open. |
| 18 | In the GPO editor, go to `Computer Configuration > Policies > Administrative Templates > System > Logon`. | The logon policy settings are visible. |
| 19 | Open policy `Always wait for the network at computer startup and logon`, set it to `Enabled`, then select `Apply` and `OK`. | The policy is configured to wait for network readiness. |
| 20 | If drive mappings are delivered through Group Policy Preferences, go to `User Configuration > Preferences > Windows Settings > Drive Maps` and review the Finance drive items. | You can confirm the drive actions, labels, letters, and target paths are correct. |
| 21 | On a test Finance device, run `gpupdate /force`, then restart the device from `Start > Power > Restart`. | The device reboots and picks up the new computer policy. |
| 22 | After restart, sign in with a test Finance account and open `This PC`. | `S:` and `P:` should map automatically. |

---

## 3. Verification

Complete all checks before closure.

1. On the affected or test device, open `File Explorer > This PC`.
Expected result: `S:` and `P:` are visible with the expected labels.

2. In File Explorer, open the path for `S:` and then open the path for `P:`.
Expected result: Both shared drives open without access denied or reconnect errors.

3. In elevated Command Prompt, run `net use`.
Expected result: `S:` and `P:` appear with status `OK`.

4. In elevated PowerShell, run `Test-Path \\corpfs01\Finance` and `Test-Path \\corpfs01\FinanceProjects`.
Expected result: Both commands return `True`.

5. In Event Viewer, open `Applications and Services Logs > Microsoft > Windows > GroupPolicy > Operational`.
Expected result: Recent policy processing completes without drive-mapping-related failures.

6. In Event Viewer, open `Windows Logs > System` and review the same sign-in window.
Expected result: Network and domain connectivity events occur before or cleanly alongside user policy processing.

7. Confirm with at least one Finance user that the drives remain available after reboot and sign-in.
Expected result: User confirms the issue is resolved.

---

## 4. Rollback

Use this section if the policy change causes unintended sign-in delay or does not resolve the issue.

### 3-Minute Containment Rollback

1. On an admin workstation, open `Group Policy Management` by pressing `Windows + R`, entering `gpmc.msc`, and selecting `OK`.
Expected result: Group Policy Management Console opens.

2. Go to `Forest > Domains > <your domain> > Group Policy Objects`, then open the modified Windows 11 or Finance mapping GPO.
Expected result: The correct GPO is selected.

3. Go to `Computer Configuration > Policies > Administrative Templates > System > Logon`.
Expected result: The logon policy settings list is visible.

4. Open `Always wait for the network at computer startup and logon`, set it back to its previous state, then select `Apply` and `OK`.
Expected result: The rollback setting is saved.

5. On the test device, open elevated Command Prompt and run `gpupdate /force`.
Expected result: Policy refresh completes.

6. Restart the test device from `Start > Power > Restart`.
Expected result: Device reboots with the rolled-back configuration.

### Post-Containment Action

7. If rollback is required, keep the incident open and escalate to EUC or AD Engineering with the following evidence:
- Screenshot or export from `GroupPolicy > Operational` log.
- Output of `net use` before and after refresh.
- Output of `gpresult /r /scope:user`.
- Confirmation whether UNC path worked when drive mapping failed.

---

## 5. Notes

- If the UNC path fails as well as the mapped drive, treat the case as a wider file server, DFS, VPN, or permissions issue rather than a pure mapping-timing problem.
- If only one user is affected and other Finance users on the same device group are healthy, check account group membership and Credential Manager before changing policy.
- This pattern is most likely immediately after migration, reboot, VPN reconnect, or first sign-in of the day.
- Related references:
  - `RCA-SharedDriveAccessDenied-S-Finance-20260813`
  - `Closure-Note-MappedDrives-Win11.txt`