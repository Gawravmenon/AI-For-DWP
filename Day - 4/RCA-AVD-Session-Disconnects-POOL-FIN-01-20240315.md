# Root Cause Analysis — AVD Session Disconnects
**Incident Reference:** AVD-POOL-FIN-01-20240315  
**Date of Incident:** 2024-03-15  
**Time Window:** 07:02 – 10:00  
**Affected Service:** Azure Virtual Desktop session host pool `POOL-FIN-01`  
**Affected Hosts:** `SHFIN-01-A`  
**Users Affected:** `FINBRIDGE\mlopez`, `FINBRIDGE\akapoor`  
**Resolved By:** Applied the recommended host-image remediation  
**Document Author:** DWP Analyst  
**Date of RCA:** 2026-08-06  

---

## 1. Incident Summary

Users in `POOL-FIN-01` experienced repeated AVD session disconnects and automatic reconnects on `SHFIN-01-A` during the morning of 2024-03-15. The failure pattern was tied to repeated `dwm.exe` crashes in `igdumd64.dll` immediately after logon, with the Desktop Window Manager exiting and the session being disconnected. The issue was resolved after the recommended remediation was applied, and users were later verified logging on to hosts in `POOL-FIN-01` with no further issues at 10:00 AM.

---

## 2. Timeline of Events

| Time | Event ID | Source | Description |
|------|----------|--------|-------------|
| 07:02:10 | 21 | TerminalServices-LocalSessionManager | Session logon succeeded for `FINBRIDGE\mlopez`, Session ID 3, source `10.10.1.55` |
| 07:02:14 | 1 | Kernel-General | System boot time reported as 2024-03-15 02:03:11, confirming the host restarted after the overnight image update |
| 07:02:16 | 1000 | Application Error | `dwm.exe` faulted in `igdumd64.dll` with exception code `0xc0000005` |
| 07:02:17 | 40 | TerminalServices-LocalSessionManager | Session disconnected for `FINBRIDGE\mlopez`, Session ID 3 |
| 07:02:18 | 9009 | Desktop Window Manager | DWM exited with code `0x40010004` |
| 07:02:44 | 21 | TerminalServices-LocalSessionManager | Reconnect logon succeeded for `FINBRIDGE\mlopez`, Session ID 3 |
| 07:02:46 | 1000 | Application Error | `dwm.exe` faulted again in `igdumd64.dll` with exception code `0xc0000005` |
| 07:02:47 | 40 | TerminalServices-LocalSessionManager | Session disconnected again for `FINBRIDGE\mlopez`, Session ID 3 |
| 07:03:01 | 9009 | Desktop Window Manager | DWM exited again with code `0x40010004` |
| 07:03:10 | 21 | TerminalServices-LocalSessionManager | Second reconnect logon succeeded for `FINBRIDGE\mlopez`, Session ID 4 |
| 07:08:22 | 21 | TerminalServices-LocalSessionManager | Session logon succeeded for `FINBRIDGE\akapoor`, Session ID 5, source `10.10.1.61` |
| 07:08:24 | 1000 | Application Error | `dwm.exe` faulted again in `igdumd64.dll`, showing the same failure pattern for a second user |
| 10:00:00 | Validation | Service Desk / Operations | Recommended remediation applied and users verified logging on to `POOL-FIN-01` hosts with no issues reported |

**Incident duration before remediation:** approximately 3 hours from first observed fault sequence to verified recovery window.

---

## 3. Impact Assessment

| Category | Detail |
|----------|--------|
| Service affected | AVD desktop sessions in `POOL-FIN-01` |
| Users affected | At least 2 confirmed users on the same session host |
| Nature of impact | Session disconnects with automatic reconnect, interrupted active work |
| Scope | Host-specific problem on `SHFIN-01-A`, with comparison host `SHFIN-02-A` remaining healthy |
| Business impact | Medium — repeated session interruptions for finance users during working hours |

---

## 4. Supporting Evidence

- **Event 21 at 07:02:10:** A normal RDS logon succeeded for `FINBRIDGE\mlopez`, showing the host accepted the session before the fault sequence started.
- **Event 1 at 07:02:14:** The host boot time was `2024-03-15 02:03:11`, which aligns with the overnight image update noted on the host and narrows the likely cause to a post-update regression.
- **Event 1000 at 07:02:16:** `dwm.exe` crashed in `igdumd64.dll` with exception code `0xc0000005`. This is the strongest technical indicator and points to a graphics/driver fault rather than a pure network issue.
- **Event 40 at 07:02:17 and 07:02:47:** The session was disconnected immediately after each crash, confirming the crash sequence directly disrupted the user session.
- **Event 9009 at 07:02:18 and 07:03:01:** Desktop Window Manager exited twice with code `0x40010004`, reinforcing that the shell graphics stack was failing repeatedly.
- **Event 21 at 07:08:22 and Event 1000 at 07:08:24:** A second user on the same host experienced the same `dwm.exe`/`igdumd64.dll` crash pattern, which weakens any user-specific explanation and supports a shared host-side cause.
- **Comparison host `SHFIN-02-A` at 07:01:46:** Desktop Window Manager started successfully and no Application Error events were recorded in the same window, which supports the conclusion that the fault was isolated to the affected image or host configuration rather than the whole pool.
- **Recovery confirmation at 10:00 AM:** Users were verified logging on to hosts in `POOL-FIN-01` with no issues reported after the remediation was applied.

**Key inference:** The pattern is most consistent with a graphics driver or host image regression causing `dwm.exe` instability after the overnight update.

---

## 5. Root Cause — 5 Why Analysis

### Problem Statement
> Users in `POOL-FIN-01` experienced repeated AVD disconnects and reconnects on `SHFIN-01-A` because the host desktop shell crashed shortly after session logon.

**Why 1 — Why were users disconnected?**  
Because the session host dropped the active AVD session immediately after `dwm.exe` crashed, forcing the user into a disconnect/reconnect cycle.

**Why 2 — Why did the desktop shell crash?**  
Because `dwm.exe` faulted in `igdumd64.dll` with exception code `0xc0000005`, and the Desktop Window Manager then exited with code `0x40010004`.

**Why 3 — Why did the graphics component fail?**  
The failure started right after the host booted from the overnight image update window, and the same pattern occurred for more than one user on the same host. That points to a host-image or graphics-driver regression rather than an individual profile, client, or transient user action.

**Why 4 — Why was the regression not present on the comparison host?**  
`SHFIN-02-A` on the pre-update image version started the Desktop Window Manager successfully and produced no Application Error events in the same window, showing the issue was not universal across the pool and was tied to the updated host image on the affected machine.

**Why 5 — Why did the change reach users before detection?**  
The overnight host-image change was not fully validated against the AVD graphics/session path before users were placed back onto the host. The affected image contained a graphics stack condition that only became visible once real user sessions triggered the DWM process.

---

## 6. Root Cause Statement

The **direct root cause** was a host-side graphics stack failure causing `dwm.exe` to crash in `igdumd64.dll` immediately after logon.

The **contributing root cause** was the overnight host-image update introducing a graphics/driver regression on `SHFIN-01-A`.

The **systemic root cause** was insufficient pre-production validation of the updated image against live AVD sign-in and session stability scenarios before returning the host to service.

---

## 7. Resolution

- The suggested remediation was applied during the incident response window.
- The affected service was restored and users were verified logging on to hosts in `POOL-FIN-01` at 10:00 AM with no issues reported.
- No further disconnects were reported after the fix was in place.

---

## 8. Preventive Actions

| Priority | Action | Owner | Purpose |
|----------|--------|-------|---------|
| High | Add a mandatory AVD sign-in smoke test to the image release process | Desktop Engineering | Confirms `dwm.exe`, shell, and session logon remain stable before production rollout |
| High | Validate new host images against multiple concurrent user logons on a non-production host pool | EUC / VDI Team | Detects host-side graphics regressions that only appear under real session load |
| High | Compare graphics driver versions and DWM behavior between updated and known-good pools before rollout | Desktop Engineering | Prevents recurrence of driver-specific crashes such as `igdumd64.dll` faults |
| Medium | Keep a rollback-ready known-good image for each production host pool | EUC / Operations | Allows rapid restoration if post-update instability is detected |
| Medium | Monitor Event 1000 and Event 9009 on session hosts after every image change | Monitoring / Operations | Surfaces DWM crash patterns early in the deployment window |
| Low | Document the recovery procedure for graphics-related AVD instability in the runbook | Service Desk / EUC | Speeds response and reduces time to remediation for future incidents |

---

## 9. Lessons Learned

- A session host can appear healthy after logon while still failing under the desktop shell workload; logon success alone is not enough to validate image quality.
- Repeated `dwm.exe` crashes in `igdumd64.dll` are a strong indicator of a graphics stack regression and should be treated as a host-image problem until proven otherwise.
- Testing against a single reference host is useful, but rollout validation should include the same image path that production users will receive.
- Quick comparison with a healthy host pool helps separate host-image regressions from user, network, or profile issues.

---

## 10. Sign-off

| Role | Name | Date |
|------|------|------|
| DWP Analyst | | |
| Service Desk Lead | | |
| Desktop Engineering | | |
| EUC / VDI Operations | | |