<#
.SYNOPSIS
    Checks and repairs Windows system image and file integrity.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Integrity.log"
Start-Transcript -Path $LogPath -Append

Write-Host "Starting System Integrity Checks..." -ForegroundColor Cyan

try {
    # Check health of the Windows Image
    Write-Host "Running DISM RestoreHealth (this may take a while)..."
    # NASA Rule 7: Check return values
    $process = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "DISM RestoreHealth did not complete successfully." }

    # Scan and repair protected system files
    Write-Host "Running SFC Scannow..."
    # NASA Rule 7: Check return values
    $process = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -ErrorAction SilentlyContinue
    if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "SFC Scannow did not complete successfully." }
}
catch {
    Write-Error "An error occurred during system integrity checks: $_"
    Stop-Transcript; exit 1
}

Write-Host "Integrity checks finished." -ForegroundColor Green
Stop-Transcript
