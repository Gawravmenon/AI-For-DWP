# Triage Summary - Floor 6 Potential Copilot Unauthorized Matter Exposure

## summary (one line)
- Conclusion: A paralegal reported Copilot surfaced a client matter they believe they never had access to, indicating a possible unauthorized information exposure that requires immediate validation.
- Reasoning: The report describes potential access beyond expected permissions, which in Legal context must be treated as credible until disproven.

## Impact (who/how many/ business urgency)
- Who: At least one paralegal report; potential impact may extend to Legal data owners and clients, to confirm.
- How many: Currently one reported incident in the Slack message; broader scope unknown (to confirm).
- Business urgency: Critical, due to potential confidentiality/compliance breach risk in a legal environment.

## Know facts
- Time/source: 09:14 Slack message from IT Ops lead.
- "One paralegal says Copilot pulled up a client matter she swears she's never had access to."
- Floor 6 is Legal, recently moved to Win11 and Intune (provided context).
- New document management app rolled out Friday afternoon to Floor 6.

### Win11/Intune migration hypotheses (to confirm)
- Hypothesis 1: Permission drift occurred during migration (group membership, inherited ACLs, or role mapping changes), and Copilot reflected now-effective access that the user did not expect.
- Hypothesis 2: Friday document management app rollout introduced a connector/indexing scope or sharing configuration change that broadened retrievable matter metadata/content.
- Hypothesis 3: Endpoint/session context issue on a newly managed Win11 device (cached identity/session mix-up) caused confusing result attribution rather than true unauthorized access.

## Missing Information to gather
- Exact prompt, Copilot response text, timestamps, and screenshot/session evidence (to confirm).
- User identity, device identity, and app/context where Copilot response was generated (to confirm).
- Whether the surfaced matter title/content is real, and if it was partial metadata vs full content (to confirm).
- Actual ACL/permissions for the reporting user against the matter in source systems (DMS/M365), to confirm.
- Whether access was newly granted (direct/group/inherited) during migration or app rollout (to confirm).
- Whether Copilot grounding source included cached/local/recent files, shared links, or cross-tenant artifacts (to confirm).
- Any additional similar reports from Floor 6 or elsewhere (to confirm).

## Likely catagory
- Conclusion: Security/Privacy Incident - Potential unauthorized data exposure via AI assistant or underlying permissions drift, to confirm.
- Reasoning: The report references possible access to a client matter outside expected authorization, and in a legal environment even a single credible exposure claim carries immediate confidentiality and compliance risk.

## suggest first diagnostic step
- Conclusion: Start an immediate evidence-preservation and access-validation workflow by capturing prompt/response/time/device evidence, then verifying source-item permissions and audit logs for the reporting user before broad changes.
- Reasoning: Early evidence capture protects forensic integrity and allows objective confirmation of unauthorized exposure versus misunderstanding, which drives the correct incident path.

## What I'd check first and why (urgency order)
1. Preserve evidence from the reporter session (prompt/response/screenshot/time/device) because evidence can be lost quickly and is required for legal/compliance decisions.
2. Validate actual access rights to the referenced matter in the source DMS/M365 ACLs to confirm whether exposure was truly unauthorized.
3. Review relevant audit logs (Copilot/M365/DMS/Entra as available) in the matching timeframe to trace grounding source and access path.
4. If unauthorized exposure is plausible, trigger incident governance path (security + legal + privacy stakeholders) and define immediate containment scope.
5. Check whether Friday rollout changed connectors/permissions/scopes for Floor 6 users to test change-related causality.
