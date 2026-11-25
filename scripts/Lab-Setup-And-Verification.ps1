<#
.SYNOPSIS
    SOC Automation Home Lab - Endpoint Setup & Detection Verification Script
.DESCRIPTION
    Documents the administrative PowerShell commands used to verify Sysmon64,
    manage the Wazuh Agent service, execute a controlled defense-evasion test
    (renaming mimikatz.exe to trappedbaai.exe), and query Sysmon Event ID 1 logs.
.NOTES
    Run in an elevated (Administrator) PowerShell session inside an isolated lab VM.
#>

# 1. Verify Sysmon64 Installation & Service Status
Write-Host "[*] Checking Sysmon64 Service Status..." -ForegroundColor Cyan
Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType

# 2. Restart & Verify Wazuh Agent Service (After Adding Sysmon Event Channel)
Write-Host "[*] Restarting Wazuh Agent Service..." -ForegroundColor Cyan
Restart-Service -Name "WazuhSvc" -ErrorAction SilentlyContinue
Get-Service -Name "WazuhSvc" | Select-Object Name, Status, StartType

# 3. Defense Evasion Test: Rename Binary to Test OriginalFileName Detection (Rule 100003)
# Note: Assumes your test binary is placed inside an isolated, Defender-excluded lab directory.
$LabDir         = "$env:USERPROFILE\Downloads\LabTest"
$OriginalBinary = Join-Path $LabDir "mimikatz.exe"
$RenamedBinary  = Join-Path $LabDir "trappedbaai.exe"

if (Test-Path $OriginalBinary) {
    Write-Host "[*] Renaming mimikatz.exe to trappedbaai.exe..." -ForegroundColor Yellow
    Rename-Item -Path $OriginalBinary -NewName "trappedbaai.exe" -Force
}

if (Test-Path $RenamedBinary) {
    Write-Host "[*] Executing trappedbaai.exe to generate Sysmon Event ID 1 telemetry..." -ForegroundColor Yellow
    & $RenamedBinary "version" "exit"
} else {
    Write-Host "[!] Test binary not found in $LabDir. Place test binary there before running." -ForegroundColor Red
}

# 4. Query Latest Sysmon Process Creation Event (Event ID 1) Locally
Write-Host "[*] Fetching latest Sysmon Event ID 1 log..." -ForegroundColor Green
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Sysmon/Operational'
    Id      = 1
} -MaxEvents 1 | Format-List TimeCreated, Id, Message
