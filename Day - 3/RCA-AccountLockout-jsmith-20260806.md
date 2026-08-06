# Root Cause Analysis — Account Lockout
**Incident Reference:** INC-20260806-JSMITH  
**Date of Incident:** 2026-08-06  
**Time Window:** 08:02 – 08:24  
**Affected User:** jsmith (FINBRIDGE domain)  
**Affected Endpoint:** DESKTOP-FB001  
**Resolved By:** FINBRIDGE\helpdesk-admin  
**Document Author:** DWP Analyst  
**Date of RCA:** 2026-08-06  

---

## 1. Incident Summary

User `jsmith` was locked out of their workstation at `DESKTOP-FB001` following two consecutive failed interactive logon attempts. The domain Account Lockout Policy automatically disabled the account after the threshold was reached. The user was unable to self-recover and required helpdesk intervention to re-enable the account, resulting in approximately 16 minutes of lost access.

---

## 2. Timeline of Events

| Time     | Event ID | Type          | Description |
|----------|----------|---------------|-------------|
| 08:02:14 | 4625     | Audit Failure | jsmith attempts interactive logon at DESKTOP-FB001 — fails: Unknown username or bad password |
| 08:04:22 | 4625     | Audit Failure | Second interactive logon attempt — fails: Unknown username or bad password |
| 08:06:01 | 4740     | Audit Failure | Account locked out by domain policy after threshold exceeded (source: DESKTOP-FB001) |
| 08:07:45 | 4625     | Audit Failure | jsmith attempts workstation unlock (logon type 7) — fails: Account locked out |
| 08:22:10 | 4722     | Audit Success | Account re-enabled by FINBRIDGE\helpdesk-admin |
| 08:23:44 | 4624     | Audit Success | jsmith successfully logs on interactively |

**Total Duration of Lockout:** ~16 minutes (08:06 to 08:22)

---

## 3. Impact Assessment

| Category         | Detail |
|------------------|--------|
| User affected    | 1 (jsmith) |
| Service affected | Desktop access / all locally authenticated applications |
| Duration         | ~16 minutes |
| Business impact  | Low — single user, resolved same morning; no data loss or system damage |
| Helpdesk effort  | ~1 admin action (account unlock via FINBRIDGE\helpdesk-admin) |

---

## 4. Evidence from Security Event Logs

- **Event 4625 (×2):** Both failures cite `"Unknown username or bad password"` with `Logon type: 2` (interactive) from `DESKTOP-FB001`. This eliminates service accounts, scheduled tasks, or remote sessions as the source — the failures originated at the physical console.
- **Event 4740:** Lockout triggered from the same machine (`DESKTOP-FB001`), confirming the domain lockout threshold (2 attempts) was met by the two 4625 events above.
- **Event 4625 (08:07):** Failure reason shifts to `"Account locked out"` with `Logon type: 7` (workstation unlock). This indicates the user attempted to re-enter credentials after the lockout was already in effect, and is consistent with the user being unaware their account had been locked rather than their password being wrong.
- **Event 4722:** Account enabled by `helpdesk-admin` ~16 minutes after lockout — no self-service recovery was available or used.
- **Event 4624:** Successful logon 94 seconds after admin unlock, with no further 4625 events — the user knew their correct password once the account was re-enabled.

**Key inference:** The user held the correct password by the time they logged in successfully. The two failures were transient input errors, not a forgotten or expired password.

---

## 5. Root Cause — 5 Why Analysis

### Problem Statement
> jsmith was locked out of DESKTOP-FB001 at 08:06 on 2026-08-06, losing desktop access for ~16 minutes and requiring helpdesk intervention to recover.

---

**Why 1 — Why was the account locked out?**  
The domain Account Lockout Policy locked the account because the maximum number of failed logon attempts (threshold: 2) was reached within the observation window.

**Why 2 — Why were there 2 failed logon attempts?**  
jsmith entered an incorrect password twice at the physical console of DESKTOP-FB001 during interactive logon (logon type 2). The successful logon at 08:23 with no further failures confirms the password was not forgotten — the failures were input errors.

**Why 3 — Why did jsmith enter the password incorrectly?**  
Most likely causes (in order of probability):
1. **Caps Lock was active** — a common cause of case-sensitive password failures at the start of a working day, particularly on a locked/sleep-resumed workstation.
2. **Recently changed password** — jsmith may have reset their password and was entering the old credential from muscle memory.
3. **Keyboard input error** — typo on a complex password with special characters.

The 2-minute gap between failures (08:02 → 08:04) suggests the user paused and tried again deliberately rather than rapid-fire attempts, which is more consistent with Caps Lock or a misremembered password than a forgotten one.

**Why 4 — Why did two failures immediately trigger a lockout?**  
The domain Account Lockout Threshold is configured to **2 invalid attempts**. This is below industry best practice (NCSC and NIST both recommend thresholds of 5–10 attempts) and creates a high sensitivity to accidental lockouts, particularly at start of day when users are resuming sessions.

**Why 5 — Why is the lockout threshold set to 2?**  
The current Group Policy setting was likely configured to meet a previous security requirement or inherited from an older baseline. There is no evidence it has been reviewed against current NCSC guidance or the operational impact of frequent accidental lockouts. No self-service password reset (SSPR) mechanism was available, meaning every lockout requires direct helpdesk intervention.

---

## 6. Root Cause Statement

The **direct root cause** is jsmith entering an incorrect password twice (most probably due to Caps Lock being active or a recently changed password), triggering an automated domain lockout.

The **contributing root cause** is a domain Account Lockout Threshold of 2 attempts, which provides no tolerance for normal human input errors and generates avoidable helpdesk tickets.

The **systemic root cause** is the absence of a self-service password reset (SSPR) capability, meaning even a routine accidental lockout requires escalation to the helpdesk and causes business disruption disproportionate to the triggering event.

---

## 7. Recommendations

| Priority | Recommendation | Owner | Rationale |
|----------|---------------|-------|-----------|
| High | Review and raise the Account Lockout Threshold to a minimum of **5 attempts** in line with NCSC guidance | IT Security / AD Team | Reduces accidental lockouts while maintaining brute-force protection |
| High | Deploy **Self-Service Password Reset (SSPR)** (e.g., via Entra ID / Azure AD SSPR) | IT Architecture | Eliminates helpdesk dependency for routine lockouts |
| Medium | Enable **Account Lockout Duration** auto-unlock (e.g., 15–30 minutes) as interim measure | AD Team | Reduces helpdesk volume before SSPR is available |
| Medium | Investigate whether `jsmith`'s password was recently changed and whether a **password change notification** was clearly communicated | Service Desk | Addresses Why 3 above |
| Low | Add a **Caps Lock indicator** reminder to the Windows logon screen via Group Policy custom text | Desktop Engineering | Reduces input errors at the console |

---

## 8. Lessons Learned

- A lockout threshold of 2 is operationally fragile — a single Caps Lock key causes an immediate incident requiring human intervention.
- The 16-minute resolution time, while reasonable, represents lost productivity and helpdesk cost for a recoverable user error.
- The absence of SSPR means the helpdesk is a mandatory dependency for a class of incidents that users in comparable organisations resolve themselves in under 2 minutes.

---

## 9. Sign-off

| Role | Name | Date |
|------|------|------|
| DWP Analyst | | |
| Service Desk Lead | | |
| IT Security | | |
