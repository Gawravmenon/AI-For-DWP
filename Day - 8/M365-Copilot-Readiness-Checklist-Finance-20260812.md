# M365 Copilot Readiness Checklist — Finance Department
**Date:** 2026-08-12  
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineer  
**Data sensitivity:** HIGH — payroll, board packs, M&A documents, client financial data  
**Licensing status:** M365 E5 confirmed, Copilot add-on not yet assigned

---

> **⚠ READ BEFORE PROCEEDING**  
> SharePoint permissions for this department were inherited from a 2019 migration and have **never been fully audited**. Copilot surfaces data based on what a user can already access — it does not introduce new permissions, but it **dramatically lowers the effort required to reach data a user technically has access to**. In a Finance department holding payroll, M&A, and board-level data, **unresolved oversharing is a critical risk that must be remediated before Copilot licences are assigned**. Sections 3 and 4 are the highest-priority gates. Do not proceed to licence assignment until both are complete and signed off.

---

## Section 1 — Licensing Prerequisites

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 1.1 | Confirm all ~200 Finance users have an active M365 E5 licence assigned in Entra ID admin centre | Licence Admin | ☐ |
| 1.2 | Confirm Microsoft 365 Copilot add-on (SKU: Microsoft Copilot for Microsoft 365) is available in the tenant — check via M365 Admin Centre → Billing → Licences | Licence Admin | ☐ |
| 1.3 | Do **not** assign Copilot licences until Sections 3 and 4 are fully signed off | Licence Admin | ☐ |
| 1.4 | Identify and document any shared/service accounts or mailboxes in the Finance group that should be excluded from Copilot assignment | Licence Admin | ☐ |
| 1.5 | Plan licence assignment via a dedicated Entra ID security group (e.g. `SG-Copilot-Finance`) to enable clean auditing and rollback | Licence Admin | ☐ |

---

## Section 2 — Microsoft 365 Apps Client Version

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 2.1 | Confirm all Finance endpoints are running **Microsoft 365 Apps for Enterprise, Current Channel, build 16.0.16227 or later** (minimum required for Copilot features) | Endpoint Team | ☐ |
| 2.2 | Run an Intune device compliance report filtered to the Finance group — identify any devices on Semi-Annual Channel or deferred updates | Endpoint Team | ☐ |
| 2.3 | Move any non-compliant devices to Current Channel via Microsoft 365 Apps admin centre or Intune policy before proceeding | Endpoint Team | ☐ |
| 2.4 | Confirm Microsoft Teams desktop client is up to date (Teams version 23306.3314.2555.9628 or later) | Endpoint Team | ☐ |
| 2.5 | Confirm Edge or supported browser version is current on all Finance endpoints for Copilot in web/browser surfaces | Endpoint Team | ☐ |

---

## ⚠ Section 3 — SharePoint & OneDrive Permissions Audit [HIGHEST PRIORITY — GATE]

> **This section is a hard gate. Copilot licence assignment must not proceed until all items below are complete and a sign-off is recorded.**  
> Copilot will generate answers by reaching across all SharePoint sites and OneDrive locations a user can access. Inherited permissions from 2019 mean users may have broad, unintended access to payroll data, M&A documents, and board packs. This must be resolved first.

### 3A — Permissions Discovery & Audit

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 3A.1 | Run SharePoint site permission reports for all Finance-owned sites via SharePoint Admin Centre → Active Sites → Export — identify all sites with broadly shared or inherited permissions | SharePoint Admin | ☐ |
| 3A.2 | Use **Microsoft 365 Assessment Tool** (or SharePoint PnP PowerShell `Get-PnPSitePermissions`) to enumerate unique vs inherited permissions across all Finance libraries | SharePoint Admin | ☐ |
| 3A.3 | Identify all SharePoint sites/libraries/folders where **"Everyone"**, **"Everyone except external users"**, or **"All Company"** sharing is in effect — these must be removed before Copilot is enabled | SharePoint Admin | ☐ |
| 3A.4 | Identify all items shared via **anonymous (Anyone) links** within Finance sites — revoke all anonymous links | SharePoint Admin | ☐ |
| 3A.5 | Produce a full list of non-Finance users or groups who have access to Finance SharePoint sites inherited from the 2019 migration — validate each access grant is still required | SharePoint Admin | ☐ |
| 3A.6 | Review OneDrive for Business of all Finance users — identify files shared externally or with broad internal links | SharePoint Admin | ☐ |
| 3A.7 | Document findings in a Permissions Audit Report and obtain sign-off from Finance department head and DPO/Information Governance before remediation begins | IG / DPO | ☐ |

### 3B — Permissions Remediation

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 3B.1 | Break inheritance on all high-sensitivity libraries (payroll, board packs, M&A, client financials) and apply explicit, role-based permissions — do not rely on inherited site-level permissions | SharePoint Admin | ☐ |
| 3B.2 | Implement least-privilege: restrict payroll data to HR/Finance Payroll sub-group only; restrict M&A and board packs to named individuals only (not broad Finance group) | SharePoint Admin | ☐ |
| 3B.3 | Remove all stale access grants identified in 3A.5 — document each removal with justification | SharePoint Admin | ☐ |
| 3B.4 | Replace broad sharing links with **People in your organisation** or **Specific people** links only — disable **Anyone** links at the SharePoint Admin Centre level for Finance sites | SharePoint Admin | ☐ |
| 3B.5 | Enable **SharePoint Advanced Management (SAM)** data access governance reports if licensed (included in M365 E5) — configure to alert on oversharing events going forward | SharePoint Admin | ☐ |
| 3B.6 | Conduct a final permissions validation pass after remediation and obtain written sign-off before proceeding to Section 4 | SharePoint Admin / IG | ☐ |

---

## ⚠ Section 4 — Sensitivity Labelling [HIGHEST PRIORITY — GATE]

> **This section is also a gate.** Copilot respects Microsoft Purview sensitivity labels and will honour label-based access restrictions. Without labels in place on high-sensitivity Finance content, Copilot has no policy-enforced barrier between a user and data they should not be surfacing in AI-generated responses.

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 4.1 | Confirm Microsoft Purview sensitivity labels are published and available to Finance users in the tenant (M365 E5 includes Purview P2) | Security / Compliance | ☐ |
| 4.2 | Define and agree a label taxonomy appropriate for Finance data, at minimum: `Internal`, `Confidential`, `Highly Confidential`, `Highly Confidential – Restricted` (for payroll/M&A/board packs) | Security / IG | ☐ |
| 4.3 | Apply `Highly Confidential – Restricted` labels to all payroll, M&A, and board pack SharePoint libraries — configure label to enforce encryption and restrict access to named group only | Security / Compliance | ☐ |
| 4.4 | Apply `Confidential` or `Highly Confidential` labels to general Finance SharePoint sites and OneDrive content | Security / Compliance | ☐ |
| 4.5 | Enable **auto-labelling policies** in Purview for Finance-related sensitive information types (e.g. payroll numbers, financial account numbers) to catch unlabelled content | Security / Compliance | ☐ |
| 4.6 | Enable **default labelling** for SharePoint document libraries — set a minimum default of `Confidential` for all Finance library uploads | SharePoint Admin | ☐ |
| 4.7 | Confirm Copilot will honour label-based access restrictions — test with a pilot user attempting to surface `Highly Confidential – Restricted` content they are not authorised for | Security / Pilot Lead | ☐ |
| 4.8 | Obtain sign-off from DPO/IG that labelling baseline is sufficient before Copilot licences are assigned | IG / DPO | ☐ |

---

## Section 5 — Identity & MFA Readiness

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 5.1 | Confirm all 200 Finance users have MFA enrolled — run Entra ID MFA registration report and chase any gaps | Identity / Helpdesk | ☐ |
| 5.2 | Confirm MFA method is phishing-resistant where possible (FIDO2 / Windows Hello for Business / Authenticator number matching) — SMS OTP is not sufficient for high-sensitivity users | Identity | ☐ |
| 5.3 | Confirm no Finance users are excluded from Conditional Access policies — check for named exclusions or legacy auth exceptions | Identity | ☐ |
| 5.4 | Confirm Conditional Access policy requires compliant device + MFA for Microsoft 365 app access for all Finance users | Identity | ☐ |
| 5.5 | Confirm no Finance user accounts have persistent admin roles that could broaden Copilot's effective data access | Identity | ☐ |
| 5.6 | Review any service accounts or shared accounts in the Finance group — ensure these are excluded from Copilot licence assignment | Identity | ☐ |

---

## Section 6 — Data Loss Prevention & Compliance

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 6.1 | Confirm DLP policies are in place and scoped to Finance users covering SharePoint, OneDrive, Teams, and Exchange for sensitive financial data types | Security / Compliance | ☐ |
| 6.2 | Review and extend existing DLP rules to cover Copilot-generated outputs and Copilot pages where applicable | Security / Compliance | ☐ |
| 6.3 | Enable **Microsoft Purview Audit (Premium)** logging for Finance users (included in E5) — ensure Copilot interaction logs are retained per your retention policy | Security / Compliance | ☐ |
| 6.4 | Confirm a Copilot interaction audit retention policy is defined — minimum recommendation is 180 days for a regulated Finance environment | Compliance | ☐ |
| 6.5 | Confirm the organisation's AI usage policy covers Copilot and has been reviewed by Legal/Compliance for financial services obligations | Legal / Compliance | ☐ |

---

## Section 7 — End-User Comms & Enablement

| # | Check | Owner | Status |
|---|-------|-------|--------|
| 7.1 | Draft and send a pre-launch communication to Finance users explaining what Copilot is, what data it can access, and what it cannot do — set accurate expectations | Comms / Change | ☐ |
| 7.2 | Include a clear statement that Copilot only surfaces data the user already has access to — but emphasise users should not share Copilot-generated outputs containing sensitive data outside approved channels | Comms / Change | ☐ |
| 7.3 | Provide a mandatory 30-minute awareness session covering responsible use, sensitivity label expectations, and what to do if Copilot surfaces unexpected content | L&D / Change | ☐ |
| 7.4 | Publish a Finance-specific Copilot acceptable use guidance note to the intranet before licences go live | Comms | ☐ |
| 7.5 | Identify 5–10 Finance power users as Copilot champions for peer support and feedback collection post-launch | Change / Finance Lead | ☐ |
| 7.6 | Define a feedback and incident reporting route for Finance users — e.g. what to do if Copilot returns content they should not have seen | Helpdesk / Security | ☐ |

---

## Sign-Off & Go / No-Go Gate

| Gate | Requirement | Sign-off | Date |
|------|-------------|----------|------|
| **Gate 1** | Section 3 (Permissions Audit & Remediation) fully complete | SharePoint Admin + Finance Head + DPO | |
| **Gate 2** | Section 4 (Sensitivity Labelling) fully complete | Security Lead + DPO | |
| **Gate 3** | Section 5 (Identity & MFA) all items green | Identity Lead | |
| **Gate 4** | Section 6 (DLP & Compliance) all items green | Compliance Lead | |
| **Gate 5** | Section 7 (End-user comms) items 7.1–7.4 complete | Change Lead | |
| **GO** | All gates signed off — Copilot licences may be assigned to `SG-Copilot-Finance` | IT Manager / CISO | |

---

*This checklist should be reviewed against current Microsoft documentation before use. M365 feature availability and minimum version requirements are subject to change.*
