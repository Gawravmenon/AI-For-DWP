# Version Header
- Document: L2-Technical-MissingDesktopShortcuts-Floor6
- Version: 1.0
- Last Updated: 2026-08-14
- Source: Runbook-Floor6-IncidentResponse-Win11-Intune-v1.0

## Objective
Determine whether missing shortcuts are relocation, policy effect, or package-driven deletion.

## Prerequisites
- Access to affected endpoint with support rights.
- Access to OneDrive KFM status and Intune script deployment results.
- Friday package script/version history.

## Procedure
1. Validate file presence in Desktop paths:
- User Desktop
- OneDrive Desktop
- Public Desktop
Expected result: relocation vs deletion is established.

2. Inspect Friday package install/uninstall scripts for shortcut actions.
Expected result: confirm or refute package mutation of links.

3. Compare policy/script results between affected and unaffected devices.
Expected result: differential policy signal identified.

4. Restore shortcuts only after mechanism confirmation.
Expected result: restored productivity without masking root cause.

## Verification
- Shortcuts persist through sign-out and sign-in.
- No recurrence on next policy sync.

## Rollback
- Revert offending package/script change.
- Reapply known-good shortcut baseline.

Expected result: stable shortcut state across user sessions.
