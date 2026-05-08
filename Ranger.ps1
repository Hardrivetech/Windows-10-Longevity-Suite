<#
.SYNOPSIS
    Checks for processes with high CPU usage and logs them. (Ranger)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Ranger.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting CPU Surveillance (Ranger)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$CPUThresholdPercent = 70 # Default
 $DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
    if ($null -ne $Config.CPUThresholdPercent) {
        $CPUThresholdPercent = $Config.CPUThresholdPercent
    }
}
if ($null -eq $CPUThresholdPercent) { throw "NASA Rule 5: CPUThresholdPercent not initialized." }

try {
    $HighCPUProcessesFound = $false

    Write-Host "Checking for processes using more than $($CPUThresholdPercent)% CPU..."

    # Get CPU usage for all processes. This requires Get-Counter.
    # We'll sample over a short period to get a more accurate instantaneous usage.
    $CpuCounters = Get-Counter '\Process(*)\% Processor Time' -ErrorAction SilentlyContinue
    # NASA Rule 7: Check return values
    if ($null -eq $CpuCounters) { Write-Warning "Could not retrieve CPU usage counters. WMI or performance counters might be unavailable or corrupted." }
    
    if ($null -ne $CpuCounters) {
        Start-Sleep -Milliseconds 500 # Wait a moment for a more stable reading
        $CpuCounters = Get-Counter '\Process(*)\% Processor Time' -ErrorAction SilentlyContinue
        if ($null -eq $CpuCounters) { Write-Warning "Could not retrieve CPU usage counters after sleep." }
        
        # NASA Rule 5: Assert CounterSamples is not null
        if ($null -eq $CpuCounters.CounterSamples) { throw "NASA Rule 5: CounterSamples collection is null." }

        # NASA Rule 2: Use bounded for-loop
        for ($i = 0; $i -lt $CpuCounters.CounterSamples.Count; $i++) {
            $Counter = $CpuCounters.CounterSamples[$i]
            # NASA Rule 5: Assert Counter properties are not null
            if ($null -eq $Counter -or $null -eq $Counter.InstanceName -or $null -eq $Counter.CookedValue) {
                Write-Warning "NASA Rule 5: Skipping counter due to missing critical properties."
                continue
            }

            # InstanceName is the process name (sometimes with #ID for multiple instances)
            $ProcessName = $Counter.InstanceName.Split('#')[0]
            $CPUUsage = [math]::Round($Counter.CookedValue, 2)

            # Exclude _Total and Idle processes, and processes below threshold
            # NASA Rule 5: Assert ProcessName is not null
            if ($null -ne $ProcessName -and $ProcessName -ne "_Total" -and $ProcessName -ne "Idle" -and $CPUUsage -gt $CPUThresholdPercent) {
                # Try to get more process details (PID, etc.)
                $Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($null -ne $Process) { Write-Host "WARNING: Process: $($Process.ProcessName) (ID: $($Process.Id)) - CPU: $($CPUUsage)%" -ForegroundColor Red }
                else { Write-Host "WARNING: Process: $($ProcessName) - CPU: $($CPUUsage)% (Details unavailable, process might have ended)" -ForegroundColor Red }
                $HighCPUProcessesFound = $true
            }
        }
    } else {
        Write-Warning "Could not retrieve CPU usage counters."
    }

    if (-not $HighCPUProcessesFound) {
        Write-Host "No processes found exceeding $($CPUThresholdPercent)% CPU usage." -ForegroundColor Green
    }

    if ($HighCPUProcessesFound -and -not $DryRun) {
        Stop-Transcript
        exit 1
    }
}
catch {
    Write-Error "An error occurred during high CPU process check: $_"
    Stop-Transcript; exit 1
}

Write-Host "High CPU processes check complete." -ForegroundColor Green
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYgK9VYz0xHiCxVc27csGbDGi
# Ke6gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUHp6Yrbyvm5oqYfOwVncUcK6u+9wwDQYJKoZIhvcN
# AQEBBQAEggEALG1iJZPLk1bqFUA7tX76LYbGo+Ort1/K3eAL05PcMh6jlOULWsVu
# YyqJE2u/m56XAM88S8jd+HtU+kJVvGjWa9MfZPm3BcnLg2+OSl3A1BY4zd/so3Ib
# T75tw8fRRZELbOo51pr2uVFVgQFTSrsnwARDm2oXN8SWxRcoJ5OEJlFeNkf9QFAl
# s//JF+NyLR0lokCYXyAfEp+71DO25nhhIE1x1RkaZW3M2d2JQUYq8AUVio/O06pt
# 929P1GPqZg1H1YYTiJUFiVrVl2oYO7fLeR+OHGfwhxkLRgDvjcUc8RizQk3wYcoT
# 9uQDH9HvftstRa2bFXB5gW9ppGcU8hHurg==
# SIG # End signature block
