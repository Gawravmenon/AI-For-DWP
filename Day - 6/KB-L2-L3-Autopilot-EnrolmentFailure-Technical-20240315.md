# L2/L3 KB: Autopilot Enrollment – Technical Deep-Dive & Resolution

**Knowledge Base ID:** KB-AP-002  
**Title:** Windows Autopilot Enrollment Error 0x80180014 – Technical Resolution & Preventive Strategy  
**Audience:** L2/L3 Support Engineers, System Administrators, Intune Specialists  
**Last Updated:** 2024-03-15  
**Severity:** High  

---

## Executive Summary

**Error:** 0x80180014 – "The device is already enrolled in MDM"  
**Root Cause:** Stale legacy MDM enrollment records in Intune and/or Entra device registry conflicting with new Autopilot enrollment  
**Resolution:** Two-phase remediation (admin center + device-side cleanup)  
**Prevention:** Pre-Autopilot legacy enrollment hygiene audit  
**Recurrence Risk:** Medium (common during migration from manual to Autopilot enrollment)

---

## Technical Background

### How Autopilot Enrollment Works
1. Device boots and connects to network
2. Windows OOBE initiates Autopilot discovery call to Microsoft servers
3. Device is looked up in Autopilot device registry by hardware hash
4. If found, assigned Autopilot profile specifies enrollment flow and policies
5. Device initiates MDM enrollment via Intune service
6. Enrollment succeeds → policies apply
7. Enrollment fails → error code returned, enrollment blocked

### Why 0x80180014 Occurs
When the Intune enrollment service processes the MDM enrollment request, it checks:
- Is this device already enrolled? (by device ID / hardware hash match)
- If yes → does the existing enrollment conflict with this request?
- If legacy enrollment exists + new Autopilot enrollment requested → conflict → 0x80180014

The error is a **protective mechanism** to prevent dual-enrollment state which would create policy conflicts and management conflicts.

---

## Root Cause Diagnosis

### Primary Cause: Legacy Stale Device Records
When a device is **manually enrolled in Intune** and later:
- User is provisioned for Autopilot
- Device is supposed to enroll via Autopilot flow
- But legacy manual enrollment record still exists in Intune database

The Autopilot flow cannot proceed because the system detects an existing enrollment.

### Secondary Cause: Stale Entra Device Objects
Similarly, **Entra ID device objects** may contain:
- Old device registration from legacy enrollment
- Duplicate objects from previous provisioning attempts
- Stale join records that conflict with new Autopilot registration

### Tertiary Cause: Persistent Local Enrollment Cache
On **device itself**, the registry/local storage may cache:
- Old MDM enrollment credentials
- Legacy work/school account connection
- Stale compliance state

If device-side cache is not cleared, even after admin-center cleanup, device may re-assert the old enrollment state.

---

## Technical Resolution Process

### Phase 1: Admin Center Remediation (Prerequisites)
**Required Access:** Intune admin center + Microsoft Entra admin center  
**Permissions:** Cloud device admin or equivalent

#### 1.1 – Locate and Document Device Records
```
Intune > Devices > All devices > Search [device name / serial / user]
```
**For each record found:**
- Record the object ID (GUID)
- Note enrollment date/time
- Note enrollment source (Autopilot vs. Manual MDM vs. Registered)
- Check MDM enrollment status and last check-in time
- Identify which record is STALE (oldest, no recent check-in)

**Expected scenario:**
- One or more stale records from previous manual enrollment
- One potential newer record (if device attempted Autopilot already)
- Multiple duplicates possible in some cases

#### 1.2 – Retire Stale Managed Device Records
For the **identified stale record(s)** (typically oldest):

```
Devices > All devices > [Select stale record] > Retire
```

**Why retire first:**
- Gracefully removes device from active management
- Allows policies to be unapplied cleanly
- Reduces risk of half-applied policies remaining
- Complies with some organizations' change control policies

Wait for retirement to complete (~2-5 minutes).

#### 1.3 – Delete Retired / Stale Records
Once retirement completes:
```
Devices > All devices > [Select retired record] > Delete
```

**Important:** Verify retirement completed before delete. A "failed to retire" state may indicate the device has network issues or policy conflicts—if so, escalate investigation before forcing delete.

#### 1.4 – Check and Clean Entra Device Objects
Switch to **Microsoft Entra admin center**:

```
Microsoft Entra admin center > Devices > All devices
```

**Search and evaluate:**
- Search by device name or serial number
- Look for **duplicate objects** for same hardware
- Identify stale Entra device object(s)

**Expected scenario:**
- One primary Entra device object (joined via Autopilot or legacy enrollment)
- Possibly one or more duplicate/stale objects from previous provisioning
- Old objects may show **Last activity** > 90 days ago

**Remediation:**
- For each stale/duplicate object: select and click **Delete**
- Keep only the single expected current device object
- Document the deletion

**Caution:** Do NOT delete the primary device object that's actively in use. If unsure, cross-reference with Intune records.

#### 1.5 – Verify Autopilot Registration and Assignment
Back in **Intune admin center**:

```
Devices > Windows > Windows enrollment > Devices (Windows Autopilot devices)
```

**Search and verify:**
- Device exists in Autopilot registry by hardware hash or serial
- Correct Autopilot profile is assigned
- Device group membership is correct (target group includes device or user)
- No assignment filters exclude the device/user combination

**If Autopilot record is missing:**
- Re-import device hardware hash via CSV (if using CSV import flow)
- Or ensure device appears in Autopilot via Intune tenant sync
- Escalate if device should be in Autopilot but is not discovered

#### 1.6 – Verify Policy Targeting
```
Devices > Configuration > Policies [Compliance / Security Baseline / etc.]
```

For each policy that should apply during Autopilot:
- Verify device/user group membership includes target
- Verify no assignment exclusion filters block the device/user
- Note the expected policy count (e.g., 4 policies should apply)

---

### Phase 2: Device-Side Remediation (Device Access Required)
**Required Access:** Local admin or remote management access to device  
**Supported Methods:** Physical access, RDP, Intune remote assistance, SCCM, etc.

#### 2.1 – Disconnect Legacy Work/School Account
On the device, navigate to:
```
Settings > Accounts > Access work or school
```

**Expected state:**
- One or more entries showing organization connection(s)
- At least one should be the legacy/old connection

**Action:**
- Select the entry tied to legacy/manual enrollment
- Click **Disconnect**
- If multiple entries, disconnect all stale/legacy entries
- Keep only the expected current connection (if any)
- Confirm disconnection

**Technical note:**  
This removes the device from the organization's work/school MDM connection at the OS level. Technically, this:
- Clears `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*` entries
- Removes work/school account credential cache
- Clears local policy cache associated with that enrollment

#### 2.2 – Verify and Clear Local Enrollment State
Open **elevated Command Prompt** and run:
```powershell
dsregcmd /status
```

**Expected output – healthy state:**
```
+----------------------------------------------------------------------+
| Device State                                                         |
+----------------------------------------------------------------------+
             AzureAdJoined : YES
          EnterpriseJoined : NO
                DomainJoined : YES
              DomainName : company.com
          Device Name : DESKTOP-FB099
        Device Id : [GUID]
            Workplace Join : NO
```

**Check for stale indicators:**
- Multiple "Work account" entries
- "Workplace Join : YES" when should be NO
- Error entries in Device State section
- MDM enrollment showing as active for old accounts

**If stale state persists:**
Run (elevated Command Prompt):
```powershell
dsregcmd /leave
```

This removes the device from Entra/AD managed state. Then:
```powershell
dsregcmd /join /provisioning /TenantId:[GUID]
```

To re-join properly. **Use with caution** – this is invasive and should only be used if disconnect and cache-clear don't resolve the state.

#### 2.3 – Reboot Device
```powershell
Restart-Computer -Force
```

Device will reboot and local enrollment components will refresh.

#### 2.4 – Trigger Autopilot Enrollment Flow
**Two methods depending on device state:**

**Option A: If device is at login screen**
- Sign out and sign in as target user
- Device will detect Autopilot assignment and initiate enrollment
- OOBE flow may appear depending on Autopilot profile settings

**Option B: If device needs full reset to re-run OOBE**
- On device: Settings > System > Recovery > Reset this PC
- Choose "Remove everything" if full OOBE re-run is needed
- Follow on-screen prompts
- After reset, sign in as target user to start Autopilot enrollment

---

## Verification & Success Criteria

### Post-Remediation Checks (Admin Center)

1. **Device Count:**
   ```
   Intune > Devices > All devices [search device name]
   ```
   - ✅ Exactly ONE device record for the hardware (no duplicates)
   - ✅ Record shows "Managed by Intune"
   - ✅ Enrollment type shows "MDM" or "Autopilot"

2. **Enrollment Status:**
   ```
   [Device record] > Compliance > Compliance state
   ```
   - ✅ Device status is "Compliant" or "Noncompliant" (not "Unknown" or "Error")
   - ✅ No error 0x80180014 in compliance details
   - ✅ Last check-in is current (within last 24 hours)

3. **Policy Application:**
   ```
   [Device record] > Configuration
   ```
   - ✅ All assigned policies show as "Applied"
   - ✅ Policy count matches expected (e.g., 4 of 4 applied, not 0 of 4)
   - ✅ No policies in "Error" or "Conflict" state

4. **Autopilot Record:**
   ```
   Devices > Windows > Windows enrollment > Devices (Autopilot)
   ```
   - ✅ Device appears in list
   - ✅ Autopilot profile shown and is correct
   - ✅ Assignment status confirms group membership

5. **Entra Device Object:**
   ```
   Microsoft Entra admin center > Devices > All devices [search device]
   ```
   - ✅ Exactly ONE object for device hardware
   - ✅ Join type: "Azure AD joined" or "Hybrid Azure AD joined" (as expected)
   - ✅ No stale/duplicate entries

### Post-Remediation Checks (Device)

1. **Work/School Connection:**
   ```
   Settings > Accounts > Access work or school
   ```
   - ✅ Only expected organization connection(s) listed
   - ✅ No duplicate or stale connections
   - ✅ Status shows "Connected"

2. **Local Enrollment State:**
   ```
   dsregcmd /status (elevated)
   ```
   - ✅ Output shows expected Azure AD join state
   - ✅ No error entries
   - ✅ Workplace Join matches expected state (typically NO for Autopilot)
   - ✅ No stale account listings

3. **User Access:**
   - ✅ User can access company resources (email, file shares, apps)
   - ✅ Windows Hello for Business or PIN works if configured
   - ✅ No "This PC cannot connect to your work account" messages

### Success Criteria Summary
```
Error 0x80180014 RESOLVED if:
✅ Enrollment completes without error
✅ Device shows "Managed by Intune" with no conflicts
✅ 4 of 4 policies applied (or expected policy count)
✅ No legacy enrollment traces in Intune or Entra
✅ Device-side work/school connections cleaned up
✅ User can access resources normally
```

---

## Preventive Actions

### Pre-Autopilot Hygiene Checklist
Implement this checklist **before assigning Autopilot** to any device:

**Admin Center Verification (Intune):**
- [ ] Device name/serial NOT currently in Intune > Devices > All devices
- [ ] Device name/serial NOT found as stale record in Intune device history
- [ ] Device hardware hash NOT in Autopilot registry (unless intentional re-enrollment)
- [ ] No multiple Intune records exist for same hardware

**Entra Verification:**
- [ ] Device name/serial NOT in Entra > Devices > All devices
- [ ] No duplicate Entra objects for same hardware
- [ ] No stale device objects >90 days old for this hardware

**Device-Side Verification (if physical access available):**
- [ ] Settings > Accounts > Access work or school shows NO work connections
- [ ] `dsregcmd /status` output shows clean state (no legacy enrollment entries)
- [ ] Device has NOT been previously enrolled in legacy manual MDM

**Result:**
- If all checks pass → Autopilot assignment can proceed
- If any check fails → remediate before Autopilot assignment

### Organizational Implementation
1. Add hygiene checklist to Autopilot deployment runbook
2. Create an automated report: "Legacy MDM Enrollments" (devices >90 days idle in Intune)
3. Proactively retire/delete stale records monthly
4. Audit Entra device objects quarterly for duplicates
5. Document device disposition (device decommissioned vs. reprovisioned) to prevent legacy records after reuse

---

## Troubleshooting Edge Cases

### Scenario: Error 0x80180014 + Error 0x80070005
**Description:**  
Enrollment fails with 0x80180014, and during policy application phase, policies fail with 0x80070005 (Access denied)

**Cause:**  
Legacy enrollment has partially initialized; policy engine tries to apply policies to the half-enrolled device but lacks permissions.

**Resolution:**
- Ensure complete deletion of legacy device record (not just retire)
- Clear device-side local state thoroughly (consider `dsregcmd /leave` if needed)
- Verify policy targeting groups include device/user AFTER cleanup
- Re-reboot device and re-attempt enrollment

---

### Scenario: Stale Record Fails to Retire
**Description:**  
Clicking "Retire" on legacy device record shows "Retirement failed" error

**Cause:**  
Device may be offline, have network connectivity issues, or policy conflicts preventing graceful retirement

**Resolution:**
- Skip retirement, proceed directly to "Delete"
- Investigate device network connectivity separately if needed
- After cleanup, ensure device can reach Microsoft endpoints (may need proxy review)

---

### Scenario: Device Still Shows 0 of 4 Policies After Cleanup
**Description:**  
After remediation, device is enrolled but policies show "0 of 4 applied"

**Cause:**
1. Policies haven't evaluated yet (< 5 minute grace period)
2. Device group membership doesn't include device (targeting filter issue)
3. Policies are stale/not deployable
4. Device lacks network connectivity to Intune

**Resolution:**
- Wait 10 minutes and refresh (policies evaluate on check-in cadence)
- In Intune > [Policy] > Assignments, verify device group is targeted
- Check device network connectivity (ping microsoft.com, test Intune endpoints)
- Force device check-in: `C:\Program Files\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe /forcepolicyfetch`

---

### Scenario: Multiple Autopilot Records for Same Hardware
**Description:**  
Device appears multiple times in Windows Autopilot devices list

**Cause:**  
Device was imported/re-imported multiple times, or hardware was provisioned to multiple users

**Resolution:**
- Identify the **correct** Autopilot record (associated with current user/target profile)
- Deregister or archive the **duplicate** records
- Verify device will only attempt enrollment against the correct record

---

## Monitoring & Alerting

### KPIs to Monitor
1. **Autopilot enrollment success rate** (target: > 95%)
2. **Error 0x80180014 incident rate** (target: < 2% of enrollments)
3. **Device records age distribution** (stale records should be < 1% of total)
4. **Duplicate Entra device objects** (target: 0)

### Recommended Alerts
- Alert if error 0x80180014 appears in > 5 devices in 24-hour window
- Alert if Intune detects device with multiple active enrollments
- Alert on devices with "Enrollment failed" status for > 48 hours
- Report stale device records (>90 days, no check-in) monthly

---

## Related Documentation
- [Known Error: Autopilot Enrollment Failure – Legacy MDM Conflict](KE-AP-001)
- [L1 KB: Troubleshooting Autopilot Enrollment Error 0x80180014](KB-AP-001)
- [Autopilot Pre-Deployment Checklist](KB-AP-003)
- [Intune Device Retirement vs. Delete Best Practices](KB-INTUNE-004)
- [Entra Device Management – Cleanup & Deduplication](KB-ENTRA-005)

---

## Support Contacts & Escalation

**L2/L3 Support for this issue:**
- Primary: Mobile Device Management Team
- Secondary: Intune Platform Support
- Escalation: Cloud Infrastructure – Entra / Intune Services

---

## Revision History
| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2024-03-15 | 1.0 | L2 Support | Initial documentation after incident resolution |

