# Structured Triage Summary

**Ticket:** T-1005

## Summary (one line)
Teams audio is not functioning on three machines located in the same meeting room.

## Impact (who / how many / business urgency)
- Who: Multiple users sharing a meeting room (to verify — confirm room location and user details)
- How many: Three machines confirmed affected; all in the same physical meeting room
- Business urgency: High — meeting room audio failure directly blocks collaborative meetings and remote calls for all users of that room

## Known Facts
- Teams audio is not working ("dead") on three machines
- All three machines are in the same meeting room
- Issue affects multiple devices simultaneously, strongly suggesting a shared/environmental cause (room audio hardware, shared peripheral, network, or policy)

## Missing Information to Gather
- Room name/location and asset IDs of the three affected machines
- Whether machines use a shared room audio device (speakerphone, conference unit, HDMI audio — to verify) or individual headsets
- Whether audio fails in Teams only, or also in other apps (to verify)
- Whether the audio device appears in Windows Sound settings on the affected machines
- Whether the issue started after a specific event (Teams update, Windows update, hardware change, room reconfiguration)
- Whether audio works when a personal headset is connected directly to one of the machines (to verify)
- Whether Teams audio works for these users on a different machine outside the room (to verify)
- Whether any policy or device driver change was recently pushed to these machines (to verify with MDM/desktop team)
- Teams client version on affected machines (to verify)

## Likely Category
- Likely category: Collaboration / Teams audio — shared meeting room peripheral or driver issue
- Sub-category: Audio device, driver, or Teams policy (to verify)
- Incident vs. Service Request: Treat as incident given multi-device impact and meeting room availability affected

## Suggested First Diagnostic Step
On one of the affected machines, open Windows Sound settings and confirm whether the meeting room audio device is listed, set as default, and showing an active signal. Then open Teams Settings > Devices and verify the correct audio device is selected. This isolates whether the issue is OS-level (device not detected) or Teams-level (wrong device configured) before involving hardware or network investigation.
