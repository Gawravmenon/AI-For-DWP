# RCA - Floor 6 Login Failures / Slow Sign-In (Win11 + Intune)

## Incident summary
- Conclusion: Floor 6 experienced widespread login failures and severe sign-in delay on Monday morning.
- Reasoning: IT Ops reported at least a dozen affected users out of a 45-device floor.

## Business impact
- Conclusion: Legal productivity was materially disrupted at business start.
- Reasoning: Affected users could not begin work normally because sign-in is a gating function.

## Timeline (known)
- Friday afternoon: New document management app rollout to Floor 6 (known).
- Monday 09:14: IT Ops reported floor-wide login/slow sign-in issues (known).
- Post-report: Correlation analysis and triage initiated (known from Project notes).

## Root cause
- Conclusion: Most likely root cause is sign-in-time install/retry load tied to Friday app deployment on recently migrated Win11/Intune-managed devices, to confirm.
- Reasoning: The strongest signal is timing + scope alignment: floor-targeted app change followed by floor-concentrated startup login slowness/failure pattern.

## Contributing factors
- Recent Win11 migration and Intune enrollment likely increased sensitivity to deployment timing and policy/app interactions (to confirm).
- Monday morning concurrency likely amplified user-visible delay if installs/retries executed at sign-in (to confirm).

## Evidence supporting root cause
- Deployment was floor-specific and occurred immediately before incident window.
- Hypothesis ranking in Project notes places deployment install/retry behavior as top likelihood.
- Triage path prioritized Intune install-state and Entra correlation as fastest discriminator.

## Evidence still required to confirm
- Per-device install/retry/failure telemetry overlap between affected and unaffected users (to confirm).
- Endpoint event traces showing app activity in the critical sign-in path (to confirm).
- Improvement after assignment pause/ring exclusion/package detection correction (to confirm).

## Evidence that would rule it out
- Similar failures on users/devices not assigned the Friday app.
- Healthy install telemetry with no retry/load during impacted sign-in windows.
- Independent Entra/Conditional Access failure pattern fully explaining access issues.

## Immediate remediation taken / recommended
- Prioritize users fully blocked from sign-in first.
- Validate assignment overlap and retry/failure loops in Intune.
- Isolate or pause problematic deployment scope while evidence is collected.
- Preserve event evidence before broad environment changes.

## Preventive actions
- Stage future legal-floor app rollouts in phased rings with Monday-morning guardrails.
- Add deployment health gates for retry-loop and sign-in-performance regressions.
- Require post-deployment validation on a representative Win11/Intune subset before full floor rollout.

## Current status
- Conclusion: Probable cause identified; final confirmation pending telemetry correlation and controlled-change validation.
- Reasoning: Current evidence supports a high-confidence hypothesis but does not yet meet full causal proof criteria.
