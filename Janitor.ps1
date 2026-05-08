<#
.SYNOPSIS
    Cleans temporary files and system caches to maintain disk health.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Cleanup.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting System Cleanup..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # 1. Clear User Temp Files
    Write-Host "Cleaning User Temp files..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:TEMP\*") {
        if ($DryRun) { Write-Host "[DRY RUN] Would remove items from $env:TEMP" -ForegroundColor Gray }
        else { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # 2. Clear System Temp Files
    Write-Host "Cleaning System Temp files..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:SystemRoot\Temp\*") {
        if ($DryRun) { Write-Host "[DRY RUN] Would remove items from $env:SystemRoot\Temp" -ForegroundColor Gray }
        else { Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # 3. Clear Prefetch (Optional, but helps with clutter over years)
    Write-Host "Cleaning Prefetch..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:SystemRoot\Prefetch\*") { Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue }

    # 4. Clean Windows Update Cache (SoftwareDistribution)
    # Note: This stops the update service temporarily to clear the folder
    Write-Host "Resetting Windows Update Cache..."
    if ($DryRun) {
        Write-Host "[DRY RUN] Would stop/start wuauserv and clear update cache." -ForegroundColor Gray
    }
    # NASA Rule 7: Check return values for service operations
    $wuauserv = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuauserv) {
        # NASA Rule 7: Check if service successfully stopped
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        $checkService = Get-Service -Name "wuauserv"
        if ($checkService.Status -ne 'Stopped') { Write-Warning "NASA Rule 7: Failed to stop wuauserv. Cache cleanup might be incomplete." }
        
        if (-not $DryRun -and (Test-Path "$env:SystemRoot\SoftwareDistribution\Download\*")) {
            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        }

        # NASA Rule 7: Check if service successfully started
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $checkService = Get-Service -Name "wuauserv"
        if ($checkService.Status -ne 'Running') { Write-Warning "NASA Rule 7: Failed to start wuauserv after cleanup." }
    } else {
        if (-not $DryRun) { Write-Warning "Windows Update service (wuauserv) not found or accessible." }
    }

    # 5. Run Disk Cleanup with default settings
    Write-Host "Running Windows Disk Cleanup..."
    # NASA Rule 7: Check return values
    if ($DryRun) { Write-Host "[DRY RUN] Would run Cleanmgr.exe /sagerun:1" -ForegroundColor Gray }
    else {
        $process = Start-Process -FilePath "Cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -PassThru -ErrorAction SilentlyContinue
        if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "Disk Cleanup (Cleanmgr.exe) did not complete successfully." }
    }
}
catch {
    Write-Error "An error occurred during the cleanup process: $_"
    Stop-Transcript; exit 1
}

Write-Host "Cleanup Complete." -ForegroundColor Green
Stop-Transcript

# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTObbf/yX249mkQzPsBC+/Pc2
# MAigggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQU6qbWoD54/dDisHnxDDmCT12xfCMwDQYJKoZIhvcN
# AQEBBQAEggEATe5wbKAyc2U+8CtNfZk309VFUj/UtYSxH9nAbQaqyMxs6A8wGd/T
# J7Vu+mD/cNdluuu/MJGpJ9QrB1WJ/+zWbu7GWzvCEhNw9JcnMHoqCwZTIztj1eJZ
# Zlf+3nssBGRVH6d1WdWf5weVGz+qeO6AG4JGH02ingh54Me4YMZNi7tpwpz6H4ea
# aK/58PXTVG4mys/fn5faHll3QNh1L4QLttUN0yJ3X1+DHIk3/jUmKLyv8IDUny0r
# Gz4lRm3/uwR8LmJHrC2CpaNNvuPm9zO2/idk1pAU1JQOAxg59BTipV901rt6eEJI
# a1b24Xj0gb97xok+hSOOoWHSZ4IEbHHvOA==
# SIG # End signature block
