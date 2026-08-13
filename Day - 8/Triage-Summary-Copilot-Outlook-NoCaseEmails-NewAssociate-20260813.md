# Incident Triage Summary - Copilot in Outlook Cannot Find Case Emails

## Incident Details
- Date: 2026-08-13
- Reporter Role: New associate (joined this week)
- Service: Microsoft 365 Copilot in Outlook
- Symptom: Copilot cannot find case emails needed for context.

## Impact Assessment
- Scope: Single new starter currently reported.
- Business Impact: Medium. Onboarding productivity and case ramp-up delayed.
- Data Risk: Low.
- Priority: P3 (single user, business impact contained).

## Likely Cause (Initial Hypothesis)
- Most likely mailbox/search indexing not fully provisioned for new account.
- Potential license or service plan mismatch for Copilot/Exchange features.
- Missing permissions to shared mailboxes or delegated folders where case mail resides.
- Cached client profile not fully synchronized post account creation.

## Triage Checks
1. Verify Copilot license assignment and service plan status in M365 admin.
2. Confirm Exchange Online mailbox is fully provisioned and active.
3. Check if required case emails are in shared mailbox vs primary mailbox.
4. Validate delegate permissions (Full Access/Read) to any relevant shared mailbox/folder.
5. Confirm Outlook is in online mode and search index status is healthy.
6. Test Copilot query against known email subject/sender with a recent sample.

## Immediate Actions Taken
- Logged as new joiner Copilot discovery issue.
- Requested sample email subjects/date range and mailbox location.
- Initiated license and mailbox provisioning verification.

## Next Actions
- Correct any license/service plan gap immediately.
- Apply missing mailbox permissions and allow propagation.
- Rebuild Outlook profile only if licensing and permissions are confirmed correct but issue persists.
- Escalate to Messaging team if search indexing backlog is detected.

## Owner and ETA
- Primary Owner: Service Desk (M365 + Messaging)
- Dependency Owner: Exchange Admin Team
- Next Update Due: Within 2 business hours
- Target Resolution: 1 business day (dependent on permission/index propagation)

## User-Facing Status
- Current status: Validating mailbox permissions, licensing, and search readiness.
- Workaround: Use Outlook search manually with sender/date filters while Copilot indexing and access checks complete.