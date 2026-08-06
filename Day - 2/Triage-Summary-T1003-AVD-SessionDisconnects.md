# Structured Triage Summary

**Ticket:** T-1003

## Summary (one line)
User's Azure Virtual Desktop session disconnects approximately every 10 minutes before automatically reconnecting, disrupting active work.

## Impact (who / how many / business urgency)
- Who: Single user (to verify — confirm name, team, and department)
- How many: One reported; unknown whether others on same AVD host pool or network path are affected (to verify)
- Business urgency: Medium-High — repeated disconnections are disruptive to productivity; severity increases if user is in a time-critical role

## Known Facts
- Session disconnects after approximately 10 minutes
- Session reconnects automatically after disconnection
- Platform is Azure Virtual Desktop (AVD) (to verify — confirm not Citrix or RDS)
- Disconnect interval is consistent (~10 min), suggesting a timeout or keepalive configuration may be involved

## Missing Information to Gather
- User identity, contact details, and department
- Client device type and OS (physical endpoint, thin client, personal device — to verify)
- Network connection type at time of issue (corporate LAN, Wi-Fi, VPN, home broadband — to verify)
- AVD client version in use (to verify)
- Whether the issue is constant or started after a specific change (update, policy push, network change)
- Whether other users on the same host pool or network segment are experiencing the same issue (to verify)
- Whether any error code or message appears at point of disconnection (to verify)
- Whether session timeout or idle disconnect policies were recently changed (to verify with AVD/MDM admin team)
- Whether the reconnection is seamless or requires re-authentication

## Likely Category
- Likely category: Virtual desktop / AVD session stability
- Sub-category: Session timeout policy, network keepalive, or host pool configuration (to verify)
- Incident vs. Service Request: Treat as incident; escalate if multiple users affected on same host pool

## Suggested First Diagnostic Step
Check the AVD session event logs on the client device for disconnect reason codes at the time of disconnection (to verify log location based on AVD client version), and confirm the approximate 10-minute interval against any configured idle/session timeout policies in the AVD host pool or Intune/GPO settings — a timeout exactly matching a policy value is a strong indicator of a configuration cause rather than a network fault.
