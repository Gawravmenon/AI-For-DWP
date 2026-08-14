# Version Header
- Document: Immediate-Action-Floor6-AppRing-Containment-and-Message
- Version: 1.0
- Last Updated: 2026-08-14
- Owner: DWP Engineering, FinBridge

## Technical Action (actual command)
- Conclusion: Execute immediate containment by removing affected devices from the Floor 6 deployment ring group.
- Reasoning: This is the fastest low-blast-radius action when deployment is the most-likely cause.

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

## Plain-Language Note to Floor 6
Floor 6 team, we understand this is disrupting your work and we are actively isolating affected devices now to stabilize sign-in performance. Our current leading cause is Friday's app rollout interacting with recent Windows 11 migration settings, and we will share progress updates as each validation checkpoint completes without committing to a time we cannot yet guarantee.
