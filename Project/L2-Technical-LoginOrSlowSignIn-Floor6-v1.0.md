# Version Header
- Document: L2-Technical-LoginOrSlowSignIn-Floor6
- Version: 1.0
- Last Updated: 2026-08-14
- Source: Runbook-Floor6-IncidentResponse-Win11-Intune-v1.0

## Objective
Contain likely deployment-driven sign-in degradation and validate causality.

## Prerequisites
- Graph permissions: Group.ReadWrite.All, Device.Read.All.
- Floor 6 affected device list.
- Intune app assignment and install-state visibility.

## Procedure
1. Freeze blast radius and collect affected device list.
Expected result: no net-new impacted assignments.

2. Remove affected devices from ring:
```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.Read.All"
$floor6RingGroupId = "TO-CONFIRM-GROUP-ID"
$affectedDeviceNames = @("TO-CONFIRM-DEVICE1","TO-CONFIRM-DEVICE2")
$affectedDeviceIds = foreach ($name in $affectedDeviceNames) { (Get-MgDevice -Filter "displayName eq '$name'" -ConsistencyLevel eventual).Id }
foreach ($deviceId in $affectedDeviceIds) { Remove-MgGroupMemberByRef -GroupId $floor6RingGroupId -DirectoryObjectId $deviceId }
```
Expected result: membership removal replicated in Entra.

3. Validate Intune install retry and failure telemetry for removed vs control devices.
Expected result: causal signal appears as reduced retries on contained set, to confirm.

4. Cross-check Entra sign-in outcomes.
Expected result: clear split between auth failures and endpoint-side delay.

## Verification
- Group membership confirms containment.
- New sign-in attempts improve on contained set, to confirm.
- Retry-loop telemetry declines.

## Rollback
```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.Read.All"
$floor6RingGroupId = "TO-CONFIRM-GROUP-ID"
$restoreDeviceIds = @("TO-CONFIRM-DEVICE-ID-1","TO-CONFIRM-DEVICE-ID-2")
foreach ($deviceId in $restoreDeviceIds) { New-MgGroupMemberByRef -GroupId $floor6RingGroupId -BodyParameter @{"@odata.id"="https://graph.microsoft.com/v1.0/devices/$deviceId"} }
```
Expected result: devices rejoin assignment ring.
