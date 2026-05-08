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
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6IUFf7wVixjefLW9AInM0Dgs
# uSOgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
# AQsFADAiMSAwHgYDVQQDDBdXaW5kb3dzTWFpbnRlbmFuY2VTdWl0ZTAeFw0yNjA1
# MDgyMTAxMjNaFw0yNzA1MDgyMTIxMjNaMCIxIDAeBgNVBAMMF1dpbmRvd3NNYWlu
# dGVuYW5jZVN1aXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3/92
# wnIIt1llLFV+0SjNEzyfmSk2LRqCY0G+SI1SRoBlPy4HXmQw9MGBFV4t2BoM202A
# cfNL8TTzhHblkwoUYpOEP4/NpWFdMFeQ+ord/qP2AcXvEChI2yOQXM7BGcyOfeOv
# UE8I9UgHVXdECumzfGwgwWPheypDu8faj4G8YhMv/OgaofxtxWEDjVGLcjruSYQ0
# gekSLdIqhi4X8lCroO5J6/4ZoO94UH8tgSfN6BS2GYwCLaOfrhhDiSvuOCl7X0x2
# 5yxvpMPAzrwI4OMMj5gyZaseXhcQ1Mi5lBTyjpIiaeEtiwBpFPOSIgMYcfTEGFUy
# pwkmw1q0SQbn5lOaFQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFJwEMfRj/lYgIdengr8i4zW0cFZqMA0GCSqG
# SIb3DQEBCwUAA4IBAQBM0i2BcZ6KmpbZv0ksmLj6QQ4qVLVh2P9pRcK2C8xz8EZ2
# jK1BWPSyPar5CqLw2ZNubAEAZxbFQlCxmWEgzjZ3QybsxLDmHv4uhljvU2nWnnty
# rze/8DJiSp9fiA4xu/H4W36dSJcvYfAisAxBJKV/fzIbHNrQWRCvzySygTyGjRb2
# x7li8UsU+fZAYDnWp5aU9Gw+sTj5ULK/wcvBsKD9y2sN6az/Z4S4xHj3LpmQfDrX
# VYBPP+WnLhwLEqYqq/ZSVvYsWPa/ZzSJMBsIiI+fC/IhHGWNX9/xzFfkGm9xpd9s
# epWLjCEpVE+R3Q85JLVNwYO1MCobYe+Mm8tRAwL9MYIB1zCCAdMCAQEwNjAiMSAw
# HgYDVQQDDBdXaW5kb3dzTWFpbnRlbmFuY2VTdWl0ZQIQMl3zoiC4cYFCMb3KCL1b
# 9jAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAjBgkqhkiG9w0BCQQxFgQUOujjsAcvGkQ5rDWp5f+ddSMU42IwDQYJKoZIhvcN
# AQEBBQAEggEAElnk41DElw/YW/esA837Gedk9ShCdRCX7WQuVBMqPKqT3O0y82zQ
# dM1pmNHPwZu11cJQCcyNndOs57XFIvwH5jCci1PpzZaDjpgUZ4w/nMW51gzJ6l21
# ef8k8kXqOH1Nx8fLBdViuUAmPtTFt7vJgektJwo4UgQyT9pm3H+RtxH6Z+icTntB
# gaEj9/9c+nfwQoaebgpTmi1DzBh2oXmen3W2jxZtHz4x8QrIxRNK7FWsZs18Vq18
# r4I7pKq1hWR+e78yROjKeiRgj8s4Fzf4ADquWsFkj6qMTBobOiaF/s8UMHN40ZH7
# 7jobBdqVhVowS2/F7gQgOyVbzfuFofSeJA==
# SIG # End signature block
