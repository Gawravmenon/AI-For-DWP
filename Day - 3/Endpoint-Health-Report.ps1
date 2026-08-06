<#
.SYNOPSIS
Read-only endpoint health report for DWP engineers (PowerShell 5.1).

.DESCRIPTION
Collects endpoint health signals without modifying system state.
All checks are read-only queries against local system data, event logs, services,
process telemetry, and an external download speed test.

VERIFY BEFORE RUNNING
1) Run context: Some sections (event logs, certain registry locations) may require elevated rights.
2) Internet speed section: Confirms outbound HTTPS access and DNS resolution to public test hosts, and that proxy rules allow downloads.
3) Bandwidth impact: Speed test intentionally downloads data (~10 MB) and may affect active network usage.
4) Environment: Script is written for Windows PowerShell 5.1.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# A helper to safely run each section and keep the report going if one check fails.
function Invoke-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
    }
    catch {
        [pscustomobject]@{
            Section = $Name
            Error   = $_.Exception.Message
        }
    }
}

Write-Host "==============================================="
Write-Host "DWP Endpoint Health Report (Read-Only)"
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Computer : $env:COMPUTERNAME"
Write-Host "User     : $env:USERNAME"
Write-Host "==============================================="
Write-Host ""

# 1) System uptime
# This section calculates how long the system has been running since last boot.
$uptime = Invoke-Section -Name 'System Uptime' -ScriptBlock {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptimeSpan = (Get-Date) - $lastBoot

    [pscustomobject]@{
        LastBootTime = $lastBoot
        UptimeDays   = [math]::Floor($uptimeSpan.TotalDays)
        UptimeHours  = $uptimeSpan.Hours
        UptimeMins   = $uptimeSpan.Minutes
    }
}

# 2) Free disk space
# This section lists local fixed drives and reports total, used, and free space in GB.
$disk = Invoke-Section -Name 'Free Disk Space' -ScriptBlock {
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" |
        Select-Object DeviceID,
            @{ Name = 'TotalGB'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
            @{ Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
            @{ Name = 'UsedGB'; Expression = { [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2) } },
            @{ Name = 'FreePercent'; Expression = { if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 } } }
}

# 3) Pending reboot check (registry)
# This section checks common reboot-pending registry indicators and reports if any are present.
$pendingReboot = Invoke-Section -Name 'Pending Reboot' -ScriptBlock {
    $pathsToCheck = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing'; Name = 'RebootPending' },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update'; Name = 'RebootRequired' },
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name = 'PendingFileRenameOperations' }
    )

    $hits = @()

    foreach ($item in $pathsToCheck) {
        if (Test-Path -Path $item.Path) {
            $regValue = Get-ItemProperty -Path $item.Path -ErrorAction SilentlyContinue
            if ($null -ne $regValue -and ($regValue.PSObject.Properties.Name -contains $item.Name)) {
                $valueData = $regValue.$($item.Name)
                $hasPendingSignal = $false

                if ($valueData -is [array]) {
                    $hasPendingSignal = ($valueData.Count -gt 0)
                }
                elseif ($null -ne $valueData) {
                    $hasPendingSignal = $true
                }

                if ($hasPendingSignal) {
                    $hits += "$($item.Path) :: $($item.Name)"
                }
            }
        }
    }

    [pscustomobject]@{
        RebootPending = ($hits.Count -gt 0)
        SignalsFound  = if ($hits.Count -gt 0) { $hits -join '; ' } else { 'None' }
    }
}

# 4) Top 5 processes by Working Set (memory)
# This section shows the five processes currently using the most physical memory (working set).
$topMemory = Invoke-Section -Name 'Top Memory Processes' -ScriptBlock {
    Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 ProcessName, Id,
            @{ Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
}

# 5) Top 5 processes by CPU
# This section shows the five processes with the highest cumulative CPU time since process start.
$topCpu = Invoke-Section -Name 'Top CPU Processes' -ScriptBlock {
    Get-Process |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 ProcessName, Id,
            @{ Name = 'CPUSeconds'; Expression = { [math]::Round($_.CPU, 2) } }
}

# 6) Last 5 system log errors
# This section reads the System event log and returns the most recent five Error-level entries.
$lastSystemErrors = Invoke-Section -Name 'Last 5 System Errors' -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
        Select-Object TimeCreated, Id, ProviderName, Message
}

# 7) Internet speed
# This section estimates download speed (Mbps) by downloading test data into memory only (no file writes).
# It tries multiple public endpoints so one DNS or host failure does not break the check.
$internetSpeed = Invoke-Section -Name 'Internet Speed' -ScriptBlock {
    $testUrls = @(
        'https://proof.ovh.net/files/10Mb.dat',
        'https://speed.cloudflare.com/__down?bytes=10000000',
        'https://speed.hetzner.de/10MB.bin'
    )

    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($testUrl in $testUrls) {
        $uri = [System.Uri]$testUrl

        try {
            [void][System.Net.Dns]::GetHostAddresses($uri.Host)
        }
        catch {
            $errors.Add("DNS lookup failed for $($uri.Host): $($_.Exception.Message)")
            continue
        }

        $webClient = New-Object System.Net.WebClient
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $bytes = $webClient.DownloadData($testUrl)
            $stopwatch.Stop()

            if ($null -eq $bytes -or $bytes.Length -le 0) {
                $errors.Add("Download returned no data from $testUrl")
                continue
            }

            $seconds = [math]::Max($stopwatch.Elapsed.TotalSeconds, 0.001)
            $mbps = (($bytes.Length * 8) / 1MB) / $seconds

            [pscustomobject]@{
                Status           = 'Success'
                TestURL          = $testUrl
                DownloadedMB     = [math]::Round($bytes.Length / 1MB, 2)
                DurationSeconds  = [math]::Round($seconds, 2)
                EstimatedMbps    = [math]::Round($mbps, 2)
                Notes            = 'Download-only measurement. Result can vary by route/proxy/load.'
            }

            return
        }
        catch {
            $errors.Add("Download failed from ${testUrl}: $($_.Exception.Message)")
        }
        finally {
            if ($stopwatch.IsRunning) {
                $stopwatch.Stop()
            }
            $webClient.Dispose()
        }
    }

    [pscustomobject]@{
        Status        = 'Failed'
        TestURL       = 'None'
        DownloadedMB  = 0
        DurationSeconds = 0
        EstimatedMbps = $null
        Notes         = ($errors -join ' | ')
    }
}

# 8) Microsoft Defender service status
# This section checks whether the Windows Defender service is present and currently running.
$defenderStatus = Invoke-Section -Name 'Defender Service Status' -ScriptBlock {
    $svc = Get-Service -Name 'WinDefend' -ErrorAction Stop
    [pscustomobject]@{
        ServiceName = $svc.Name
        DisplayName = $svc.DisplayName
        Status      = $svc.Status.ToString()
        IsRunning   = ($svc.Status -eq 'Running')
    }
}

# 9) Number of users logged in
# This section counts interactive user sessions (console/RDP/cached interactive) from logon session data.
$loggedInUsers = Invoke-Section -Name 'Logged In Users' -ScriptBlock {
    $interactiveTypes = @(2, 10, 11)

    $sessions = Get-CimInstance -ClassName Win32_LogonSession |
        Where-Object { $interactiveTypes -contains $_.LogonType }

    $userRefs = foreach ($session in $sessions) {
        Get-CimAssociatedInstance -InputObject $session -Association Win32_LoggedOnUser -ErrorAction SilentlyContinue
    }

    $realUsers = $userRefs |
        Where-Object {
            $_.Name -and
            $_.Name -notmatch '^DWM-' -and
            $_.Name -notmatch '^UMFD-' -and
            $_.Name -ne 'LOCAL SERVICE' -and
            $_.Name -ne 'NETWORK SERVICE' -and
            $_.Name -ne 'SYSTEM'
        } |
        Select-Object -Property Domain, Name -Unique

    [pscustomobject]@{
        LoggedInUserCount = @($realUsers).Count
        Users             = if (@($realUsers).Count -gt 0) { ($realUsers | ForEach-Object { "$($_.Domain)\$($_.Name)" }) -join '; ' } else { 'None detected' }
    }
}

# 10) Last Windows Update install time
# This section reads installed hotfix history and reports the most recent update date if available.
$lastUpdate = Invoke-Section -Name 'Last Windows Update' -ScriptBlock {
    $hotfixes = Get-HotFix | Where-Object { $_.InstalledOn -is [datetime] }

    if ($hotfixes) {
        $latest = $hotfixes | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
        [pscustomobject]@{
            LastUpdateDate = $latest.InstalledOn
            HotFixID       = $latest.HotFixID
            Description    = $latest.Description
        }
    }
    else {
        [pscustomobject]@{
            LastUpdateDate = $null
            HotFixID       = 'Unknown'
            Description    = 'No dated hotfix entries returned by Get-HotFix.'
        }
    }
}

# Output report
Write-Host "[1] System Uptime"
$uptime | Format-List
Write-Host ""

Write-Host "[2] Free Disk Space"
$disk | Format-Table -AutoSize
Write-Host ""

Write-Host "[3] Pending Reboot (Registry Check)"
$pendingReboot | Format-List
Write-Host ""

Write-Host "[4] Top 5 Processes by Memory (Working Set)"
$topMemory | Format-Table -AutoSize
Write-Host ""

Write-Host "[5] Top 5 Processes by CPU"
$topCpu | Format-Table -AutoSize
Write-Host ""

Write-Host "[6] Last 5 System Log Errors"
$lastSystemErrors | Format-Table -Wrap -AutoSize
Write-Host ""

Write-Host "[7] Internet Speed"
$internetSpeed | Format-List
Write-Host ""

Write-Host "[8] Microsoft Defender Service"
$defenderStatus | Format-List
Write-Host ""

Write-Host "[9] Logged In Users"
$loggedInUsers | Format-List
Write-Host ""

Write-Host "[10] Last Windows Update"
$lastUpdate | Format-List
Write-Host ""

Write-Host "Report complete. Script performed read-only checks only."
