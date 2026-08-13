# End-User Communication: Copilot Ticket Updates

Date: 2026-08-12

Hello everyone,

Thanks for raising your Copilot issues. We reviewed each case and, in plain terms, most of these are access, setup, or data timing issues rather than a Copilot product bug.

Below is a clear update for each ticket and what to do next.

## Ticket 1: Finance lead - Copilot will not summarize Q3 board pack in SharePoint

What is likely happening:
- You can open the file, but Copilot may still be blocked from using it because of protection settings (for example, sensitivity policy restrictions).

What you should do next:
1. Check the file's sensitivity label.
2. Ask your M365 admin to confirm whether Copilot is allowed to process files with that label.
3. If policy allows it and it still fails, share the file link and exact prompt used so support can test the same path.

## Ticket 2: New hire - Copilot in Outlook knows nothing about recent emails

What is likely happening:
- New accounts often need time before email/activity data is fully available to Copilot.
- In some cases, the Copilot license is assigned but not fully active yet.

What you should do next:
1. Confirm with IT that your Copilot license is active.
2. Wait for initial indexing/settling time for a new account.
3. Retry with a narrow prompt, for example: "Summarize my emails from today about onboarding tasks."

## Ticket 3: HR manager - Copilot in Word says it does not have access to salary review spreadsheet

What is likely happening:
- Copilot is respecting access controls. If access is restricted, Copilot will not pull from that spreadsheet.

What you should do next:
1. Open the spreadsheet directly using the same account signed into Word.
2. If access fails or is limited, request the required permission from the file owner.
3. If you can open it fully but Copilot still says no access, send support the file path and screenshot of the message.

## Ticket 4: Sales rep - Copilot in Teams cannot find a contract shared via guest link from another organization

What is likely happening:
- Guest/external sharing links from another tenant are often limited for Copilot grounding.

What you should do next:
1. Confirm whether the file is hosted in another organization's tenant.
2. Ask the owner to share through an internal approved location if business policy allows.
3. Retry by providing clear file context in your prompt.

## Ticket 5: IT admin - Copilot stopped for whole Finance team this morning

What is likely happening:
- A broad outage for one group is often caused by licensing or service-plan assignment changes.

What you should do next:
1. Check Copilot license assignment for the whole Finance group.
2. Confirm no service plan was disabled in group-based licensing.
3. If licensing is correct and issue continues tenant-wide for that group, raise to support with timestamp and affected user list.

## Ticket 6: Manager - Copilot summarized a file you do not remember opening

What is likely happening:
- Copilot can use content you currently have permission to access, even if you forgot that permission existed.

What you should do next:
1. Review your current access to the folder/file.
2. If access is no longer needed, ask the owner/admin to remove it.
3. Use this as a permission hygiene check for old folder access.

## Ticket 7: Analyst - Copilot gives generic answers and does not seem to use internal SharePoint content

What is likely happening:
- This usually means Copilot cannot reliably ground in relevant internal content yet (access scope, indexing freshness, or setup prerequisites).

What you should do next:
1. Test with one known SharePoint file you can open.
2. Ask Copilot about that exact file name or topic from that file.
3. If still generic, send support the file link, your exact prompt, and time tested.

## Ticket 8: Executive assistant - Copilot in Outlook cannot see shared mailbox calendar managed for director

What is likely happening:
- Shared/delegated mailbox calendar scenarios can have access-model limits compared with your own primary mailbox.

What you should do next:
1. Confirm whether the request is for a delegated/shared mailbox calendar.
2. Test the same ask on your own mailbox calendar to compare behavior.
3. Share both results with support so they can validate delegated-calendar support for your client/version.

## What support may ask from you (to speed up resolution)

Please include:
- Exact prompt used
- App and platform (Outlook desktop/web, Teams desktop/web, Word desktop/web)
- Time of test
- Link to the affected file/mailbox (if allowed)
- Screenshot of the exact error message

This helps us resolve issues faster and avoid repeated troubleshooting steps.
