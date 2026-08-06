# Structured Triage Summary

**Ticket:** T-1006

## Summary (one line)
User reports general device slowness beginning after upgrading to Windows 11 two days ago.

## Impact (who / how many / business urgency)
- Who: Single user (to verify — confirm name, team, and department)
- How many: One reported; unknown whether other users who recently upgraded to Win11 are experiencing the same (to verify)
- Business urgency: Medium — general slowness degrades productivity across all tasks; urgency increases if user role is operationally critical

## Known Facts
- User upgraded to Windows 11 two days ago
- Slowness is described as general ("everything is slow"), not limited to one application
- Issue appears directly linked to the Win11 upgrade in the user's view
- Specific performance metrics not yet captured

## Missing Information to Gather
- User identity, contact details, and department
- Device name/asset ID, hardware spec (RAM, CPU, storage type — to verify)
- Upgrade method used (in-place upgrade, fresh build, MDM policy push — to verify)
- Whether slowness is constant or worse at specific times (startup, login, after lock screen)
- Task Manager readings: CPU, memory, and disk usage at time of slowness (to verify)
- Whether Windows Update, Defender, or Intune policy activity is still running post-upgrade (to verify)
- Available disk space on C: drive
- Whether the device meets Windows 11 minimum hardware requirements (to verify)
- Whether any drivers were updated or are flagged as incompatible post-upgrade (to verify in Device Manager)
- Whether other recently upgraded Win11 devices show the same behaviour (to verify with desktop team)

## Likely Category
- Likely category: Endpoint performance / post-upgrade resource contention or driver compatibility
- Sub-category: Windows 11 in-place upgrade side effects (to verify)
- Incident vs. Service Request: Service request if isolated; incident if a pattern across multiple Win11 upgrades

## Suggested First Diagnostic Step
Open Task Manager (Ctrl+Shift+Esc) and check the Performance tab for CPU, memory, and disk usage. If disk is near 100%, check the Processes tab for Windows Update or Defender activity — post-upgrade background tasks are the most common cause of sustained slowness in the first 24–48 hours after a Win11 upgrade. Record the readings before taking any action.
