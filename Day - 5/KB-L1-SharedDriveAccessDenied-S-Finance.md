# L1 Knowledge Base — Finance Team Cannot Access Shared Drives

## Version Header

| Field | Value |
|------|-------|
| Title | L1 Knowledge Base — Finance Team Cannot Access Shared Drives |
| Version | 1.0 |
| Date | 13/08/2026 |
| Author | DWP Analyst |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

## Purpose

This article helps first-line analysts handle incidents where Finance users cannot see or open shared drives `S:` or `P:` after signing in to a Windows 11 device.

## Typical User Symptoms

- `S:` drive is missing from `This PC`.
- `P:` drive is missing from `This PC`.
- User says shared Finance folders were available previously but disappeared after restart.
- User can sign in to Windows but cannot reach team files needed for work.

## What This Usually Is

On migrated Windows 11 devices, mapped drive processing can happen before the network is fully ready at sign-in. The share itself is usually healthy, but the mapping fails too early.

## L1 Checks

1. Confirm the username, device name, and affected drive letters.
2. Ask whether the issue started after restart, first login of the day, or reconnect.
3. Ask whether other Finance users are affected.
4. Ask the user to open File Explorer and select `This PC`.
5. Ask the user to type the UNC path into the address bar if known, for example `\\corpfs01\Finance`.
6. If the UNC path opens but the mapped drive is missing, continue with local refresh steps.

## L1 Resolution Steps

1. Ask the user to disconnect and reconnect to VPN if they are remote.
2. Ask the user to sign out of Windows and sign back in.
3. If still missing, ask the user to open Command Prompt and run `gpupdate /force`.
4. After `gpupdate /force` completes, ask the user to restart the device.
5. After restart, ask the user to sign in and check `This PC` again.

## Success Criteria

- `S:` and `P:` appear in `This PC`.
- User can open the Finance folders.
- User confirms access is restored.

## Escalate to L2/L3 When

- UNC path does not open.
- More than one Finance user is affected.
- The issue persists after `gpupdate /force` and restart.
- The device is on Windows 11 and the failure repeats after each reboot.
- There are signs of permission denial rather than missing mapping.

## Evidence to Include in Escalation

- Username.
- Device name.
- Windows version.
- Whether the user is on VPN, office network, or AVD.
- Whether `S:`, `P:`, or both are affected.
- Whether UNC access worked.
- Result of `gpupdate /force`.
- Confirmation whether a restart was completed.

## Reference

Use the deeper article `KB-L2L3-SharedDriveAccessDenied-S-Finance.md` for engineering diagnosis and policy remediation.