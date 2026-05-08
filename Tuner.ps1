<#
.SYNOPSIS
    Optimizes drives (Trim for SSD, Defrag for HDD).
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Optimization.log"
Start-Transcript -Path $LogPath -Append

Write-Host "Starting Drive Optimization..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # Get all fixed local drives
    $Drives = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null }
    # NASA Rule 5: Assert drive collection is not null
    if ($null -eq $Drives) { throw "NASA Rule 5: Failed to retrieve system volumes for optimization." }

    # NASA Rule 2: Use bounded for-loop
    for ($i = 0; $i -lt $Drives.Count; $i++) {
        $Drive = $Drives[$i]
        # NASA Rule 5: Assert DriveLetter is not null
        if ($null -ne $Drive.DriveLetter) {
            Write-Host "Optimizing Volume $($Drive.DriveLetter)..."
            if ($DryRun) {
                Write-Host "[DRY RUN] Would optimize volume $($Drive.DriveLetter)" -ForegroundColor Gray
            } else {
                # NASA Rule 7: Check return values
                Optimize-Volume -DriveLetter $Drive.DriveLetter -Verbose -ErrorAction SilentlyContinue
            }
        }
    }
}
catch {
    Write-Error "An error occurred during drive optimization: $_"
    Stop-Transcript; exit 1
}

Write-Host "Optimization complete." -ForegroundColor Green
Stop-Transcript

# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQHprZx3RkSBNWG9gMuQPnSeZ
# YW6gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUw8VVz4Bm84RKAB6j1qc6WNQPtxcwDQYJKoZIhvcN
# AQEBBQAEggEAWyhtVJoCUtUs/2x8Xa+XAb6ZsnKvh7Ni0AK/xL/0wTp0vEpY//mi
# T3LxZk1XxBNNYHIKa/6v09wsbk5mt0BHmq9OI4Ud8UK4tn/Re+MdJwI740U+aDfY
# H6gOvpGpDfUmm2A8TL6HvC8CJb88L8nh5mWt8Ni8JQuKSzlqsFVVuNHtr5FecPbD
# wGOAH3B4wWSDPE028+CVk2lHBKfxJpAaew1F7SHppjYmwpBObyfpqWMdDLORMmav
# pZWjK95oTTil1wWj0Jrj/xJkgWwOWS8QGdwYs02AMcsLeUZBVfHxM/cCVcGQaIBv
# TxWX6JaTLjIrLMSxk1iZRJNA9fQcubEGxA==
# SIG # End signature block
