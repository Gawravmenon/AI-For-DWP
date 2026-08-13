# Copilot Support Ticket Triage Assessment

Date: 2026-08-12  
Role: DWP Engineer (Copilot ticket triage)

Cause taxonomy used (as requested):
- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault (last resort)

## Results

| ID | Ticket (summary) | Likely cause (ranked, most probable first) | Fastest check (single first check) | Is this actually a Copilot bug? |
|---|---|---|---|---|
| 1 | Finance lead cannot summarize Q3 board pack in SharePoint though they can see it | 1) sensitivity label restriction 2) permissions/access boundary 3) data indexing lag 4) genuine Copilot fault | Check the board pack's sensitivity label and whether policy allows Copilot processing for that label. | **No (likely).** User visibility does not guarantee Copilot can process content; labels/policy commonly block grounding even when the user can open the file. |
| 2 | New hire started yesterday; Copilot in Outlook knows nothing about recent emails | 1) data indexing lag 2) license/client prerequisite issue 3) permissions/access boundary 4) genuine Copilot fault | Verify the account has a Copilot license assigned and active in M365 admin, then allow for initial indexing window. | **No (likely).** Day-1/day-2 accounts often have incomplete index/graph signals; this is usually onboarding/index latency rather than product defect. |
| 3 | HR manager asked Copilot in Word to use sensitive salary review spreadsheet; got "I don't have access" | 1) permissions/access boundary 2) sensitivity label restriction 3) license/client prerequisite issue 4) genuine Copilot fault | Open the spreadsheet with the same signed-in identity used in Word and confirm effective permission (including inherited/share permissions). | **No.** The explicit access denial indicates normal access boundary enforcement, not a Copilot malfunction. |
| 4 | Sales rep in Teams cannot find contract shared via guest link from another org | 1) guest/external sharing limitation 2) permissions/access boundary 3) license/client prerequisite issue 4) genuine Copilot fault | Confirm whether the contract is external-tenant content accessed via guest/B2B link and not ingested as first-party tenant content. | **No (likely).** Cross-tenant guest-shared files commonly do not ground the same way as internal tenant data. |
| 5 | IT admin: Copilot stopped for whole Finance team this morning; worked yesterday | 1) license/client prerequisite issue 2) permissions/access boundary 3) genuine Copilot fault | Check Finance users' Copilot license/service-plan assignment changes since yesterday (group-based licensing, expired trial, disabled service plan). | **Unclear, but usually No.** Team-wide sudden failure is more often licensing/service configuration drift than a core Copilot defect. Escalate as product issue only if licensing/config checks are clean. |
| 6 | Manager says Copilot summarized a file they forgot they had access to | 1) permissions/access boundary 2) data indexing lag 3) genuine Copilot fault | Validate current ACL/effective permissions on the cited folder/file for that user. | **No.** This is consistent with normal behavior: Copilot can use content the user is authorized to access, even if the user forgot that access existed. |
| 7 | Analyst gets generic answers; Copilot seems not to use any internal SharePoint content | 1) permissions/access boundary 2) data indexing lag 3) license/client prerequisite issue 4) genuine Copilot fault | Test one known internal SharePoint file the analyst can open and ask Copilot about that exact file by name/path. | **Unclear, leaning No.** Broad "generic answers" usually points to missing access scope, index freshness, or setup prerequisites before assuming product fault. |
| 8 | Executive assistant: Copilot in Outlook cannot see shared mailbox calendar managed for director | 1) permissions/access boundary 2) license/client prerequisite issue 3) guest/external sharing limitation 4) genuine Copilot fault | Confirm whether Copilot is being asked to act on delegated/shared mailbox calendar data (not the assistant's primary mailbox) and verify delegated access model support in current client scenario. | **No (likely).** Shared/delegated mailbox scenarios frequently have access-model limits versus primary mailbox grounding behavior. |

## Notes for triage stance

- Default posture applied: non-Copilot root causes first.
- "Genuine Copilot fault" is intentionally ranked last in each case.
- Escalate as potential product bug only after the first-pass checks above are clean and reproducible with clear scope.
