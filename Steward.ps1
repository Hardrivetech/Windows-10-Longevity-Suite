<#
.SYNOPSIS
    Creates a System Restore Point. (Steward)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Steward.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append
Write-Host "Safety Snapshot (Steward): Creating System Restore Point..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # Check if a restore point was created in the last 24 hours to avoid system rate-limiting
    # NASA Rule 7: Check return values
    $RestorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if ($null -ne $RestorePoints) {
        $LastRP = $RestorePoints | Sort-Object CreationTime -Descending | Select-Object -First 1
    } else {
        Write-Warning "Could not retrieve system restore points."
    }

    if ($null -ne $LastRP -and ( (Get-Date) - [DateTime]$LastRP.CreationTime ).TotalHours -lt 24) {
        Write-Host "A restore point was created recently. Skipping to avoid Windows 24-hour limit." -ForegroundColor Yellow
    }
    else {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would enable System Restore and create a restore point." -ForegroundColor Gray
        } else {
            # Ensure System Restore is enabled for the OS drive
            Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop # NASA Rule 7: Fail if cannot enable
            Checkpoint-Computer -Description "Automated_Maintenance_Point" -RestorePointType "APPLICATION_INSTALL" # NASA Rule 7: Fail if cannot create
            Write-Host "Restore point created successfully." -ForegroundColor Green
        }
    }
}
catch {
    Write-Warning "Could not create restore point. Ensure you are running with Administrative privileges."
    Stop-Transcript; exit 1
}

Stop-Transcript