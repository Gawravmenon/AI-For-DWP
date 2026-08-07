# AVD Black Screen Incident - Ranked Hypothesis (2026-08-07)

## Scope Facts
- Symptom: blank/black screen after login. Clears after ~30s for some users; persists for others.
- Who: ~40% of users on POOL-FIN-01.
- Control group: POOL-FIN-02 completely unaffected.
- Since: ~07:00 this morning.
- Change: overnight image update to POOL-FIN-01 at 02:00. POOL-FIN-02 was not updated.

## Key Timing-Weighted Conclusion
Most consistent single cause with the timing and pool isolation clue:

**Image-level regression introduced in the updated POOL-FIN-01 golden image, specifically in logon shell initialization (Explorer/AppX startup path).**

Rationale:
- The only confirmed changed variable is the 02:00 image update on POOL-FIN-01.
- Symptoms start after that window and are constrained to the updated pool.
- POOL-FIN-02 being fully unaffected argues against tenant-wide, network-wide, or identity-wide causes.

## Re-Ranked Top 5 Causes (Most Probable First)

### 1) Image-level logon shell initialization regression (Explorer/AppX init path)
Why this fits scope facts:
- Best match to update timing and one-pool-only impact.
- Black screen post-authentication with delayed desktop appearance is consistent with shell-init delay.
- Mixed behavior (some recover in ~30s, some persist) can occur with startup race/timing conditions.

Single fastest check:
- Reproduce with a brand-new test profile on POOL-FIN-01 and compare same test on POOL-FIN-02.

### 2) Image-introduced FSLogix/profile load compatibility issue
Why this fits scope facts:
- Black screen + delayed recovery often maps to profile attach/load delay.
- Variability by user aligns with profile/container condition differences.
- Isolation to updated pool is consistent if only that image changed component behavior.

Single fastest check:
- Correlate black-screen window with FSLogix/profile-load event timing on one affected POOL-FIN-01 host.

### 3) Display/GPU driver regression in the new image
Why this fits scope facts:
- Black screen can be display stack initialization related.
- Driver drift is commonly image-scoped.
- Unchanged POOL-FIN-02 remaining clean supports pool-specific image regression.

Single fastest check:
- Compare display driver versions between affected POOL-FIN-01 host(s) and POOL-FIN-02 host(s).

### 4) AVD agent/stack version mismatch introduced with POOL-FIN-01 rollout
Why this fits scope facts:
- Component mismatch can delay session presentation after sign-in.
- If only updated pool has stack/version divergence, impact remains pool-isolated.
- Partial user impact can reflect host allocation differences.

Single fastest check:
- Compare AVD agent/bootloader/stack versions across affected vs unaffected hosts and versus POOL-FIN-02.

### 5) New logon-time policy/script/task in updated image baseline
Why this fits scope facts:
- Logon-time processing stalls can produce temporary black screens.
- Pool-specific baseline change could isolate to POOL-FIN-01.
- Lower probability than top causes until processing delays are proven.

Single fastest check:
- Capture one affected-user logon trace and confirm whether GP/script processing duration matches black-screen interval.

## Analyst Position
- Do not commit to a single cause yet.
- Prioritize elimination order: #1 -> #2 -> #3, because those best explain both the timing and the unaffected control pool.

---

## Addendum - Event Evidence Review and Resolution Plan (2026-08-07)

### Incident Window Event Details Reviewed

Affected host: SHFIN-01-A (POOL-FIN-01)

- 07:02:10 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21
	- Session logon succeeded for FINBRIDGE\mlopez (Session ID 3).
- 07:02:14 - Microsoft-Windows-Kernel-General Event 1
	- Host boot time recorded as 02:03:11 (post overnight image update).
- 07:02:16 - Application Error Event 1000
	- Faulting application: dwm.exe (10.0.22621.2861)
	- Faulting module: igdumd64.dll (31.0.101.4146)
	- Exception code: 0xc0000005
- 07:02:17 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 40
	- Session disconnected (Session ID 3).
- 07:02:18 - Desktop Window Manager Event 9009
	- DWM exited with code 0x40010004.
- 07:02:44 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21
	- Reconnect logon succeeded.
- 07:02:46 - Application Error Event 1000
	- Repeated dwm.exe fault in igdumd64.dll.
- 07:02:47 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 40
	- Session disconnected again.
- 07:03:01 - Desktop Window Manager Event 9009
	- DWM exited again.
- 07:03:10 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21
	- Second reconnect succeeded (Session ID 4).
- 07:08:22 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21
	- Another user logon succeeded (FINBRIDGE\akapoor, Session ID 5).
- 07:08:24 - Application Error Event 1000
	- Same dwm.exe/igdumd64.dll crash pattern recurs.

Comparison host: SHFIN-02-A (POOL-FIN-02, unaffected)

- 07:01:44 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21
	- Session logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011
	- DWM started successfully.
- No Application Error Event 1000 entries in the same window.

### Reviewed Hypotheses Against Evidence

#### 1) Image-level logon shell initialization regression (Explorer/AppX path)
Judgement: Contradicts

Determining evidence:
- 07:02:16 and 07:02:46 - Application Error Event 1000 shows dwm.exe faulting in igdumd64.dll.
- 07:02:18 and 07:03:01 - DWM Event 9009 confirms compositor crash/exit.
- Pattern points to graphics path failure, not shell init delay as primary mechanism.

#### 2) Image-introduced FSLogix/profile load compatibility issue
Judgement: Contradicts

Determining evidence:
- 07:02:10 - LSM Event 21 confirms logon already succeeded.
- 07:02:16 and 07:02:17 - Immediate crash/disconnect sequence (Event 1000 followed by Event 40).
- Repeated same sequence at 07:02:44 to 07:02:47, indicating runtime crash rather than profile attach stall.

#### 3) Display/GPU driver regression in updated image
Judgement: Supports

Determining evidence:
- 07:02:16, 07:02:46, 07:08:24 - Application Error Event 1000 repeatedly implicates igdumd64.dll.
- 07:02:18 and 07:03:01 - DWM Event 9009 follows crashes.
- SHFIN-02-A at 07:01:46 has DWM Event 9011 success and no matching crash events.

#### 4) AVD agent/stack version mismatch introduced during rollout
Judgement: Neutral

Determining evidence:
- LSM Event 21 logon successes at 07:02:10, 07:02:44, and 07:03:10 show session establishment works.
- Available logs do not include explicit AVD agent/bootloader fault events.
- Evidence neither directly confirms nor fully excludes this hypothesis.

#### 5) New logon-time policy/script/task stall in updated image baseline
Judgement: Contradicts

Determining evidence:
- Repeating crash-disconnect cycles: Event 1000 (07:02:16, 07:02:46) and Event 40 (07:02:17, 07:02:47).
- DWM exit events (9009) at 07:02:18 and 07:03:01 align with process failure, not a pure GP/script delay.

### Surviving Hypothesis

**Display/GPU driver regression introduced by the POOL-FIN-01 image update, causing dwm.exe to crash in igdumd64.dll during user logon.**

### Detailed Resolution Steps

#### 1) Immediate Containment
- Place POOL-FIN-01 session hosts in drain mode to stop new assignments.
- Route new sessions to POOL-FIN-02 during remediation.
- Pause any additional rollout of the updated POOL-FIN-01 image.

#### 2) Confirm Blast Radius
- Query all POOL-FIN-01 hosts for:
	- Application Error Event 1000 where faulting app = dwm.exe and module = igdumd64.dll.
	- Desktop Window Manager Event 9009.
	- LSM Event 40 disconnects following Event 21 logons.
- Rank hosts by crash count to prioritize fixes.

#### 3) Validate Version Delta
- Capture graphics driver version/date from one affected POOL-FIN-01 host.
- Compare with one healthy POOL-FIN-02 host and pre-update image baseline.
- Confirm the exact driver package/version introduced with the failing image.

#### 4) Tactical Host Mitigation
- Roll back Intel graphics driver to the known-good version from pre-update baseline.
- If rollback is not immediately possible, apply temporary policy to reduce/disable hardware acceleration path for remote sessions.
- Reboot host and perform validation logons with at least two affected-user profiles.

#### 5) Golden Image Hotfix
- Branch the updated image and remove the problematic driver package.
- Install validated known-good graphics driver.
- Prevent automatic re-introduction of the bad driver via update policy.
- Run smoke tests:
	- 10-20 repeated logon/logoff cycles.
	- Multi-user concurrency.
	- Reconnect behavior.

#### 6) Controlled Re-Deployment
- Deploy fixed image to one canary host in POOL-FIN-01.
- Observe during active logon traffic for at least 60 minutes.
- Promote rollout in small batches only if:
	- No new Event 1000 dwm.exe/igdumd64.dll crashes.
	- No new DWM Event 9009 errors.
	- No user-reported black-screen recurrence.

#### 7) Closure Criteria
- Two business hours without recurring DWM/igdumd64 crash events on POOL-FIN-01.
- Session disconnect rates return to pre-incident baseline.
- User impact reduced to normal operating levels.
- Pool image/driver parity documented and approved.
