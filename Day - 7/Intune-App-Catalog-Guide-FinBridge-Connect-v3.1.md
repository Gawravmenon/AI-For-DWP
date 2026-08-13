# Intune App Catalog Guide: FinBridge Connect v3.1 (.intunewin)

Purpose: This guide shows a DWP engineer how to add a Windows application to the Intune app catalog before any phased rollout begins.

Worked example used throughout:
Application: FinBridge Connect v3.1
Package type: .intunewin
Install command: FinBridgeConnect_Setup.exe /silent
Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
Detection method: Registry key HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1

Important note for all steps: Intune UI labels can vary by tenant version, service release, and portal experience. Use the paths below as the expected route, but verify against your live tenant and do not trust wording blindly.

1. Sign in to the Intune admin center.
Expected portal: https://intune.microsoft.com
Verify you are in the correct tenant before creating the app.

2. Go to the app catalog area.
Expected navigation path: Home > Apps > All apps > Add.
Label-variance warning: In some tenants this appears as Apps > Windows apps, or the Add button appears inside a Windows-specific view. Verify the live navigation labels.

3. Choose the correct app type.
Use these selection rules:
For FinBridge Connect (.intunewin): select Windows app (Win32) (sometimes shown as Win32 app or Windows app (Win32)).
For Microsoft Store applications: select Microsoft Store app (new) (or equivalent Store app label in your tenant).
For a web link shortcut: select Web link.
Label-variance warning: The exact names in the Select app type panel may differ. Confirm by description and package type, not label text alone.

4. Start app creation for the .intunewin package.
Select Windows app (Win32), then upload the FinBridge Connect v3.1 .intunewin file when prompted.
If the wizard asks for the setup file name, select FinBridgeConnect_Setup.exe from the packaged content list.

5. Complete App Information fields.
Enter at minimum:
Name: FinBridge Connect
Description: FinBridge Connect desktop client for enterprise secure finance connectivity.
Publisher: FinBridge
Version: 3.1
Optional but recommended: category, information URL, privacy URL, logo.
Label-variance warning: This page may be called App information, Properties, or Information in different portal revisions.

6. Complete Program fields.
Enter:
Install command: FinBridgeConnect_Setup.exe /silent
Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
Install behavior: System (recommended for device-wide enterprise app installs)
Use User context only if the app is designed per-user and does not require machine-wide resources.
Label-variance warning: Install behavior may be shown as Device context vs User context in some tenants. Device/System are equivalent concepts here.

7. Configure Requirements.
Set the minimum supported platform so unsupported devices are excluded.
Enter:
Operating system architecture: choose the architecture your package supports (for example 64-bit, or 32-bit and 64-bit if both are supported).
Minimum operating system: select the approved baseline for your estate (for example Windows 10 21H2 or Windows 11 equivalent baseline).
Label-variance warning: Requirement field order and naming may vary by tenant.

8. Configure Detection Rules.
Purpose: Detection tells Intune how to confirm installation success.
For this worked example, use a Registry detection rule:
Rule type: Registry
Key path: HKLM\SOFTWARE\FinBridge\Connect
Value name: Version
Detection method: String comparison
Operator: Equals
Expected value: 3.1
Label-variance warning: Some tenants present this as Detection rules > Add rule, with slightly different operator names.

9. Understand alternate detection options.
Use MSI product code detection when deploying MSI-based installers and product code is reliable.
Use file or folder detection when the app consistently writes a known executable or file path.
Use registry detection when version data is reliably written to a stable key/value pair.

10. Configure Return Codes.
Purpose: Return codes map installer exit codes to Intune outcomes.
At minimum, verify these standard mappings are present:
0 = Success
3010 = Soft reboot
1641 = Hard reboot
Any unexpected non-mapped code should be treated as Failure until validated.
Label-variance warning: Some tenants expose Return codes in a dedicated page; others include it under Program or Advanced.

11. Review and create the app object.
Validate that package, commands, requirements, detection rule, and return codes match the deployment design.
Select Create.

12. Confirm app object appears in the catalog.
Go to Apps > All apps and search for FinBridge Connect.
Open the app and verify the Overview/Properties values are correct.
Check specifically that the install and uninstall commands and detection rule were saved exactly.

13. Prepare pilot assignments before broad rollout.
Create or select a small pilot group (for example 10-50 representative devices/users across roles and hardware profiles).
Do not assign directly to the full 10,000-device fleet on first deployment.
Reason: pilot rollout reduces blast radius, validates install behavior and detection accuracy, and catches environment-specific conflicts before mass impact.

14. Understand assignment intent types.
Required: Intune automatically installs the app on targeted devices/users.
Available for enrolled devices: app is listed in Company Portal and users can choose to install.
Uninstall: Intune removes the app from targeted devices/users.
Label-variance warning: The Assignment type labels can differ slightly by tenant and app type.

15. Assign FinBridge Connect to pilot first.
Open the app > Assignments > Add group.
Set assignment intent to Required for the pilot group only.
Keep production-wide groups unassigned until pilot success criteria are met.

16. Verify install status from Intune.
In the app record, open Monitor (or Device install status/User install status view).
Review counts and device-level results.
Look for pilot device transitions from Pending to Installed.

17. Verify on an assigned test device.
On the test endpoint, sync policy from Company Portal or Settings > Accounts > Access work or school > Info > Sync.
Wait for policy processing, then confirm FinBridge Connect is installed.
Confirm detection evidence exists:
Registry path HKLM\SOFTWARE\FinBridge\Connect
Registry value Version equals 3.1

18. Interpret common Intune status values.
Installed: Intune detected the app successfully based on detection rules.
Failed: Installation did not complete successfully, or detection did not match expected state after install.
Not applicable: Device does not meet requirement filters (for example OS version or architecture mismatch), or assignment scope does not apply to that object.

19. Gate for phased rollout.
Only move beyond pilot when all are true:
Pilot install success rate is acceptable.
No critical failures remain untriaged.
Detection is consistent across pilot devices.
Uninstall path is validated.
After this gate, expand from pilot to phased rings, then broad deployment.

20. Tenant-label verification reminder.
At each wizard page, confirm you are selecting by function, not by exact UI text.
If labels differ, match by page purpose: App Information, Program, Requirements, Detection Rules, Return Codes, Assignments, and Monitoring.
Record any tenant-specific naming differences in your change notes so future engineers can follow your exact environment.