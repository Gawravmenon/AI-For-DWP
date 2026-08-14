# Hypothesis - Potential Copilot Matter Exposure (Floor 6) - Friday Deployment Assessment

## Scenario anchor
- Conclusion: A potential unauthorized matter exposure was reported after Friday app deployment to the same floor.
- Reasoning: Temporal proximity raises concern, but authorization truth must be established from ACL and audit evidence.

## Ranked likely causes (most to least likely)
1. Conclusion: Pre-existing or migration-induced permission drift is the primary cause; Friday deployment timing is incidental.
   Reasoning: Unexpected access perceptions commonly come from group/ACL inheritance changes during migration and role remapping.

2. Conclusion: Friday app deployment changed connector/index scope or sharing model, broadening what Copilot could retrieve.
   Reasoning: A new document app can alter data graph visibility if connector permissions or index boundaries were misconfigured.

3. Conclusion: User context confusion (wrong account/session/token context) produced a misleading result attribution.
   Reasoning: Newly managed endpoints can expose profile/session edge cases that mimic unauthorized exposure.

4. Conclusion: Report reflects metadata exposure only (title/reference) rather than full content access.
   Reasoning: Users may interpret surfaced metadata as full document access, which changes incident severity.

## Fastest check for each cause
1. Check: Validate reporter's effective ACLs on the exact matter at incident time (direct, group, inherited).
   Why fast: This is the quickest objective truth test for unauthorized access.

2. Check: Review Friday deployment change set for connector scopes, app permissions, and indexing boundaries.
   Why fast: Directly tests whether rollout could have expanded retrieval scope.

3. Check: Confirm signed-in account context, tenant context, and app session identity on the reporting device.
   Why fast: Quickly eliminates identity mix-up scenarios.

4. Check: Reconstruct with evidence whether Copilot returned metadata, snippet, or full content.
   Why fast: Severity and containment decisions depend on this distinction.

## Evidence that confirms Friday deployment as cause
- Conclusion: Deployment is likely causal if scope/permission changes introduced Friday map directly to the exposed matter path.
- Reasoning: Change-linked permission expansion plus matching audit trail indicates causal connection.
- Confirming evidence examples (to confirm):
  - Audit logs show access path through newly enabled connector/scope from Friday rollout.
  - Exposure reproducible only on users in Friday-assigned cohort.
  - Rollback/scope restriction removes exposure behavior.

## Evidence that rules out Friday deployment as cause
- Conclusion: Deployment is likely non-causal if ACL evidence shows pre-existing authorized access or exposure persists independent of rollout settings.
- Reasoning: If authorization state predates rollout or behavior is unchanged by rollback, deployment is not primary cause.
- Rule-out evidence examples (to confirm):
  - Reporter had inherited access before Friday.
  - No connector/scope changes occurred in Friday package configuration.
  - Same behavior occurs in unaffected cohorts with no Friday app assignment.
