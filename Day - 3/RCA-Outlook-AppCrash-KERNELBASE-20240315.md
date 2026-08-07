# Root Cause Analysis - Outlook Application Crash Loop
**Incident Reference:** INC-20240315-OUTLOOK-APPCRASH  
**Date of Incident:** 2024-03-15  
**Analysis Window:** 09:13:44 - 09:18:05 (within reported 30-minute impact window)  
**Affected User:** Single endpoint user (name not provided)  
**Affected Endpoint:** Windows 11 endpoint (hostname not provided)  
**Application Affected:** Microsoft Outlook (OUTLOOK.EXE)  
**Document Author:** DWP Analyst  
**Date of RCA:** 2026-08-07

---

## 1. Incident Summary

The user was unable to use Outlook because the process repeatedly crashed shortly after launch. The Application log shows two Outlook application crashes (Event ID 1000), followed by Windows Error Reporting correlation (Event ID 1001), and a .NET Runtime unhandled exception record (Event ID 1026). The repeated crash signature is consistent across entries and points to an access violation condition.

Note on wording: this is an application usability lockout (user locked out of using Outlook), not an account lockout event.

---

## 2. What Each Event ID Records

### Event ID 1000 (Source: Application Error, Level: Error)
Records that an application process crashed. It includes the faulting application, faulting module, exception code, fault offset, process details, and report correlation identifiers.

For this incident, Event 1000 records:
- Faulting application: OUTLOOK.EXE (16.0.17126.20132)
- Faulting module: KERNELBASE.dll (10.0.22621.3155)
- Exception code: 0xc0000005 (access violation)
- Repeatable fault offset: 0x000000000003a4b2

### Event ID 1001 (Source: Windows Error Reporting, Level: Information)
Records the Windows Error Reporting (WER) outcome metadata for a crash/hang event. It links the failure to a fault bucket and event type for telemetry grouping and triage.

For this incident, Event 1001 records:
- Event Name: APPCRASH
- Fault bucket: 1847362910, type 4
- Response: Not available
- Cab Id: 0

### Event ID 1026 (Source: .NET Runtime, Level: Error)
Records a .NET runtime termination due to an unhandled managed exception in a process using .NET runtime components.

For this incident, Event 1026 records:
- Application: OUTLOOK.EXE
- Framework Version: v4.0.30319
- Exception: System.AccessViolationException

---

## 3. Reconstructed Sequence of Events (Plain English)

1. Outlook starts at 09:13:44.
2. Within about 38 seconds, Outlook crashes at 09:14:22 with access violation 0xc0000005 in KERNELBASE.dll (Event 1000).
3. The user likely retries Outlook.
4. Outlook crashes again at 09:17:45 with the same crash signature (Event 1000), indicating a persistent, not random, failure.
5. Windows Error Reporting logs APPCRASH telemetry at 09:18:01 (Event 1001), grouping the recurring failure.
6. .NET Runtime logs process termination due to unhandled System.AccessViolationException at 09:18:05 (Event 1026).
7. Practical result: user remains unable to use Outlook during the window due to repeated immediate process termination.

---

## 4. Most Likely Cause of the Application Lockout

### Most likely cause
Outlook enters a repeatable crash loop caused by an access violation (memory access fault) during runtime, surfacing through KERNELBASE.dll and terminating the process.

### Evidence from the supplied events
- Two Event 1000 entries show identical failure shape:
	- Same app version (OUTLOOK.EXE 16.0.17126.20132)
	- Same module version (KERNELBASE.dll 10.0.22621.3155)
	- Same exception code (0xc0000005)
	- Same fault offset (0x000000000003a4b2)
- Event 1026 confirms an unhandled System.AccessViolationException, aligned with 0xc0000005 semantics.
- Event 1001 APPCRASH confirms OS-level crash categorization and bucketed recurrence.

### Scope of certainty
- High confidence: repeated Outlook process crash loop prevented application use.
- Moderate confidence: immediate trigger lies in code path invoking invalid memory access; exact underlying component (add-in, profile corruption, Office build issue, or dependent library interaction) cannot be conclusively identified from only these four events.

### Items to verify against Microsoft documentation
- Verify exact interpretation boundaries for Event ID 1001 Fault bucket type 4 and Cab Id 0 behavior in current WER documentation.
- Verify whether this Outlook build (16.0.17126.20132) has known crash advisories or fixed issues related to KERNELBASE.dll / AccessViolationException.
- Verify recommended Office diagnostics sequence for repeated Event 1000 + 1026 combinations on Windows 11 build family 22621.

---

## 5. Five-Why Analysis

### Problem statement
User could not use Outlook because the application terminated repeatedly within minutes of launch.

### Why 1: Why could the user not use Outlook?
Because Outlook crashed each time it was launched.

Evidence: Event 1000 at 09:14:22 and 09:17:45 for OUTLOOK.EXE.

### Why 2: Why did Outlook crash?
Because an access violation occurred (0xc0000005), causing fatal termination.

Evidence: Event 1000 exception code 0xc0000005 and Event 1026 System.AccessViolationException.

### Why 3: Why did the access violation keep happening?
Because the crash was triggered in a repeatable execution path (same module and same fault offset), not a one-off transient event.

Evidence: KERNELBASE.dll with identical offset 0x000000000003a4b2 in both Event 1000 entries.

### Why 4: Why was that repeatable crash path present on this endpoint at this time?
Most likely one persistent condition loaded with Outlook startup (for example add-in interaction, profile/data state issue, or Office binary state mismatch) repeatedly invoked the failing code path.

Evidence: second crash occurs after restart attempt; no variance in signature.

Uncertainty: exact component cannot be proven from supplied events alone.

### Why 5: Why was the user effectively locked out of the application during the window?
Because the environment lacked immediate mitigation before repeated retries (for example safe-mode launch path, add-in isolation, quick repair action, or rapid rollback), so each launch attempt reproduced the same fatal exception.

Evidence: back-to-back crash sequence and WER logging without evidence of successful recovery in the provided window.

---

## 6. Root Cause Statement

The direct root cause of user impact was a repeatable Outlook application crash loop caused by access violation 0xc0000005, recorded as APPCRASH and unhandled System.AccessViolationException. This created an application lockout condition where the user could launch Outlook but could not keep it running.

The underlying technical origin of the invalid memory access (specific add-in, profile artifact, Office build defect, or dependency interaction) remains unconfirmed from the provided log subset and requires targeted follow-on diagnostics.

---

## 7. Corrective and Preventive Actions

1. Immediate containment: launch Outlook in safe mode and disable all COM add-ins, then re-enable one by one to isolate trigger.
2. Repair action: run Office Quick Repair, then Online Repair if required.
3. Profile isolation: create a new Outlook profile and test with same mailbox.
4. Build validation: compare Office channel/build against known-good fleet baseline; patch or rollback per enterprise policy.
5. Evidence expansion: collect Application + Office alerts, Reliability Monitor, and WER report artifacts for bucket correlation.
6. Prevention: establish a first-response runbook for repeated Event 1000/1026 Outlook crashes.

Items 1-4 should be verified against current Microsoft support guidance before production rollout.

---

## 8. Residual Risks

- If root trigger is an add-in distributed by policy, multiple users may be at risk.
- If root trigger is build-specific, recurrence may continue until build remediation is completed.
- Without WER dump analysis, confidence in component-level root cause remains limited.

---

## 9. Sign-off

| Role | Name | Date |
|------|------|------|
| DWP Analyst |  |  |
| Service Desk Lead |  |  |
| Desktop Engineering |  |  |

