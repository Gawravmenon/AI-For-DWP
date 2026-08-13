# Incident Triage Summary - Legal Team Lost Copilot Access (40 Users)

## Incident Details
- Date: 2026-08-13
- Reporter Role: Legal operations manager
- Service: Microsoft 365 Copilot
- Symptom: Entire Legal team (approx. 40 users) lost Copilot access this morning; service was working last week.

## Impact Assessment
- Scope: Department-wide outage (Legal team).
- Business Impact: High. Significant interruption to legal drafting, review, and email summarization workflows.
- Data Risk: Low direct data exposure risk; availability incident.
- Priority: P1 (multi-user critical business impact).

## Likely Cause (Initial Hypothesis)
- Bulk license unassignment or group-based licensing policy change.
- Tenant-level service plan toggle, expired subscription, or billing/suspension event.
- Conditional Access or network/security policy update blocking Copilot endpoints.
- Incident in M365 service health affecting Copilot features.

## Triage Checks
1. Confirm issue reproducibility across multiple affected users.
2. Verify Copilot license assignment state for impacted user set.
3. Validate group-based licensing rules and recent changes.
4. Review M365 Service Health for Copilot-related advisories/incidents.
5. Check Conditional Access and proxy/firewall changes since last known good state.
6. Review admin audit logs for licensing, policy, or role changes in past 24 hours.

## Immediate Actions Taken
- Declared major incident for Legal team Copilot outage.
- Started impact list capture and named representative user tests.
- Engaged M365 admin and identity teams for parallel checks.

## Next Actions
- Restore missing licenses or service plans if removed.
- Roll back blocking policy changes if validated as root cause.
- If tenant service incident confirmed, communicate vendor advisory and ETA.
- Provide hourly stakeholder updates until restoration complete.

## Owner and ETA
- Primary Owner: Service Desk Major Incident Manager
- Dependency Owners: M365 Admin, Identity/Access Team, Network Security
- Next Update Due: Within 60 minutes
- Target Restoration: Earliest possible upon root-cause confirmation

## User-Facing Status
- Current status: Active major incident investigation with cross-team engagement.
- Workaround: Use standard M365 workflows without Copilot until service restored.