# Triage Summary - Floor 6 Missing Desktop Shortcuts (Win11)

## summary (one line)
- Conclusion: At least one Floor 6 user reported missing desktop shortcuts on Monday morning, potentially linked to profile/state changes after Win11/Intune migration and recent app rollout.
- Reasoning: The symptom was explicitly reported in the 09:14 IT Ops message and matches common post-migration profile or policy behavior changes.

## Impact (who/how many/ business urgency)
- Who: At least one reported user on Floor 6; broader user impact unknown (to confirm).
- How many: One explicit report in Slack; total affected count to confirm.
- Business urgency: Medium to High, depending on whether this is isolated inconvenience or wider profile/state issue affecting legal productivity.

## Know facts
- Time/source: 09:14 Slack message from IT Ops lead.
- "Someone else says their desktop shortcuts vanished."
- Floor 6 has 45 devices, recently migrated to Win11 and enrolled in Intune (provided context).
- New document management app was rolled out Friday afternoon to that floor.

### Win11/Intune migration hypotheses (to confirm)
- Hypothesis 1: OneDrive Known Folder Move or profile path redirection changed after migration, making shortcuts appear missing due to relocation rather than deletion.
- Hypothesis 2: Intune policy/script baseline or remediation removed/replaced desktop links (user or Public Desktop) as part of standardization.
- Hypothesis 3: Friday app packaging/uninstall actions altered shortcut creation behavior and removed legacy shortcuts.

## Missing Information to gather
- Exact affected user(s), device(s), and whether issue is persistent across re-login/reboot (to confirm).
- Whether shortcuts are missing from user Desktop path, Public Desktop, or only visually hidden (to confirm).
- Whether OneDrive Known Folder Move, profile reset, FSLogix/profile container behavior, or policy changed recently (to confirm).
- Whether Intune scripts/policies altered taskbar/start/desktop layout or removed legacy links (to confirm).
- Whether missing shortcuts are app-specific (especially new document app) or broad across all apps (to confirm).
- Whether files are deleted vs relocated vs blocked by permissions (to confirm).

## Likely catagory
- Conclusion: Endpoint Configuration/Profile Issue - Possible user profile redirection/policy/app packaging side-effect, to confirm.
- Reasoning: The symptom is state/configuration oriented (desktop artifacts) rather than service outage, and it occurred after migration plus managed-policy/app changes that commonly affect profile paths and shortcut behavior.

## suggest first diagnostic step
- Conclusion: Perform a targeted file/path and policy state check on one affected endpoint by verifying Desktop/Public Desktop contents, OneDrive/KFM status, and recent Intune policy/script execution history.
- Reasoning: This quickly distinguishes deletion from relocation or visibility/policy changes and enables the lowest-risk restoration decision.

## What I'd check first and why (urgency order)
1. Confirm this is not part of a larger profile integrity issue tied to login/slowness incident, because shared root cause changes priority and response.
2. Validate whether shortcut files still exist (user Desktop/Public Desktop/OneDrive Desktop) to distinguish loss from relocation.
3. Check recent Intune scripts/policies and Friday app install actions for shortcut creation/removal logic.
4. Compare one unaffected Floor 6 device against one affected device to identify differential policy/app state quickly.
5. Decide restoration method (recreate links vs policy rollback vs packaging fix) only after confirming mechanism.
