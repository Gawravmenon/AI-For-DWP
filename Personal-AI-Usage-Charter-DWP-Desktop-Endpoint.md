# Personal AI Usage Charter (DWP Desktop/Endpoint Engineering, Public AI Assistants)

**Owner:** [Your Name]  
**Role:** DWP Engineer (Desktop/Endpoint)  
**Version/Date:** 1.0 / 04 Aug 2026

## 1) Purpose and Scope
I use public AI assistants to improve speed and quality in endpoint engineering work while protecting DWP data, users, and services. This charter applies to my daily desktop/endpoint activities (build, support, scripting, troubleshooting, documentation) and to all prompts I send to public AI tools.

## 2) Appropriate DWP Tasks for Public LLM Help
I may use public AI for low-risk, non-sensitive assistance such as:
1. Drafting and improving PowerShell, batch, Bash, or Python script structure using placeholder data only.
2. Explaining command behavior, error patterns, registry concepts, event log interpretation, and troubleshooting flow.
3. Creating generic runbooks, checklists, SOP templates, and change-plan wording.
4. Refactoring script readability, adding comments, and proposing safer error handling.
5. Producing test ideas for endpoint changes (pre-checks, rollback checks, post-change validation).
6. Summarizing public vendor documentation (Microsoft, OEM, browser, AV, MDM) without sharing internal config details.
7. Building communication drafts for incident updates that contain no internal identifiers or user data.

## 3) Tasks Not Appropriate for Public LLMs
I will not use public AI for:
1. Any prompt containing DWP internal data, architecture details, network topology, hostnames, tenant specifics, asset IDs, incident timelines, or vulnerability details not already public.
2. Any code, logs, tickets, screenshots, or exports containing end-user PII, secrets, credentials, tokens, keys, or session artifacts.
3. Security-sensitive decisions that require authoritative internal policy interpretation (for example: access control exceptions, incident severity calls, containment decisions).
4. Final approval of production changes, risk acceptance, or CAB justification.
5. Uploading or pasting full internal scripts/configs from production endpoints.
6. AI-driven actions executed directly in production without human validation and controlled rollout.

## 4) Data-Handling Rule (PII and Credentials)
Hard rule: I never enter end-user PII or credentials into a public AI assistant.

This includes, but is not limited to:
1. Names, NI numbers, addresses, phone numbers, email addresses, case references, usernames tied to individuals.
2. Passwords, passphrases, API keys, certificates, private keys, tokens, cookies, connection strings, recovery codes.
3. Raw logs or screenshots containing user/account/device identifiers.

If I need AI help, I must:
1. Redact or synthesize first (replace real values with neutral placeholders).
2. Minimize data to the smallest safe snippet.
3. Sanity-check prompt content before sending.
4. Stop and escalate to internal approved tooling if redaction cannot make data safe.

## 5) Personal Generate-Then-Verify Rule (Scripts and System Changes)
I treat AI output as a draft, never as trusted truth.

Before any endpoint execution or change, I will:
1. Generate: Ask AI for a candidate script/change with assumptions stated.
2. Review: Manually inspect every command, path, scope, and side effect.
3. Verify in safe stages:
   - Static checks (syntax/lint, dependency checks).
   - Test in lab/sandbox VM.
   - Test on non-critical pilot endpoint group.
   - Confirm rollback path works.
4. Control execution:
   - Use least privilege.
   - Prefer read-only/dry-run first.
   - Log actions and outcomes.
5. Validate outcome:
   - Confirm intended fix.
   - Confirm no regression (performance, login, policy, app compatibility, security tooling).
6. Record:
   - Keep a change note with prompt intent, manual edits, test evidence, and approval trail.

No script or system change goes to production from AI output without human verification and staged testing.

## 6) Personal Accountability
I am accountable for every prompt I send and every change I implement. AI assists my engineering judgment; it does not replace policy, security controls, peer review, or formal change governance.
