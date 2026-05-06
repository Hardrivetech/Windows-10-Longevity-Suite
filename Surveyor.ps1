<#
.SYNOPSIS
    Checks for low disk space on all fixed local drives. (Surveyor)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Surveyor.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Disk Capacity Survey (Surveyor)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$ThresholdPercent = 15 # Default
 $DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
    if ($null -ne $Config.DiskSpaceThresholdPercent) {
        $ThresholdPercent = $Config.DiskSpaceThresholdPercent
    }
}
if ($null -eq $ThresholdPercent) { throw "NASA Rule 5: DiskSpaceThresholdPercent not initialized." }

try {
    $LowSpaceFound = $false
    $Drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null }
    
    # NASA Rule 5: Assert drive collection is not null
    if ($null -eq $Drives) { throw "NASA Rule 5: Failed to retrieve system volumes." }

    for ($i = 0; $i -lt $Drives.Count; $i++) {
        $Drive = $Drives[$i]
        # NASA Rule 5: Assert Drive properties are not null
        if ($null -eq $Drive.DriveLetter -or $null -eq $Drive.SizeRemaining -or $null -eq $Drive.Size) { Write-Warning "NASA Rule 5: Drive object missing critical properties." }
        $FreeSpaceGB = [math]::Round($Drive.SizeRemaining / 1GB, 2)
        $TotalSizeGB = [math]::Round($Drive.Size / 1GB, 2)
        $PercentFree = [math]::Round(($Drive.SizeRemaining / $Drive.Size) * 100, 2)

        Write-Host "Checking Drive $($Drive.DriveLetter): ($($Drive.FileSystemLabel))" -ForegroundColor Gray
        Write-Host " - Total Size: $TotalSizeGB GB"
        Write-Host " - Free Space: $FreeSpaceGB GB ($PercentFree%)"

        if ($PercentFree -lt $ThresholdPercent) {
            Write-Host "WARNING: Drive $($Drive.DriveLetter): is running low on space!" -ForegroundColor Red
            $LowSpaceFound = $true
        }
    }

    if ($LowSpaceFound) {
        if (-not $DryRun) { Write-Warning "One or more drives have less than $ThresholdPercent% free space." }
        Stop-Transcript
        exit 1
    }
    else {
        Write-Host "All drives have sufficient free space." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred during the disk space check: $_"
    Stop-Transcript; exit 1
}

Write-Host "Disk space check complete." -ForegroundColor Green
Stop-Transcript