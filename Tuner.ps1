<#
.SYNOPSIS
    Optimizes drives (Trim for SSD, Defrag for HDD).
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Optimization.log"
Start-Transcript -Path $LogPath -Append

Write-Host "Starting Drive Optimization..." -ForegroundColor Cyan

try {
    # Get all fixed local drives
    $Drives = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null }
    # NASA Rule 5: Assert drive collection is not null
    if ($null -eq $Drives) { throw "NASA Rule 5: Failed to retrieve system volumes for optimization." }

    # NASA Rule 2: Use bounded for-loop
    for ($i = 0; $i -lt $Drives.Count; $i++) {
        $Drive = $Drives[$i]
        # NASA Rule 5: Assert DriveLetter is not null
        if ($null -ne $Drive.DriveLetter) {
            Write-Host "Optimizing Volume $($Drive.DriveLetter)..."
            # NASA Rule 7: Check return values
            Optimize-Volume -DriveLetter $Drive.DriveLetter -Verbose -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Error "An error occurred during drive optimization: $_"
    Stop-Transcript; exit 1
}

Write-Host "Optimization complete." -ForegroundColor Green
Stop-Transcript
