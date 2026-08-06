<#
.SYNOPSIS
Displays a small endpoint health summary.

.DESCRIPTION
Collects basic computer details, free space on the C drive, the top five
memory-consuming processes, recent system error events, and a count of stale
user profiles that have not been used in the last 90 days.

.AUTHOR
Unknown

.HOW TO RUN
Run from PowerShell:
  .\inherit.ps1

.NOTES
This refactor improves readability only. It does not change the script's behavior.
#>

# Get core computer details such as the device name and total physical memory.
$computerSystem = Get-CimInstance Win32_ComputerSystem

# Get the amount of free space on the C drive in bytes.
$freeBytesOnCDrive = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the five running processes using the most working set memory.
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get up to 10 recent System log entries and keep only those marked as errors.
$recentSystemErrors = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}

# Get local user profiles and keep only non-system profiles that have not been used in over 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}

# Display the computer name and total physical memory.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory

# Display the free space on the C drive in gigabytes, rounded to two decimal places.
Write-Host ([math]::Round($freeBytesOnCDrive/1GB,2)) 'GB free'

# Display the name and working set memory usage for each of the top memory-consuming processes.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Display the timestamp and message for each recent System error event.
$recentSystemErrors | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If any stale user profiles were found, display how many were detected.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }