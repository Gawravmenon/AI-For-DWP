# Version Header
- Document: L2-Technical-CopilotMatterExposure-Floor6
- Version: 1.0
- Last Updated: 2026-08-14
- Source: Runbook-Floor6-IncidentResponse-Win11-Intune-v1.0

## Objective
Treat reported Copilot matter exposure as a security signal and determine authorization truth.

## Prerequisites
- Security incident bridge active.
- Access to M365/Copilot logs and source system audit logs.
- Access to ACL/group membership history for reported matter.

## Procedure
1. Capture prompt, response, timestamp, user identity, and device identity.
Expected result: minimum forensic dataset preserved.

2. Validate effective ACLs at incident time for reported matter.
Expected result: authoritative authorized or unauthorized determination.

3. Review Friday deployment changes for connectors, scopes, and app permissions.
Expected result: explicit map of whether rollout changed retrievable scope.

4. Reproduce in controlled session with security observer.
Expected result: reproducible path or isolated one-off behavior.

## Verification
- Chain-of-custody documented.
- ACL truth established and peer-reviewed.
- Audit path explains grounding source access.

## Rollback
- Revert connector/scope changes introduced Friday if causal.
- Remove unintended access grants.
- Preserve evidence before configuration rollback.

Expected result: exposure path closed and forensics preserved.
