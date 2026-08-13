# Closure Note: Autopilot Enrollment Failure – Legacy MDM Conflict

**Ticket:** T1006  
**Device:** DESKTOP-FB099  
**User:** rthomas  
**Issue Date:** 2024-03-15 09:22  
**Resolution Date:** 2024-03-15  
**Closed By:** IT Service Desk – L2 Support

---

## Issue Description
Device DESKTOP-FB099 (user rthomas) failed to enroll via Windows Autopilot with error code 0x80180014 ("The device is already enrolled in MDM"). Device had a legacy manual MDM enrollment from 2023-11-04 that conflicted with the new Autopilot enrollment attempt.

---

## Root Cause
Stale legacy MDM enrollment record (from previous manual enrollment) on device and associated stale/duplicate Entra device objects prevented successful Autopilot enrollment initiation.

---

## Resolution Applied

### Admin Center Actions
1. ✅ Located and deleted stale managed device record in Intune (legacy manual enrollment)
2. ✅ Removed duplicate/stale Entra device object in Microsoft Entra admin center
3. ✅ Verified correct Autopilot registration and profile assignment in place
4. ✅ Confirmed device group membership for Autopilot policy targeting

### Device-Side Actions
1. ✅ Disconnected legacy work/school MDM connection (Settings > Accounts > Access work or school)
2. ✅ Verified enrollment state cleared via `dsregcmd /status`
3. ✅ Rebooted device
4. ✅ Re-ran Autopilot enrollment during OOBE

---

## Verification

✅ **Enrollment Status:** Succeeded  
✅ **Policy Application:** 4 of 4 security profiles applied successfully  
✅ **Error 0x80180014:** No longer present  
✅ **Device Health:** Managed by Intune, compliant, check-in current  
✅ **User Access:** Able to access company resources and applications

---

## Work Completed (Hours)
- Admin center cleanup: 0.5 hours
- Device-side remediation: 0.75 hours
- **Total:** 1.25 hours

---

## Follow-Up Actions / Preventive Measures
- Added pre-Autopilot legacy-enrollment hygiene check to Autopilot handoff runbook
- Documented this scenario in L2 KB for future reference
- Recommended audit of legacy manual enrollments before Autopilot mass deployment

---

## Notes
This issue represents a common scenario during transitions from legacy device management to Autopilot. Implementing the hygiene gate before Autopilot assignment will prevent recurrence across the organization.

**Ticket Status:** ✅ CLOSED – Issue Resolved
