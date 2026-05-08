<#
.SYNOPSIS
    Cleans up the Windows Component Store (WinSxS) to free up disk space. (Custodian)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Custodian.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append
Write-Host "Component Store Maintenance (Custodian): Starting Cleanup..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    Write-Host "Analyzing WinSxS folder for cleanable components..."
    # Get-WindowsComponentStore -Online | Format-Table -AutoSize # Optional: to see current state

    Write-Host "Starting component store cleanup (this may take a while)..."
    # /ResetBase makes all superseded components permanently removed.
    # /StartComponentCleanup removes superseded components without /ResetBase.
    # Combining them ensures a thorough cleanup.
    # NASA Rule 7: Check return values
    if ($DryRun) { Write-Host "[DRY RUN] Would execute DISM cleanup." -ForegroundColor Gray }
    else {
        $process = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait -PassThru -ErrorAction SilentlyContinue
        if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "DISM cleanup did not complete successfully." }
    }

    Write-Host "Component store cleanup finished." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during WinSxS cleanup: $_"
    Stop-Transcript; exit 1
}

Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFE4lUOvxa/5ozIA3AL1kZP9H
# 9zSgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUHS/X64mU9XkM53J8A2erAh+b/QEwDQYJKoZIhvcN
# AQEBBQAEggEANhf2m7B+WzwfaTVvpcjfHuDJVLAyKrMvpmNh78NZBbPzAMD+ylZq
# f50mb+BmlYM0uWkdrAL+KJ1HGcyQNTzLwQCr9hgh292QPKXfIZRCvjS5YYQyMrN7
# KHlUUupjrp9FHfcV7VtMi6W+0YvL/hYSoLkQRYPFqhKSPDO5uZVxw7n5TF3sdBio
# NQ00YlaxzT+Rjajafyp1Rd60mgXLIVtvSL1M//FcJlHAQoPOzBBpE1mMVBnr/RA0
# vPcnxfk+n7WXQx5StX/lQJMFyReX2O/5BeoGKU5B8mlOn1NvLbE1gsRWl9O6D1Pg
# NX64c2Cx/fF2k93p9fm+NgIWIsVFziPlrg==
# SIG # End signature block
