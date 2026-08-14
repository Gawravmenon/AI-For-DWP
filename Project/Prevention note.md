# Prevention Note — Industry-Standard Process Change

## The Control: Post-Deployment Change Validation (PDCV)

ITIL-standard mandatory observation and sign-off checkpoint required before a change affecting more than 10 users is considered "deployed" and released to full business use.

## How It Works (ITIL 4 Framework)

**Standard**: Aligns with ITIL Change Management "Remediation" phase requirement that deployment is not complete until impact validation is confirmed.

**Trigger**: Any change pushed Friday after 12:00 PM affecting a floor/team must have explicit PDCV sign-off **before normal Monday business hours** (by 08:00 AM) or automatic rollback is initiated.

**Data source**: Automated monitoring dashboard capturing standard ITIL metrics:
- Technical success (did the deployment install/activate?)
- Operational success (are systems responding normally?)
- User-facing success (are affected users able to work?)

## Pass Criteria (ALL required for change to move from "In Progress" to "Successful")

| Metric | Standard ITIL Measure | Success Threshold | Monitored By |
|--------|--------|-----------------|-------|
| System availability | Uptime of managed endpoints in scope | ≥99% (≤1% down) | Infrastructure Monitoring |
| User task completion | Sign-in success rate vs baseline | ≥95% (≤5% variance from normal) | Infrastructure Monitoring |
| Application performance | Install completion without rollback/retry | ≥98% success rate | Application Performance Monitoring |
| Security/Compliance | No policy violations or access anomalies reported | Zero unresolved flags | Security Monitoring |
| User impact reports | Service desk tickets related to change | ≤5% increase over baseline | Service Desk Integration |

## Enforcement (ITIL CAB Authority)

1. Change Manager opens PDCV ticket Friday at deployment time
2. Automated monitoring feeds data into dashboard overnight
3. **08:00 AM Monday**: Change Manager + Change Advisory Board review dashboard
4. **Pass**: Change status moves to "Successful," normal operations continue
5. **Fail**: Automated rollback initiated immediately, change reverts to previous state, incident opened
6. **No sign-off by 08:30 AM**: Automatic rollback is triggered (prevents zombie deployments)

## Why This Would Have Caught Floor 6

By 08:00 AM Monday, automated ITIL monitoring would have reported:

- **User task completion FAIL**: Sign-in success 87% vs normal 98% (11% variance; exceeds 5% threshold)
- **Application performance FAIL**: Document app install success 96% (below 98% threshold, retry loop detected)
- **User impact reports FAIL**: Service desk tickets spiked 340% vs baseline (login, shortcuts, access reports)
- **Security flag FAIL**: Copilot access anomaly reported in monitoring system

**Change Advisory Board is forced to review at 08:00 AM.** Rollback decision made by 08:15 AM before users broadly attempt login. Incident escalation begins immediately.

## Industry Adoption

This is standard practice in:
- ITIL 4 Change Management (required for all "emergency" or high-velocity changes)
- NIST SP 800-53 (Change Control validation requirement)
- ISO/IEC 20000-1 (Change Management standard)
- SRE/DevOps playbooks (post-deployment validation gate)

## Implementation

- **Framework**: Integrate with existing ITIL Change Advisory Board workflow
- **Tooling**: Use current ITSM tool (ServiceNow/Jira/etc.) + existing monitoring stack
- **CAB authority**: Change Manager + Service Delivery Manager can authorize rollback
- **Effective**: Next non-routine deployment after training
- **No new tools required**: Uses existing change management + monitoring infrastructure
