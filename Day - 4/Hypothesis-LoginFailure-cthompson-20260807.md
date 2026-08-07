# Login Failure Hypothesis - cthompson (2026-08-07)

## Scope Facts Used
- Symptom: cthompson unable to log in.
- Impact: single user only.
- Start time: approximately 08:40 this morning.
- Known change: none reported.

## Ranked Most-Likely Causes (Most Probable First)

### 1) Account lockout due to bad password retries (user/device/mobile app)
Why this fits scope facts:
- Single-user impact strongly matches a user-specific lockout condition.
- Sudden onset at a specific time is consistent with a lockout threshold being reached.
- No formal change is needed for this to occur.

Fastest single check:
- In AD/Azure AD account view, check whether cthompson is currently locked out (or review latest lockout event around 08:40).

### 2) Password expired or recently changed, but cached/stored credentials are stale on one endpoint
Why this fits scope facts:
- Single-user symptom aligns with credential mismatch isolated to one identity/session.
- Time-specific failure can start when expiry boundary is hit or when old cached creds keep replaying.
- No infrastructure change is required.

Fastest single check:
- Attempt web sign-in for cthompson via M365/Entra portal from a clean browser session; success there but failure on device indicates endpoint cached-credential issue.

### 3) Conditional Access or MFA challenge failure for this user (authenticator drift, denied prompt, device compliance state)
Why this fits scope facts:
- One-user-only issue fits per-user CA/MFA state problems.
- Abrupt start time can happen when a policy condition is newly evaluated (new location/risk/session renewal) without a reported platform change.

Fastest single check:
- Review Entra sign-in logs for cthompson at ~08:40 and read the explicit failure reason (CA block, MFA denied/failed, non-compliant device).

### 4) User account disabled/restricted or sign-in blocked at identity layer
Why this fits scope facts:
- Isolated user impact is consistent with an account state flag affecting only cthompson.
- Can begin suddenly if an automated process or admin action set a block, even when the user reports "no change".

Fastest single check:
- Open cthompson account properties and verify enabled/sign-in-allowed status and any restriction flags.

### 5) Local profile/Windows credential provider corruption on one device (not identity platform-wide)
Why this fits scope facts:
- Single user and no broader outage suggest an endpoint-local sign-in path issue.
- Start time can coincide with reboot/update side effects without explicit user-reported change.

Fastest single check:
- Try cthompson sign-in on a known-good alternate device/VDI host; if successful there, original endpoint profile/provider path is the likely fault domain.

## Notes
- This is a hypothesis list only, ranked by fit to the provided scope facts.
- No single root cause is being committed at this stage.

## Evidence Assessment Against Incident Window Logs (2024-03-15 08:44-09:12)

### Hypothesis 1) Account lockout due to bad password retries (user/device/mobile app)
Judgement: Supported

Why:
- Repeated bad-password failures are recorded first, then a lockout is explicitly logged.
- 08:44:01, Event 4776: credential validation failed with `0xC000006A` (wrong password).
- 08:44:03 / 08:44:28 / 08:44:55, Event 4625: bad password failures (interactive logon type 2).
- 08:44:56, Event 4740: account locked out for `FINBRIDGE\cthompson` from `DESKTOP-FB022`.
- 08:45:10, Event 4625: failure reason switches to `Account locked out` (logon type 7 unlock).

### Hypothesis 2) Password expired or recently changed, but cached/stored credentials are stale on one endpoint
Judgement: Supported (partial)

Why:
- Wrong-password events are consistent with stale/incorrect stored credentials being replayed.
- 08:44:01, Event 4776: wrong password (`0xC000006A`) from `DESKTOP-FB022`.
- 08:45:44 / 08:46:01 / 08:46:33, Event 4771: Kerberos pre-auth failures `0x18` (wrong password) from `10.10.8.112`.
- Evidence supports "incorrect credentials being submitted repeatedly"; these logs do not directly prove password expiry itself.

### Hypothesis 3) Conditional Access or MFA challenge failure for this user (authenticator drift, denied prompt, device compliance state)
Judgement: Contradicts

Why:
- Available failures are classic AD/Kerberos wrong-password and lockout events, not CA/MFA challenge or policy-block outcomes.
- 08:44:01, Event 4776: wrong password (`0xC000006A`).
- 08:44:56, Event 4740: account lockout.
- 08:45:44 / 08:46:01 / 08:46:33, Event 4771: wrong password (`0x18`).
- No event in the provided set indicates MFA denial, CA block, or device compliance block.

### Hypothesis 4) User account disabled/restricted or sign-in blocked at identity layer
Judgement: Neutral to contradicting

Why:
- The explicit recorded state change is lockout, not disablement/sign-in block.
- 08:44:56, Event 4740 confirms lockout condition.
- 08:45:10, Event 4625 confirms subsequent `Account locked out` failure.
- No provided event indicates account disabled, expired, or administratively blocked status change.

### Hypothesis 5) Local profile/Windows credential provider corruption on one device (not identity platform-wide)
Judgement: Neutral

Why:
- Initial failed attempts come from `DESKTOP-FB022` (supports a local origin possibility).
- 08:44:03 / 08:44:28 / 08:44:55, Event 4625 from `DESKTOP-FB022`.
- However, additional wrong-password Kerberos attempts come from different source IP `10.10.8.112`, so activity is not exclusively tied to a single local interactive path.
- 08:45:44 / 08:46:01 / 08:46:33, Event 4771 from `10.10.8.112`.

## Surviving Hypothesis After Elimination

### Winning hypothesis
Account lockout caused by repeated wrong-password attempts (with likely continued bad credential replay from another source at `10.10.8.112`).

Why this survives:
- It is directly confirmed by lockout and wrong-password events in sequence.
- 08:44:56 Event 4740 confirms lockout.
- 08:44:01 Event 4776 and 08:45:44/08:46:01/08:46:33 Event 4771 confirm repeated wrong password submissions.

## Detailed Resolution Steps

1. Contain further lockouts before unlock
- Temporarily isolate repeated bad-auth source(s):
	- Sign out user from all sessions where possible.
	- If reachable, disconnect network from suspicious source `10.10.8.112` until credential cleanup is complete.
- Rationale: unlocking before stopping replay will relock the account quickly.

2. Identify every bad-credential source
- Use DC/security logs to pivot on account `FINBRIDGE\\cthompson` for Events 4740, 4771, 4776, 4625 in the same time window.
- Build source list: `DESKTOP-FB022` and `10.10.8.112` (plus any additional hosts/services found).

3. Reset credentials safely
- Perform an admin-initiated password reset for cthompson.
- Require a strong temporary password and force change at next sign-in.
- If policy allows, invalidate active sessions/tokens after reset.

4. Unlock account
- Unlock `FINBRIDGE\\cthompson` in AD only after Step 1 and Step 2 controls are in place.
- Confirm account status is Enabled + Unlocked.

5. Clean stale credentials on each source endpoint
- On `DESKTOP-FB022` while logged in as support/admin:
	- Remove saved credentials in Credential Manager (Windows Credentials and Generic Credentials related to domain, O365, VPN, mapped drives, Teams/Outlook if domain-tied).
	- Remove stale mapped drive entries that auto-reconnect with old password.
	- Update any scheduled tasks/services running as cthompson with new password.
	- Lock/unlock or sign out/sign in as cthompson using new password.
- On source `10.10.8.112`:
	- Determine asset owner/type (workstation, server, VDI, app host).
	- Repeat stale-credential cleanup and service/task password update.

6. Validate successful authentication path
- Test interactive sign-in for cthompson on primary endpoint.
- Verify no new 4625/4771/4776 failures for at least 10-15 minutes after login.
- Confirm absence of new 4740 lockout events.

7. If relock occurs, continue deep source hunt
- Check for non-interactive callers still using old password:
	- Mobile mail profile, legacy app passwords, scripts, IIS app pools, Windows services, scheduled jobs, VPN clients, printers/scanners with SMB auth.
- Temporarily disable suspected scheduled task/service identity until credential is updated.

8. Close with preventive hardening
- Document root trigger host/process (for example `10.10.8.112` scheduled task/service).
- Advise user to update password on all enrolled devices.
- Add monitoring alert for repeated 4771/4776 on same user to catch replay early.
