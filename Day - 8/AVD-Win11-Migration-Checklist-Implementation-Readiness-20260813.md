# Azure Virtual Desktop (AVD) Windows 11 Migration
## Checklist, Implementation Plan, and Readiness Check

Date: 2026-08-13  
Owner: DWP Engineering  
Scope: Windows 11 workplace migration to Azure Virtual Desktop

---

## 1) Objective

Provide a practical execution document to:
- Validate prerequisites and controls before migration.
- Execute migration in controlled phases.
- Confirm operational readiness before production go-live.

---

## 2) Pre-Implementation Checklist

### 2.1 Governance and Project Controls
- [ ] Migration scope approved (users, departments, regions).
- [ ] CAB/Change request approved with implementation window.
- [ ] Rollback criteria and decision authority documented.
- [ ] Business communications and outage notice prepared.
- [ ] Service desk and L2/L3 support briefed.

### 2.2 Licensing and Identity
- [ ] Eligible AVD licensing confirmed for all target users.
- [ ] Microsoft Entra ID user and group hygiene complete (no stale/duplicate objects).
- [ ] Conditional Access policies reviewed for AVD sign-in paths.
- [ ] MFA and compliant-device requirements validated.
- [ ] Break-glass/admin access tested.

### 2.3 Azure Subscription and Access
- [ ] Subscription owner/delegate permissions verified.
- [ ] Least-privilege RBAC assigned (host pool, workspace, app groups, VM, networking).
- [ ] Resource naming standards and tags agreed.
- [ ] Budget, cost alerts, and quota limits configured.

### 2.4 Network and Connectivity
- [ ] VNet/subnets ready with capacity for session hosts.
- [ ] NSG/UDR rules allow required AVD, identity, and management endpoints.
- [ ] DNS resolution for AD/Entra hybrid dependencies tested.
- [ ] ExpressRoute/VPN routing validated for corporate resources.
- [ ] Latency and packet-loss baseline captured from representative sites.

### 2.5 Session Host Platform
- [ ] Golden image strategy defined (Gallery image/custom image).
- [ ] Windows 11 image patched and hardened to baseline.
- [ ] FSLogix profile container design approved (storage type, redundancy, permissions).
- [ ] Antivirus/EDR exclusions for FSLogix and Office containers validated.
- [ ] Host sizing finalized (vCPU/RAM per user profile/workload).
- [ ] Autoscaling plan configured and cost-tested.

### 2.6 Application and Data
- [ ] Application inventory categorized: required, optional, deprecated.
- [ ] Packaging model confirmed (MSIX/Intune/script/manual).
- [ ] Line-of-business app compatibility test completed on Windows 11 AVD host.
- [ ] Printer strategy defined (universal print/network print mapping).
- [ ] OneDrive/Outlook/Teams profile behavior tested with FSLogix.

### 2.7 Security and Compliance
- [ ] Security baseline GPO/Intune policies applied and validated.
- [ ] Logging enabled: Azure Monitor, Log Analytics, diagnostic settings.
- [ ] Defender for Cloud/Endpoint onboarding verified.
- [ ] Data residency and compliance controls validated.
- [ ] Privileged operations audited and recorded.

### 2.8 Monitoring and Operations
- [ ] AVD Insights workbook configured and tested.
- [ ] Alerting thresholds set (session disconnects, sign-in failures, host unhealthy state).
- [ ] Backup/restore validated for profile and configuration data.
- [ ] Incident runbooks and escalation paths published.
- [ ] Capacity and performance dashboards shared with operations.

---

## 3) Implementation Plan

### Phase 0: Design Finalization (T-2 to T-1 weeks)
1. Confirm target architecture (pooled/personal host pool, DR approach).
2. Freeze build standards (image version, baseline policies).
3. Finalize pilot cohort and success criteria.
4. Approve rollback and communications plan.

### Phase 1: Build Foundation (T-1 week)
1. Create/validate host pools, workspaces, and app groups.
2. Deploy session hosts from approved image.
3. Configure domain join/Entra join model and policy assignment.
4. Configure FSLogix storage and permissions.
5. Onboard monitoring, diagnostics, and alerting.

### Phase 2: Pilot Migration (T-5 to T-3 days)
1. Migrate pilot users (5-10% representative sample).
2. Execute app, print, collaboration, and profile persistence tests.
3. Collect KPI baseline: logon time, app launch time, disconnect rate.
4. Resolve defects and update known errors.
5. Obtain pilot sign-off.

### Phase 3: Wave Migration (Go-Live Window)
1. Migrate users in defined waves by business function.
2. Use hypercare bridge during each wave (DWP + identity + network + app owners).
3. Track wave KPIs and incident trends in real time.
4. Pause/continue decisions made at wave gate checkpoints.

### Phase 4: Stabilization and Handover (T+1 to T+5 days)
1. Confirm post-migration SLA performance.
2. Decommission or downscale legacy VDI assets as approved.
3. Complete documentation, handover, and lessons learned.
4. Close change and obtain service owner acceptance.

---

## 4) Readiness Check (Go/No-Go Gate)

Use this gate in CAB or pre-go-live review. A "No" in any critical item is a No-Go.

### 4.1 Critical Go/No-Go Items
- [ ] Identity sign-in and MFA path validated for pilot and production users.
- [ ] Session host health green across target pool.
- [ ] FSLogix profile create/read/write tested successfully.
- [ ] Core business apps validated by application owners.
- [ ] Monitoring and alerting active with on-call ownership.
- [ ] Rollback path tested and executable within agreed RTO.
- [ ] Service desk readiness confirmed (KBs, scripts, triage matrix).

### 4.2 Operational Readiness Items
- [ ] Capacity headroom >= 20% for peak session concurrency.
- [ ] Average interactive logon time within target threshold.
- [ ] Disconnect and reconnect behavior validated under load.
- [ ] Printer and collaboration tools working for pilot personas.
- [ ] End-user communication and support channels active.

### 4.3 Decision Record
- Decision: [ ] Go  [ ] No-Go  
- Approved by (CAB/Service Owner): ____________________  
- Date/Time: ____________________  
- Conditions/Actions: __________________________________

---

## 5) Suggested Azure CLI Validation Commands

Run from an authenticated Azure CLI session with correct subscription context.

```powershell
# Set subscription context
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"

# List host pools
az desktopvirtualization hostpool list --resource-group <RG_NAME> --output table

# List session hosts in a host pool
az desktopvirtualization session-host list \
  --resource-group <RG_NAME> \
  --host-pool-name <HOSTPOOL_NAME> \
  --output table

# List workspaces
az desktopvirtualization workspace list --resource-group <RG_NAME> --output table

# List application groups
az desktopvirtualization applicationgroup list --resource-group <RG_NAME> --output table

# Check VM power states for session hosts (example)
az vm list -g <RG_NAME> -d --query "[].{Name:name,Power:powerState,PrivateIP:privateIps}" -o table

# Validate diagnostic settings on a resource
az monitor diagnostic-settings list \
  --resource <RESOURCE_ID> \
  --output table
```

---

## 6) Risks and Mitigations

- Risk: Sign-in failures due to CA/policy mismatch.  
  Mitigation: Pre-validate with pilot identities and emergency access account.

- Risk: Slow logons from profile container issues.  
  Mitigation: Validate FSLogix permissions, storage throughput, and exclusions.

- Risk: App incompatibility on Windows 11 multi-session.  
  Mitigation: Test matrix by persona before wave rollout.

- Risk: Network-induced disconnects.  
  Mitigation: Baseline latency/jitter and enforce QoS/routing checks.

---

## 7) Hypercare Success Criteria (First 5 Business Days)

- [ ] P1 incidents: 0 unresolved beyond SLA.
- [ ] AVD sign-in success rate meets target.
- [ ] User-reported severe performance issues below agreed threshold.
- [ ] All major known errors documented with workaround/owner.
- [ ] Daily health report shared to stakeholders.

---

## 8) Sign-Off

Prepared by: ____________________  
Reviewed by: ____________________  
Approved by: ____________________  
Date: ____________________
