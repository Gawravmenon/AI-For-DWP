# JAMF Compliance Profile Translation - macOS Security Baseline

Author: DWP Engineer  
Date: 2026-08-14  
Platform: macOS - JAMF Pro  
Target Fleet: Design Team (25 devices)

---

## Overview

This document translates the DWP macOS security baseline into JAMF Pro configuration profile settings and compliance checks. Each requirement includes:

- Payload type
- Value to set
- Enforcement effect
- Known false-positive risk
- Practical recommendation to reduce noise without lowering security

The intent is to mirror the same implementation discipline used in the Day 6 Intune baseline labs.

---

## Important UI Verification Note (Read Before Build)

JAMF Pro payload names, section headers, and option labels can change between versions and also differ between classic and newer UI experiences.

Do not treat any exact field label in this document as authoritative until you verify it in your own JAMF Pro instance.

For every requirement below, validate:

1. Payload category name
2. Exact checkbox or dropdown label
3. Behavior on a pilot Mac after inventory update

Where noted as High drift risk, verify in tenant before production scope assignment.

---

## Implementation Pattern for 25 Devices

Because this is a small Design fleet, use a controlled ring approach:

1. Ring 0 pilot: 5 devices
2. Ring 1 production: remaining 20 devices
3. Validation hold: 48-72 hours between rings

Suggested static groups:

- DWP-Mac-Design-Pilot-05
- DWP-Mac-Design-Prod-20
- DWP-Mac-Design-Exception-Temporary

---

## Requirement 1 - FileVault Disk Encryption Must Be Enabled

| Field | Detail |
|---|---|
| Payload Type | Security and Privacy payload (FileVault controls), or dedicated Disk Encryption/FileVault area depending on JAMF version |
| Value | Enable FileVault. Enforce personal recovery key generation and escrow to JAMF. Allow limited deferrals only if approved (for example, max 1-3). |
| JAMF UI Path (verify in tenant) | Computers -> Configuration Profiles -> [Profile] -> Security and Privacy / Disk Encryption section |
| Effect | Full-disk encryption at rest. Data is inaccessible without valid login or recovery key. |
| False-Positive Risk | Encryption in progress after assignment; first-login not completed; escrow not posted yet due to delayed inventory check-in; user deferred enablement within approved window. |
| Recommendation | Treat FileVault non-compliance as soft-fail for first 24-48 hours post-assignment, then enforce. Confirm escrow receipt in JAMF before hard compliance actions. |
| UI Naming Drift Risk | High |

Endpoint verification commands (pilot device):

```bash
fdesetup status
fdesetup validaterecovery
```

---

## Requirement 2 - Gatekeeper Must Be Enabled (Identified Developers Only)

| Field | Detail |
|---|---|
| Payload Type | Restrictions payload (application execution / Gatekeeper-related controls) |
| Value | Allow app execution from App Store and identified developers only. Do not allow Anywhere. |
| JAMF UI Path (verify in tenant) | Computers -> Configuration Profiles -> [Profile] -> Restrictions / Security controls |
| Effect | Prevents unsigned or untrusted applications from launching by default while permitting signed and notarized developer software. |
| False-Positive Risk | Creative-tool plugins, niche design utilities, and internally packaged apps can appear blocked before vendor notarization catches up; temporary admin override can look like drift. |
| Recommendation | Pre-stage an allowlist process for approved design tools and plugins. Validate new creative software in pilot before broad install. |
| UI Naming Drift Risk | High |

Endpoint verification commands (pilot device):

```bash
spctl --status
spctl --assess -vv /Applications/Safari.app
```

---

## Requirement 3 - Minimum macOS Version Must Be Current Stable Minus One Point Release

| Field | Detail |
|---|---|
| Payload Type | Usually not a single payload toggle. Implement using Smart Group criteria and/or compliance benchmark logic, optionally combined with Software Update enforcement profile. |
| Value | Define N-1 threshold from current stable release. Example rule: if stable is 15.6, minimum allowed is 15.5. Update monthly. |
| JAMF UI Path (verify in tenant) | Computers -> Smart Computer Groups -> Criteria (Operating System Version) and compliance workflow tooling used by your org |
| Effect | Prevents endpoints from lagging beyond one supported point release and narrows vulnerability exposure. |
| False-Positive Risk | Apple phased rollout timing; machine offline during rollout; device has downloaded update but not rebooted; delayed inventory recon causes stale version reporting. |
| Recommendation | Introduce a grace window aligned to your update cadence (for example 7 days) before hard access impact. Update N-1 threshold during monthly patch governance. |
| UI Naming Drift Risk | High |

Endpoint verification commands (pilot device):

```bash
sw_vers -productVersion
softwareupdate --list
```

---

## Requirement 4 - Firewall Must Be Enabled

| Field | Detail |
|---|---|
| Payload Type | Security and Privacy payload (Firewall section) |
| Value | Firewall On. Enable stealth mode where business-compatible. Keep essential management paths allowed by policy. |
| JAMF UI Path (verify in tenant) | Computers -> Configuration Profiles -> [Profile] -> Security and Privacy -> Firewall |
| Effect | Reduces unsolicited inbound access and lowers lateral movement opportunity on user endpoints. |
| False-Positive Risk | Approved tooling may require inbound rules; local service prompts not yet accepted; scanner checks may fail if they only test one firewall state source. |
| Recommendation | Pair policy with documented exceptions for approved remote support/design tooling and monitor exception growth monthly. |
| UI Naming Drift Risk | Medium |

Endpoint verification commands (pilot device):

```bash
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
```

---

## Requirement 5 - Login Password Required After Sleep or Screen Saver

| Field | Detail |
|---|---|
| Payload Type | Security and Privacy controls and/or Login Window/Restrictions related keys, depending on JAMF profile schema version |
| Value | Require password immediately after sleep or screen saver starts (or short approved grace period if business-approved). |
| JAMF UI Path (verify in tenant) | Computers -> Configuration Profiles -> [Profile] -> Security and Privacy / Login Window related controls |
| Effect | Prevents unauthorized access on unattended devices by forcing re-authentication after lock events. |
| False-Positive Risk | Presentation mode and wake/sleep timing behavior can cause transient state mismatch; third-party lock tools may conflict with reporting source. |
| Recommendation | For design presenters, use a tightly controlled short grace period exception group rather than relaxing baseline globally. |
| UI Naming Drift Risk | High |

Endpoint verification commands (pilot device):

```bash
defaults read com.apple.screensaver askForPassword
defaults read com.apple.screensaver askForPasswordDelay
```

---

## Requirement 6 - Automatic Security Updates Must Be Enabled

| Field | Detail |
|---|---|
| Payload Type | Software Update payload |
| Value | Enable automatic check, download, and install for security updates and system data files. Enable background security responses where available in your OS version. |
| JAMF UI Path (verify in tenant) | Computers -> Configuration Profiles -> [Profile] -> Software Update |
| Effect | Accelerates patch adoption and reduces exposure window to known vulnerabilities. |
| False-Positive Risk | Device off during maintenance window; low free disk; user deferral policy interaction; CDN or network issues delaying update availability. |
| Recommendation | Track update compliance at D+3 and D+7 after release. Trigger user comms and targeted remediation before escalating to access controls. |
| UI Naming Drift Risk | Medium to High |

Endpoint verification commands (pilot device):

```bash
softwareupdate --schedule
softwareupdate --history
```

---

## Baseline Summary Table (Quick Mapping)

| Requirement | Payload Type | Value | Effect | False-Positive Risk |
|---|---|---|---|---|
| FileVault enabled | Security and Privacy / Disk Encryption | FileVault On, escrow recovery key | Encrypts data at rest | Encryption or escrow still in progress |
| Gatekeeper enabled | Restrictions | App Store + identified developers | Blocks untrusted app execution | Plugin/notarization lag |
| Minimum macOS N-1 | Smart Group + compliance workflow | Stable minus one point release | Keeps devices near current patch level | Phased rollout and reboot delay |
| Firewall enabled | Security and Privacy | Firewall On (+ stealth mode where allowed) | Reduces inbound attack surface | Tooling exceptions or rule timing |
| Password after sleep/saver | Security and Privacy / Login controls | Require immediately (or approved short grace) | Prevents walk-up access on unlocked sessions | Timing/reporting mismatch around sleep state |
| Automatic security updates | Software Update | Auto check/download/install security content | Improves patch velocity | Offline devices and storage constraints |

---

## Compliance State Model for JAMF Operations

Unlike Intune, JAMF implementations often use a combination of profile scope, inventory signals, smart groups, and optional access-control integrations. For this fleet, operationally treat state as:

| State | What It Means | Access/Enforcement Impact |
|---|---|---|
| Compliant | Device meets all six controls and latest inventory confirms status | Normal access |
| In remediation window | One or more controls failing but within defined correction period (recommended: 7 days for update and encryption convergence) | Notify user and service desk; no immediate hard block |
| Non-compliant | Failing controls beyond remediation window | Move to enforcement group, restrict access per org policy, open incident |

Implementation note: This state model is process-driven unless your JAMF stack includes a formal compliance module with native status objects. Verify exact capabilities in your tenant.

---

## Post-Assignment Validation Workflow

### Step 1 - Confirm Profile Scope and Install

1. Verify profile is scoped to pilot group first.
2. On each pilot Mac, confirm profile install status in JAMF inventory.
3. Run endpoint spot checks using the commands listed in each requirement.

### Step 2 - Confirm Per-Setting Health Signals

For each pilot endpoint, collect and compare:

1. JAMF inventory values
2. Local command output
3. Last inventory update timestamp

Do not classify device as hard non-compliant if local state is correct but inventory timestamp is stale.

### Step 3 - Promote to Production Ring

Promote from 5 to 25 devices only when:

1. No unresolved false positives remain
2. Recovery key escrow is confirmed for FileVault devices
3. Approved exception list is documented for design tooling

---

## Common Troubleshooting: FileVault Shows Failing While User Reports It Is On

Top three causes and fastest checks:

### Cause 1: Encryption Is Active But Not Completed

Check:

```bash
fdesetup status
diskutil apfs list
```

If encryption is still converting, keep device in remediation window and recheck after next inventory cycle.

### Cause 2: Recovery Key Escrow Has Not Landed in JAMF Yet

Check:

1. Local FileVault state is On
2. JAMF inventory has no current escrow record yet

Action: trigger inventory update, then re-validate escrow before enforcement.

### Cause 3: User Deferred Enablement During Allowed Window

Check:

1. Profile allows deferral
2. User has not exhausted permitted deferrals

Action: communicate deadline and monitor until enforcement cutover.

---

## Quick Validation Checklist

| Check | Tool/Source | Pass Condition |
|---|---|---|
| Profile applied | JAMF device inventory | Target profile present |
| FileVault state | fdesetup status | FileVault is On |
| Gatekeeper state | spctl --status | assessments enabled |
| OS version threshold | sw_vers -productVersion | Version is greater than or equal to N-1 |
| Firewall state | socketfilterfw --getglobalstate | Firewall enabled |
| Password-after-lock setting | defaults read com.apple.screensaver | Password prompt required per baseline |
| Security update automation | softwareupdate --schedule | Automatic scheduling enabled |

---

## Settings With High Probability of UI Label Drift

Verify these in your own tenant before rollout:

| Setting | Drift Risk | Verification Action |
|---|---|---|
| FileVault controls and escrow labels | High | Confirm exact FileVault payload section and escrow field labels in your JAMF version |
| Gatekeeper allow-mode labels | High | Confirm dropdown wording for identified developers vs Anywhere |
| Password-after-sleep/saver controls | High | Confirm whether control appears under Security and Privacy, Login Window, or key-level custom settings |
| Minimum OS enforcement method | High | Confirm whether you are using Smart Group criteria, compliance benchmarks, or another module |
| Software update security-response toggles | Medium to High | Confirm which update options exist for your managed macOS versions |

---

## Final Operational Reminder

Treat this document as implementation guidance, not a source of exact JAMF UI strings.

Before production enforcement, validate every payload label and behavior in your own JAMF Pro instance using a 5-device pilot and endpoint command evidence.
