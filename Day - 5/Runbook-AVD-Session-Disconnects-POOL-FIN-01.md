# Runbook — AVD Session Disconnects (DWM / igdumd64)

## Version Header

| Field | Value |
|------|-------|
| Title | Runbook — AVD Session Disconnects (DWM / igdumd64) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Sathishbabu |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

**Incident Pattern:** Repeated AVD disconnect/reconnect loops caused by `dwm.exe` crashing in `igdumd64.dll` on a specific session host after image update.
**Primary Scope:** Host pool `POOL-FIN-01`, affected host `SHFIN-01-A`.
**Source RCA:** `RCA-AVD-Session-Disconnects-POOL-FIN-01-20240315`.
**Runbook Date:** 2026-08-07
**Audience:** DWP / EUC engineers performing incident remediation under time pressure.

---

## 1. Prerequisites

Complete this checklist before starting. Do not begin remediation until every required item is confirmed.

### A. Access Checklist
- [ ] [ELEVATED] Confirm you can open **Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01**.
- [ ] [ELEVATED] Confirm your account can change **Drain mode** and **sign out user sessions** for session hosts.
- [ ] [ELEVATED] Confirm your account can run VM actions in the host resource group (redeploy/recreate/restart VM).
- [ ] [ELEVATED] Confirm local admin access to `SHFIN-01-A` and `SHFIN-02-A` (RDP or approved management channel).
- [ ] Confirm read access to Azure Monitor / Log Analytics used by AVD diagnostics.
- [ ] Confirm permission to send user-facing maintenance notices.

### B. Tool Checklist
- [ ] Azure Portal is reachable and you can sign in.
- [ ] PowerShell console is available (`Windows PowerShell` or `PowerShell 7`).
- [ ] `Az` module is installed (verify with `Get-Module -ListAvailable Az`).
- [ ] Event Viewer is available on the session host.
- [ ] Access to known-good image reference used by healthy host `SHFIN-02-A` is available.

### C. Mandatory End-User / Incident Inputs Checklist
- [ ] Primary affected user UPN(s) or `DOMAIN\username` value(s).
- [ ] Exact first failure timestamp with timezone.
- [ ] User source endpoint details (device name and source IP if available).
- [ ] Symptom confirmation: disconnect/reconnect loop after sign-in.
- [ ] Business impact and urgency (for example: finance close window, payroll cutoff).
- [ ] Confirmation whether issue occurs for more than one user.
- [ ] Most recent successful login time (if known).

### D. Environment Facts Checklist
- [ ] Host pool name is confirmed as `POOL-FIN-01`.
- [ ] Suspected host is confirmed as `SHFIN-01-A`.
- [ ] Healthy comparison host is confirmed as `SHFIN-02-A`.
- [ ] At least one healthy host is available to receive redirected users before enabling drain mode.

---

## 2. Procedure

Perform steps in order. Each step is one concrete action.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open browser to `https://portal.azure.com` and sign in with your engineering account. | Azure Portal home page loads successfully. |
| 2 | In the top search bar, enter `Host pools` and open **Azure Virtual Desktop | Host pools**. | The Host pools list page opens. |
| 3 | Select host pool `POOL-FIN-01`. | `POOL-FIN-01` overview page opens. |
| 4 | In the left menu of `POOL-FIN-01`, select **Session hosts**. | Session host grid is displayed. |
| 5 | Select session host `SHFIN-01-A` from the grid. | `SHFIN-01-A` details blade opens. |
| 6 | [ELEVATED] In `SHFIN-01-A` details, set **Allow new sessions** to **No** (Drain mode ON), then click **Save**. | New sessions are no longer assigned to `SHFIN-01-A`. |
| 7 | In the same host pool left menu, select **User sessions**. | Active user sessions list opens. |
| 8 | Filter user sessions by session host `SHFIN-01-A`. | Only sessions on `SHFIN-01-A` are shown. |
| 9 | Select each active session and use **Send message** with text `Maintenance in progress. You will be signed out in 5 minutes.` | Users on `SHFIN-01-A` receive a maintenance warning. |
| 10 | [ELEVATED] After 5 minutes, select each remaining session on `SHFIN-01-A` and click **Sign out**. | No active sessions remain on `SHFIN-01-A`. |
| 11 | [ELEVATED] RDP to `SHFIN-01-A` using local admin-capable credentials. | Desktop session to `SHFIN-01-A` opens. |
| 12 | [ELEVATED] Open **Event Viewer** (`eventvwr.msc`). | Event Viewer console opens. |
| 13 | [ELEVATED] Navigate to **Windows Logs > Application**, then click **Filter Current Log...** and set `Event IDs` to `1000`. | Application log view shows only event ID 1000 entries. |
| 14 | [ELEVATED] In filtered Application events, inspect **General** message text for `dwm.exe` and `igdumd64.dll`. | Crash signature is confirmed or ruled out for Application log. |
| 15 | [ELEVATED] Navigate to **Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational**. | DWM Operational log opens. |
| 16 | [ELEVATED] Click **Filter Current Log...** and set `Event IDs` to `9009`. | DWM log view shows only event ID 9009 entries. |
| 17 | [ELEVATED] Navigate to **Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational**. | Local Session Manager log opens. |
| 18 | [ELEVATED] Click **Filter Current Log...** and set `Event IDs` to `21,40`. | Log shows sign-in (`21`) and disconnect (`40`) events for correlation. |
| 19 | [ELEVATED] Open **Windows PowerShell** as Administrator on `SHFIN-01-A`. | Elevated PowerShell console opens. |
| 20 | [ELEVATED] Run `Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber`. | OS build baseline for `SHFIN-01-A` is displayed for record. |
| 21 | [ELEVATED] Run `Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'DISPLAY' } | Select-Object DeviceName, DriverVersion, DriverDate`. | Display driver baseline for `SHFIN-01-A` is displayed for record. |
| 22 | [ELEVATED] Repeat Step 11 on `SHFIN-02-A`. | Session to healthy comparison host opens. |
| 23 | [ELEVATED] Repeat Step 21 on `SHFIN-02-A`. | Known-good display driver baseline is captured. |
| 24 | In Azure Portal search bar, enter `Virtual machines`, then open **Virtual machines**. | VM list page opens. |
| 25 | Select VM `SHFIN-01-A`, then open **Overview**. | VM overview blade for `SHFIN-01-A` opens. |
| 26 | [ELEVATED] Rebuild `SHFIN-01-A` using the known-good image reference aligned to `SHFIN-02-A` (follow your org standard method: image version pin or VM redeploy workflow). | Rebuild/redeploy operation starts successfully. |
| 27 | In VM `SHFIN-01-A` **Overview**, refresh until **Provisioning state** equals `Succeeded`. | Provisioning completes without errors. |
| 28 | [ELEVATED] Click **Restart** on VM `SHFIN-01-A` in Azure VM overview and confirm. | VM restarts and returns to running state. |
| 29 | Return to **Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts**. | Session host list reopens for status check. |
| 30 | Verify `SHFIN-01-A` shows status `Available` and heartbeat healthy. | Host is online and healthy in AVD. |
| 31 | [ELEVATED] Open `SHFIN-01-A` details and set **Allow new sessions** to **Yes**, then click **Save**. | Host can receive user sessions again. |
| 32 | Start one controlled test connection using an AVD test user from Windows App/Remote Desktop client. | Test session starts and remains connected. |

---

## 3. Verification

Complete all checks before closure.

1. Open **Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts**.
Expected result: `SHFIN-01-A` shows `Available` and can accept sessions.

2. Open **Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions** and verify active test session appears on `SHFIN-01-A`.
Expected result: Test user session is connected and stable on `SHFIN-01-A`.

3. Keep the test session connected for 15 minutes and refresh **User sessions** every 5 minutes.
Expected result: Session state remains `Active` with no disconnect/reconnect cycle.

4. On `SHFIN-01-A`, open **Event Viewer (eventvwr.msc) > Windows Logs > Application**.
Expected result: Application log opens for host-side crash review.

5. In **Windows Logs > Application**, select **Filter Current Log...**, set **Event IDs** to `1000`, and set **Logged** to `Last 1 hour`.
Expected result: Filtered view shows only recent application crash events.

6. Review filtered `Event ID 1000` entries and confirm there are no new entries containing `dwm.exe` or `igdumd64.dll` after remediation timestamp.
Expected result: No new `dwm.exe` / `igdumd64.dll` crash events are present.

7. On `SHFIN-01-A`, open **Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational**.
Expected result: DWM operational log is open.

8. In DWM Operational log, select **Filter Current Log...**, set **Event IDs** to `9009`, and set **Logged** to `Last 1 hour`.
Expected result: Filtered DWM view shows only relevant exit events.

9. Confirm no new `Event ID 9009` events are generated after remediation timestamp.
Expected result: No abnormal DWM exits after fix.

10. On `SHFIN-01-A`, open **Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational**.
Expected result: Session lifecycle log is open.

11. In LocalSessionManager Operational log, select **Filter Current Log...** and set **Event IDs** to `40` with **Logged** = `Last 1 hour`.
Expected result: Disconnect events list is limited to recent window.

12. Confirm repeated `Event ID 40` entries are not occurring for the same user session in the validation window.
Expected result: No repeating disconnect pattern is present.

13. Call or message impacted users and record confirmation that reconnect loop is resolved.
Expected result: Users confirm stable login and session continuity.

14. Update the incident ticket with screenshots/exports from steps 1-12 and include remediation timestamp.
Expected result: Closure evidence is complete and auditable.

---

## 4. Rollback (Immediate Actions)

Use this section if user impact increases after host reintroduction. Target execution time is under 3 minutes.

### 3-Minute Containment Rollback

1. [ELEVATED] Open **Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A**.
Expected result: Host details blade is open.

2. [ELEVATED] Set **Allow new sessions** to **No** and click **Save**.
Expected result: New sessions stop landing on `SHFIN-01-A` immediately.

3. [ELEVATED] Go to **Host pools > POOL-FIN-01 > User sessions**, filter by session host `SHFIN-01-A`, select all sessions, and click **Sign out**.
Expected result: All active sessions are removed from unstable host.

4. [ELEVATED] In **Session hosts**, verify at least one healthy host shows `Available`.
Expected result: Users can reconnect to healthy capacity.

5. Send user update: `Issue isolated to one host. Please reconnect now.`
Expected result: Users reconnect to healthy hosts instead of `SHFIN-01-A`.

6. On `SHFIN-01-A`, open **Event Viewer > Windows Logs > Application**, filter `Event IDs = 1000`, `Logged = Last 30 minutes`.
Expected result: Evidence window is ready for rollback incident capture.

7. On `SHFIN-01-A`, open **Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational**, filter `Event IDs = 9009`, `Logged = Last 30 minutes`.
Expected result: DWM failure evidence is ready for escalation.

### Post-Containment Recovery Rollback

8. [ELEVATED] Keep `SHFIN-01-A` in drain mode until rebuild completes and full verification passes.
Expected result: Unstable host is quarantined from users.

9. [ELEVATED] Rebuild or replace `SHFIN-01-A` from the last confirmed-good image used before failed remediation.
Expected result: Host returns with known-good baseline.

10. [ELEVATED] If rebuild fails, remove `SHFIN-01-A` from host pool and add replacement host from known-good image.
Expected result: Pool stability is restored without the failed host.

11. Escalate to Desktop Engineering with event log evidence and timestamp of rollback containment.
Expected result: Engineering receives exact data to complete root-fix.

---

## 5. Notes

- This failure signature is host-side when `dwm.exe` faults in `igdumd64.dll` with `0xc0000005`; do not treat it as a pure network issue without contrary evidence.
- A successful logon event (`Event 21`) does not prove session stability; DWM may still crash seconds later.
- If multiple users fail only on one host, prioritize host-image rollback/replacement over user-profile troubleshooting.
- During post-image-change windows, monitor `Event ID 1000`, `Event ID 9009`, and `Event ID 40` for at least 30 minutes before declaring stability.
- Related incidents and references:
  - `RCA-AVD-Session-Disconnects-POOL-FIN-01-20240315`
  - `AVD-Session-Disconnects-Evidence-Assessment`
  - `Known-Error-AVD-BlackScreen-POOL-FIN-01-20260807`
  - `RCA-AVD-BlackScreen-POOL-FIN-01-20260807`
