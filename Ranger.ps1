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