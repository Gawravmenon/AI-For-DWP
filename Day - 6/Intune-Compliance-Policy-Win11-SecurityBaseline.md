# Intune Compliance Policy – Windows 11 Security Baseline
**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Platform:** Windows 11 – Microsoft Intune  
**Grace Period (all settings):** 7 days  

---

## Overview

This document translates the DWP Windows 11 security baseline requirements into Intune compliance policy settings. Each entry includes the exact setting name, required value, enforcement effect, known false-positive risks, and a recommendation to reduce noise without weakening security posture.

> **Note on UI paths (verified 2026-08-11):** Intune's compliance policy UI is located at:  
> **Microsoft Intune admin center → Manage devices → Compliance → By platform → Windows → Policies → Create policy**  
> *(Inside the Compliance blade, use the left-hand "By platform" section to select Windows. The top tab bar shows: Policies | Notifications | Retire noncompliant devices | Compliance settings | Scripts | Monitor. Tenant-wide compliance behaviour — including the compliance validity period — lives under the **Compliance settings** tab, not inside an individual policy.)*

---

## Requirement 1 – BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting Name** | `Require BitLocker` |
| **Value** | `Require` |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **Microsoft Attestation Service evaluation settings → Windows 10 and 11** → `BitLocker` |
| **Effect** | Marks a device non-compliant if BitLocker is not actively protecting the OS (C:) drive. Intune queries the Windows Security Center attestation state, not just whether BitLocker is installed. |
| **False-Positive Risk** | • Device has BitLocker enabled but the **encryption is still in progress** at time of check — Intune reads "not fully encrypted" as non-compliant.<br>• **TPM chip absent or disabled** in firmware (e.g., older hardware re-imaged to Win11).<br>• **Suspended BitLocker** (common during patching via SCCM/MECM task sequences) is reported as non-compliant until resumed.<br>• Virtual machines without vTPM 2.0 configured in Hyper-V / AVD host pool. |
| **Recommendation** | The 7-day grace period covers most in-progress encryption scenarios. Additionally, create a **remediation script** (Intune Remediations) that auto-resumes suspended BitLocker after patching windows close. Document the AVD/VM exclusion group and apply a scoped policy to those devices with vTPM confirmed. |

---

## Requirement 2 – Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | `Require Secure Boot to be enabled on the device` |
| **Value** | `Require` |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **Microsoft Attestation Service evaluation settings → Windows 10 and 11** → `Secure Boot` |
| **Effect** | Uses Windows Health Attestation Service (HAS) to verify Secure Boot state is enabled in UEFI firmware. Devices with Secure Boot disabled or with a Legacy BIOS boot mode are marked non-compliant. |
| **False-Positive Risk** | • **Legacy BIOS / CSM mode** devices that passed Win11 hardware check through an exception — these cannot enable Secure Boot without a re-image.<br>• **Dual-boot Linux** devices where Secure Boot was deliberately disabled.<br>• HAS attestation **network latency** — device may show non-compliant for a short window after enrolment before the attestation report is received.<br>• Some **third-party signed bootloaders** (e.g., older driver-signing tools) can cause Secure Boot to report as off even when enabled. |
| **Recommendation** | Pre-flight: run `Confirm-SecureBootUEFI` via a proactive remediation before policy goes live to identify non-capable hardware. Exclude confirmed legacy hardware into a separate policy group with compensating controls (e.g., mandatory full-disk encryption audit). |

---

## Requirement 3 – Minimum OS Build: N-1 (22621.2861)

| Field | Detail |
|---|---|
| **Setting Name** | `Minimum OS version` |
| **Value** | `10.0.22621.2861` |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **Device Properties** → `Minimum OS version` |
| **Effect** | Devices running a build older than 22621.2861 (Windows 11 22H2, N-1 relative to latest known good 22621.3155) are marked non-compliant. This ensures devices are no more than one quality update behind. |
| **False-Positive Risk** | • **WUfB (Windows Update for Business) deferral rings** — devices in a 14+ day deferral ring will not have received the update yet and will flag non-compliant during the deferral window.<br>• **Metered connections / bandwidth throttling** delaying update download.<br>• **Pending reboot** — update downloaded and staged but not yet applied; device still reports old build number.<br>• Devices enrolled mid-cycle that haven't completed their first scan. |
| **Recommendation** | Align the compliance minimum build with the **end of the WUfB deferral window** for your slowest ring (e.g., if Ring 3 has a 21-day deferral, don't set N-1 until day 22). The 7-day grace period helps absorb reboot lag. Review and update the minimum build monthly as part of the Patch Tuesday process. |

---

## Requirement 4 – Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Setting Name** | `Real-time protection` |
| **Value** | `Require` |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **Defender** → `Real-time protection` |
| **⚠️ Prerequisite** | `Real-time protection` is a **dependent setting** — it is grayed out until you first set **"Microsoft Defender Antimalware"** (the setting directly above it in the Defender section) to **`Require`**. Without this parent setting enabled, the toggle for Real-time protection cannot be changed. Set both: `Microsoft Defender Antimalware` = **Require**, then `Real-time protection` = **Require**. |
| **Effect** | Marks the device non-compliant if Windows Defender Antivirus real-time protection is disabled or if a third-party AV has taken over the Windows Security Center registration without real-time protection active. |
| **False-Positive Risk** | • **Third-party AV products** (e.g., Symantec, CrowdStrike Falcon in passive mode) that disable Defender RTP by design — Intune checks the Windows Security Center state, not whether a third-party product is protecting the device.<br>• **Tamper Protection** conflicts during AV migration periods.<br>• Defender service **transiently restarting** after a definition update or Windows update — short gap where RTP reports as off.<br>• Devices in **Windows PE / provisioning mode** during Autopilot OOBE. |
| **Recommendation** | If a third-party AV is deployed (e.g., via Intune or SCCM), validate it registers correctly in Windows Security Center with RTP status "On". Use **Defender for Endpoint** integration in Intune (MDE compliance signal) as a more reliable signal than the Security Center check alone, especially in hybrid AV environments. |

---

## Requirement 5 – Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting Name** | `Microsoft Defender Firewall` |
| **Value** | `Require` |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **System Security** → `Microsoft Defender Firewall` |
| **Effect** | Checks that Windows Defender Firewall is active across all three network profiles (Domain, Private, Public). A device with firewall disabled on any one profile is marked non-compliant. |
| **False-Positive Risk** | • **Third-party firewall software** (e.g., Symantec Endpoint Firewall) that disables the Windows Firewall service — Windows Security Center may still report the native firewall as off even though the device has firewall protection.<br>• **Group Policy conflicts** — an on-premises GPO that disables Windows Firewall for the Domain profile will override Intune settings on hybrid-joined devices.<br>• **VPN split-tunnelling** configurations that temporarily alter firewall profile state.<br>• Legacy LOB apps that add "disable firewall" workarounds during installation. |
| **Recommendation** | For **hybrid Azure AD joined** devices, audit conflicting on-prem GPOs using `gpresult /h` before enforcement. If third-party firewalls are in use, ensure they register in Windows Security Center. Consider using an **Intune Firewall configuration profile** in tandem with the compliance check to enforce and remediate simultaneously. |

---

## Requirement 6 – A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Setting Name** | `Require a password to unlock mobile devices` / `Password required` |
| **Value** | `Require` |
| **Additional Settings** | `Minimum password length`: 8 characters (DWP baseline) |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **System Security** → Password → `Require a password to unlock mobile devices` |
| **Effect** | Enforces that the device has a screen lock credential (PIN, password, or Windows Hello) configured. Without this, the device is marked non-compliant. Combines with Windows Hello for Business policy for stronger authentication enforcement. |
| **False-Positive Risk** | • **Kiosk / shared devices** (e.g., frontline worker shared endpoints) intentionally configured without a personal PIN — these will always flag non-compliant under a standard policy.<br>• **Windows Hello for Business provisioning delay** — device enrolled but WHfB PIN not yet set (common in the first 24 hours post-Autopilot).<br>• **Service accounts / unattended devices** that auto-logon by design.<br>• Users who have only set up **biometrics** (Face/Fingerprint) without a backup PIN — this is technically compliant but can confuse some reporting. |
| **Recommendation** | Exclude confirmed kiosk and shared devices into a dedicated compliance policy with alternative compensating controls (e.g., auto-lock timeout, no local admin rights). Set grace period awareness: the 7-day window gives time for WHfB provisioning to complete post-enrolment. Align with the Windows Hello for Business Intune configuration profile. |

---

## Requirement 7 – Device Boot Integrity Must Be Enforced (Windows equivalent of "not jailbroken")

| Field | Detail |
|---|
---|
| **Setting Name** | `Code integrity` |
| **Value** | `Require` |
| **Intune UI Path** | Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **Microsoft Attestation Service evaluation settings → Windows 10 and 11** → `Code integrity` |
| **⚠️ Note** | The "Device must not be jailbroken or rooted" option **does not exist in Windows compliance policies** — it is an Android/iOS-only setting. On Windows, the equivalent boot-integrity check is **Code integrity**, which uses the Windows Health Attestation Service (HAS) to verify that boot-critical components have not been tampered with. |
| **Effect** | Detects whether Code Integrity (CI) policy is active and enforcing at boot time. If a device has had its bootloader, kernel, or early-load drivers tampered with — or if CI enforcement is disabled — the device is marked non-compliant. Works in conjunction with Secure Boot and BitLocker to form a full attestation chain. |
| **False-Positive Risk** | • **Developer/test devices** with custom Code Integrity policies or test-signed drivers may trigger this check.<br>• **Hyper-V nested virtualisation** configurations that alter the attestation chain.<br>• **Health Attestation Service connectivity issues** — if the device cannot reach `has.spserv.microsoft.com`, the attestation report is absent and the device may be marked non-compliant by default.<br>• **Time sync drift** — HAS uses certificate timestamps; significant NTP drift can invalidate the attestation report. |
| **Recommendation** | Ensure all devices have reliable internet access to the HAS endpoint (whitelist in proxy/firewall if needed). For developer machines, consider a separate compliance policy scoped to that group with this check relaxed, backed up by MDE risk-level compliance instead. Monitor NTP sync health via a proactive remediation script. |

> **⚠️ UI Path Note:** The "jailbroken/rooted" label does not exist in Windows compliance policies — it is surfaced only for Android and iOS/iPadOS. On Windows 10/11, the boot-integrity equivalent is **Code integrity** under **Microsoft Attestation Service evaluation settings → Windows 10 and 11**. All three attestation settings (BitLocker, Secure Boot, Code integrity) live in this same section, confirmed from the Intune admin center UI.

---

## Grace Period Summary

| Requirement | Setting | Grace Period |
|---|---|---|
| BitLocker on OS Drive | Require BitLocker | **7 days** |
| Secure Boot Enabled | Require Secure Boot | **7 days** |
| Minimum OS Build 22621.2861 | Minimum OS version | **7 days** |
| Defender Real-Time Protection | Require real-time protection | **7 days** |
| Firewall All Profiles | Microsoft Defender Firewall | **7 days** |
| PIN or Password Configured | Password required | **7 days** |
| Not Jailbroken / Rooted | Code integrity (Windows equivalent) | **7 days** |

> **Configuring grace period in Intune:**  
> Manage devices → Compliance → By platform → Windows → Policies → [Policy] → **Actions for noncompliance** → `Mark device noncompliant` → Set **Schedule** to `7 days`  
> *(Tenant-wide compliance validity period is separate: Manage devices → Compliance → **Compliance settings** tab → "Compliance status validity period (days)" — default is 30 days.)*

---

## ⚠️ Settings Flagged for Potential UI Changes

The following settings may have been affected by Intune UI updates since training data cutoff. Verify the exact location in your tenant before policy deployment:

| Setting | Risk | Recommended Action |
|---|---|---|
| `Require BitLocker` | BitLocker and Secure Boot sit under **Microsoft Attestation Service evaluation settings → Windows 10 and 11**, not a generic "Device Health" section. | Verified from UI screenshot: the section header reads "Microsoft Attestation Service evaluation settings" with a sub-section "Windows 10 and 11" containing BitLocker, Secure Boot, and Code integrity. |
| `Device must not be jailbroken or rooted` | **This setting does not exist for Windows.** It is Android/iOS-only. The Windows equivalent is `Code integrity` in the same attestation section. | Use **Code integrity** = Require under Microsoft Attestation Service evaluation settings → Windows 10 and 11. |
| `Minimum OS version` | Format accepted by the UI has changed between tenants (some require `10.0.22621.2861`, others accept `22621.2861`). | Test with a known non-compliant device to confirm the format is being evaluated correctly. |
| `Microsoft Defender Firewall` | In some Intune builds this is surfaced under "Windows Security" rather than "System Security". | Confirm the UI path reflects your current admin center version (navigate to **Manage devices → Compliance → By platform → Windows → Policies** → edit policy to inspect section headers). |

---

## Post-Assignment Validation

### Step 1 – Find the Device's Compliance Status for This Specific Policy

**Path:**
> Manage devices → Compliance → By platform → Windows → Policies → **[This Policy]** → Monitor → **Device status**

This view shows every device the policy has been assigned to, with a per-device compliance state. To drill into a single test device:

1. Open the **Device status** tab within the policy
2. Search for the device by name in the filter bar
3. Click the device name → the **Per-setting compliance status** panel opens on the right, showing the result for **each individual setting** (BitLocker, Secure Boot, OS version, etc.) with a pass/fail indicator

Alternatively, navigate directly from the device record:
> All devices → [Device name] → **Compliance** (left blade) → select the policy name to see per-setting breakdown

---

### Step 2 – What Compliance States Mean for Conditional Access

| State | What It Means | Conditional Access Impact |
|---|---|---|
| **Compliant** | All settings in the policy are passing. The device has checked in and reported a clean state within the compliance validity period (default: 30 days). | CA grants access normally. The `deviceCompliant` claim is present in the token. No access restrictions applied by this policy. |
| **In grace period** | One or more settings are failing, but the device is still within the **7-day Actions for noncompliance** window. The device is technically non-compliant but has not yet been **marked** non-compliant. | **CA still grants access** during the grace period — the device is treated as compliant for token issuance purposes. This is the window to remediate without user impact. |
| **Not compliant** | One or more settings are failing AND the grace period has expired. Intune has formally marked the device non-compliant. | **CA blocks access** to any resource protected by a "Require compliant device" Conditional Access policy (typically Exchange Online, SharePoint, Teams). The user sees: *"You can't get there from here"* or *"This device does not meet the security requirements."* Sign-in logs in Entra ID will show error **530003**. |

> **Key operational point:** A device showing "In grace period" is your remediation window. Once it flips to "Not compliant", the user is locked out and you need to both fix the device **and** wait for Intune to re-evaluate (next check-in cycle, or trigger manually via **Sync** in the device record).

---

### Step 3 – BitLocker Shows Non-Compliant Despite Being Enabled

This is the most common post-assignment support call. The three most likely causes and the fastest check for each:

#### Cause 1: BitLocker is Suspended (not disabled — suspended)

Suspension is applied automatically during Windows Updates, driver installs, BIOS updates, and SCCM/MECM task sequences. Intune reads "suspended" as non-compliant.

**Fastest check — run on the device:**
```powershell
manage-bde -status C:
```
Look for `Protection Status`. If it reads **"Protection Off"** but `Conversion Status` is **"Fully Encrypted"**, BitLocker is suspended, not off.

**Fix:**
```powershell
manage-bde -protectors -enable C:
```

---

#### Cause 2: Intune's Attestation Report Is Stale / Not Yet Received

The compliance check for BitLocker uses the **Windows Health Attestation Service**, not a direct local query. After a sync, there can be a delay of up to 15–30 minutes before HAS returns a fresh report. Devices newly enrolled or recently rebooted are especially prone to this.

**Fastest check:**
In the Intune admin center, look at the **Last check-in** timestamp on the device record. If it was less than 30 minutes ago, the attestation report may not yet have returned.

On the device, force a fresh check-in:
```powershell
# Force Intune Management Extension sync
Start-Process "C:\Program Files (x86)\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe" -ArgumentList "syncapp"
```
Then in the admin center: All devices → [Device] → **Sync** button → wait 10 minutes → refresh compliance view.

---

#### Cause 3: TPM Is Present but Not Initialised / Ownership Not Taken

BitLocker can appear active locally but the TPM attestation chain is broken if the TPM was reset, not provisioned during Autopilot, or has a firmware version mismatch.

**Fastest check — run on the device:**
```powershell
Get-Tpm
```
Check:
- `TpmPresent` = True
- `TpmReady` = True
- `TpmEnabled` = True
- `TpmOwned` = True

If any of these are `False`, the TPM is not in a state where Windows can generate a valid HAS attestation report, and BitLocker will report as non-compliant regardless of encryption status.

**Fix path:** Re-initialise TPM via `tpm.msc` → Clear TPM (requires reboot + BIOS confirmation) → BitLocker will re-seal keys to the newly initialised TPM → check compliance again after next sync.

---

### Quick Reference: Post-Sync Validation Checklist

| Check | Tool | Pass Condition |
|---|---|---|
| Policy assigned and evaluated | Intune → Policy → Device status | Device appears, state is not "Pending" |
| Per-setting breakdown visible | Intune → Device → Compliance → Policy | Each setting shows ✓ or specific failing setting named |
| BitLocker suspension | `manage-bde -status C:` on device | Protection Status = "Protection On" |
| TPM health | `Get-Tpm` on device | All four properties = True |
| HAS attestation received | Intune device record → Last check-in | Timestamp is recent; re-sync if >30 min ago |
| Grace period status | Intune → Policy → Device status → State column | "In grace period" = still OK; "Not compliant" = CA may block |

---

## References

- [Microsoft Intune compliance policies for Windows – Microsoft Learn](https://learn.microsoft.com/en-us/mem/intune/protect/compliance-policy-create-windows)
- [Windows Health Attestation – Microsoft Learn](https://learn.microsoft.com/en-us/windows/security/threat-protection/protect-high-value-assets-by-controlling-the-health-of-windows-10-based-devices)
- [BitLocker compliance settings – Microsoft Learn](https://learn.microsoft.com/en-us/mem/intune/protect/encrypt-devices)
- [DWP Personal AI Usage Charter](../Personal-AI-Usage-Charter-DWP-Desktop-Endpoint.md)
