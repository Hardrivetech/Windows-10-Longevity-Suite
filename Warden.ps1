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