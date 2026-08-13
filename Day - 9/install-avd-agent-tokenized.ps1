<#
.SYNOPSIS
Downloads and installs Azure Virtual Desktop agent components using token from environment variable.

.DESCRIPTION
Alternative to install-avd-agent.ps1 that accepts the registration token via environment variable
rather than parameter. Useful for piped workflows or when passing sensitive tokens via environment.

.EXAMPLE
$token = $(az desktopvirtualization hostpool retrieve-registration-token `
  -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)
$env:AVD_REGISTRATION_TOKEN = $token
.\install-avd-agent-tokenized.ps1

.NOTES
- Requires curl.exe (native Windows tool, available on Windows 11)
- Reads RegistrationToken from $env:AVD_REGISTRATION_TOKEN
- Uses /quiet flag for silent installation (no UI prompts)
- Waits for both installers to complete before returning
#>

$ErrorActionPreference = 'Stop'

# Read registration token from environment variable
$RegistrationToken = $env:AVD_REGISTRATION_TOKEN

if ([string]::IsNullOrEmpty($RegistrationToken)) {
    Write-Error "AVD_REGISTRATION_TOKEN environment variable not set"
    exit 1
}

Write-Host "Starting Azure Virtual Desktop Agent Installation (Tokenized)" -ForegroundColor Green
Write-Host "Registration Token Source: Environment Variable" -ForegroundColor Cyan

# URLs for official Microsoft RD agent installers
$uris = @(
    'https://go.microsoft.com/fwlink/?linkid=2310011',  # RDAgent
    'https://go.microsoft.com/fwlink/?linkid=2311028'   # RDAgentBootLoader
)

# Target MSI file names
$fileNames = @(
    'Microsoft.RDInfra.RDAgent.Installer.msi',
    'Microsoft.RDInfra.RDAgentBootLoader.Installer.msi'
)

# Download MSI files using curl.exe
Write-Host "`nDownloading MSI installer files..." -ForegroundColor Yellow
$installers = @()
$i = 0
foreach ($uri in $uris) {
    $fileName = $fileNames[$i]
    $outputPath = Join-Path $pwd $fileName
    
    Write-Host "  Downloading: $fileName" -ForegroundColor Cyan
    & curl.exe -L $uri -o $outputPath
    
    # Unblock file to allow execution
    Unblock-File -Path $fileName -ErrorAction SilentlyContinue
    $installers += (Join-Path $pwd $fileName)
    $i++
}

# Identify agent and boot loader installers
$agentInstaller = $installers | Where-Object { $_ -like '*RDAgent.Installer*' }
$bootInstaller = $installers | Where-Object { $_ -like '*RDAgentBootLoader.Installer*' }

Write-Host "`nInstalling RD Agent..." -ForegroundColor Yellow
Write-Host "  MSI: $agentInstaller" -ForegroundColor Cyan
# Install RDAgent with registration token (enables auto-registration to host pool)
Start-Process msiexec.exe -ArgumentList @(
    '/i', $agentInstaller, 
    '/quiet', 
    'REGISTRATIONTOKEN=' + $RegistrationToken
) -Wait -NoNewWindow

Write-Host "`nInstalling RD Agent Boot Loader..." -ForegroundColor Yellow
Write-Host "  MSI: $bootInstaller" -ForegroundColor Cyan
# Install RDAgentBootLoader (required for agent to start properly)
Start-Process msiexec.exe -ArgumentList @(
    '/i', $bootInstaller, 
    '/quiet'
) -Wait -NoNewWindow

Write-Host "`nService Installation Status:" -ForegroundColor Green
Get-Service -Name RDAgent,RDAgentBootLoader -ErrorAction SilentlyContinue | 
    Select-Object Name, Status, StartType | Format-Table -AutoSize

Write-Host "Installation complete. Services should be running." -ForegroundColor Green
Write-Host "Note: It may take 1-2 minutes for the session host to appear in the host pool." -ForegroundColor Cyan
