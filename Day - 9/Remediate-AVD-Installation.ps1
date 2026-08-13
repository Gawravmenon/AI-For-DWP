<#
.SYNOPSIS
Troubleshoots and remediates MSI installation failures for Azure Virtual Desktop agents.

.DESCRIPTION
Attempts to identify and fix MSI installation issues by:
1. Uninstalling previous failed installations
2. Verifying prerequisites (disk space, permissions, services)
3. Re-installing with verbose logging for error diagnosis
4. Capturing detailed logs for analysis

.PARAMETER RegistrationToken
Mandatory. JWT registration token from host pool.

.PARAMETER VerboseLogging
If $true (default), installs with verbose logging (/l*v flag).

.PARAMETER UninstallFirst
If $true (default), attempts to uninstall previous versions first.

.EXAMPLE
$token = $(az desktopvirtualization hostpool retrieve-registration-token `
  -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)
.\Remediate-AVD-Installation.ps1 -RegistrationToken $token

.NOTES
- Requires elevated (Administrator) privileges
- Creates detailed logs in C:\Logs\ directory
- May require VM restart after remediation
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$RegistrationToken,
    
    [bool]$VerboseLogging = $true,
    [bool]$UninstallFirst = $true
)

$ErrorActionPreference = 'Stop'

# Ensure Admin privileges
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

Write-Host "Azure Virtual Desktop Installation Remediation" -ForegroundColor Green
Write-Host "=============================================`n" -ForegroundColor Green

# Create logs directory if needed
if (-not (Test-Path 'C:\Logs')) {
    New-Item -ItemType Directory -Path 'C:\Logs' -Force | Out-Null
    Write-Host "✓ Created C:\Logs directory" -ForegroundColor Green
}

Write-Host "Step 1: Prerequisite Checks" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan

# Check disk space
$diskSpace = (Get-Volume C:).SizeRemaining
$diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
Write-Host "  Available disk space on C:\: $diskSpaceGB GB" -ForegroundColor Cyan

if ($diskSpace -lt 1GB) {
    Write-Error "Insufficient disk space (requires at least 1 GB)"
    exit 1
}

# Check Windows Installer service
$msiService = Get-Service msiserver -ErrorAction SilentlyContinue
Write-Host "  Windows Installer service: $($msiService.Status)" -ForegroundColor Cyan

if ($msiService.Status -ne 'Running') {
    Write-Host "  Starting Windows Installer service..." -ForegroundColor Yellow
    Start-Service msiserver -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Check permissions on Program Files
Write-Host "  Checking C:\Program Files permissions..." -ForegroundColor Cyan
$progFilesExists = Test-Path 'C:\Program Files'
if ($progFilesExists) {
    Write-Host "  ✓ C:\Program Files is accessible" -ForegroundColor Green
} else {
    Write-Error "C:\Program Files not found or not accessible"
    exit 1
}

Write-Host "`nStep 2: Download MSI Files" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan

$uris = @(
    'https://go.microsoft.com/fwlink/?linkid=2310011',  # RDAgent
    'https://go.microsoft.com/fwlink/?linkid=2311028'   # RDAgentBootLoader
)

$fileNames = @(
    'Microsoft.RDInfra.RDAgent.Installer.msi',
    'Microsoft.RDInfra.RDAgentBootLoader.Installer.msi'
)

$installers = @()
$i = 0
foreach ($uri in $uris) {
    $fileName = $fileNames[$i]
    $outputPath = Join-Path $env:TEMP $fileName
    
    if (Test-Path $outputPath) {
        Write-Host "  Using cached MSI: $fileName" -ForegroundColor Cyan
    } else {
        Write-Host "  Downloading: $fileName" -ForegroundColor Cyan
        & curl.exe -L $uri -o $outputPath 2>&1 | Out-Null
    }
    
    Unblock-File -Path $outputPath -ErrorAction SilentlyContinue
    $installers += $outputPath
    $i++
}

$agentInstaller = $installers | Where-Object { $_ -like '*RDAgent.Installer*' }
$bootInstaller = $installers | Where-Object { $_ -like '*RDAgentBootLoader.Installer*' }

if (-not $agentInstaller -or -not $bootInstaller) {
    Write-Error "Failed to download MSI files"
    exit 1
}

Write-Host "  ✓ MSI files ready" -ForegroundColor Green

if ($UninstallFirst) {
    Write-Host "`nStep 3: Uninstall Previous Versions" -ForegroundColor Cyan
    Write-Host "---" -ForegroundColor Cyan
    
    # Stop services if running
    foreach ($svc in @('RDAgent', 'RDAgentBootLoader')) {
        $service = Get-Service $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-Host "  Stopping $svc..." -ForegroundColor Cyan
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
    }
    
    # Get uninstall strings from registry
    $uninstallKeys = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | 
        Where-Object { $_.GetValue('DisplayName') -like '*RD Agent*' -or $_.GetValue('DisplayName') -like '*FSLogix*' }
    
    foreach ($key in $uninstallKeys) {
        $displayName = $key.GetValue('DisplayName')
        $uninstallString = $key.GetValue('UninstallString')
        
        if ($uninstallString) {
            Write-Host "  Uninstalling: $displayName" -ForegroundColor Cyan
            Invoke-Expression $uninstallString -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
}

Write-Host "`nStep 4: Install with Verbose Logging" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan

$agentLogFile = 'C:\Logs\remediation-agent-install.log'
$bootLogFile = 'C:\Logs\remediation-boot-install.log'

if ($VerboseLogging) {
    Write-Host "  Installing RD Agent (with verbose logging)..." -ForegroundColor Cyan
    $agentArgs = @(
        '/i', $agentInstaller,
        '/l*v', $agentLogFile,
        'REGISTRATIONTOKEN=' + $RegistrationToken
    )
} else {
    Write-Host "  Installing RD Agent..." -ForegroundColor Cyan
    $agentArgs = @(
        '/i', $agentInstaller,
        '/quiet',
        'REGISTRATIONTOKEN=' + $RegistrationToken
    )
}

$agentProcess = Start-Process msiexec.exe -ArgumentList $agentArgs -Wait -PassThru -NoNewWindow
$agentExitCode = $agentProcess.ExitCode

Write-Host "  RD Agent exit code: $agentExitCode" -ForegroundColor Cyan

if ($VerboseLogging) {
    Write-Host "  Installing RD Agent Boot Loader (with verbose logging)..." -ForegroundColor Cyan
    $bootArgs = @(
        '/i', $bootInstaller,
        '/l*v', $bootLogFile
    )
} else {
    Write-Host "  Installing RD Agent Boot Loader..." -ForegroundColor Cyan
    $bootArgs = @(
        '/i', $bootInstaller,
        '/quiet'
    )
}

$bootProcess = Start-Process msiexec.exe -ArgumentList $bootArgs -Wait -PassThru -NoNewWindow
$bootExitCode = $bootProcess.ExitCode

Write-Host "  RD Agent Boot Loader exit code: $bootExitCode" -ForegroundColor Cyan

Write-Host "`nStep 5: Verify Installation" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan

Start-Sleep -Seconds 3

# Check services
$rdAgent = Get-Service RDAgent -ErrorAction SilentlyContinue
$bootLoader = Get-Service RDAgentBootLoader -ErrorAction SilentlyContinue

if ($rdAgent) {
    Write-Host "  RDAgent service: $($rdAgent.Status)" -ForegroundColor Cyan
} else {
    Write-Host "  ✗ RDAgent service not found" -ForegroundColor Red
}

if ($bootLoader) {
    Write-Host "  RDAgentBootLoader service: $($bootLoader.Status)" -ForegroundColor Cyan
} else {
    Write-Host "  ✗ RDAgentBootLoader service not found" -ForegroundColor Red
}

# Check binaries
Write-Host "  Checking for binaries..." -ForegroundColor Cyan
$binaries = @(
    'C:\Program Files\FSLogix\Apps\Agents\RDAgent.exe',
    'C:\Program Files\FSLogix\Apps\RDAgentBootLoader.exe'
)

$allBinariesFound = $true
foreach ($binary in $binaries) {
    if (Test-Path $binary) {
        Write-Host "    ✓ $binary" -ForegroundColor Green
    } else {
        Write-Host "    ✗ $binary" -ForegroundColor Red
        $allBinariesFound = $false
    }
}

Write-Host "`nStep 6: Log Analysis" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan

if (Test-Path $agentLogFile) {
    $errors = Select-String -Path $agentLogFile -Pattern 'Error|error|ERROR|Failed|failed|FAILED' -ErrorAction SilentlyContinue
    if ($errors) {
        Write-Host "  ⚠ Errors found in agent install log:" -ForegroundColor Yellow
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  ✓ No errors detected in agent log" -ForegroundColor Green
    }
}

if (Test-Path $bootLogFile) {
    $errors = Select-String -Path $bootLogFile -Pattern 'Error|error|ERROR|Failed|failed|FAILED' -ErrorAction SilentlyContinue
    if ($errors) {
        Write-Host "  ⚠ Errors found in boot loader log:" -ForegroundColor Yellow
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  ✓ No errors detected in boot loader log" -ForegroundColor Green
    }
}

Write-Host "`n" -ForegroundColor Green
Write-Host "Remediation Complete" -ForegroundColor Green
Write-Host "=====================`n" -ForegroundColor Green

if ($allBinariesFound -and $agentExitCode -eq 0 -and $bootExitCode -eq 0) {
    Write-Host "✓ Installation successful!" -ForegroundColor Green
    Write-Host "  Session host should appear in pool within 1-2 minutes." -ForegroundColor Green
    Write-Host "  Monitor at: https://portal.azure.com" -ForegroundColor Green
} else {
    Write-Host "✗ Installation may have issues. Review logs:" -ForegroundColor Red
    Write-Host "  Agent Log: $agentLogFile" -ForegroundColor Yellow
    Write-Host "  Boot Log: $bootLogFile" -ForegroundColor Yellow
    Write-Host "`n  Recommended: Review logs for specific error codes." -ForegroundColor Yellow
}

# Prompt for restart
Write-Host "`nNote: A restart may be required for services to fully initialize." -ForegroundColor Cyan
$response = Read-Host "Restart VM now? (y/n)"
if ($response -eq 'y') {
    Write-Host "Restarting..." -ForegroundColor Cyan
    Restart-Computer -Force
} else {
    Write-Host "Restart deferred. Manual restart recommended." -ForegroundColor Cyan
}
