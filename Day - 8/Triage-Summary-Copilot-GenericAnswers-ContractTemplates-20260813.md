# Incident Triage Summary - Copilot Gives Generic Answers on Contract Template Clauses

## Incident Details
- Date: 2026-08-13
- Reporter Role: Contract specialist
- Service: Microsoft 365 Copilot (SharePoint/Word grounding)
- Symptom: Copilot returns vague, generic responses about clauses in contract templates library and appears not to read source documents.

## Impact Assessment
- Scope: Single user reported, possible broader library configuration issue.
- Business Impact: Medium. Slower contract review and drafting quality concerns.
- Data Risk: Low.
- Priority: P3 (single-user but workflow quality degradation).

## Likely Cause (Initial Hypothesis)
- User prompts may be too broad and not anchored to specific files.
- Copilot grounding limited by permissions, indexing lag, or unsupported file formats.
- Template library may contain scanned PDFs/images without extractable text.
- Content may be in locations outside user access, causing fallback to generic output.

## Triage Checks
1. Confirm library URL, sample template files, and formats (.docx/.pdf/scanned).
2. Verify user can open templates directly and has read permissions.
3. Confirm templates are searchable in Microsoft Search/SharePoint.
4. Test prompt quality with explicit file references and clause names.
5. Check whether files are encrypted, labeled, or protected in ways that reduce grounding.
6. Compare behavior in Word Copilot (open document) vs chat prompt without file context.

## Immediate Actions Taken
- Logged as Copilot grounding quality issue.
- Requested 2 to 3 sample prompts, expected answers, and source files.
- Began verification of file type/indexing/access path.

## Next Actions
- Provide prompt guidance using source-anchored queries.
- Convert non-text/scanned templates to searchable text where required.
- Escalate to M365 Copilot support if behavior persists after access/index checks.

## Owner and ETA
- Primary Owner: Service Desk M365 queue
- Dependency Owner: SharePoint Library Owner
- Next Update Due: Within 4 business hours
- Target Resolution: 1 to 2 business days depending on content remediation

## User-Facing Status
- Current status: Investigating whether issue is prompt context, file accessibility, or indexability.
- Workaround: Open a specific template first and ask Copilot clause questions against that active document.