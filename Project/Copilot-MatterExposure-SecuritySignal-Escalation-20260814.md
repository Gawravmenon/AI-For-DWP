# Copilot Matter Exposure: Correct Classification and Escalation

## What it actually is
- Conclusion: The statement "Copilot pulled up a matter she's never had access to" is a potential unauthorized data exposure signal, not a normal support ticket.
- Reasoning: The core question is authorization integrity and confidentiality risk, which places it in security/privacy incident triage rather than routine endpoint troubleshooting.

## What I would NOT do
- Conclusion: Do not close or downgrade this as "AI weirdness" or user misunderstanding without evidence.
- Reasoning: Dismissing early can destroy investigation fidelity, delay containment, and create legal/compliance exposure if access was truly unauthorized.
- Do not:
  - Close as cosmetic/app bug before validating ACLs and audit trails.
  - Ask the user to retry repeatedly in ways that overwrite volatile evidence.
  - Make broad config changes first that could erase causality signals.

## Two-sentence escalation draft
"We have a credible potential confidentiality incident: a Legal user reports Copilot surfaced a client matter outside expected access, so we are treating this as a security/privacy signal pending validation. Please open Security Incident triage now and preserve evidence (prompt/response, timestamp, user/device context, and relevant access/audit logs) before any remediation changes."
