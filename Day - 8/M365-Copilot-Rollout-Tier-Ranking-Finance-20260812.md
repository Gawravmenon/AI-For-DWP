# M365 Copilot Rollout — Item Tier Ranking
**Department:** Finance (~200 users)  
**Date:** 2026-08-12  
**Source checklist:** M365-Copilot-Readiness-Checklist-Finance-20260812.md  
**Data sensitivity:** HIGH — payroll, board packs, M&A documents, client financial data

---

## Why This Document Exists

Completing every checklist item before rollout is ideal but rarely practical. This document ranks each item by **risk consequence of skipping**, not by technical effort. For a Finance department with unaudited 2019 permissions and high-sensitivity data, the risk profile is materially different from a standard departmental rollout — that difference is reflected in the MUST tier.

---

## Tier 1 — MUST Complete Before Rollout (Blocking)

> These items must be fully resolved and signed off before a single Copilot licence is assigned. Skipping any of them creates an immediate data exposure, compliance, or security risk that Copilot's AI capabilities will amplify.

| Ref | Item | Section |
|-----|------|---------|
| 3A.1 | Run SharePoint site permission reports for all Finance-owned sites — export and review | §3A |
| 3A.2 | Enumerate unique vs inherited permissions across all Finance libraries using Assessment Tool or PnP PowerShell | §3A |
| 3A.3 | Identify and remove all "Everyone", "Everyone except external users", and "All Company" access from Finance sites | §3A |
| 3A.4 | Revoke all anonymous (Anyone) links within Finance sites | §3A |
| 3A.5 | Identify all non-Finance users/groups with inherited access from 2019 migration — validate or remove each | §3A |
| 3A.6 | Review OneDrive for all Finance users — identify externally shared or broadly linked files | §3A |
| 3A.7 | Document permissions audit findings and obtain DPO/IG sign-off before remediation | §3A |
| 3B.1 | Break inheritance on high-sensitivity libraries (payroll, board packs, M&A, client financials) and apply explicit role-based permissions | §3B |
| 3B.2 | Apply least-privilege: restrict payroll to Payroll sub-group only; restrict M&A and board packs to named individuals only | §3B |
| 3B.3 | Remove all stale access grants from 2019 migration — document each removal | §3B |
| 3B.4 | Disable "Anyone" links at SharePoint Admin Centre level for Finance sites | §3B |
| 3B.6 | Conduct final permissions validation and obtain written sign-off | §3B |
| 4.1 | Confirm Purview sensitivity labels are published and available to Finance users | §4 |
| 4.2 | Define and agree Finance label taxonomy (Internal → Highly Confidential – Restricted) | §4 |
| 4.3 | Apply `Highly Confidential – Restricted` to payroll, M&A, and board pack libraries — enforce encryption | §4 |
| 4.4 | Apply `Confidential` / `Highly Confidential` labels to general Finance SharePoint and OneDrive content | §4 |
| 4.8 | Obtain DPO/IG sign-off that labelling baseline is sufficient | §4 |
| 5.1 | Confirm all 200 Finance users have MFA enrolled — remediate any gaps | §5 |
| 5.3 | Confirm no Finance users are excluded from Conditional Access policies | §5 |
| 5.4 | Confirm Conditional Access requires compliant device + MFA for M365 access for Finance users | §5 |
| 6.1 | Confirm DLP policies are scoped to Finance users across SharePoint, OneDrive, Teams, Exchange | §6 |
| 6.5 | Confirm the organisation's AI usage policy covers Copilot and has been reviewed by Legal/Compliance | §6 |
| 1.1 | Confirm all ~200 Finance users have active M365 E5 licences assigned | §1 |
| 1.3 | Do not assign Copilot licences until gates 1 and 2 (Sections 3 and 4) are signed off | §1 |

---

## Tier 2 — SHOULD Complete Before Rollout (High Risk if Skipped)

> These items do not block Day 1 technically, but skipping them leaves meaningful gaps in security posture, auditability, or user safety. They should be completed in the days immediately before or on the day licences are assigned.

| Ref | Item | Section |
|-----|------|---------|
| 3B.5 | Enable SharePoint Advanced Management (SAM) data access governance reports — alert on oversharing events | §3B |
| 4.5 | Enable auto-labelling policies in Purview for Finance sensitive information types | §4 |
| 4.6 | Enable default labelling for SharePoint document libraries — minimum `Confidential` for Finance uploads | §4 |
| 4.7 | Pilot test: confirm Copilot honours label-based access restrictions for `Highly Confidential – Restricted` content | §4 |
| 5.2 | Confirm MFA method is phishing-resistant (FIDO2 / WHfB / Authenticator number matching) — no SMS OTP for Finance | §5 |
| 5.5 | Confirm no Finance user accounts carry persistent admin roles that would broaden Copilot's effective data access | §5 |
| 5.6 | Identify and exclude service/shared accounts from Copilot licence assignment | §5 |
| 6.2 | Extend DLP rules to cover Copilot-generated outputs and Copilot pages | §6 |
| 6.3 | Enable Purview Audit (Premium) logging for Finance users — confirm Copilot interaction logs are retained | §6 |
| 6.4 | Confirm Copilot interaction audit retention policy is defined — minimum 180 days | §6 |
| 7.1 | Send pre-launch communication to Finance users — what Copilot is, what data it can access | §7 |
| 7.2 | Communication must include clear statement that users should not share Copilot outputs containing sensitive data outside approved channels | §7 |
| 7.3 | Deliver mandatory 30-minute awareness session before licences go live | §7 |
| 1.2 | Confirm Copilot add-on SKU is available in the tenant (Billing → Licences) | §1 |
| 1.4 | Identify and document shared/service accounts that should be excluded from Copilot assignment | §1 |
| 2.1 | Confirm all Finance endpoints are on M365 Apps Current Channel build 16.0.16227 or later | §2 |
| 2.3 | Move non-compliant devices from Semi-Annual Channel to Current Channel before rollout | §2 |
| 2.4 | Confirm Teams desktop client is at minimum version 23306.3314.2555.9628 | §2 |

---

## Tier 3 — CAN Complete During or After Rollout (Lower Risk)

> These items improve operational hygiene, monitoring, or user experience but do not expose data or create security gaps if deferred by a few weeks. Track them as post-rollout actions with owners and target dates.

| Ref | Item | Section |
|-----|------|---------|
| 1.5 | Create dedicated Entra ID security group `SG-Copilot-Finance` for clean licence management and rollback | §1 |
| 2.2 | Run Intune device compliance report filtered to Finance group — document any deferred update devices | §2 |
| 2.5 | Confirm Edge or supported browser is current on all Finance endpoints | §2 |
| 7.4 | Publish Finance-specific Copilot acceptable use guidance to intranet | §7 |
| 7.5 | Identify 5–10 Finance Copilot champions for peer support and feedback | §7 |
| 7.6 | Define a feedback and incident reporting route for unexpected Copilot content | §7 |

---

## Why the Permissions & Oversharing Audit Is MUST Tier — Finance-Specific Justification

Licensing verification (Section 1) and client version checks (Section 2) are **technically simpler and faster** to complete. It would be reasonable to assume they should be the first gates. They are not the highest-risk items for this department. Here is why the permissions audit outranks them.

### 1. Copilot Is an Access Multiplier, Not a New Permission System

Copilot does not grant access to anything a user cannot already reach. What it does is **dramatically reduce the effort and expertise required to surface that content**. A Finance analyst who technically has inherited read access to a payroll SharePoint library — because of a permission set carried forward from a 2019 migration and never cleaned up — may never have known that access existed and may never have found that data manually. With Copilot, a single natural language prompt like *"summarise this month's payroll changes"* could return that content instantly.

The 2019 migration inheritance means this scenario is not theoretical for this department. It is the default state of the environment.

### 2. The Data at Risk Is Categorically Different from a Standard Rollout

Most Copilot rollout guides treat oversharing as a hygiene item. For Finance departments, the stakes are fundamentally higher:

- **Payroll data** — personal financial information for employees. Exposure constitutes a data breach with mandatory reporting obligations under UK GDPR / DPA 2018.
- **M&A documents** — exposure before deal completion can constitute a market disclosure violation. Financial services regulators treat this as a serious compliance failure.
- **Board packs** — contain material non-public information (MNPI). Broad access to MNPI via an AI tool raises insider dealing risk.
- **Client financial data** — subject to FCA conduct rules and potentially contractual confidentiality obligations. Breach carries regulatory and reputational consequences.

None of these risks exist in the same form if Copilot is not assigned. Assigning licences before auditing permissions converts latent access risk into an active AI-assisted exposure surface.

### 3. Licensing and Client Version Failures Are Recoverable Immediately

If Copilot licences are assigned before client version checks are complete, the worst outcome is that some users see a degraded or non-functional Copilot experience. The fix is a software update. There is no data exposure. No breach notification. No regulatory consequence.

If Copilot licences are assigned before the permissions audit is complete and a user surfaces payroll or M&A data they should not have seen, the harm is already done. A permissions fix after the fact does not undo the exposure.

### 4. The 2019 Migration Creates a Specific, Unquantified Risk

Most organisations with modern SharePoint estates have some degree of oversharing. This department has a **known, unquantified, seven-year-old permissions inheritance** that has never been reviewed. The scope of the problem is unknown until the audit in Section 3A is complete. It is not safe to assume the risk is small. Until 3A.2 has been run and the results reviewed, the actual blast radius of a Copilot rollout for these 200 users is unknown.

That uncertainty alone is sufficient reason to treat the audit as a hard gate rather than a parallel workstream.

### 5. Summary

| Factor | Licensing / Client Version | Permissions Audit |
|--------|---------------------------|-------------------|
| Failure consequence | Degraded UX, no data risk | Active data exposure, potential breach |
| Reversibility | Immediate (licence/update) | Cannot un-expose data already surfaced |
| Regulatory risk if skipped | None | High (GDPR, FCA, MNPI) |
| Scope known before starting | Yes — 200 users, known SKUs | No — 7 years of inherited permissions |
| Time to remediate if issues found | Hours to days | Days to weeks |

Licensing and client version checks should run **in parallel** with the permissions audit to save time. They should not be treated as the primary gate, and the permissions audit must not be deferred until after they are complete.

---

*This ranking should be reviewed with the Finance department head, DPO, and Information Governance lead before rollout planning is finalised.*
