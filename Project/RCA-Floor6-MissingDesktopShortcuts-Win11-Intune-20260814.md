# RCA - Floor 6 Missing Desktop Shortcuts (Win11 + Intune)

## Incident summary
- Conclusion: Floor 6 users reported missing desktop shortcuts on Monday morning.
- Reasoning: Report originated in the same incident window as other post-migration disruption signals.

## Business impact
- Conclusion: Impact is moderate to high depending on scope and whether access paths to legal tools were disrupted.
- Reasoning: Missing shortcuts can reduce productivity quickly, especially when tied to daily workflow applications.

## Timeline (known)
- Friday afternoon: New document management app rollout to Floor 6 (known).
- Monday 09:14: Missing shortcuts report captured by IT Ops (known).
- Follow-up triage: Profile/path/policy checks prioritized as first diagnostic path (known from Project notes).

## Root cause
- Conclusion: Most likely root cause is profile redirection or Known Folder Move path change making shortcuts appear missing rather than deleted, to confirm.
- Reasoning: This is a common post-migration behavior and best matches the symptom description without requiring file deletion assumptions.

## Contributing factors
- Intune policy or remediation script may have modified desktop layout/links (to confirm).
- Friday app package logic may have removed/replaced legacy shortcuts (to confirm).

## Evidence supporting root cause
- Existing hypothesis ranking favors relocation/path behavior as most likely mechanism.
- Triage strategy emphasized Desktop/Public Desktop/OneDrive path verification before restore actions.
- Incident context includes recent migration where profile redirection changes are common.

## Evidence still required to confirm
- File-path proof that shortcuts exist in redirected location(s) on affected devices (to confirm).
- Policy/script execution records showing path/layout changes near incident window (to confirm).
- Comparison of affected vs unaffected Floor 6 device state for shortcut handling (to confirm).

## Evidence that would rule it out
- Verified deletion/removal events from app package or script actions.
- Missing links across devices where no profile redirection/KFM change occurred.
- Reproduction showing no path relocation while shortcuts are absent.

## Immediate remediation taken / recommended
- Validate whether shortcuts are relocated vs removed before recreating links.
- Review Friday package actions and Intune policy/script deltas.
- Restore user productivity with minimal-risk shortcut rehydration only after mechanism is confirmed.

## Preventive actions
- Add pre/post migration checks for desktop path continuity and user-link preservation.
- Require package QA to validate shortcut behavior on Win11 + Intune managed endpoints.
- Document a standardized shortcut-restoration and rollback procedure.

## Current status
- Conclusion: Likely mechanism identified; final RCA pending endpoint path and policy evidence confirmation.
- Reasoning: Present evidence supports a high-confidence direction but remains inferential until device-level proof is captured.
