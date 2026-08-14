# RCA - Floor 6 Potential Copilot Matter Exposure (Security Signal)

## Incident summary
- Conclusion: A Legal user reported Copilot surfaced a client matter they believed they never had access to.
- Reasoning: This is a potential authorization and confidentiality signal, not a standard support bug.

## Business impact
- Conclusion: Impact is critical due to potential confidentiality/compliance exposure.
- Reasoning: Even a single credible unauthorized-access signal in Legal context requires incident-grade handling.

## Timeline (known)
- Friday afternoon: New document management app rollout to Floor 6 (known).
- Monday 09:14: Report surfaced via IT Ops Slack message (known).
- Immediate classification: Treated as security/privacy signal requiring evidence preservation (known from Project notes).

## Root cause
- Conclusion: Most likely root cause is permission drift or access model change (migration-era ACL/group inheritance effects), to confirm.
- Reasoning: This pattern is the highest-likelihood explanation for perceived "never had access" outcomes and must be validated against authoritative ACL and audit data.

## Contributing factors
- Friday app deployment may have altered connector/index scope or sharing boundaries (to confirm).
- Recent Win11/Intune migration could have coincided with role/group realignment (to confirm).

## Evidence supporting root cause
- Existing Project analysis classifies this as security signal and rejects "AI weirdness" closure.
- Hypothesis ranking places permission drift ahead of endpoint display/context-only explanations.
- Incident guidance prioritizes ACL truth-check and audit reconstruction before broad remediation.

## Evidence still required to confirm
- Reporter prompt/response/timestamp/device evidence capture (to confirm).
- Effective access at incident time for the user on the exact matter (to confirm).
- Audit path showing how result grounding was authorized/unauthorized (to confirm).

## Evidence that would rule it out
- Verified pre-existing authorized access to the matter before incident window.
- No material connector/scope/permission changes tied to Friday deployment.
- Reproduction shows metadata-only visibility with no unauthorized content access.

## Immediate remediation taken / recommended
- Preserve reporter evidence and relevant audit artifacts immediately.
- Route through Security Incident governance with Legal/Privacy stakeholders.
- Avoid broad configuration changes until forensic minimum dataset is secured.

## Preventive actions
- Tighten change controls around connector scope and permission propagation.
- Add post-migration entitlement verification for sensitive legal matter sets.
- Establish a standard Copilot exposure triage runbook with evidence checklist.

## Current status
- Conclusion: Security signal correctly identified; technical root cause not yet proven and remains under formal validation.
- Reasoning: Correct classification is complete, but causal determination depends on ACL/audit evidence still marked to confirm.
