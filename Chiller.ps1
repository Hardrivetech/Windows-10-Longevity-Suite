<#
.SYNOPSIS
    Monitors CPU temperature and checks for thermal throttling indicators. (Chiller)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Chiller.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Thermal Surveillance (Chiller)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # 1. Get Temperature (MSAcpi_ThermalZoneTemperature)
    $ThermalZones = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
    # NASA Rule 7: Check return values
    if ($null -eq $ThermalZones) { Write-Warning "Standard Thermal Zone WMI data not available on this hardware." }
    
    # NASA Rule 2: Use bounded for-loop
    if ($null -ne $ThermalZones) {
        for ($i = 0; $i -lt $ThermalZones.Count; $i++) {
            $Zone = $ThermalZones[$i]
            # NASA Rule 5: Assert CurrentTemperature is valid
            if ($null -ne $Zone.CurrentTemperature -and $Zone.CurrentTemperature -gt 0) {
                $TempCelsius = ($Zone.CurrentTemperature / 10) - 273.15 # Convert from Tenths of Kelvin to Celsius
                $Status = "Healthy"
                if ($TempCelsius -gt 85) { $Status = "CRITICAL" }
                elseif ($TempCelsius -gt 70) { $Status = "WARNING" }
                
                $Color = "Green"
                if ($Status -ne "Healthy") { $Color = "Red" }
                Write-Host "Zone $($Zone.InstanceName): $($TempCelsius)°C ($Status)" -ForegroundColor $Color
            }
        }
    } else {
        Write-Warning "Standard Thermal Zone WMI data not available."
    }

    # 2. Check for Thermal Throttling Status (MSFT_PshThermalStatus)
    $ThrottlingStatus = Get-CimInstance -Namespace root/wmi -ClassName MSFT_PshThermalStatus -ErrorAction SilentlyContinue
    $ThrottlingDetected = $false

    if ($null -ne $ThrottlingStatus) { # NASA Rule 7: Check return values
        if ($null -ne $ThrottlingStatus.Active -and $ThrottlingStatus.Active) { # NASA Rule 5: Assert Active property
            Write-Host "ALERT: Thermal Throttling is currently ACTIVE!" -ForegroundColor Red
            $ThrottlingDetected = $true
        } else {
            Write-Host "No active thermal throttling detected." -ForegroundColor Green
        }
    } else {
        Write-Host "Thermal throttling flags (MSFT_PshThermalStatus) are not supported by this BIOS/Firmware." -ForegroundColor Gray
    }


    # Exit with error code if critical heat or throttling is detected
    if ($ThrottlingDetected -and -not $DryRun) {
        Stop-Transcript
        exit 1
    }
}
catch {
    Write-Error "An error occurred during thermal monitoring: $_"
    Stop-Transcript; exit 1
}

Write-Host "Thermal surveillance complete." -ForegroundColor Green
Stop-Transcript