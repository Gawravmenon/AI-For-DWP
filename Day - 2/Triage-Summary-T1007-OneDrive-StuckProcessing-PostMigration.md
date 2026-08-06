# Structured Triage Summary

**Ticket:** T-1007

## Summary (one line)
OneDrive has been stuck on 'processing changes' since a migration, with files reported as missing locally.

## Impact (who / how many / business urgency)
- Who: Single user (to verify — confirm name, team, and department)
- How many: One reported; unknown whether other users from the same migration batch are affected (to verify)
- Business urgency: High — files reported as missing locally; potential data access risk until sync state is confirmed safe. Do not advise deletion of any files until sync state is fully understood.

## Known Facts
- OneDrive sync status has been stuck on "processing changes" since a migration event
- User reports files are missing locally
- Duration: ongoing since migration (exact migration date/time to verify)
- Whether files are missing from OneDrive cloud, locally only, or both is not yet confirmed

## Missing Information to Gather
- User identity, contact details, and department
- Type of migration performed (tenant-to-tenant, SharePoint migration, account rename, licence change — to verify)
- How long OneDrive has been in "processing changes" state
- Whether files are confirmed present in OneDrive cloud via browser (to verify before any local action)
- Whether the user has moved, deleted, or renamed files manually during or after migration
- Device name/asset ID and OneDrive client version
- Whether available local disk space is sufficient for the sync (to verify)
- Whether OneDrive shows any specific error icon, error message, or conflict markers (to verify)
- Whether other users migrated at the same time are experiencing the same issue (to verify)
- Whether IT/migration team has confirmed migration completed successfully for this user's account (to verify)

## Likely Category
- Likely category: Cloud storage / OneDrive sync failure post-migration
- Sub-category: Account relink, sync conflict, or migration incomplete (to verify)
- Incident vs. Service Request: Treat as incident until file safety is confirmed; escalate to migration team immediately if files cannot be located in the cloud

## Suggested First Diagnostic Step
Before touching the local OneDrive folder or resetting the client, instruct the user to open OneDrive via browser and confirm whether the files are present in the cloud. This establishes whether files are safe in the cloud (sync issue only) or genuinely missing (potential data loss requiring immediate escalation). Do not reset OneDrive sync or unlink the account until cloud file presence is confirmed.
