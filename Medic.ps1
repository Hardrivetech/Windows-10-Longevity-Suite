<#
.SYNOPSIS
    Checks and repairs Windows system image and file integrity.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Integrity.log"
Start-Transcript -Path $LogPath -Append

Write-Host "Starting System Integrity Checks..." -ForegroundColor Cyan

try {
    # Check health of the Windows Image
    Write-Host "Running DISM RestoreHealth (this may take a while)..."
    # NASA Rule 7: Check return values
    $process = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "DISM RestoreHealth did not complete successfully." }

    # Scan and repair protected system files
    Write-Host "Running SFC Scannow..."
    # NASA Rule 7: Check return values
    $process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "SFC Scannow did not complete successfully." }
}
catch {
    Write-Error "An error occurred during system integrity checks: $_"
    Stop-Transcript; exit 1
}

Write-Host "Integrity checks finished." -ForegroundColor Green
Stop-Transcript

# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIpJ8SLQYjuW61UlMNTP9H0nI
# KSOgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUM4Hd2bOmGeyMNtoBskCJ40pXWXcwDQYJKoZIhvcN
# AQEBBQAEggEAkib0EW96Tn0b8AAQ6lSp9CZGPsC9OGfc6XVFzM24udxojE+gxQaW
# fRE1zDVAhY0GahuoCDqN2b7JY1JtjOT8s+argHDbfcXsNvr6nUCs5PIRVatckMAG
# sEBPfJ5K7iYpXAbG+otDuSZB5PW2uqolNjiWavJ0LrOr5d69YsZij1418LNEFXdj
# cFkhk/sx8/8szA2Cq3qXTPPWpOXkJlbMft242X345sImEEq669HOF0CnhgkPC8xw
# 0+uw5oUPQWsf1YSJ4ucwtgHXSosd7tTHeosDkqJzSLQqkB0yYzZMt3bavYfyvvl2
# O1zmT/DudZi0QQEWjDC+qAe7+vF7eaxQxw==
# SIG # End signature block
