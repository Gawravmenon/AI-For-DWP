[CmdletBinding()]
param(
    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [string]$OutputRoot = "$env:ProgramData\Floor6Evidence",

    [Parameter()]
    [datetime]$StartTime = (Get-Date).Date.AddDays(-3).AddHours(12),

    [Parameter()]
    [datetime]$EndTime = (Get-Date),

    [Parameter()]
    [string]$AppNameKeyword = "document"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-WarnMsg {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    if ($DryRun) {
        Write-Host "[DRYRUN] Would run: $Name" -ForegroundColor DarkYellow
        return
    }

    Write-Info "Running: $Name"
    & $Action
}

function Export-Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    if ($DryRun) {
        Write-Host "[DRYRUN] Would write text file: $Path" -ForegroundColor DarkYellow
        return
    }

    $Lines | Out-File -FilePath $Path -Encoding utf8
}

function Export-Object {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [object]$Data
    )

    if ($DryRun) {
        Write-Host "[DRYRUN] Would write JSON file: $Path" -ForegroundColor DarkYellow
        return
    }

    $Data | ConvertTo-Json -Depth 6 | Out-File -FilePath $Path -Encoding utf8
}

if ($EndTime -lt $StartTime) {
    throw "EndTime must be greater than or equal to StartTime."
}

$runStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDir = Join-Path $OutputRoot ("Floor6-AppDeploymentEvidence-{0}-{1}" -f $env:COMPUTERNAME, $runStamp)

Write-Info "Top-ranked cause targeted: Friday app deployment causing sign-in install/retry load."
Write-Info "Time window: $StartTime to $EndTime"
Write-Info "App keyword filter: $AppNameKeyword"

if ($DryRun) {
    Write-Host "[DRYRUN] No files will be written." -ForegroundColor DarkYellow
} else {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Info "Evidence output folder: $outputDir"
}

$summary = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    StartTime = $StartTime
    EndTime = $EndTime
    AppNameKeyword = $AppNameKeyword
    IsDryRun = [bool]$DryRun
    Findings = [ordered]@{}
}

Invoke-Step -Name "Capture device baseline" -Action {
    $baseline = [ordered]@{
        Timestamp = Get-Date
        OS = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, LastBootUpTime
        ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory
        CurrentUser = [ordered]@{
            UserName = $env:USERNAME
            UserDomain = $env:USERDOMAIN
        }
    }

    if (-not $DryRun) {
        Export-Object -Path (Join-Path $outputDir "01-Baseline.json") -Data $baseline
    }
}

Invoke-Step -Name "Capture Entra/AAD registration status" -Action {
    $dsregPath = Join-Path $outputDir "02-dsreg-status.txt"
    if ($DryRun) {
        Write-Host "[DRYRUN] Would run dsregcmd /status and write: $dsregPath" -ForegroundColor DarkYellow
    } else {
        dsregcmd /status | Out-File -FilePath $dsregPath -Encoding utf8
    }
}

Invoke-Step -Name "Collect installed app evidence from registry" -Action {
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = foreach ($path in $uninstallPaths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSPath
    }

    $filtered = $apps | Where-Object { $_.DisplayName -match [regex]::Escape($AppNameKeyword) }

    if (-not $DryRun) {
        $apps | Sort-Object DisplayName | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $outputDir "03-AllInstalledApps.csv")
        $filtered | Sort-Object DisplayName | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $outputDir "04-KeywordMatchedApps.csv")
    }

    $summary.Findings.KeywordMatchedInstalledApps = @($filtered).Count
}

Invoke-Step -Name "Collect Intune Management Extension logs and keyword hits" -Action {
    $imeLogDir = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
    $hitLines = @()
    $logFiles = @()

    if (Test-Path $imeLogDir) {
        $logFiles = Get-ChildItem -Path $imeLogDir -File -ErrorAction SilentlyContinue
    }

    $pattern = "(?i)($([regex]::Escape($AppNameKeyword))|install|retry|fail|error|detection)"

    foreach ($file in $logFiles) {
        $matches = Select-String -Path $file.FullName -Pattern $pattern -ErrorAction SilentlyContinue
        if ($matches) {
            $hitLines += $matches | ForEach-Object {
                "[{0}] {1}: {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim()
            }
        }
    }

    if (-not $DryRun) {
        Export-Text -Path (Join-Path $outputDir "05-IME-KeywordHits.txt") -Lines ($hitLines | Select-Object -First 3000)
    }

    $summary.Findings.IMELogFilesFound = @($logFiles).Count
    $summary.Findings.IMEKeywordHits = @($hitLines).Count
}

Invoke-Step -Name "Collect deployment and app-related event logs in time window" -Action {
    $logSpecs = @(
        @{ LogName = "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin"; File = "06-DM-EDP-Admin.evtx.txt" },
        @{ LogName = "Application"; File = "07-Application-MSI.evtx.txt" },
        @{ LogName = "System"; File = "08-System-Services.evtx.txt" },
        @{ LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"; File = "09-LogonPerformance.evtx.txt" },
        @{ LogName = "Microsoft-Windows-Winlogon/Operational"; File = "10-Winlogon.evtx.txt" },
        @{ LogName = "Microsoft-Windows-AAD/Operational"; File = "11-AAD-Operational.evtx.txt" }
    )

    $totalEvents = 0

    foreach ($spec in $logSpecs) {
        try {
            $events = Get-WinEvent -FilterHashtable @{ LogName = $spec.LogName; StartTime = $StartTime; EndTime = $EndTime } -ErrorAction Stop

            if ($spec.LogName -eq "Application") {
                $events = $events | Where-Object {
                    $_.ProviderName -match "MsiInstaller|AppModel-Runtime|Application Error"
                }
            }

            if ($spec.LogName -eq "System") {
                $events = $events | Where-Object {
                    $_.ProviderName -match "Service Control Manager|GroupPolicy|User Profile Service"
                }
            }

            if ($spec.LogName -like "*Diagnostics-Performance*") {
                $events = $events | Where-Object { $_.Id -ge 100 -and $_.Id -le 199 }
            }

            $events = $events | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
            $totalEvents += @($events).Count

            if (-not $DryRun) {
                $outPath = Join-Path $outputDir $spec.File
                $events | Format-List | Out-String -Width 4096 | Out-File -FilePath $outPath -Encoding utf8
            }
        }
        catch {
            Write-WarnMsg "Could not read log $($spec.LogName): $($_.Exception.Message)"
        }
    }

    $summary.Findings.TotalEventRecordsCollected = $totalEvents
}

Invoke-Step -Name "Collect recent sign-in sessions" -Action {
    $qUserPath = Join-Path $outputDir "12-QUser.txt"

    if ($DryRun) {
        Write-Host "[DRYRUN] Would run quser and write: $qUserPath" -ForegroundColor DarkYellow
    } else {
        quser | Out-File -FilePath $qUserPath -Encoding utf8
    }
}

Invoke-Step -Name "Build quick causality indicators" -Action {
    $indicators = [ordered]@{
        DeploymentLikely = $false
        Why = @()
        RuleOutSignals = @()
    }

    if (($summary.Findings.IMEKeywordHits -as [int]) -gt 0) {
        $indicators.DeploymentLikely = $true
        $indicators.Why += "Intune Management Extension logs contain install/retry/failure or app-keyword hits during evidence run."
    }

    if (($summary.Findings.TotalEventRecordsCollected -as [int]) -eq 0) {
        $indicators.RuleOutSignals += "No deployment-related event records were collected in the selected window."
    }

    $summary.Findings.CausalityIndicators = $indicators

    if (-not $DryRun) {
        Export-Object -Path (Join-Path $outputDir "13-CausalityIndicators.json") -Data $indicators
    }
}

Invoke-Step -Name "Write evidence summary" -Action {
    if (-not $DryRun) {
        Export-Object -Path (Join-Path $outputDir "00-EvidenceSummary.json") -Data $summary
    }
}

if ($DryRun) {
    Write-Host "[DRYRUN] Completed preview of evidence collection steps." -ForegroundColor Green
} else {
    Write-Info "Evidence collection completed. Review: $outputDir"
}
