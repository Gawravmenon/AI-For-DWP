param(
    [Parameter(Mandatory = $true)]
    [string]$RegistrationToken
)

$ErrorActionPreference = 'Stop'
$uris = @(
    'https://go.microsoft.com/fwlink/?linkid=2310011',
    'https://go.microsoft.com/fwlink/?linkid=2311028'
)
$fileNames = @(
    'Microsoft.RDInfra.RDAgent.Installer.msi',
    'Microsoft.RDInfra.RDAgentBootLoader.Installer.msi'
)
$installers = @()
$i = 0
foreach ($uri in $uris) {
    $fileName = $fileNames[$i]
    $outputPath = Join-Path $pwd $fileName
    & curl.exe -L $uri -o $outputPath
    Unblock-File -Path $fileName
    $installers += (Join-Path $pwd $fileName)
    $i++
}
$agentInstaller = $installers | Where-Object { $_ -like '*RDAgent.Installer*' }
$bootInstaller = $installers | Where-Object { $_ -like '*RDAgentBootLoader.Installer*' }
Start-Process msiexec.exe -ArgumentList @('/i', $agentInstaller, '/quiet', 'REGISTRATIONTOKEN=' + $RegistrationToken) -Wait -NoNewWindow
Start-Process msiexec.exe -ArgumentList @('/i', $bootInstaller, '/quiet') -Wait -NoNewWindow
Get-Service -Name RDAgent,BootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType
