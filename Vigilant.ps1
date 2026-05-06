<#
.SYNOPSIS
    Purges old files from specified directories based on age. (Vigilant)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Vigilant.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) -ItemType Directory }

Start-Transcript -Path $LogPath -Append
Write-Host "File Retention Enforcement (Vigilant): Starting Purge..." -ForegroundColor Cyan

try {
    # --- CONFIGURATION ---
    $ConfigPath = Join-Path $PSScriptRoot "config.json"
    $RetentionDays = 30 # Default
    $DryRun = $false
    if (Test-Path $ConfigPath) {
        $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
        if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
        if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
        if ($null -ne $Config.FileRetentionDays) {
            $RetentionDays = $Config.FileRetentionDays
        }
    }
    if ($null -eq $RetentionDays) { throw "NASA Rule 5: FileRetentionDays not initialized." }

    $TargetFolders = @(
        "$env:TEMP",
        "$env:SystemRoot\Temp"
    )

    $CutoffDate = (Get-Date).AddDays(-$RetentionDays)
    Write-Host "Purging files older than $RetentionDays days (Created before: $CutoffDate)..." -ForegroundColor Gray

    # NASA Rule 2: Use bounded for-loops
    for ($i = 0; $i -lt $TargetFolders.Count; $i++) {
        $Folder = $TargetFolders[$i]
        
        if ($null -ne $Folder -and (Test-Path $Folder)) {
            Write-Host "Processing folder: $Folder" -ForegroundColor Yellow
            # NASA Rule 7: Check return values
            # Retrieve files older than the cutoff date. 
            # We use -Recurse to catch sub-directories, but target files for deletion.
            $Files = Get-ChildItem -Path $Folder -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $CutoffDate }
            if ($null -eq $Files) { Write-Host "No files found exceeding the retention period in this folder." -ForegroundColor Gray }

            if ($Files) {
                $FileCount = @($Files).Count
                for ($j = 0; $j -lt $FileCount; $j++) {
                    $File = $Files[$j]
                    try {
                        # NASA Rule 5: Assert File.FullName is not null
                        if ($null -eq $File.FullName) { Write-Warning "NASA Rule 5: File object missing FullName property." }
                        
                        if ($DryRun) {
                            Write-Host "[DRY RUN] Would delete: $($File.FullName)" -ForegroundColor Gray
                        } else {
                            Write-Host "Deleting: $($File.FullName) [Last Modified: $($File.LastWriteTime)]" -ForegroundColor DarkGray
                            Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                        }
                    }
                    catch {
                        Write-Warning "Could not delete $($File.FullName): $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    # --- LOG ROTATION ---
    Write-Host "Cleaning up old log files..." -ForegroundColor Gray
    $LogDir = Join-Path $PSScriptRoot "Logs"
    if (Test-Path $LogDir) {
        $OldLogs = Get-ChildItem -Path $LogDir -File | Where-Object { $_.LastWriteTime -lt $CutoffDate }
        $LogCount = @($OldLogs).Count
        
        for ($l = 0; $l -lt $LogCount; $l++) {
            $LogFile = $OldLogs[$l]
            if ($DryRun) {
                Write-Host "[DRY RUN] Would rotate log: $($LogFile.Name)" -ForegroundColor Gray
            } else {
                Remove-Item $LogFile.FullName -Force
            }
        }
    }
}
catch {
    Write-Error "An error occurred during the purge process: $_"
    Stop-Transcript; exit 1
}

Write-Host "Purge complete." -ForegroundColor Green
Stop-Transcript