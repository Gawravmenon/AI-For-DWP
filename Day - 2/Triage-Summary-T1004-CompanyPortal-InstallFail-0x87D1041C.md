# Structured Triage Summary

**Ticket:** T-1004

## Summary (one line)
Application fails to install from Company Portal with error 0x87D1041C on a managed Windows endpoint.

## Impact (who / how many / business urgency)
- Who: Single user (to verify — confirm name, team, and department)
- How many: One reported; unknown whether the failure is device-specific or affects all users attempting the same app (to verify)
- Business urgency: Medium — user cannot access a required business application; urgency increases if app is needed for active work

## Known Facts
- Installation initiated via Company Portal (Intune-managed device — to verify)
- Error code returned: 0x87D1041C
- Error 0x87D1041C is a known Intune/Company Portal error code generally associated with app installation failure on the client side (to verify exact meaning against current Intune documentation)
- Application name not yet captured

## Missing Information to Gather
- User identity, contact details, and department
- Name and version of the application being installed
- Device name/asset ID and Windows version/build
- Whether the device is Intune-enrolled and compliant (to verify in Intune portal)
- Whether the same app installs successfully on another device (to verify)
- Whether the error appeared immediately or after a partial download
- Whether the device has sufficient disk space for the installation
- Whether a previous version of the app is installed or partially installed (to verify)
- Whether any other apps from Company Portal install successfully on this device
- Intune device sync status and last check-in time (to verify with MDM admin)

## Likely Category
- Likely category: Endpoint management / Intune app deployment failure
- Sub-category: Company Portal / MDM app install error (to verify)
- Incident vs. Service Request: Service request if isolated to one user/device; incident if the app is failing for multiple users

## Suggested First Diagnostic Step
On the affected device, force an Intune sync via Company Portal or Settings, then retry the installation and capture the full error details. Check available disk space on C: and confirm no partial installation remnants exist. If the issue persists, check the device's Intune compliance state and last check-in time in the MDM admin portal — a non-compliant or stale device record is a common cause of this error (to verify).
