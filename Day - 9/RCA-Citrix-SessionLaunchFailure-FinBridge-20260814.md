# RCA - Citrix Session Launch Failure (FinBridge-VDI-Pool-02)

Date: 2026-08-14  
Prepared by: DWP Analyst

## Incident Summary

A large subset of users could not launch VDI sessions in FinBridge-VDI-Pool-02. Broker logs recorded timeout and launch failure events, while Pool-02 showed high VDA unregistration. Pool-01 remained largely healthy.

## Impact

- Business service impacted: Citrix VDI session launch for Pool-02 users
- Affected users: 22 of 30
- Unaffected comparator: FinBridge-VDI-Pool-01 (19/20 registered)

## Evidence Inventory

1. Citrix Session Broker log:
- [08:58:03] Launch requested for Pool-02 user
- [08:58:04] Broker querying available machines
- [08:58:34] Timeout waiting for machine registration response (30000ms)
- [08:58:34] Failed with error 1030 'No machines available in the desktop group'

2. Catalog registration state:
- Pool-02: 25 provisioned, 3 registered, 22 unregistered, 0 maintenance
- Pool-01: 20 provisioned, 19 registered, 1 unregistered

3. Unregistered machine sample (Pool-02):
- Failed registration attempts around 06:15-06:16
- Error: Unable to contact Delivery Controller
- Connection refused to dc-vdi-02.finbridge.local:80

4. Controller health:
- dc-vdi-02: Broker Service STOPPED, last known running yesterday 23:40
- dc-vdi-02: Update installed today 00:15, reboot required flag set, host not rebooted
- dc-vdi-01: Broker Service RUNNING, uptime 14 days

## Timeline (Known Facts)

- Yesterday 23:40: dc-vdi-02 Broker Service last known running
- Today 00:15: Windows Update installed on dc-vdi-02, reboot required set
- 06:15:22: Pool-02 VDI-P02-014 registration attempt failed (connection refused to dc-vdi-02:80)
- 06:16:01: Pool-02 VDI-P02-017 registration attempt failed (connection refused to dc-vdi-02:80)
- 08:58:03: User launch request submitted in Pool-02
- 08:58:34: Broker timeout and failure error 1030 with 'No machines available in the desktop group'

## Analysis

- The failure is pool-specific rather than site-wide.
- Pool-02 has severe registration degradation (3/25 registered), while Pool-01 is healthy (19/20 registered).
- Pool-02 registration failures explicitly cite inability to contact dc-vdi-02 with connection refused.
- dc-vdi-02 Broker Service is STOPPED at time of investigation.

These facts align with a controller service availability failure affecting Pool-02 machine registration and resulting in insufficient launchable machines.

## 5-Why Analysis

1. Why did users fail to launch Pool-02 sessions?
- Broker could not find available registered machines and returned error 1030 with text 'No machines available in the desktop group'.

2. Why were insufficient machines available?
- Most Pool-02 machines were unregistered (22 of 25).

3. Why were Pool-02 machines unregistered?
- Registration attempts failed with connection refused to dc-vdi-02:80.

4. Why was dc-vdi-02 unreachable for registration on broker endpoint?
- Citrix Broker Service on dc-vdi-02 was STOPPED.

5. Why did Broker Service remain stopped without rapid recovery?
- Controller had an update with reboot-required state not completed, and service health guardrail/recovery process did not prevent prolonged outage.

## Finalized Hypothesis

Primary hypothesis selected:
- A dc-vdi-02 Broker Service outage, likely sustained by incomplete post-update reboot/health recovery, caused broad Pool-02 VDA unregistration and subsequent session launch failures.

Note on error code meaning:
- Only explicit meaning used is from the provided log text associated with code 1030: 'No machines available in the desktop group'.

## Remediation Plan (Exact Order)

1. Initiate controlled change and notify stakeholders.
2. Capture pre-remediation evidence (service state, registration counts, key logs).
3. Reboot dc-vdi-02 to clear pending reboot/update state.
4. Post-reboot, verify Broker Service startup type is Automatic and status is Running.
5. If service does not auto-start, manually start Broker Service and resolve startup errors from logs.
6. Confirm controller endpoint reachability for VDA registration.
7. Trigger registration refresh on unregistered Pool-02 VDAs (restart Citrix Desktop Service in batches) if needed.
8. Observe registration recovery and test real user launches.
9. Document closure evidence and communicate restoration.

## Verification of Resolution

Mandatory checks:
- dc-vdi-02 Broker Service remains Running over a stability window.
- Pool-02 registered count rises significantly from baseline of 3.
- New launch attempts in Pool-02 complete successfully.
- No repeating broker timeout/1030 launch failures during observation period.

Evidence to capture:
- Before/after catalog registration screenshots or exports
- Service status snapshots from both controllers
- Test launch results from impacted user set

## Preventive Actions

1. Patch governance
- Enforce reboot completion and post-reboot validation before declaring controller maintenance complete.

2. Service resilience
- Configure Broker Service recovery actions and alerting for service stop events.

3. Monitoring
- Alert on abnormal unregistered-machine ratio per pool and broker timeout spikes.

4. Failover assurance
- Periodically validate VDA controller list/failover behavior so each pool can survive single-controller outages.

5. Operational checklist
- Add explicit post-update Citrix health checks (service state, registration trend, launch synthetic tests) to maintenance SOP.

## Closure Criteria

- User-impact metric recovered to normal operating threshold for Pool-02.
- No new incidents of the same symptom during defined monitoring period.
- Preventive controls implemented and documented.
