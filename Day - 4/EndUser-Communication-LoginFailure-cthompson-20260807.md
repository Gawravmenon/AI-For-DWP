# End-User Communication Pack - Login Incident (cthompson)

## Shared Facts (Source of Truth)
- A single user, cthompson, could not sign in during the morning incident window.
- The issue started around 08:44 and was caused by repeated incorrect password attempts that triggered an account lock.
- Attempts came from DESKTOP-FB022 and a second source at 10.10.8.112.
- Helpdesk performed account recovery actions at 09:08:14.
- Successful interactive sign-in was verified at 09:09:01 from DESKTOP-FB022.
- Incident was confirmed resolved at 09:09, with no further issues reported by the user.

## Audience 1 - Non-technical executive
Your access and data are safe. This morning, one user (cthompson) could not sign in after repeated wrong password attempts locked the account, with attempts seen from the user PC and one other network source. Support completed account recovery at 09:08:14, and successful sign-in was confirmed at 09:09:01. The incident was resolved at 09:09 with no further issues reported. No action is required from you.

## Audience 2 - Affected end-user team (10 people, non-technical)
Hi team, one colleague (cthompson) could not sign in this morning because repeated wrong password attempts locked the account, with attempts seen from the user PC and one other network source. Support completed account recovery at 09:08:14, successful sign-in was confirmed at 09:09:01 from the same PC, and the issue was resolved at 09:09 with no further problems reported. If you see the same sign-in issue, contact the Service Desk immediately and report your device name and time of failure.

## Audience 3 - Engineer-to-engineer internal note
Incident scope:
- Single-user impact: FINBRIDGE\\cthompson unable to log in.
- Start: ~08:44.
- Resolved: 09:09.

Root cause:
- Account lockout due to repeated bad-password submissions.
- Contributing condition: continued bad-credential replay from secondary source.

Config/environment detail:
- Primary endpoint: DESKTOP-FB022 (10.10.1.88).
- Secondary auth source observed: 10.10.8.112.
- Key security telemetry in incident window:
  - 4776 @ 08:44:01, 0xC000006A (wrong password), source workstation DESKTOP-FB022.
  - 4625 @ 08:44:03 / 08:44:28 / 08:44:55, bad password, Logon Type 2, source DESKTOP-FB022.
  - 4740 @ 08:44:56, account locked out, caller DESKTOP-FB022.
  - 4625 @ 08:45:10, account locked out, Logon Type 7, source DESKTOP-FB022.
  - 4771 @ 08:45:44 / 08:46:01 / 08:46:33, 0x18 (wrong password), source IP 10.10.8.112.

Exact action taken:
- Investigated failure and lockout sequence in Security log.
- Performed account recovery actions (enable/unlock workflow by FINBRIDGE\\helpdesk-admin at 09:08:14).
- Applied credential replay remediation steps so stale credentials stopped re-submitting.

Verification step:
- 4722 @ 09:08:14: account enabled by FINBRIDGE\\helpdesk-admin.
- 4624 @ 09:09:01: successful interactive logon (Type 2) for FINBRIDGE\\cthompson from DESKTOP-FB022.
- User confirmed no further issue at 09:09.

Preventive action required:
- Identify owning asset/process behind 10.10.8.112 and remove/update stale stored credentials (tasks, services, mapped drives, app profiles, scripts).
- Add monitoring for repeated 4771/4776 bursts per user to trigger early intervention before lockout.
- Reuse lockout runbook order: stop replay source -> reset/update credentials -> unlock/enable -> verify clean 4624 success without new 4625/4771/4776.
