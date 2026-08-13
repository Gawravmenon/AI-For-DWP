# L1 KB: Troubleshooting Autopilot Enrollment Error 0x80180014

**Knowledge Base ID:** KB-AP-001  
**Title:** Windows Autopilot Enrollment Fails with Error 0x80180014 – Device Already Enrolled in MDM  
**Audience:** L1 Service Desk, First-Line Support  
**Last Updated:** 2024-03-15  
**Severity:** High  

---

## Quick Reference

| Aspect | Details |
|--------|---------|
| **Error Code** | 0x80180014 |
| **Error Message** | "The device is already enrolled in MDM" |
| **Common Cause** | Legacy/stale MDM enrollment preventing Autopilot enrollment |
| **Typical Resolution Time** | 30–60 minutes (including device access) |
| **Escalation Path** | L2 Support if Phase 2 (device actions) cannot be completed |

---

## Step-by-Step Troubleshooting

### Step 1: Verify Symptom (2 minutes)
Confirm user is experiencing error 0x80180014 during Autopilot enrollment:
- Ask user: "Does your error message mention 'already enrolled in MDM'?"
- Ask user: "What stage of Windows setup did this occur?" (OOBE is most common)
- Collect device name and serial number

**If symptom doesn't match**, escalate to L2 Support.

---

### Step 2: Check Device Status in Intune (5 minutes)
Access Intune admin center as IT admin:
1. Navigate to **Devices > All devices**
2. Search for device by name (e.g., DESKTOP-FB099)
3. Check if **multiple device records** exist for same hardware/user
4. Look for "Managed by MDM" status and check-in age
5. **Document findings:**
   - How many records found?
   - What are the creation dates?
   - Is there a stale/old record alongside a newer one?

**Expected finding:** You should see an old device record with enrollment date from weeks/months prior.

---

### Step 3: Check Autopilot Registration (5 minutes)
Still in Intune admin center:
1. Navigate to **Devices > Windows > Windows enrollment > Devices (Windows Autopilot)**
2. Search for the device by serial number or hardware hash
3. Verify the Autopilot record is present and shows:
   - Correct Autopilot profile assigned
   - Target group includes the device/user

**If Autopilot record is missing**, escalate to L2 Support.

---

### Step 4: L1 Escalation to L2 (Handoff Point)
At this point, **escalate to L2 Support** with the following information:

**Escalation Ticket Should Include:**
- Device name and serial number
- User name and organization
- Screenshot showing "Managed by MDM" status from Intune
- Number of device records found for same hardware
- Creation dates of all device records
- Confirmation that Autopilot record exists and is assigned correctly

**Do NOT attempt admin center cleanup or device-side actions** as an L1 analyst. L2 will coordinate the multi-phase remediation.

---

## When to Escalate (Before Step 4)

Escalate immediately to L2 if:
- ✅ Error code is NOT 0x80180014 (different error)
- ✅ Device cannot be found in Intune (never enrolled)
- ✅ Autopilot record is missing for a device that should have one
- ✅ Device has error 0x80070005 in addition to 0x80180014
- ✅ User cannot provide device access for device-side troubleshooting

---

## User Communication Script

Once you've escalated, provide this communication to the user:

---

**Dear [User],**

Thank you for reporting the enrollment issue with your device [DEVICE-NAME]. Our technical team has identified the root cause and is working on a resolution.

**What's happening:**  
Your device has an older enrollment record that's preventing the new Autopilot enrollment. Our support team is removing the old record and will re-start the enrollment process.

**What we need from you:**  
We may need temporary access to your device to complete the cleanup. IT will contact you to schedule this (typically 15–30 minutes).

**Next steps:**  
- We will notify you once the old record is removed
- We will provide instructions for re-starting the enrollment
- The entire process should be complete within 24 hours

**Questions?**  
Contact the Service Desk at [CONTACT INFO]

---

## Related Articles
- [L2/L3 KB: Autopilot Enrollment – Deep Technical Troubleshooting](KB-AP-002)
- [Known Error: Autopilot Enrollment Failure Due to Legacy MDM Enrollment](KE-AP-001)
- [Autopilot Pre-Deployment Checklist](KB-AP-003)

---

## Additional Notes
- This error typically appears in hybrid Azure AD joined or Azure AD joined scenarios
- Error most common during device re-provisioning or re-enrollment after manual MDM removal
- Prevention: Run legacy enrollment hygiene check before assigning Autopilot profile

