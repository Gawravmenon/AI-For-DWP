# Known Error: Autopilot Enrollment Failure Due to Legacy MDM Enrollment

## Error Summary
**Error Code:** 0x80180014  
**Error Message:** "The device is already enrolled in MDM"  
**Affected Component:** Windows Autopilot enrollment  
**Severity:** High  
**Status:** Known issue with documented resolution

---

## Who Is Affected
Devices that have:
- Previous manual/legacy MDM enrollment from Intune
- Azure AD join status: Hybrid or Azure AD joined
- Assigned Autopilot profile and attempting re-enrollment or first enrollment
- Stale managed device records in Intune admin center
- Stale or duplicate Entra device objects

**Example Scenario:**  
Device DESKTOP-FB099 user rthomas attempted Autopilot enrollment but failed because the device had a legacy manual MDM enrollment from 2023-11-04.

---

## Why It Happens
When a device has an existing legacy/manual MDM enrollment record, the Autopilot enrollment process detects a conflict and rejects the enrollment attempt with error 0x80180014. The system cannot process a new Autopilot enrollment until the legacy enrollment state is completely removed from both Intune and Entra device registry.

---

## Symptoms
- Enrollment fails immediately or during policy application phase
- Error 0x80180014 appears in Intune enrollment diagnostics
- Device shows "Managed by MDM" but policy application shows 0 of X profiles applied
- User sees enrollment failure during Windows out-of-box experience (OOBE)
- Additional error 0x80070005 (Access denied) may appear when policies attempt to apply

---

## Workaround (Temporary)
**If immediate access required:** Device can function on standard Windows without Intune management until permanent resolution is applied. User can defer Windows setup to proceed to desktop and IT can resolve enrollment remotely.

---

## Permanent Resolution
Follow the two-phase remediation process:

### Phase 1: Admin Center Cleanup (IT-only)
1. Go to Intune admin center > **Devices > All devices**
2. Search device by name (DESKTOP-FB099), serial number, or user
3. Identify the legacy/stale managed device record
4. Select **Retire** (if policy requires graceful shutdown), then **Delete**
5. Go to **Microsoft Entra admin center > Devices > All devices**
6. Locate and remove any stale/duplicate device objects for same hardware
7. Verify **Devices > Windows enrollment > Windows Autopilot devices** shows the correct Autopilot record
8. Confirm device is in target group for Autopilot policy assignment

### Phase 2: Device-Side Cleanup (User assistance or remote management)
1. Go to device **Settings > Accounts > Access work or school**
2. Select legacy organization connection and click **Disconnect**
3. If using remote access, run elevated command: `dsregcmd /status` to verify enrollment state cleared
4. **Reboot device**
5. Restart Autopilot enrollment process (OOBE or Windows reset as needed)

---

## Success Indicators
- Autopilot enrollment completes without error 0x80180014
- Device shows in Intune as "Managed by Intune"
- Compliance and security policies apply successfully (4 of 4 profiles applied)
- User can access corporate resources

---

## Prevention
Before assigning Autopilot to any device:
- Verify no legacy MDM enrollment exists
- Check for stale Intune managed device records
- Remove duplicate stale Entra device objects
- Add this check to Autopilot handoff runbook

---

## Escalation
If after completing both phases the error persists, escalate to **Level 2/3 Support** with:
- Device name and serial number
- Enrollment diagnostic logs from Intune
- Screenshots of Entra device objects
