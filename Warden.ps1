<#
.SYNOPSIS
    Checks for processes with high memory usage and logs them. (Warden)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Warden.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Memory Policing (Warden)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$MemoryThresholdMB = 500 # Default
 $DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
    if ($null -ne $Config.MemoryThresholdMB) {
        $MemoryThresholdMB = $Config.MemoryThresholdMB
    }
}
if ($null -eq $MemoryThresholdMB) { throw "NASA Rule 5: MemoryThresholdMB not initialized." }

try {
    $HighMemoryProcessesFound = $false

    Write-Host "Checking for processes using more than $($MemoryThresholdMB) MB of RAM..."

    # Get all processes and filter by WorkingSet (physical memory usage)
    $Processes = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.WorkingSet / 1MB -gt $MemoryThresholdMB } | Sort-Object WorkingSet -Descending
    # NASA Rule 7: Check return values
    if ($null -eq $Processes) { Write-Warning "Could not retrieve system processes." }

    if ($Processes.Count -gt 0) {
        Write-Host "WARNING: Found $($Processes.Count) processes with high memory usage:" -ForegroundColor Red
        $HighMemoryProcessesFound = $true

        # NASA Rule 2: Use bounded for-loop
        for ($i = 0; $i -lt $Processes.Count; $i++) {
            $Process = $Processes[$i]
            # NASA Rule 5: Assert Process properties are not null
            if ($null -ne $Process -and $null -ne $Process.ProcessName -and $null -ne $Process.Id -and $null -ne $Process.WorkingSet) {
                $MemoryUsedMB = [math]::Round($Process.WorkingSet / 1MB, 2)
                Write-Host " - Process: $($Process.ProcessName) (ID: $($Process.Id)) - Memory: $($MemoryUsedMB) MB"
            } else {
                Write-Warning "NASA Rule 5: Skipping process due to missing critical properties."
            }
        }
    } else {
        Write-Host "No processes found exceeding $($MemoryThresholdMB) MB of RAM." -ForegroundColor Green
    }

    # Exit with 1 if high memory processes were found, otherwise 0
    if ($HighMemoryProcessesFound -and -not $DryRun) {
        Stop-Transcript
        exit 1
    }
}
catch {
    Write-Error "An error occurred during high memory process check: $_"
    Stop-Transcript; exit 1
}

Write-Host "High memory processes check complete." -ForegroundColor Green
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/suA/qe016z5ikrtfEXQL7N9
# WQ6gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUgGd3EQff1P6FSaevHO4Hy1x4XfAwDQYJKoZIhvcN
# AQEBBQAEggEAijTmdWKGKXreMRAjapIJYtYNg8arNpRtA1Lm7IgnyKcAgAcb+cNn
# Hp+9mIN6wwBCtmv2EOrvX1DRhV7Nse/yaCegyvuUKUUTs1vmODn98vMMYh2XQsu9
# 5jZN49tuX1mH5hpVHNnYx+U+Yp9pW+z/zIX9e152zfFJJU5YMoFtZYCvwLNB+3Sw
# V8oYqLdbNfd84Um5/ngn+6aAQlutsqWFVIctOac8DW75mH/7Vgqc6c8in0bINwsB
# BijKYreiq8SlTeXTufYHPPy/xNC1YzJb7Lda4GpTFa0oje+4Lldh/yuMrBgAzSQ/
# lDH1N2B1fIAIML2WolKQYMf1Ow4eS0PA9g==
# SIG # End signature block
