<#
.SYNOPSIS
Diagnostic script for Azure Virtual Desktop agent installation troubleshooting.

.DESCRIPTION
Comprehensive diagnostics to verify AVD agent installation, service status, and identify
installation failures. Useful for debugging when services exist but host doesn't appear in pool.

.PARAMETER RetrieveLogs
If $true, retrieves MSI installation logs from C:\Logs\ directory

.PARAMETER CheckBinaries
If $true, verifies that actual executable files exist on disk

.PARAMETER CheckServices
If $true, verifies service registry entries and status

.PARAMETER All
If $true, performs all diagnostic checks

.EXAMPLE
.\Diagnose-AVD-Agent.ps1 -All

.EXAMPLE
.\Diagnose-AVD-Agent.ps1 -CheckBinaries -CheckServices -RetrieveLogs

.NOTES
Must be run with elevated (Administrator) privileges on the session host VM.
#>

param(
    [switch]$CheckBinaries = $false,
    [switch]$CheckServices = $false,
    [switch]$RetrieveLogs = $false,
    [switch]$All = $false
)

$ErrorActionPreference = 'Continue'

# If -All specified, enable all checks
if ($All) {
    $CheckBinaries = $CheckServices = $RetrieveLogs = $true
}

Write-Host "Azure Virtual Desktop Agent Diagnostics" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Check if running as admin
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator for full diagnostics"
}

Write-Host "1. RDAgent Service Status" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan
$rdAgentService = Get-Service RDAgent -ErrorAction SilentlyContinue
if ($rdAgentService) {
    $rdAgentService | Select-Object Name, Status, StartType | Format-Table -AutoSize
    Write-Host "   ✓ RDAgent service exists" -ForegroundColor Green
} else {
    Write-Host "   ✗ RDAgent service NOT FOUND" -ForegroundColor Red
}

Write-Host "`n2. RDAgentBootLoader Service Status" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan
$bootService = Get-Service RDAgentBootLoader -ErrorAction SilentlyContinue
if ($bootService) {
    $bootService | Select-Object Name, Status, StartType | Format-Table -AutoSize
    Write-Host "   ✓ RDAgentBootLoader service exists" -ForegroundColor Green
} else {
    Write-Host "   ✗ RDAgentBootLoader service NOT FOUND" -ForegroundColor Red
}

if ($CheckServices) {
    Write-Host "`n3. Service Registry Entries" -ForegroundColor Cyan
    Write-Host "---" -ForegroundColor Cyan
    
    $rdAgentPath = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\RDAgent' -Name ImagePath -ErrorAction SilentlyContinue
    if ($rdAgentPath) {
        Write-Host "   RDAgent ImagePath: $($rdAgentPath.ImagePath)" -ForegroundColor Cyan
    } else {
        Write-Host "   ✗ RDAgent registry entry NOT FOUND" -ForegroundColor Red
    }
    
    $bootPath = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\RDAgentBootLoader' -Name ImagePath -ErrorAction SilentlyContinue
    if ($bootPath) {
        Write-Host "   RDAgentBootLoader ImagePath: $($bootPath.ImagePath)" -ForegroundColor Cyan
    } else {
        Write-Host "   ✗ RDAgentBootLoader registry entry NOT FOUND" -ForegroundColor Red
    }
}

if ($CheckBinaries) {
    Write-Host "`n4. Agent Binary Verification" -ForegroundColor Cyan
    Write-Host "---" -ForegroundColor Cyan
    
    $binaries = @(
        'C:\Program Files\FSLogix\Apps\Agents\RDAgent.exe',
        'C:\Program Files\FSLogix\Apps\RDAgentBootLoader.exe',
        'C:\Program Files\FSLogix\Apps\Agent\RDAgent.exe',
        'C:\Program Files (x86)\FSLogix\Apps\Agents\RDAgent.exe'
    )
    
    $foundBinaries = @()
    foreach ($binary in $binaries) {
        $exists = Test-Path $binary
        if ($exists) {
            Write-Host "   ✓ $binary" -ForegroundColor Green
            $foundBinaries += $binary
        } else {
            Write-Host "   ✗ $binary" -ForegroundColor Red
        }
    }
    
    if ($foundBinaries.Count -eq 0) {
        Write-Host "`n   ⚠ WARNING: No RDAgent binaries found!" -ForegroundColor Yellow
        Write-Host "   This is the critical issue preventing host pool registration." -ForegroundColor Yellow
        Write-Host "   MSI installation likely failed to extract files." -ForegroundColor Yellow
    }
}

Write-Host "`n5. Running Processes" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan
$rdAgentProc = Get-Process RDAgent -ErrorAction SilentlyContinue
if ($rdAgentProc) {
    Write-Host "   ✓ RDAgent.exe process running (PID: $($rdAgentProc.Id))" -ForegroundColor Green
} else {
    Write-Host "   ✗ RDAgent.exe process NOT running" -ForegroundColor Red
}

$bootProc = Get-Process RDAgentBootLoader -ErrorAction SilentlyContinue
if ($bootProc) {
    Write-Host "   ✓ RDAgentBootLoader.exe process running (PID: $($bootProc.Id))" -ForegroundColor Green
} else {
    Write-Host "   ✗ RDAgentBootLoader.exe process NOT running" -ForegroundColor Red
}

Write-Host "`n6. Host Pool Registration Status" -ForegroundColor Cyan
Write-Host "---" -ForegroundColor Cyan

# Check for registration indicators
$registryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
$poolId = Get-ItemProperty $registryPath -Name POOLTARGET -ErrorAction SilentlyContinue
if ($poolId) {
    Write-Host "   ✓ Pool registration config found" -ForegroundColor Green
    Write-Host "   Pool Target: $($poolId.POOLTARGET)" -ForegroundColor Cyan
} else {
    Write-Host "   ⚠ No pool target environment variable found" -ForegroundColor Yellow
}

if ($RetrieveLogs) {
    Write-Host "`n7. MSI Installation Logs" -ForegroundColor Cyan
    Write-Host "---" -ForegroundColor Cyan
    
    $logFiles = @(
        'C:\Logs\agent-install.log',
        'C:\Logs\boot-install.log',
        'C:\Logs\agent-verbose.log',
        'C:\Logs\boot-verbose.log'
    )
    
    foreach ($logFile in $logFiles) {
        if (Test-Path $logFile) {
            Write-Host "`n   File: $logFile" -ForegroundColor Cyan
            Write-Host "   Last 30 lines:" -ForegroundColor Cyan
            Write-Host "   ---" -ForegroundColor Cyan
            Get-Content $logFile -Tail 30 | ForEach-Object { Write-Host "   $_" }
            
            # Search for errors
            $errors = Select-String -Path $logFile -Pattern 'Error|error|ERROR|Failed|failed|FAILED' -ErrorAction SilentlyContinue
            if ($errors) {
                Write-Host "`n   ⚠ ERROR LINES FOUND:" -ForegroundColor Yellow
                $errors | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
            }
        }
    }
}

Write-Host "`n" -ForegroundColor Green
Write-Host "Diagnostics Complete" -ForegroundColor Green
Write-Host "===========================`n" -ForegroundColor Green

# Summary
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "--------" -ForegroundColor Cyan

$serviceExists = -not [string]::IsNullOrEmpty($rdAgentService)
$serviceRunning = $rdAgentService -and ($rdAgentService.Status -eq 'Running')
$binaryExists = $foundBinaries.Count -gt 0 2>/dev/null
$processRunning = $rdAgentProc -ne $null

if ($serviceExists -and $serviceRunning -and $binaryExists -and $processRunning) {
    Write-Host "✓ Agent appears to be properly installed and running" -ForegroundColor Green
    Write-Host "  Session host should appear in pool shortly (1-2 minutes)" -ForegroundColor Green
} else {
    Write-Host "✗ Issues detected:" -ForegroundColor Red
    if (-not $serviceExists) { Write-Host "  - Service does not exist" -ForegroundColor Red }
    if (-not $serviceRunning) { Write-Host "  - Service is not running" -ForegroundColor Red }
    if (-not $binaryExists) { Write-Host "  - Binaries not found on disk (CRITICAL)" -ForegroundColor Red }
    if (-not $processRunning) { Write-Host "  - Process is not running" -ForegroundColor Red }
    Write-Host "`n  Recommended next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run with -RetrieveLogs to analyze installation logs" -ForegroundColor Yellow
    Write-Host "  2. Check for specific error codes in logs" -ForegroundColor Yellow
    Write-Host "  3. Verify disk space and permissions on C:\Program Files\" -ForegroundColor Yellow
    Write-Host "  4. Consider re-running MSI installation with verbose logging" -ForegroundColor Yellow
}
