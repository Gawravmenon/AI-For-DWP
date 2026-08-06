Engineer-to-engineer internal note:
Root cause: Win11 upgrade removed legacy VPN client, but Intune did not re-deploy the new client because of a detection-rule gap.

Action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE<vendor>
- Forced Intune sync
- New client deployed
- Split-tunnel config applied
- Connectivity confirmed to all internal subnets

Verification:
- Internal subnet connectivity confirmed
- No data loss

Preventive action needed:
- Fix Intune detection rule so VPN redeployment triggers correctly after Win11 upgrade/removal of the legacy client