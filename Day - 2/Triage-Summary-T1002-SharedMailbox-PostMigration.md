# Structured Triage Summary

**Ticket:** T-1002

## Summary (one line)
Finance user cannot open a shared mailbox following a migration event, preventing access to team email.

## Impact (who / how many / business urgency)
- Who: Single Finance user (to verify — confirm name, role, and team)
- How many: One reported user; unknown whether other Finance staff are affected (to verify)
- Business urgency: High — Finance teams typically have time-sensitive email dependencies; shared mailbox access loss may affect business operations

## Known Facts
- User is in the Finance department (to verify exact team)
- User cannot open a shared mailbox
- Issue follows a migration event (mailbox migration, tenant migration, or platform change — to verify which)
- Specific error message or failure behaviour not yet captured

## Missing Information to Gather
- User identity, contact details, and exact role
- Name/address of the shared mailbox they cannot access
- Type of migration performed (mailbox move, tenant-to-tenant, Exchange Online migration — to verify)
- Exact failure behaviour: error message, blank screen, permission denied, or mailbox not visible (to verify)
- Whether the user could access the shared mailbox before migration
- Whether other users in Finance can access the same shared mailbox (to verify)
- Whether the user's own primary mailbox is working normally
- Client being used: Outlook desktop, Outlook Web App, or mobile (to verify)
- Whether a profile rebuild or cache clear has been attempted
- Whether permissions were re-applied to the shared mailbox post-migration (to verify with mail platform team)

## Likely Category
- Likely category: Email and collaboration / shared mailbox permissions post-migration
- Sub-category: Exchange Online / Outlook permissions (to verify)
- Incident vs. Service Request: Treat as incident if multiple users affected; may be service request if isolated permission issue

## Suggested First Diagnostic Step
Confirm the user's own mailbox is functional in Outlook Web App (OWA) to isolate client vs. mailbox issue, then check whether the shared mailbox appears in OWA under "Open another mailbox" — if it opens in OWA but not Outlook desktop, the issue is likely a stale Outlook profile or cached permissions. If it fails in OWA too, escalate to the mail platform team to verify delegated permissions were migrated correctly.
