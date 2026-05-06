<#
.SYNOPSIS
    Cleans up the Windows Component Store (WinSxS) to free up disk space. (Custodian)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Custodian.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append
Write-Host "Component Store Maintenance (Custodian): Starting Cleanup..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    Write-Host "Analyzing WinSxS folder for cleanable components..."
    # Get-WindowsComponentStore -Online | Format-Table -AutoSize # Optional: to see current state

    Write-Host "Starting component store cleanup (this may take a while)..."
    # /ResetBase makes all superseded components permanently removed.
    # /StartComponentCleanup removes superseded components without /ResetBase.
    # Combining them ensures a thorough cleanup.
    # NASA Rule 7: Check return values
    if ($DryRun) { Write-Host "[DRY RUN] Would execute DISM cleanup." -ForegroundColor Gray }
    else {
        $process = Start-Process -FilePath "Dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait -PassThru -ErrorAction SilentlyContinue
        if ($null -eq $process -or $process.ExitCode -ne 0) { Write-Warning "DISM cleanup did not complete successfully." }
    }

    Write-Host "Component store cleanup finished." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during WinSxS cleanup: $_"
    Stop-Transcript; exit 1
}

Stop-Transcript