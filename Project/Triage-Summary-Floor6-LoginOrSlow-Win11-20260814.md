# Triage Summary - Floor 6 Login Failures / Very Slow Sign-In (Win11)

## summary (one line)
- Conclusion: Multiple Legal users on Floor 6 are unable to log in or are experiencing very slow logins Monday morning after recent Win11/Intune migration and a Friday app rollout.
- Reasoning: This statement comes directly from the 09:14 IT Ops report describing at least a dozen users with login failure or severe delay symptoms.

## Impact (who/how many/ business urgency)
- Who: Legal team users on Floor 6.
- How many: At least a dozen affected users reported; total Floor 6 estate is 45 devices.
- Business urgency: High, because login/access delay blocks legal work at start of business day and affects multiple users simultaneously.

## Know facts
- Time/source: 09:14 Slack message from IT Ops lead.
- "At least a dozen people can't log in or it's taking forever."
- Floor 6 hosts Legal team with 45 devices (provided context).
- Devices on Floor 6 were recently migrated to Win11 and enrolled in Intune (provided context).
- A new document management app was rolled out to Floor 6 on Friday afternoon.

### Win11/Intune migration hypotheses (to confirm)
- Hypothesis 1: Friday document management app deployment is causing heavy sign-in-time installs/retries on managed Win11 devices, leading to long logons and some apparent login failures.
- Hypothesis 2: New or updated Intune compliance/conditional access posture after migration is intermittently blocking or delaying authentication token issuance.
- Hypothesis 3: Post-migration policy baseline (security, network, or profile policies) is increasing logon processing time or causing profile load contention.

## Missing Information to gather
- Exact failure mode split: "cannot log in" vs "logs in but takes forever" (to confirm).
- Affected scope by user/device list, including exact count and pattern by team/desk area (to confirm).
- First-seen time and whether issue started before or after Monday sign-in rush (to confirm).
- Whether affected users are on-network, VPN, docked, or Wi-Fi only (to confirm).
- Entra ID/Azure AD sign-in status and conditional access outcomes for impacted users (to confirm).
- Intune device compliance and recent policy/app deployment status for impacted devices (to confirm).
- Whether the new document management app install is still running, failed, or retry-looping at sign-in (to confirm).
- Event logs around logon profile load, authentication, network provider, and Group Policy processing (to confirm).

## Likely catagory
- Conclusion: Major Incident - Endpoint Access/Performance degradation (Win11 + identity/policy/app deployment interaction), to confirm.
- Reasoning: At least a dozen users are impacted at business start, the issue affects core access, and the symptoms began in the same period as recent Win11/Intune transition plus a Friday floor-wide app change.

## suggest first diagnostic step
- Conclusion: Pull a rapid impact matrix now by listing affected users/devices and correlating Intune deployment status of the Friday app with Entra sign-in logs for the same users and time window.
- Reasoning: This is the fastest way to separate authentication failure from endpoint deployment-induced slowdown and validate the highest-probability shared-change hypothesis without assuming root cause.

## What I'd check first and why (urgency order)
1. Confirm or refute active unauthorized data exposure case from the related Copilot report (cross-incident safety gate) because potential confidentiality risk outranks availability.
2. Validate current blast radius for login/slowness (who cannot work right now) to prioritize user restoration and executive comms.
3. Correlate impacted devices/users with Friday app rollout assignment and install state to identify common denominator quickly.
4. Check Entra sign-in failures/conditional access outcomes for affected users to separate auth problems from endpoint slowness.
5. Sample 2-3 impacted endpoints for logon duration breakdown and event evidence to confirm root direction before broad remediation.
