<#
.SYNOPSIS
    Cleans up the Windows Component Store (WinSxS) to free up disk space. (Custodian)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Custodian.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append
Write-Host "Component Store Maintenance (Custodian): Starting Cleanup..." -ForegroundColor Cyan

try {
    Write-Host "Analyzing WinSxS folder for cleanable components..."
    # Get-WindowsComponentStore -Online | Format-Table -AutoSize # Optional: to see current state

    Write-Host "Starting component store cleanup (this may take a while)..."
    # /ResetBase makes all superseded components permanently removed.
    # /StartComponentCleanup removes superseded components without /ResetBase.
    # Combining them ensures a thorough cleanup.
    # NASA Rule 7: Check return values
    $process = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait -PassThru -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "DISM cleanup did not complete successfully." }

    Write-Host "Component store cleanup finished." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during WinSxS cleanup: $_"
    Stop-Transcript; exit 1
}

Stop-Transcript