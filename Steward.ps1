<#
.SYNOPSIS
    Creates a System Restore Point. (Steward)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Steward.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append
Write-Host "Safety Snapshot (Steward): Creating System Restore Point..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # Check if a restore point was created in the last 24 hours to avoid system rate-limiting
    # NASA Rule 7: Check return values
    $RestorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if ($null -ne $RestorePoints) {
        $LastRP = $RestorePoints | Sort-Object CreationTime -Descending | Select-Object -First 1
    } else {
        Write-Warning "Could not retrieve system restore points."
    }

    if ($null -ne $LastRP -and ( (Get-Date) - [DateTime]$LastRP.CreationTime ).TotalHours -lt 24) {
        Write-Host "A restore point was created recently. Skipping to avoid Windows 24-hour limit." -ForegroundColor Yellow
    }
    else {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would enable System Restore and create a restore point." -ForegroundColor Gray
        } else {
            # Ensure System Restore is enabled for the OS drive
            Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop # NASA Rule 7: Fail if cannot enable
            Checkpoint-Computer -Description "Automated_Maintenance_Point" -RestorePointType "APPLICATION_INSTALL" # NASA Rule 7: Fail if cannot create
            Write-Host "Restore point created successfully." -ForegroundColor Green
        }
    }
}
catch {
    Write-Warning "Could not create restore point. Ensure you are running with Administrative privileges."
    Stop-Transcript; exit 1
}

Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSToaiJyd/EZCBoFHsJ/0Lj/3
# q4+gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUWxKJk/f3gISgkEwhX0G7Zv6bkRwwDQYJKoZIhvcN
# AQEBBQAEggEAF94FA/C5R86+rbFnEZexuqBmsj4tqPoTL80shUo2IXV0gUaVB+a9
# HSLmcFaj/iveirBz+kZ10ZGBSrHj5M+NWfuCRRqIuq7Zs4m0RHajGD+1lmYb6JLq
# phsJKbv6TUPJ200fwUmw5ccmhL+7pz7EBAnkbna0vAZMaYRlQOCMpvZ2OPRtG/D8
# HnJkM6D0sdranbIiEnfhC6I296uLeSTfDtQTKYMMz3SyE07ZsOWggPINCSKCHymR
# KZVt3mBBlNZI3PYC8JfSCk3KrL0K7tdjFozrP0UUo6prE/rCMoa3yfp652kO2ana
# ucEYuzD8lgUDFx/xVr+LPGFi+HCapfu0lA==
# SIG # End signature block
