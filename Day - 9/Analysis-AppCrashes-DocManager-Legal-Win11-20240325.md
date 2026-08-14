# Detailed Analysis - Legal Floor 6 App Crash Wave (DocManager v2.1)

Date: 2026-08-14  
Analyst: DWP

## 1) Scope Facts (from provided evidence)

Affected estate facts:
- Device group: Legal-Win11
- Endpoint count: 45 devices
- Business area: Floor 6 Legal teams

Nexthink DEX facts:
- 08:00: DEX 91, app crash rate 0.1%, disk I/O Normal
- 09:00: DEX 90, app crash rate 0.2%, disk I/O Normal
- 10:00: DEX 58, app crash rate 6.2%, disk I/O High
- 11:00: DEX 55, app crash rate 6.8%, disk I/O High
- Top crashing process between 10:00-11:00: DocManager.exe (74% of all crashes)

SCCM deployment facts:
- [09:38:20] Deployment started: Legal Document Manager v2.1 to Legal-Win11 (45 devices)
- [09:44:07] Install completed: 45/45 devices
- [09:44:07] Install result: Success, 0 failures

Version and release-note facts:
- Previous version: Document Manager v2.0 (stable, deployed 6 weeks prior)
- New version: Document Manager v2.1
- Vendor known limitation: under-8GB devices can experience high disk I/O and intermittent crashes during first hours post-install while auto-save indexing builds

Fleet hardware profile:
- 60% have 8GB RAM
- 40% have 4GB RAM

## 2) Correlation Analysis (Why Sources Must Be Combined)

Time alignment:
- Pre-change (08:00 and 09:00): baseline healthy (DEX around 90, crashes near zero, disk I/O normal)
- Change event (09:38-09:44): v2.1 rollout completed to all 45 devices
- Post-change (10:00 and 11:00): immediate and sustained degradation

Content alignment:
- Dominant crashing process is DocManager.exe, the exact application that changed
- Disk I/O shift from Normal to High appears only after deployment
- Hardware risk condition (under 8GB RAM) exists in 40% of impacted fleet

Interpretation:
- SCCM confirms deployment execution quality (delivery/install)
- Nexthink confirms post-deployment runtime quality degradation
- Jointly, this indicates a runtime regression pattern rather than deployment packaging failure

## 3) Ranked Likely Causes (Most Probable First)

### 1. v2.1 auto-save indexing behavior caused post-install resource pressure and crashes

Why it fits:
- Crash spike starts in first full hour after rollout
- High disk I/O appears in the same window as crash increase
- Vendor note explicitly describes high disk I/O and intermittent crashes in first hours
- Crashes are primarily in DocManager.exe (74%)

Fastest check to confirm/eliminate:
- Compare crash and disk I/O trend for devices by RAM class (4GB vs 8GB)
- Validate whether crash rate naturally declines after initial indexing completion window
- Check for vendor advisory/hotfix reference specific to auto-save indexing

Specific remediation if confirmed:
- Roll back v2.1 to v2.0 for highest-risk 4GB devices first
- Apply vendor-provided mitigation/hotfix or policy to defer/limit initial indexing
- Re-stage rollout using canary rings with mixed hardware

### 2. Hardware-memory constraints amplified the defect impact

Why it fits:
- 40% of devices are 4GB, below the vendor 8GB guidance threshold
- Vendor symptom cluster includes both disk I/O pressure and crash intermittency under low-memory conditions

Fastest check to confirm/eliminate:
- Segment telemetry by RAM tier and compare:
  - crash rate
  - disk queue/active time profile
  - DEX recovery slope

Specific remediation if confirmed:
- Keep 4GB cohort on v2.0 until validated mitigation exists
- Prioritize memory-constrained devices for feature suppression or hardware refresh plan

### 3. Broad immediate rollout increased blast radius of otherwise known-limited behavior

Why it fits:
- 45/45 completed in a narrow window, so all users entered indexing window almost together
- Simultaneous exposure can create wave pattern even for intermittent failures

Fastest check to confirm/eliminate:
- Confirm deployment schedule concentration versus user login peaks
- Compare with prior phased deployments where similar spikes did not occur

Specific remediation if confirmed:
- Enforce staged ring policy (pilot, partial, full)
- Add first-2-hour crash/I-O quality gate before promotion

## 4) What Is Ruled Out (Given Current Evidence)

- "Deployment failed" is not supported:
  - SCCM reports 45/45 success and 0 failures
- "Random unrelated app instability" is less likely:
  - Crash dominance in DocManager.exe indicates concentration around changed app
- "Pre-existing daily baseline issue" is unlikely:
  - 08:00 and 09:00 metrics show normal conditions before change window

## 5) Working Hypothesis

Most likely working hypothesis:
- Legal Document Manager v2.1 introduced a known-limitation runtime pattern (auto-save indexing) that drove high disk I/O and intermittent DocManager crashes during initial post-install hours, with strongest impact on the 4GB segment, producing the observed floor-wide crash wave.

## 6) Recommended Validation Steps (Operational Sequence)

1. Build a per-device cohort view (4GB vs 8GB) for 09:30-12:00.
2. Measure crash rate and disk I/O deltas by cohort.
3. Confirm whether DocManager crash dominance is higher on 4GB devices.
4. Execute controlled rollback for most impacted cohort.
5. Re-sample metrics each hour for 3 hours post-remediation.
6. Document recovery against baseline thresholds.

## 7) Success Criteria for Recovery

- App crash rate trends back toward baseline (target under 0.5%)
- Disk I/O returns from High to Normal in affected group
- DEX score recovers toward pre-change band (target 85+)
- DocManager.exe share of total crashes materially decreases from 74%

## 8) Immediate Risk Controls

- Freeze additional v2.1 broad deployments pending mitigation validation
- Introduce temporary support guidance for Legal users during stabilization window
- Route severe-impact users to fallback version (v2.0) where needed

## 9) Preventive Controls for Future Releases

- Mandatory release-note risk mapping to hardware inventory before approval
- Canary deployment with explicit low-memory representation
- Promotion gate using objective telemetry (crash, DEX, disk I/O) in first business hours
- Known limitation registry linked to deployment policies

## 10) Analysis Conclusion

The evidence supports a high-confidence, change-correlated runtime regression tied to DocManager v2.1 auto-save indexing behavior. SCCM and Nexthink are complementary: SCCM proves complete and successful change rollout timing, while Nexthink proves immediate post-change endpoint degradation centered on DocManager with concurrent high disk I/O. The hardware profile (40% at 4GB) explains severity and breadth of impact.
