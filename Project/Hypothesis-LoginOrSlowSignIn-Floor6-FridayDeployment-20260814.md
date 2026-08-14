# Hypothesis - Login Or Slow Sign-In (Floor 6) - Friday Deployment Assessment

## Scenario anchor
- Conclusion: A new app was deployed Friday afternoon to Floor 6 and login/slowness issues were reported Monday morning.
- Reasoning: The close timing makes deployment-related impact plausible, but timing alone cannot prove causation.

## Ranked likely causes (most to least likely)
1. Conclusion: App deployment created sign-in-time install/retry load (required install, detection loop, or dependency wait) on many endpoints.
   Reasoning: This best fits many users seeing very slow login, with some perceiving failure when delay exceeds expectation.

2. Conclusion: Deployment introduced a dependency conflict at sign-in (identity plug-in, network provider, profile hook, or security agent interaction).
   Reasoning: A floor-scoped app change can trigger broad endpoint behavior if it touches auth/session initialization paths.

3. Conclusion: Deployment is only a trigger and the primary blocker is conditional access/compliance drift after Win11/Intune migration.
   Reasoning: Migration-era posture changes can surface at first heavy Monday logon, coinciding with but not caused by the app.

4. Conclusion: Deployment is unrelated; a separate identity or network event occurred in the same window.
   Reasoning: Correlation by time can be coincidental, so control-group comparison is required.

## Fastest check for each cause
1. Check: In Intune, compare Friday app install state and retry/failure counts between affected and unaffected Floor 6 devices.
   Why fast: Correlation can be established in minutes from deployment telemetry.

2. Check: On 2 to 3 affected devices, review event timeline around logon for app install activity, service start delays, and shell initialization.
   Why fast: A focused sample quickly shows whether the app is in the critical path.

3. Check: Review Entra sign-in + conditional access outcomes for impacted users in the same time window.
   Why fast: Distinguishes true auth blocking from endpoint-side delay.

4. Check: Compare non-Floor 6 users with similar policy posture but without Friday app assignment.
   Why fast: Provides a control to test whether incident is deployment-scoped.

## Evidence that confirms Friday deployment as cause
- Conclusion: Deployment is likely causal if affected users/devices strongly overlap with the Friday assignment and issue onset follows install attempts.
- Reasoning: High overlap + temporal sequence + endpoint logs showing app activity in logon path is a causal pattern.
- Confirming evidence examples (to confirm):
  - Affected devices show install/retry loops or long install durations at sign-in.
  - Unaffected devices either did not receive the app yet or completed install cleanly earlier.
  - Incident severity drops after pausing assignment, excluding ring, or fixing package detection logic.

## Evidence that rules out Friday deployment as cause
- Conclusion: Deployment is likely non-causal if affected and unaffected populations show no meaningful difference in app assignment/install state.
- Reasoning: Lack of differential signal weakens deployment hypothesis.
- Rule-out evidence examples (to confirm):
  - Same login failures appear on users/devices not targeted by the app.
  - Entra/CA failures explain inability to sign in regardless of endpoint deployment status.
  - App install telemetry is healthy and not active during impacted logon windows.
