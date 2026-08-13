# Incident Triage Summary - Copilot Access Denied on SharePoint NDA

## Incident Details
- Date: 2026-08-13
- Reporter Role: Paralegal
- Service: Microsoft 365 Copilot (SharePoint grounding)
- Symptom: Copilot returns "I don't have access to that content" when asked to summarize a client NDA.
- User Context: File is in a SharePoint folder the user has not opened previously.

## Impact Assessment
- Scope: Single user currently reported.
- Business Impact: Medium. NDA review work is blocked/delayed for case preparation.
- Data Risk: Low. Behavior indicates access enforcement is working as designed.
- Priority: P3 (single-user productivity impact, no security breach).

## Likely Cause (Initial Hypothesis)
- Most likely permissions gap: user does not have effective access to the target file/folder.
- Secondary possibility: access granted recently but indexing or token refresh has not completed.
- Tertiary possibility: user prompt references a document by name without selecting/opening the actual source.

## Triage Checks
1. Confirm exact SharePoint site, library, folder, and file path.
2. Verify user access using SharePoint "Manage Access" and effective permissions.
3. Confirm the user can open the file directly in SharePoint browser.
4. Validate if access was recently granted (last 24 hours) and check propagation delay.
5. Ask user to open the file once, then retry Copilot prompt from file context.
6. Check for sensitivity label or policy restrictions that could block Copilot grounding.

## Immediate Actions Taken
- Logged as access-related Copilot grounding issue.
- Requested evidence: screenshot of error, file URL, and UTC timestamp.
- Routed to SharePoint site owner for permission confirmation.

## Next Actions
- If no access: request least-privilege read access through site owner approval flow.
- If access exists but Copilot still fails: collect M365 Copilot session ID and escalate to M365 support queue.
- Re-test after permission confirmation and user re-authentication.

## Owner and ETA
- Primary Owner: Service Desk (M365 queue)
- Dependency Owner: SharePoint Site Owner
- Next Update Due: Within 2 business hours
- Target Resolution: Same business day if permission change is straightforward

## User-Facing Status
- Current status: Investigating access path and permission inheritance.
- Workaround: Open the NDA directly in SharePoint and confirm read access before re-running Copilot summary request.