<#
.SYNOPSIS
    Checks for low disk space on all fixed local drives. (Surveyor)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Surveyor.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Disk Capacity Survey (Surveyor)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$ThresholdPercent = 15 # Default
 $DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
    if ($null -ne $Config.DiskSpaceThresholdPercent) {
        $ThresholdPercent = $Config.DiskSpaceThresholdPercent
    }
}
if ($null -eq $ThresholdPercent) { throw "NASA Rule 5: DiskSpaceThresholdPercent not initialized." }

try {
    $LowSpaceFound = $false
    $Drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null }
    
    # NASA Rule 5: Assert drive collection is not null
    if ($null -eq $Drives) { throw "NASA Rule 5: Failed to retrieve system volumes." }

    for ($i = 0; $i -lt $Drives.Count; $i++) {
        $Drive = $Drives[$i]
        # NASA Rule 5: Assert Drive properties are not null
        if ($null -eq $Drive.DriveLetter -or $null -eq $Drive.SizeRemaining -or $null -eq $Drive.Size) { Write-Warning "NASA Rule 5: Drive object missing critical properties." }
        $FreeSpaceGB = [math]::Round($Drive.SizeRemaining / 1GB, 2)
        $TotalSizeGB = [math]::Round($Drive.Size / 1GB, 2)
        $PercentFree = [math]::Round(($Drive.SizeRemaining / $Drive.Size) * 100, 2)

        Write-Host "Checking Drive $($Drive.DriveLetter): ($($Drive.FileSystemLabel))" -ForegroundColor Gray
        Write-Host " - Total Size: $TotalSizeGB GB"
        Write-Host " - Free Space: $FreeSpaceGB GB ($PercentFree%)"

        if ($PercentFree -lt $ThresholdPercent) {
            Write-Host "WARNING: Drive $($Drive.DriveLetter): is running low on space!" -ForegroundColor Red
            $LowSpaceFound = $true
        }
    }

    if ($LowSpaceFound) {
        if (-not $DryRun) { Write-Warning "One or more drives have less than $ThresholdPercent% free space." }
        Stop-Transcript
        exit 1
    }
    else {
        Write-Host "All drives have sufficient free space." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred during the disk space check: $_"
    Stop-Transcript; exit 1
}

Write-Host "Disk space check complete." -ForegroundColor Green
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNSrEh5dOD0yWqXSgIGykJTdm
# OxigggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUAm3XIxDQKrexjYH09rhHsU3YGeowDQYJKoZIhvcN
# AQEBBQAEggEAmCv6zHhpMSw8HBUmo4wqxALTwVpYSWHzItpc5TOzQf5vSlwei2qV
# e83vvm+042ynZ66J/zENG0R9s7iLSgIV1i/l2AqoNs0ENwvsWUSXWdehx0WZjXUo
# tqQMBZXve/R7Uhuc6DjiuWu0z6+dgkBFIHeGOaNa8vGf0lm1cwK/BN18b9aUh9wG
# agbMC9A+RlWf2jeV6MZPEuwG7V98WSoNlJp565FQ7Kteq1NfHnGLeXbrGI49eEFM
# TTyGak1pT+WoS05dDOdR6cnNjrv18cM3Fj5BC+0wg/M8HFlvpjaezfpfgO79y3GY
# b69RqswnJMf68Mm5/UThavvXp8oYrjWxag==
# SIG # End signature block
