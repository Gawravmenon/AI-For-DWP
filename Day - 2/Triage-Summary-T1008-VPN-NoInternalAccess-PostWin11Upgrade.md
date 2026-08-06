# Structured Triage Summary

**Ticket:** T-1008

## Summary (one line)
VPN connects successfully but no internal resources are reachable following a Windows 11 upgrade.

## Impact (who / how many / business urgency)
- Who: Single user (to verify — confirm name, team, and department)
- How many: One reported; unknown whether other Win11 upgrade recipients are affected (to verify)
- Business urgency: High — user is effectively unable to access any internal systems or services despite VPN showing as connected; working remotely without internal access blocks most DWP endpoint tasks

## Known Facts
- VPN connection establishes and shows as connected
- No internal resources are reachable after VPN connects
- Issue began after upgrading to Windows 11
- VPN client name/version not yet captured

## Missing Information to Gather
- User identity, contact details, and department
- VPN client name and version (to verify)
- Upgrade method (in-place upgrade, fresh build — to verify)
- Whether the VPN worked on Windows 10 on the same device prior to upgrade
- Whether the VPN worked at any point after the Win11 upgrade
- Specific internal resources being tested (file shares, intranet, internal DNS — to verify)
- Whether DNS resolution is failing or IP routing is the issue (to verify via basic connectivity test)
- Whether the VPN client was reinstalled or reconfigured after the Win11 upgrade (to verify)
- Whether Windows Firewall or any network profile change occurred post-upgrade (to verify)
- Whether the device network adapter drivers are current post-upgrade (to verify in Device Manager)
- Whether other recently upgraded Win11 devices have the same VPN behaviour (to verify with desktop/network team)

## Likely Category
- Likely category: Network / VPN split-tunnelling or routing issue post-Win11 upgrade
- Sub-category: VPN client compatibility, driver change, or Windows Firewall profile post-upgrade (to verify)
- Incident vs. Service Request: Treat as incident; escalate to network/VPN team if more than one Win11 upgrade shows the same pattern

## Suggested First Diagnostic Step
While VPN is connected, ask the user to open Command Prompt and run `ipconfig /all` to confirm a VPN adapter IP has been assigned and an internal DNS server address is present, then attempt `ping` or `nslookup` against a known internal hostname or IP (using a safe test target — do not share internal addresses in this ticket). This quickly separates a DNS resolution failure from a full routing failure, directing the next step toward either VPN DNS configuration or a driver/routing table issue.
