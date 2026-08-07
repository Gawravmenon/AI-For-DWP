s# End-User Communication Pack - AVD Black Screen Incident (2026-08-07)

## Audience 1 - Non-technical executive
Your access and data are safe. This morning around 07:00, about 40% of users in FIN-01 saw a black screen after sign-in because an overnight 02:00 FIN-01 update introduced a display component fault; FIN-02 was unaffected. We rolled FIN-01 back to the last known-good display baseline and validated recovery at 10:00, with successful logins and no new reports. No action is required unless you still see the issue.

## Audience 2 - Affected end-user team (10 people, non-technical)
Your access and data are safe. Around 07:00 today, about 40% of users in FIN-01 saw a black screen after sign-in because a display part in the 02:00 overnight FIN-01 update failed, while FIN-02 stayed unaffected. We returned FIN-01 to the last known-good display setup and confirmed at 10:00 that logins worked with no new issues reported. If you see the same issue again, sign out, sign back in once, and contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note
Access and data integrity remained intact throughout the incident. At ~07:00, ~40% of users on POOL-FIN-01 hit post-login black screen; POOL-FIN-02 remained unaffected. Change correlation: POOL-FIN-01 received overnight image update at 02:00, POOL-FIN-02 did not.

Root cause:
- Image-introduced Intel display stack regression on POOL-FIN-01 causing desktop compositor failure.
- Evidence pattern on affected host(s): LSM Event 21 logon success, then Application Error Event 1000 (dwm.exe faulting in igdumd64.dll v31.0.101.4146, exception 0xc0000005), DWM Event 9009 exits, then LSM Event 40 disconnects.
- Control comparison: unaffected POOL-FIN-02 host showed DWM Event 9011 startup success and no matching Event 1000 in incident window.

Exact action taken:
- Applied approved corrective action to restore FIN-01 to known-good display baseline (driver/image rollback-hotfix path), then recycled/restarted impacted hosts as part of remediation flow.

Config detail:
- Faulting module observed: igdumd64.dll v31.0.101.4146 on affected updated hosts.
- Faulting process: dwm.exe 10.0.22621.2861.

Verification:
- Resolution confirmed at 10:00.
- Verified users successfully logging into POOL-FIN-01 hosts.
- No new black-screen reports after remediation in validation window.

Required preventive action:
- Enforce canary rollout and crash-gate checks before broad image promotion.
- Pin/approve graphics driver versions in the golden image pipeline and block unreviewed drift.
- Add automated alerting for Event 1000 (dwm.exe + igdumd64.dll) and DWM 9009 spikes post-change.
