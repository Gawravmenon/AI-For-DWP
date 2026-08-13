# Detailed Analysis - Autopilot Enrolment Failure

## Incident Summary
- Device: DESKTOP-FB099
- User: FINBRIDGE\rthomas
- Date observed: 2024-03-15 09:22
- Enrollment type: Autopilot
- Enrollment state: Failed
- Error code: 0x80180014
- Error description: The device is already enrolled in MDM.
- Existing MDM enrollment: Yes (legacy manual enrollment from 2023-11-04)
- Azure AD joined: Yes
- Policy state: 0 of 4 profiles applied, LastError 0x80070005 (Access denied)
- Network: Required Microsoft endpoints reachable, no proxy detected
- Licensing: M365, Intune P1, and Autopilot licenses present

## Confirmed Root Cause
The Autopilot enrollment attempt failed because the device already had a legacy, manual MDM enrollment record from 2023-11-04. The existing enrollment conflicts with Autopilot enrollment, so Autopilot cannot complete until the stale legacy enrollment state is removed.

## Evidence That Confirms Root Cause
- EnrollmentState = Failed
- ErrorCode = 0x80180014
- ErrorDescription = The device is already enrolled in MDM.
- MDMEnrolled = Yes (previous enrollment)
- EnrolmentSource = Legacy manual MDM enrollment

## Resolution Plan (Exact Steps)

### A. Intune admin center actions (Admin center only)
1. Locate existing device records
- Go to Intune admin center > Devices > All devices.
- Search by device name (DESKTOP-FB099), serial number, and user (rthomas) to identify all records tied to this physical device.

2. Validate Autopilot registration
- Go to Devices > Windows > Windows enrollment > Devices (Windows Autopilot devices).
- Find the Autopilot record for the same hardware hash/serial.
- Confirm the intended Autopilot profile assignment is correct.

3. Retire or delete stale managed device record(s)
- In Devices > All devices, identify the legacy/manual enrollment-backed managed device object.
- If still active, choose Retire first when policy requires a graceful cleanup.
- After retirement completes (or if already stale), Delete the stale managed device object.

4. Remove duplicate or stale Entra device objects if present
- In Microsoft Entra admin center > Devices > All devices, locate duplicate/stale objects for the same hardware.
- Remove only the stale duplicate entries, preserving the expected current object used for Autopilot flow.

5. Confirm assignment readiness
- Verify user/device group membership required for Autopilot enrollment and baseline policy targeting.
- Confirm there are no exclusion filters blocking the device/user.

### B. Device-side actions (Device access required: physical or remote)
1. Remove legacy work/school MDM connection
- On the device: Settings > Accounts > Access work or school.
- Select the legacy organization connection and Disconnect.
- If multiple entries exist, remove stale/legacy entry tied to prior manual enrollment.

2. Remove residual enrollment artifacts (if disconnect alone is insufficient)
- Open elevated Command Prompt and run dsregcmd /status to review join and MDM state.
- Remove stale local MDM enrollment artifacts per standard enterprise runbook if still present.

3. Reboot device
- Restart after disconnection/cleanup to ensure enrollment components refresh.

4. Start clean Autopilot enrollment cycle
- If device is already in provisioning stage and state is inconsistent, perform Windows reset aligned with Autopilot process.
- Re-run OOBE and sign in with intended user so Autopilot enrollment starts fresh.

## Correct Order of Operations
1. Admin center: identify stale and duplicate records.
2. Admin center: retire/delete stale Intune managed device object(s).
3. Admin center: remove stale duplicate Entra device object(s) if present.
4. Admin center: verify Autopilot registration/profile assignment and targeting groups.
5. Device access: disconnect legacy work/school MDM connection.
6. Device access: clear residual enrollment state if required, then reboot.
7. Device access: rerun Autopilot (OOBE/reset path as needed).
8. Admin center + device: verify successful enrollment and policy application.

## Verification Checks After Remediation

### Device-side verification (Device access required)
- Enrollment completes during OOBE without 0x80180014.
- In Settings > Access work or school, only the expected current organization connection is present.
- dsregcmd /status shows expected join/workplace state without legacy conflict indicators.

### Intune admin center verification (Admin center only)
- Devices > All devices shows a single healthy current managed device object for DESKTOP-FB099.
- Device shows Managed by MDM and check-in is current.
- Assigned compliance/security profiles begin applying successfully (no 0 of 4 state).
- Error 0x80180014 no longer appears in enrollment diagnostics.

### Success criteria
- Autopilot enrollment status: Succeeded.
- Policy application: expected profiles applied successfully.
- Compliance evaluation proceeds normally.

## Preventive Action for Other Legacy-Enrolled Devices
Implement a pre-Autopilot legacy-enrollment hygiene gate:
- Before assigning/reprovisioning any device for Autopilot, run a checklist that verifies:
  - No existing legacy/manual MDM enrollment on device.
  - No stale Intune managed device object for same hardware/serial.
  - No duplicate stale Entra device objects.
- Enforce this as a required service desk step in the Autopilot handoff runbook.
- Add a periodic admin report to detect devices with historical manual enrollment markers and remediate them before next reprovisioning.

## Notes
- Error code meanings were taken directly from collected evidence:
  - 0x80180014: device already enrolled in MDM.
  - 0x80070005: access denied (observed during policy phase after failed enrollment state).