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
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5eYMrx+pCnXjRxYM1npR+OZP
# iT6gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUsDhsfEezZhr4KwKh7yfnIMRt1DIwDQYJKoZIhvcN
# AQEBBQAEggEAd48+STSwHn7OMDqRjfnrJXlXHH1VUCMrmCax+PboQNaxN1EXYMwW
# OaRTLDxlU0OkdFTpkGW923Y7DtITWgRPCtcAm7nuTydpohUF9pTlvN5OWF+hgm+r
# +5NB/Szm5N2gokaiTLrwhT5pP31Z4Z9lFXwJixVOopAF/gXRd9b+2Wo3PLa+12Xp
# Dw3GNIr1e97BJFCvm7y4xuUagXgKSdC74VasF0vR1RQ98/VC4YBE9fZPaFGNmlbL
# avNxt+7hFcVSe7FXtLPbouZNfqSCEDRBeyLv7IbYaupb+udqH4Gffqwge9n4joaL
# AOU2FZzxzKUZLLl77ytKZrVqO3nUksomeg==
# SIG # End signature block
