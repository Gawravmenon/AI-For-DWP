# Version Header
- Document: Runbook-Floor6-IncidentResponse-Win11-Intune
- Version: 1.0
- Last Updated: 2026-08-14
- Owner: DWP Engineering, FinBridge

# Scope
This runbook covers three related Floor 6 scenarios:
1. Login failures or very slow sign-in after Friday app deployment.
2. Potential Copilot unauthorized matter exposure signal.
3. Missing desktop shortcuts after migration/deployment changes.

# Most-Likely Cause Decision
- Conclusion: For the broad Monday disruption, the most-likely primary cause is Friday document app deployment creating sign-in-time install or retry load on Floor 6 devices, to confirm.
- Reasoning: Timing and floor-specific scope align with the largest blast-radius symptom cluster (login delay or failure).

# Immediate Technical Action (Scenario 1 Containment)
Use Microsoft Graph PowerShell to pull affected devices from the Floor 6 deployment ring.

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.Read.All"

$floor6RingGroupId = "TO-CONFIRM-GROUP-ID"
$affectedDeviceNames = @("TO-CONFIRM-DEVICE1","TO-CONFIRM-DEVICE2")

$affectedDeviceIds = foreach ($name in $affectedDeviceNames) {
    (Get-MgDevice -Filter "displayName eq '$name'" -ConsistencyLevel eventual).Id
}

foreach ($deviceId in $affectedDeviceIds) {
    Remove-MgGroupMemberByRef -GroupId $floor6RingGroupId -DirectoryObjectId $deviceId
}
```

Expected result: affected devices are no longer in the assignment group and stop receiving that ring policy/app intent on next sync.

# Plain-Language Floor 6 Message
Floor 6 team, we know this is disrupting your morning and we are actively stabilizing affected devices now. Our current leading cause is Friday's app rollout interacting with recent Windows 11 migration settings, so we are isolating impacted devices first and we will post updates as soon as validation confirms each step.

## Scenario 1: Login Failures or Slow Sign-In
### Prerequisites
- Intune and Entra read/write access for app-assignment groups.
- List of affected devices and users for Floor 6.
- Access to Intune deployment status and Entra sign-in logs.

### Procedure
1. Freeze blast radius.
Expected result: no new devices are added to the affected deployment ring.

2. Pull currently affected devices from the Floor 6 app ring group using the command block above.
Expected result: affected devices are removed from assignment target group membership.

3. Force policy sync on pilot test device and one unaffected control.
Expected result: pilot shows reduction of install-retry pressure; control remains stable.

4. Validate install state and retry counts in Intune for affected set.
Expected result: retry-loop or failed-install pattern is visible if deployment is causal.

5. Validate Entra sign-in outcomes for impacted users in same window.
Expected result: distinction between auth failure and endpoint-side delay is clear.

### Verification
- Group membership confirms affected devices removed.
- Intune app install retries reduce after containment.
- New login attempts on contained devices improve, to confirm.

### Rollback
If containment is incorrect, add devices back to ring:

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.Read.All"
$floor6RingGroupId = "TO-CONFIRM-GROUP-ID"
$restoreDeviceIds = @("TO-CONFIRM-DEVICE-ID-1","TO-CONFIRM-DEVICE-ID-2")
foreach ($deviceId in $restoreDeviceIds) {
    New-MgGroupMemberByRef -GroupId $floor6RingGroupId -BodyParameter @{"@odata.id"="https://graph.microsoft.com/v1.0/devices/$deviceId"}
}
```

Expected result: targeted devices rejoin rollout ring.

## Scenario 2: Potential Copilot Unauthorized Matter Exposure
### Prerequisites
- Security incident channel engaged.
- Access to M365/Copilot and source system audit logs.
- Access to matter ACL and group membership history.

### Procedure
1. Preserve evidence immediately.
Expected result: prompt, response, timestamp, user, and device artifacts are captured.

2. Validate effective permissions for reported matter at incident time.
Expected result: objective pass or fail on authorization state.

3. Compare Friday connector/scope/app permission changes.
Expected result: clear mapping between deployment change and retrieval scope, or none.

4. Reproduce safely with security observer in controlled test.
Expected result: behavior is reproducible or isolated to one context.

### Verification
- Evidence package complete and chain-of-custody documented.
- ACL truth established for reporting user.
- Audit path identifies whether source access was authorized.

### Rollback
- Revert connector scope or permission changes introduced Friday, if confirmed causal.
- Remove newly granted access paths introduced in error.
- Keep evidence preserved before applying rollback.

Expected result: exposure path is closed while preserving forensic traceability.

## Scenario 3: Missing Desktop Shortcuts
### Prerequisites
- Local admin or support session on affected device.
- Access to OneDrive KFM status, Intune scripts, and Friday package scripts.

### Procedure
1. Check Desktop, OneDrive Desktop, and Public Desktop paths.
Expected result: determine relocated vs deleted shortcut state.

2. Review Friday package scripts for shortcut add/remove actions.
Expected result: identify explicit shortcut mutation commands or absence of them.

3. Compare one affected and one unaffected device policy/script results.
Expected result: isolate differential policy cause.

4. Restore shortcuts only after mechanism is confirmed.
Expected result: user productivity restored without masking root cause.

### Verification
- Shortcuts appear in expected path and user shell.
- No repeated disappearance on next sign-in.

### Rollback
- Revert offending script or package change.
- Reapply baseline shortcut package from known-good version.

Expected result: stable shortcut persistence across sign-in cycles.

# Change Control Notes
- Mark all unverified claims as to confirm until telemetry and audit checks complete.
- Do not close security signals as product bugs without authorization proof.
