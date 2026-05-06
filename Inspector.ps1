<#
.SYNOPSIS
    Monitors S.M.A.R.T. status and health of physical disks. (Inspector)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Inspector.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Disk Inspection (Inspector)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # Retrieve all physical disks and their operational status
    $Disks = Get-PhysicalDisk
    # NASA Rule 5: Assert disk collection is not null
    if ($null -eq $Disks) { throw "NASA Rule 5: Failed to retrieve physical disks." }
    $FailureFound = $false

    # NASA Rule 2: Use bounded for-loop
    for ($i = 0; $i -lt $Disks.Count; $i++) {
        $Disk = $Disks[$i]
        # NASA Rule 5: Assert Disk properties are not null
        if ($null -eq $Disk.DeviceId -or $null -eq $Disk.FriendlyName) { throw "NASA Rule 5: Disk object missing critical properties." }
        Write-Host "Checking Disk $($Disk.DeviceId): $($Disk.FriendlyName)" -ForegroundColor Gray        
        $Health = $Disk.HealthStatus
        $OpStatus = $Disk.OperationalStatus
        
        # StorageReliabilityCounter maps to common S.M.A.R.T. attributes
        $Counters = Get-StorageReliabilityCounter -PhysicalDisk $Disk

        if ($Health -ne "Healthy") {
            Write-Host "WARNING: Disk $($Disk.DeviceId) reported status: $Health" -ForegroundColor Red
            Write-Host "Operational Status: $OpStatus" -ForegroundColor Yellow
            # NASA Rule 5: Assert Health and OpStatus are not null
            if ($null -ne $Health -and $null -ne $OpStatus) { $FailureFound = $true }
            else { Write-Warning "NASA Rule 5: Disk health/operational status is null." }
        } else {
            Write-Host "Disk $($Disk.DeviceId) health: Healthy" -ForegroundColor Green
        }

        if ($Counters) {
            Write-Host " - Temperature: $($Counters.Temperature) C"
            Write-Host " - Wear Level: $($Counters.Wear)% used"
            Write-Host " - Read Errors: $($Counters.ReadErrorsTotal)"
            Write-Host " - Write Errors: $($Counters.WriteErrorsTotal)"
        }
        Write-Host "------------------------------------------------"
    }

    if ($FailureFound) {
        Write-Warning "Disk issues detected."
    }
    if ($FailureFound -and -not $DryRun) { Stop-Transcript; exit 1 }
}
catch {
    Write-Error "An error occurred while inspecting disks: $_"
    Stop-Transcript; exit 1
}

Write-Host "Disk inspection complete." -ForegroundColor Green
Stop-Transcript