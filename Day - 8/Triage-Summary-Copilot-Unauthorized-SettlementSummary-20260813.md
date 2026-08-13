# Incident Triage Summary - Copilot Surfaced Draft Settlement From Unassigned Matter

## Incident Details
- Date: 2026-08-13
- Reporter Role: Partner
- Service: Microsoft 365 Copilot (cross-content grounding)
- Symptom: Copilot surfaced and summarized draft settlement from a matter user is not assigned to.
- Security Concern: User states they were unaware of access to that folder.

## Impact Assessment
- Scope: Potentially multi-user depending on permission model.
- Business Impact: High due to confidentiality concerns.
- Data Risk: High. Possible over-permission exposure, even if technically authorized.
- Priority: P1 (potential information governance incident).

## Likely Cause (Initial Hypothesis)
- Most likely over-permissioned SharePoint/Teams site or inherited ACL granting broader access than intended.
- Possible stale membership in security group not aligned with matter staffing.
- Less likely Copilot issue; Copilot typically reflects existing user permissions.

## Triage Checks
1. Capture exact source document URL and location surfaced by Copilot.
2. Verify user can manually open source file outside Copilot.
3. Audit effective permissions on site, library, folder, and file.
4. Review group memberships (AAD/M365/SharePoint groups) for unintended inclusion.
5. Check recent permission changes and inheritance breaks.
6. Notify Information Security and Legal IT governance for incident oversight.

## Immediate Actions Taken
- Raised as potential data exposure incident.
- Requested preservation of evidence (prompt text, output snippet, timestamp, source link).
- Initiated urgent access review with site owner and security governance.

## Next Actions
- Remove unintended access immediately if confirmed.
- Validate whether any additional users have same overexposure path.
- Perform retrospective permission hygiene across matter workspaces.
- Document incident outcome and required control improvements.

## Owner and ETA
- Primary Owner: Information Security + Legal IT Governance
- Supporting Owner: Service Desk M365 queue
- Next Update Due: Within 1 hour
- Target Containment: Immediate upon confirmation of over-permission

## User-Facing Status
- Current status: Security triage in progress with high priority containment checks.
- Workaround: Do not redistribute surfaced content; report any additional unexpected document visibility immediately.