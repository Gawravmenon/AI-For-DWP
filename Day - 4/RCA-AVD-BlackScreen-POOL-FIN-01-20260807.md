# RCA - AVD Black Screen Post-Login

## Incident Summary
- Incident: Users experienced black/blank screen after AVD login.
- Affected pool: POOL-FIN-01
- Unaffected pool: POOL-FIN-02
- Start time: ~07:00 (first user impact reported)
- Resolution time: 10:00
- Current status: Resolved and verified

## Business Impact
- Approximately 40% of users assigned to POOL-FIN-01 were impacted.
- User experience ranged from:
  - black screen clearing after ~30 seconds
  - persistent black screen followed by disconnect/reconnect loops for some sessions
- Productivity impact was concentrated on finance users routed to POOL-FIN-01 hosts.

## Scope and Change Correlation
- Overnight image update applied only to POOL-FIN-01 at 02:00.
- POOL-FIN-02 did not receive the update and remained fully healthy.
- This created a strong control comparison isolating the change domain to POOL-FIN-01 image stack.

## Supporting Technical Evidence

### Affected Host Evidence (SHFIN-01-A, POOL-FIN-01)
- 07:02:10 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 21
  - Session logon succeeded (FINBRIDGE\\mlopez, Session ID 3).
- 07:02:14 - Microsoft-Windows-Kernel-General Event 1
  - Host boot time 02:03:11, consistent with post-image-update restart.
- 07:02:16 - Application Error Event 1000 (Error)
  - Faulting application: dwm.exe (10.0.22621.2861)
  - Faulting module: igdumd64.dll (31.0.101.4146)
  - Exception: 0xc0000005
- 07:02:17 - Microsoft-Windows-TerminalServices-LocalSessionManager Event 40
  - Session disconnected.
- 07:02:18 - Desktop Window Manager Event 9009 (Error)
  - DWM exited with code 0x40010004.
- 07:02:44 - LSM Event 21
  - Reconnect logon succeeded.
- 07:02:46 - Application Error Event 1000
  - Repeated dwm.exe fault in igdumd64.dll.
- 07:02:47 - LSM Event 40
  - Session disconnected again.
- 07:03:01 - DWM Event 9009
  - Repeated DWM exit.
- 07:08:24 - Application Error Event 1000
  - Same dwm.exe/igdumd64.dll crash pattern for another user.

### Unaffected Control Evidence (SHFIN-02-A, POOL-FIN-02)
- 07:01:44 - LSM Event 21
  - Session logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011 (Information)
  - DWM started successfully.
- No Application Error Event 1000 in the same analysis window.

## Timeline (All Times Local)
- 02:00 - Scheduled image update completed for POOL-FIN-01.
- 02:03 - POOL-FIN-01 host reboot observed (Kernel-General Event 1 confirms boot timeline).
- ~07:00 - User reports begin: black screen after login on POOL-FIN-01.
- 07:02-07:08 - Repeating telemetry captured:
  - successful logon (Event 21)
  - dwm.exe crash in igdumd64.dll (Event 1000)
  - DWM termination (Event 9009)
  - session disconnect (Event 40)
- 07:xx-09:xx - Triage and hypothesis elimination performed; root cause narrowed to image-introduced display driver regression.
- 09:xx - Corrective resolution executed (driver/image mitigation on impacted pool hosts).
- 10:00 - Service verified restored:
  - users logging in successfully to POOL-FIN-01 hosts
  - no new user issues reported
  - black screen symptom no longer observed

## Root Cause Statement
Primary root cause was an image-introduced Intel display driver regression on POOL-FIN-01 hosts, causing Desktop Window Manager (dwm.exe) to crash in igdumd64.dll during post-login desktop composition.

## Why Other Hypotheses Were Eliminated
- Shell initialization regression (Explorer/AppX): contradicted by explicit DWM crash telemetry in graphics module.
- FSLogix/profile load delay: contradicted by immediate crash-disconnect sequence after successful logon.
- AVD agent mismatch: no direct agent fault evidence in reviewed event set; considered secondary/neutral.
- Logon script/GPO delay: contradicted by process crash signatures and DWM termination events.

## 5 Whys Analysis
1. Why did users see black screens after login?
- Because desktop composition failed during session startup, and some sessions disconnected/retried.

2. Why did desktop composition fail?
- Because dwm.exe crashed repeatedly with access violation (0xc0000005).

3. Why did dwm.exe crash?
- Because the faulting module was igdumd64.dll (Intel graphics user-mode driver), indicating a graphics driver instability/regression.

4. Why was the unstable driver active only in impacted sessions?
- Because POOL-FIN-01 received an overnight image update that introduced the changed graphics stack, while POOL-FIN-02 remained on prior baseline.

5. Why was this not prevented before production impact?
- Pre-deployment validation did not include enough AVD-specific graphics/compositor stress checks and canary soak coverage to detect this failure mode.

## Resolution Implemented
- Containment:
  - Prevented additional impact while remediation proceeded on POOL-FIN-01.
- Remediation:
  - Applied the approved display driver/image corrective action from triage (rollback/hotfix to known-good graphics path).
- Validation:
  - Confirmed successful user logons on POOL-FIN-01.
  - Confirmed no continuing black-screen reports after fix.
  - Verified incident resolved at 10:00.

## Preventive and Corrective Actions

### Immediate Preventive Controls
- Enforce staged canary rollout for pool image updates before full pool adoption.
- Add deployment gate to compare crash telemetry for:
  - Application Error Event 1000 (dwm.exe)
  - DWM Event 9009/9011
- Block production promotion if crash signatures appear in canary window.

### Engineering Hardening
- Lock/approve graphics driver versions in golden image pipeline.
- Disable automatic unreviewed graphics driver drift in session host update path.
- Maintain known-good driver matrix per host pool and workload profile.

### Validation Improvements
- Add synthetic logon tests with repeated connect/reconnect cycles on canary hosts.
- Include Teams/graphics workload smoke tests in image acceptance.
- Expand soak test duration to include first business-hour logon surge.

### Monitoring and Alerting
- Add alerts for sudden rise in:
  - LSM Event 40 disconnects after Event 21 logon
  - Application Error Event 1000 with dwm.exe
  - DWM Event 9009 spikes
- Create dashboard panel split by host pool to quickly spot control-vs-treatment divergence.

### Process and Governance
- Require explicit rollback plan attached to each image rollout change record.
- Require sign-off that unaffected control pool remains available for rapid traffic shift.
- Run post-change review checklist at +30 min, +60 min, and start-of-business.

## Evidence-to-Conclusion Mapping
- Event 1000 (dwm.exe -> igdumd64.dll) repeated on affected host establishes graphics module failure.
- Event 9009 confirms DWM process exits aligned with user symptom window.
- Event 21 success followed by Event 40 disconnect ties crash to post-login phase.
- Event 9011 success and absence of Event 1000 on unaffected pool host validates change isolation.

## Final Outcome
- Incident resolved by 10:00.
- Verified users can log in to POOL-FIN-01 without black-screen symptom.
- No further issues reported after remediation within validation window.
