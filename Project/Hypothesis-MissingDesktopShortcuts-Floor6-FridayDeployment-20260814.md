# Hypothesis - Missing Desktop Shortcuts (Floor 6) - Friday Deployment Assessment

## Scenario anchor
- Conclusion: Missing desktop shortcuts were reported Monday after a Friday floor-specific app rollout in a recent Win11/Intune migration context.
- Reasoning: The timeline supports a configuration-side effect hypothesis, but file-path evidence is required to separate relocation from deletion.

## Ranked likely causes (most to least likely)
1. Conclusion: Profile redirection/Known Folder Move state changed, and shortcuts were relocated rather than removed.
   Reasoning: This is a common post-migration outcome and often appears to users as "vanished" icons.

2. Conclusion: Friday app deployment added cleanup/remove-shortcut logic (or replaced old links) affecting user/Public Desktop.
   Reasoning: Packaging scripts frequently manage shortcuts and can unintentionally remove expected links.

3. Conclusion: Intune baseline/remediation policy enforced desktop layout standardization that hid or removed shortcuts.
   Reasoning: Policy-driven state control can alter desktop artifacts across cohorts.

4. Conclusion: One-off user profile corruption or shell cache issue is causing display mismatch.
   Reasoning: Isolated cache/profile faults can mimic deletion but usually have narrower scope.

## Fastest check for each cause
1. Check: On affected device, inspect user Desktop, OneDrive Desktop, and Public Desktop paths for missing links.
   Why fast: Immediately distinguishes relocation from true deletion.

2. Check: Review Friday package install/uninstall scripts and shortcut actions in deployment logs.
   Why fast: Directly validates whether rollout touched shortcut files.

3. Check: Compare Intune policy/script results between one affected and one unaffected Floor 6 device.
   Why fast: Differential comparison quickly highlights policy-caused behavior.

4. Check: Rebuild icon cache/sign out-in and validate profile health indicators.
   Why fast: Rapidly eliminates shell presentation artifacts.

## Evidence that confirms Friday deployment as cause
- Conclusion: Deployment is likely causal if shortcut loss aligns with package actions and affected scope matches assignment scope.
- Reasoning: Matching scope, timing, and file-action logs form a strong causal chain.
- Confirming evidence examples (to confirm):
  - Deployment logs show explicit remove/replace shortcut commands on impacted paths.
  - Issue appears only on devices that received the Friday package variant.
  - Test rollback or package fix restores expected shortcuts.

## Evidence that rules out Friday deployment as cause
- Conclusion: Deployment is likely non-causal if shortcuts are merely relocated by profile/KFM behavior or if issue occurs where package was not assigned.
- Reasoning: A non-deployment mechanism breaks the rollout-causation chain.
- Rule-out evidence examples (to confirm):
  - Shortcuts exist intact in redirected desktop path.
  - Devices without Friday package show identical symptom.
  - Package scripts contain no shortcut modification logic.
