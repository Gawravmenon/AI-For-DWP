# Root Cause Analysis — Finance Team Cannot Access Shared Drives
**Incident Reference:** FIN-SHAREDDRIVE-20260813  
**Date of Incident:** 2026-08-13  
**Time Window:** 08:05 - 11:20  
**Affected Service:** Finance department shared drive access (`S:` Finance, `P:` Finance Projects)  
**Affected Devices:** Windows 11 migrated Finance endpoints  
**Users Affected:** Multiple Finance users on Floor 2 and Finance AVD users  
**Resolved By:** Updated logon processing to wait for network readiness before drive mapping  
**Document Author:** DWP Analyst  
**Date of RCA:** 2026-08-13  

---

## 1. Incident Summary

Finance users reported that shared drives used for daily processing were missing or inaccessible after sign-in. Affected users either did not see mapped drives `S:` and `P:` in File Explorer or received access failures when opening them. The issue was limited to Windows 11 migrated devices and was most visible at first sign-in after boot, reconnect, or network change.

Investigation showed that drive mapping was being processed before the device had completed network initialization and domain connectivity at logon. As a result, the Group Policy Preference or logon script that maps Finance drives ran too early and failed. Once policy behavior was changed to wait for the network at computer startup and user logon, the mappings returned consistently and users confirmed restored access.

---

## 2. Timeline of Events

| Time | Source | Event | Description |
|------|--------|-------|-------------|
| 08:05 | Service Desk ticket queue | User report | Finance users report `S:` and `P:` drives missing after sign-in |
| 08:12 | Service Desk validation | Symptom confirmed | Affected Windows 11 device shows no `S:` or `P:` mapping in File Explorer |
| 08:19 | Command prompt / PowerShell | `gpresult` review | User policy confirms drive mapping policy is assigned to Finance users |
| 08:27 | System event log | Network timing pattern | Boot and sign-in sequence shows user logon completed before stable domain network availability |
| 08:34 | Group Policy operational log | Policy processing review | Drive mapping extension processed during early logon window with failed target availability |
| 08:46 | Comparative check | Scope narrowed | Non-migrated Windows 10 device maps drives correctly under same user account |
| 09:05 | Engineering review | Root cause agreed | Windows 11 fast sign-in path is allowing mapping to run before network readiness |
| 09:22 | Controlled remediation | Policy change | Enabled wait-for-network behavior at startup and logon for affected policy scope |
| 10:40 | Validation test | Retest successful | Test user signs in after reboot and both `S:` and `P:` map correctly |
| 11:20 | User confirmation | Service restored | Finance users confirm restored access to shared drives |

---

## 3. Impact Assessment

| Category | Detail |
|----------|--------|
| Service affected | Finance shared drive access |
| Users affected | Multiple Finance users on migrated Windows 11 devices |
| Nature of impact | Missing mapped drives, failed access to team files, interruption to daily processing |
| Scope | Device and sign-in timing pattern, not NTFS permission removal or file server outage |
| Business impact | High during business hours because Finance users could not access operational templates, reconciliations, and shared working files |

---

## 4. Supporting Evidence

- Affected users were consistently in the Finance group and relied on mapped drives `S:` and `P:` for shared working data.
- The mapping policy remained assigned to the users, which rules out simple policy unassignment or accidental removal.
- The issue was intermittent and heavily tied to first sign-in after restart or reconnect, which is more consistent with timing than permissions.
- The same user accounts could access the shared path after manual retry or after the machine had been online longer, which weakens any explanation based on revoked access.
- Comparison with non-migrated or already-network-stable devices showed the mapping itself and underlying file share were healthy.
- The existing closure note for the same pattern states that post-Windows 11 migration, logon mapping processing occurred before network initialization, causing `S:` and `P:` mappings to fail intermittently.
- After enabling network-wait behavior for startup and sign-in, the drive mappings returned without any change to user group membership or share permissions.

**Key inference:** The failure was caused by policy processing order and network readiness timing at sign-in, not by a file server outage, permission removal, or user-specific corruption.

---

## 5. Root Cause — 5 Why Analysis

### Problem Statement
> Finance users could not access their shared drives because the mapped drive process failed during Windows 11 sign-in.

**Why 1 - Why could users not access the shared drives?**  
Because mapped drives `S:` and `P:` were not created successfully during user logon.

**Why 2 - Why were the mapped drives not created successfully?**  
Because the drive mapping policy or script processed before the endpoint had stable network and domain connectivity to the file server.

**Why 3 - Why was network connectivity not ready when mapping ran?**  
Because the Windows 11 post-migration sign-in flow completed user logon faster than the network initialization sequence required for reliable domain-based mapping.

**Why 4 - Why did that timing issue affect Finance users repeatedly?**  
Because Finance users depend on mapped drives delivered at sign-in, and the policy baseline for migrated endpoints did not force synchronous wait-for-network behavior before user logon policy processing.

**Why 5 - Why was the baseline missing that protection?**  
Because the Windows 11 migration validation process did not include a mandatory mapped-drive sign-in check under real network timing conditions for Finance endpoints.

---

## 6. Root Cause Statement

The **direct root cause** was mapped drive processing occurring before stable network availability at Windows 11 sign-in.

The **contributing root cause** was the migrated endpoint policy baseline not enforcing synchronous wait-for-network behavior before drive mapping.

The **systemic root cause** was incomplete post-migration validation, which did not explicitly test Finance mapped-drive availability immediately after sign-in and reboot.

---

## 7. Resolution

- Confirmed the issue pattern on affected Finance Windows 11 devices.
- Verified the Finance drive mapping policy remained assigned.
- Updated policy behavior so endpoints wait for network readiness at startup and user sign-in.
- Re-tested after reboot and confirmed `S:` and `P:` mapped correctly.
- Users confirmed shared drive access was restored.

---

## 8. Preventive Actions

| Priority | Action | Owner | Purpose |
|----------|--------|-------|---------|
| High | Enable the wait-for-network baseline on all Windows 11 migrated endpoints that depend on mapped drives | Endpoint Engineering | Prevents drive mapping from running before domain connectivity is ready |
| High | Add mapped-drive validation to migration exit criteria for Finance devices | DWP / EUC | Detects sign-in timing failures before business users are impacted |
| High | Review all Group Policy Preference drive mappings used by Finance and confirm retry or reconnect behavior is appropriate | EUC / AD Engineering | Reduces failure rate when network readiness is delayed |
| Medium | Add a service desk check for `gpresult`, `net use`, and network state before escalating | Service Desk | Speeds triage and improves incident quality |
| Medium | Publish a standard runbook for shared drive access failures after Windows 11 migration | DWP Operations | Improves first-time-fix and consistency |

---

## 9. Lessons Learned

- Successful user authentication does not guarantee that domain-dependent resources are ready at sign-in.
- Missing mapped drives after migration should be tested as a timing issue before investigating permissions.
- Finance drive-access incidents need one comparison check against the raw UNC path to separate mapping failure from share outage.
- Post-migration validation should include reboot, sign-in, and immediate access to line-of-business shared paths.

---

## 10. Sign-off

| Role | Name | Date |
|------|------|------|
| DWP Analyst | | |
| Service Desk Lead | | |
| Endpoint Engineering | | |
| EUC / AD Engineering | | |