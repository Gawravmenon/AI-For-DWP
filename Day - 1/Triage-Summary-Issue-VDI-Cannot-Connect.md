# Triage Summary – VDI Connection Failure

**Analyst:** DWP Service Desk  
**Date Logged:** 04 Aug 2026  
**Source:** End-user verbal/written report

---

## Summary
User unable to connect to VDI today; client displays "cannot connect" error. Last successful connection was Friday.

---

## Impact
- **Who:** Single end-user (identity to confirm)
- **How many:** 1 reported (whether wider outage is affecting others — to confirm)
- **Business urgency:** High — user has no access to their virtual desktop and cannot work from home

---

## Known Facts
1. VDI connection is failing today (2026-08-04, Monday).
2. Error message presented: "cannot connect" (exact wording to confirm).
3. Connection worked successfully on Friday (last known good state).
4. User is working from home on a WiFi connection.
5. No change to working setup reported by user (to confirm).

---

## Missing Information to Gather
1. Username / staff ID (to check account status and any overnight changes).
2. Exact error message text or error code displayed by the VDI client.
3. VDI client name and version (e.g. Citrix Workspace, VMware Horizon, AVD client).
4. Device type and OS (corporate laptop, personal device, Windows/Mac/other).
5. Whether the device has internet connectivity for other sites (to isolate WiFi vs. VDI).
6. Whether any Windows updates, software updates, or reboots occurred over the weekend.
7. Whether any other users in the same area/team are experiencing the same issue.
8. Whether VPN is required before VDI, and if so, whether VPN connects successfully.
9. Time of first failure attempt today.
10. Any changes to home network (new router, ISP issue, moved location — to confirm).

---

## Likely Category
**Category:** Remote Access / VDI Connectivity  
**Sub-category:** Client-side connection failure (possible causes: network/firewall, VDI client issue, authentication/account issue, or platform outage)

---

## Suggested First Diagnostic Step
**Check for a known platform incident first:**  
Query the internal incident/outage board or contact the VDI platform team to confirm whether there is an active or recent outage affecting the VDI environment. If no platform outage is confirmed, proceed to verify the user's internet connectivity (ask them to browse an external site), then confirm VPN connectivity if required prior to VDI launch.
