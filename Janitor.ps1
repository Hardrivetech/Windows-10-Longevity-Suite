<#
.SYNOPSIS
    Cleans temporary files and system caches to maintain disk health.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Cleanup.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting System Cleanup..." -ForegroundColor Cyan
try {
    # 1. Clear User Temp Files
    Write-Host "Cleaning User Temp files..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:TEMP\*") { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue }

    # 2. Clear System Temp Files
    Write-Host "Cleaning System Temp files..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:SystemRoot\Temp\*") { Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue }

    # 3. Clear Prefetch (Optional, but helps with clutter over years)
    Write-Host "Cleaning Prefetch..."
    # NASA Rule 7: Check return values
    if (Test-Path "$env:SystemRoot\Prefetch\*") { Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue }

    # 4. Clean Windows Update Cache (SoftwareDistribution)
    # Note: This stops the update service temporarily to clear the folder
    Write-Host "Resetting Windows Update Cache..."
    # NASA Rule 7: Check return values for service operations
    $wuauserv = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuauserv) {
        # NASA Rule 7: Check if service successfully stopped
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        $checkService = Get-Service -Name "wuauserv"
        if ($checkService.Status -ne 'Stopped') { Write-Warning "NASA Rule 7: Failed to stop wuauserv. Cache cleanup might be incomplete." }

        if (Test-Path "$env:SystemRoot\SoftwareDistribution\Download\*") { Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue }

        # NASA Rule 7: Check if service successfully started
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $checkService = Get-Service -Name "wuauserv"
        if ($checkService.Status -ne 'Running') { Write-Warning "NASA Rule 7: Failed to start wuauserv after cleanup." }
    } else {
        Write-Warning "Windows Update service (wuauserv) not found or accessible."
    }

    # 5. Run Disk Cleanup with default settings
    Write-Host "Running Windows Disk Cleanup..."
    # NASA Rule 7: Check return values
    $process = Start-Process -FilePath "Cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -PassThru -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "Disk Cleanup (Cleanmgr.exe) did not complete successfully." }
}
catch {
    Write-Error "An error occurred during the cleanup process: $_"
    Stop-Transcript; exit 1
}

Write-Host "Cleanup Complete." -ForegroundColor Green
Stop-Transcript
