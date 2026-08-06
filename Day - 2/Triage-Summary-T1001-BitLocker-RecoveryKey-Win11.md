# Structured Triage Summary

**Ticket:** T-1001

## Summary (one line)
New Windows 11 laptop prompts for BitLocker recovery key on every boot, preventing normal user login.

## Impact (who / how many / business urgency)
- Who: Single end user (to verify — confirm name, team, and department)
- How many: One reported device (to verify — check if other new Win11 builds are affected)
- Business urgency: High — user cannot access device independently; recovery key prompt blocks every boot cycle

## Known Facts
- Device is a new Windows 11 laptop (build/issue date to verify)
- BitLocker recovery key prompt appears at every boot
- Issue is recurring, not a one-off event

## Missing Information to Gather
- User identity, contact details, and department
- Device name/asset ID and serial number (needed to locate recovery key in estate management tooling)
- Exact point in boot where prompt appears (pre-login screen vs. after Windows loads — to verify)
- Whether the device was ever successfully booted without the prompt
- Whether any hardware changes, BIOS/UEFI changes, or docking events occurred before issue started
- Whether Secure Boot or TPM status has changed (to verify)
- Whether device is Intune/MDM enrolled and whether a compliance or encryption policy was recently pushed (to verify)
- Whether the user has the recovery key or knows where it is stored
- Whether the issue appeared immediately from first use or started after a specific event (update, reboot, undocking)

## Likely Category
- Likely category: Endpoint security / BitLocker TPM binding issue on new Windows 11 device
- Sub-category: Encryption / hardware trust (to verify)
- Incident vs. Service Request classification: Treat as incident until root cause confirmed — repeated recovery key prompts may indicate a TPM, Secure Boot, or MDM policy issue requiring investigation

## Suggested First Diagnostic Step
Retrieve the BitLocker recovery key from the estate/identity management tooling (e.g. Intune/Azure AD — to verify against DWP tooling) using the device asset ID, provide it to the user to unlock the device, then immediately check:
1. TPM status in Device Manager or equivalent — confirm TPM is present, enabled, and showing no errors (to verify)
2. Secure Boot state in BIOS/UEFI — confirm it is enabled and unchanged
3. Intune/MDM compliance state — check whether a BitLocker policy is forcing re-seal on each boot (to verify)

Do not attempt BIOS changes or TPM resets without verifying the rollback/recovery path and escalating if outside first-line scope.
