<#
.SYNOPSIS
    Updates Microsoft Defender signatures and runs a malware scan.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Sentry.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Security Scan (Sentry)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # 1. Update Defender Signatures
    Write-Host "Updating virus definitions..."
    # 2. Run a Quick Scan
    # ScanType 1 = Quick Scan, 2 = Full Scan
    Write-Host "Running Quick Scan..."
    # 3. Check for active threats
    # Note: Get-MpThreat returns threats currently detected by the engine
    $Threats = Get-MpThreat
    if ($null -ne $Threats) {
        $ThreatCount = @($Threats).Count
        Write-Host "WARNING: Detected $ThreatCount threats!" -ForegroundColor Red
        
        for ($i = 0; $i -lt $ThreatCount; $i++) {
            $Threat = $Threats[$i]
            if ($null -ne $Threat) { Write-Host " - $($Threat.ThreatName) (Severity: $($Threat.SeverityID))" }
        }
    } else {
        Write-Host "No active threats detected." -ForegroundColor Green
    }

    if ($DryRun) {
        Write-Host "[DRY RUN] Would update MpSignature and start MpScan." -ForegroundColor Gray
    } else {
        Update-MpSignature
        Start-MpScan -ScanType QuickScan
    }
}
catch {
    Write-Error "An error occurred during the security scan: $_"
    Stop-Transcript; exit 1
}

Write-Host "Security scan complete." -ForegroundColor Green
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUu0kjpeq0TV0oQb18DWPIY927
# 4FigggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQU59tFGhipCt5efGUTE1lg8/kUmLYwDQYJKoZIhvcN
# AQEBBQAEggEAYxSTqZb0dKPO7sEnMIptB3W3AJaG/fa/oaHW4pRT2xLBUuOGTT5R
# WDIqL3+uOMzIPP4oWU+1r/pIXd7epbhGO3uAOnVHj8wlyGyBLz7tUc8MtrIObJrY
# +y406r8wiw7oxOOvLdznre1DWM746rjJ+3CkwWLf+ZQk3ZipVOcAQw9gLTxh4HlS
# 9gTVMjQtFE50YnS0A3ssW5hZUjY0aF2lxnOJn+WzJTQZ7Ha2vFEfMtqeDopVLFee
# xG863zQ9Q9/JswlWpv+f+79XpxholSo0XJLHDlF54dY0GRvTU2mVu54iaq56pZ60
# IZrfnMyrorhpybsKawP7xXsvbCCE8t23lQ==
# SIG # End signature block
