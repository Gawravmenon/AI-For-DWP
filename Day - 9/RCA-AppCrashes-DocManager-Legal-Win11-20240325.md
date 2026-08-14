# Root Cause Analysis - Legal Floor 6 App Crash Wave (DocManager v2.1)

Author: DWP Engineer  
Date: 2026-08-14  
Floor/Business Unit: Floor 6 - Legal  
Platform: Windows 11 - SCCM + Nexthink DEX  
Target Fleet: Legal-Win11 (45 devices)

---

## Executive Overview

This RCA consolidates two independent data sources to establish a single incident narrative:

- Source 1: Nexthink DEX telemetry (experience, crash rate, disk I/O)
- Source 2: SCCM deployment logs (change timing and installation scope)

Neither source alone is sufficient. SCCM confirms that deployment succeeded but does not describe runtime quality. Nexthink confirms runtime degradation but does not identify deployment success/failure context. Correlation of both proves a post-install runtime regression, not a package delivery failure.

---

## Incident Summary

- Incident: Wave of Legal user app crashes during morning business hours.
- Start of observable degradation: 10:00 snapshot.
- Last provided degraded point: 11:00 snapshot.
- Primary crashing executable (10:00-11:00): DocManager.exe (74% of all crashes).
- Incident class: Change-induced endpoint degradation.

---

## Scope and Impact

| Field | Detail |
|---|---|
| Device group | Legal-Win11 |
| Total endpoints in scope | 45 |
| Deployment completion | 45/45 successful, 0 failures |
| User cohort affected | Legal teams on Floor 6 |
| Service impact | High app instability and lower endpoint experience quality |
| Business risk | Reduced productivity in document-heavy legal workflows |

---

## Source Data Baseline

### Source 1 - Nexthink DEX Export (Legal-Win11)

| Date | Time | DEX Score | App Crash Rate | Disk I/O |
|---|---|---|---|---|
| 2024-03-25 | 08:00 | 91 | 0.1% | Normal |
| 2024-03-25 | 09:00 | 90 | 0.2% | Normal |
| 2024-03-25 | 10:00 | 58 | 6.2% | High |
| 2024-03-25 | 11:00 | 55 | 6.8% | High |

Top crashing process in degradation window: DocManager.exe (74%).

### Source 2 - SCCM Deployment Log

| Time | Event |
|---|---|
| 09:38:20 | Deployment started: Legal Document Manager v2.1 to Legal-Win11 (45 devices) |
| 09:44:07 | Install completed: 45 of 45 devices |
| 09:44:07 | Install result: Success, 0 failures |

Package context:

- Previous version: Document Manager v2.0 (stable, deployed 6 weeks prior).
- New version: Document Manager v2.1.
- Vendor known limitation: under-8GB devices may see high disk I/O and intermittent crashes for first hours during initial auto-save index build.

Fleet hardware profile:

- 60% at 8GB RAM.
- 40% at 4GB RAM (below vendor threshold).

---

## Correlated Timeline (Cross-Source)

| Time | SCCM Change Signal | Nexthink Experience Signal | Correlated Interpretation |
|---|---|---|---|
| 08:00 | No v2.1 rollout yet | DEX 91, crashes 0.1%, disk I/O normal | Stable pre-change baseline |
| 09:00 | Rollout not yet completed | DEX 90, crashes 0.2%, disk I/O normal | Stable pre-change trend continues |
| 09:38-09:44 | v2.1 fully installed on 45/45 | No hourly spike yet captured | Change introduced to entire fleet in narrow window |
| 10:00 | First full post-rollout hour | DEX 58, crashes 6.2%, disk I/O high | Immediate post-change degradation |
| 11:00 | Second post-rollout hour | DEX 55, crashes 6.8%, disk I/O high | Degradation sustained in early post-install period |

---

## Multi-Factor Correlation Statement

The following independent signals converge:

1. Timing correlation: degradation starts immediately after successful fleet-wide deployment.
2. Process correlation: dominant crash process is the same app that changed (DocManager.exe).
3. Symptom correlation: high disk I/O appears post-install and aligns with vendor-noted indexing behavior.
4. Hardware susceptibility correlation: 4GB subgroup (40%) maps directly to vendor under-8GB risk condition.

This is stronger than temporal coincidence because the changed process, symptom pattern, and susceptible hardware class all match the release limitation profile.

---

## Root Cause Statement

Primary root cause is a post-install runtime limitation in Document Manager v2.1 auto-save indexing, which caused elevated disk I/O and intermittent DocManager crashes during initial index build hours, with amplified impact on the under-8GB (4GB) segment of Legal-Win11.

---

## Contributing Factors

| Factor | Contribution to Incident |
|---|---|
| Full-fleet immediate rollout (45/45) | Increased blast radius and user-visible concurrency of failures |
| 40% 4GB endpoints | Raised susceptibility to vendor-documented limitation |
| Morning deployment window | Increased active-user exposure during indexing period |
| No canary/soak gate | Reduced chance of early detection before full impact |

---

## Why SCCM Success and Nexthink Degradation Are Both True

| Statement | What It Means |
|---|---|
| SCCM install success | Package delivered and installed correctly |
| Nexthink crash and DEX regression | Application runtime quality degraded after install |

There is no contradiction: deployment mechanics succeeded, but runtime behavior regressed.

---

## 5 Whys Analysis

1. Why did Legal users report a crash wave?
- DocManager crash rate rose sharply during 10:00-11:00.

2. Why did crash rate rise at that time?
- v2.1 was deployed fleet-wide minutes earlier.

3. Why did v2.1 lead to instability?
- Auto-save indexing increased early-hours resource pressure, matching vendor known limitation behavior.

4. Why was impact broad and severe?
- 40% of devices are 4GB RAM, directly fitting the under-8GB risk profile.

5. Why was issue not contained before broad impact?
- Rollout lacked staged canary and first-hours performance/crash gate criteria.

---

## Confidence and Assumptions

| Item | Assessment |
|---|---|
| RCA confidence | High |
| Basis | Timing + process + symptom + hardware alignment across both sources |
| Primary assumption | No independent, simultaneous platform-wide fault outside provided data window |

---

## Immediate Containment Plan (Operational)

### Priority Actions (First 4 Hours)

1. Pause additional v2.1 rollouts to other collections.
2. Segment Legal-Win11 by RAM class and identify highest crash concentration.
3. Roll back v2.1 to v2.0 for 4GB devices first.
4. If rollback is constrained, disable/defer indexing feature through vendor-supported policy or config.
5. Send targeted communication to Legal and Service Desk describing expected stabilization and workaround.

### Validation Gates for Containment Success

| Metric | Target |
|---|---|
| App crash rate | Return toward pre-change level, target under 0.5% |
| Disk I/O | Return from High to Normal trend |
| DEX score | Recover toward baseline, target 85+ |
| Top crash process share | DocManager.exe share materially reduced from 74% |

---

## Corrective and Preventive Actions

### Short-Term (0-48 Hours)

- Execute rollback/hotfix strategy for under-8GB cohort.
- Compare hourly crash and I/O trend by RAM cohort (4GB vs 8GB).
- Confirm reduction in DocManager crash dominance.

### Medium-Term (Within 7 Days)

- Introduce staged ring deployment for Legal app updates:
  - Ring 0: 5-10 representative devices (include 4GB and 8GB mix).
  - Ring 1: 30-40% of remaining estate.
  - Ring 2: full production after validation hold.
- Add release gate: no severe crash or DEX regression in first two business hours.
- Require pre-approval risk mapping of vendor release notes to real hardware distribution.

### Long-Term (Governance)

- Define application minimum hardware baseline for DocManager advanced features.
- Maintain compatibility matrix by RAM/storage class.
- Create automated alert for post-deployment pattern:
  - crash spike + disk I/O spike + DEX drop within 2-4 hours of rollout.

---

## Evidence-to-Conclusion Mapping

| Evidence | Conclusion |
|---|---|
| SCCM: v2.1 deployed to 45/45 by 09:44 with 0 failures | All Legal devices were exposed nearly simultaneously |
| Nexthink: pre-change stable at 08:00-09:00 | Baseline was healthy before rollout |
| Nexthink: 10:00 crash 6.2%, DEX 58, disk I/O High | Degradation started in first post-deployment hour |
| Nexthink: 11:00 crash 6.8%, DEX 55, disk I/O High | Degradation persisted in early indexing period |
| Top crashing process DocManager.exe at 74% | Changed app is principal failure source |
| Vendor note: under-8GB devices prone to high I/O + crashes | Symptom pattern matches documented product limitation |
| Fleet profile: 40% 4GB devices | Susceptible hardware share explains impact scale |

---

## Final Determination

This incident is a change-induced runtime regression associated with Document Manager v2.1 auto-save indexing. SCCM and Nexthink data are jointly conclusive when correlated: deployment completed successfully and immediately preceded a DocManager-centric crash surge with high disk I/O, exactly matching vendor-known behavior on lower-memory devices.

---

## Optional Follow-Up Artifacts

If required for incident closure package, generate:

1. Service Desk closure note (technical).
2. Legal leadership communication (non-technical).
3. Problem record known error entry with workaround and rollout guardrails.
