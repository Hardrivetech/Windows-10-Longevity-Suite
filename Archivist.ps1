<#
.SYNOPSIS
    Backs up critical user folders using Robocopy. (Archivist)
#>

Set-StrictMode -Version Latest

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$BackupDestination = "D:\Backups\SystemMaintenance" # Fallback
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    if ($Config.BackupDestination) { $BackupDestination = $Config.BackupDestination }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

$LogPath = "$env:SystemDrive\Scripts\Logs\Archivist.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append
Write-Host "Data Archiving (Archivist): Starting Backup..." -ForegroundColor Cyan

$Sources = @(
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Desktop"
)

if (!(Test-Path $BackupDestination)) {
    Write-Warning "Backup destination $BackupDestination not found."
    Stop-Transcript; exit 1
}

try {
    for ($i = 0; $i -lt $Sources.Count; $i++) {
        $Source = $Sources[$i]
        if ($null -eq $Source) { continue }

        if (Test-Path $Source) {
            $FolderName = Split-Path $Source -Leaf
            $Dest = Join-Path $BackupDestination $FolderName
            
            Write-Host "Mirroring $FolderName (Source: $Source)..." -ForegroundColor Yellow
            if ($DryRun) {
                Write-Host "[DRY RUN] Would execute: robocopy $Source $Dest /MIR /R:3 /W:5 /MT:32 /LOG+:$LogPath /NP /TEE" -ForegroundColor Gray
            } else {
                # NASA Rule 7: Robocopy return codes are handled by the shell, but we log the operation
                & robocopy $Source $Dest /MIR /R:3 /W:5 /MT:32 /LOG+:$LogPath /NP /TEE
            }
        }
    }
}
catch {
    Write-Error "An error occurred during archiving: $_"
    Stop-Transcript; exit 1
}

Write-Host "Archiving process finished." -ForegroundColor Green
Stop-Transcript