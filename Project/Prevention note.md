# Prevention Note

## Specific process change
Implement a mandatory control called Monday Readiness Gate (MRG) for any Friday afternoon floor-level rollout.

## What this control is
Before a Friday deployment can continue past pilot scope, the change owner must pass a written MRG checklist by 08:30 Monday using real telemetry from the target floor and a matched control group.

## Required pass criteria (all must pass)
1. Sign-in health: no abnormal increase in failed or prolonged sign-ins in the target floor versus control.
2. App health: no install retry-loop or failure spike in the target floor deployment set.
3. Access safety: no unresolved authorization anomaly reports in legal or sensitive-data workflows.
4. User-state integrity: no spike in profile or desktop artifact regressions (for example missing shortcuts).

## Enforcement
If any single criterion fails, deployment auto-pauses for that floor and cannot resume until incident owner and security approver sign off documented corrective action.

## Why this would have caught it
This exact control would have forced early Monday checkpoint evidence on sign-in behavior, rollout retry patterns, and access anomalies before broad business impact continued.
