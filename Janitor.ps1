<#
.SYNOPSIS
    Cleans temporary files and system caches to maintain disk health.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Cleanup.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting System Cleanup..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # 1. Clear User Temp Files
    Write-Host "Cleaning User Temp files..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:TEMP\*") {
        if ($DryRun) { Write-Host "[DRY RUN] Would remove items from $env:TEMP" -ForegroundColor Gray }
        else { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # 2. Clear System Temp Files
    Write-Host "Cleaning System Temp files..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:SystemRoot\Temp\*") {
        if ($DryRun) { Write-Host "[DRY RUN] Would remove items from $env:SystemRoot\Temp" -ForegroundColor Gray }
        else { Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # 3. Clear Prefetch (Optional, but helps with clutter over years)
    Write-Host "Cleaning Prefetch..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:SystemRoot\Prefetch\*") { Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue }

    # 4. Clean Windows Update Cache (SoftwareDistribution)
    # Note: This stops the update service temporarily to clear the folder
    Write-Host "Resetting Windows Update Cache..."
    if ($DryRun) {
        Write-Host "[DRY RUN] Would stop/start wuauserv and clear update cache." -ForegroundColor Gray
    }
    # NASA Rule 7: Check return values for service operations
    $wuauserv = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuauserv) {
        # NASA Rule 7: Check if service successfully stopped
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        $checkService = Get-Service -Name "wuauserv"
        if ($checkService.Status -ne 'Stopped') { Write-Warning "NASA Rule 7: Failed to stop wuauserv. Cache cleanup might be incomplete." }
        
        if (-not $DryRun -and (Test-Path "$env:SystemRoot\SoftwareDistribution\Download\*")) {
            Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        }

        # NASA Rule 7: Check if service successfully started
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $checkService = Get-Service -Name "wuauserv"
        if ($checkService.Status -ne 'Running') { Write-Warning "NASA Rule 7: Failed to start wuauserv after cleanup." }
    } else {
        if (-not $DryRun) { Write-Warning "Windows Update service (wuauserv) not found or accessible." }
    }

    # 5. Run Disk Cleanup with default settings
    Write-Host "Running Windows Disk Cleanup..."
    # NASA Rule 7: Check return values
    if ($DryRun) { Write-Host "[DRY RUN] Would run Cleanmgr.exe /sagerun:1" -ForegroundColor Gray }
    else {
        $process = Start-Process -FilePath "Cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -PassThru -ErrorAction SilentlyContinue
        if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "Disk Cleanup (Cleanmgr.exe) did not complete successfully." }
    }
}
catch {
    Write-Error "An error occurred during the cleanup process: $_"
    Stop-Transcript; exit 1
}

Write-Host "Cleanup Complete." -ForegroundColor Green
Stop-Transcript
