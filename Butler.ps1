<#
.SYNOPSIS
    Organizes files in specified folders. (Butler)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Butler.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting File Triage (Butler)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$TargetFolders = @() # Initialize from config
$ExtensionMap = @{} # Initialize from config
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    if ($Config.DryRun) { $DryRun = $Config.DryRun }
    if ($Config.Butler.TargetFolders) {
        $TargetFolders = $Config.Butler.TargetFolders | ForEach-Object { $_ -replace '%USERPROFILE%', $env:USERPROFILE }
    }
    # ExtensionMap is too complex for interactive setup, keep as direct JSON edit
    if ($Config.Butler.ExtensionMap) {
        $ExtensionMap = @{}
        $Config.Butler.ExtensionMap.PSObject.Properties | ForEach-Object {
            $ExtensionMap[$_.Name] = $_.Value
        }
    }
}

try {
    # NASA Rule 5: Assert configuration properties exist
    if ($null -eq $TargetFolders -or $TargetFolders.Count -eq 0) {
        Write-Warning "Butler: No target folders defined in configuration. Skipping triage."
        Stop-Transcript; exit 0
    }

    # NASA Rule 2: Use bounded for-loops for collection iteration
    for ($i = 0; $i -lt $TargetFolders.Count; $i++) {
        $Target = $TargetFolders[$i]
        if ($null -ne $Target -and (Test-Path $Target)) {
            Write-Host "Triage for folder: $Target" -ForegroundColor Gray
            $Files = Get-ChildItem -Path $Target -File
            $FileCount = @($Files).Count

            for ($j = 0; $j -lt $FileCount; $j++) {
                $File = $Files[$j]
                if ($null -eq $File -or $null -eq $File.Extension) { continue }

                $Moved = $false
                $Extension = $File.Extension.ToLower()

                $Categories = @($ExtensionMap.Keys)
                for ($k = 0; $k -lt $Categories.Count; $k++) {
                    $Category = $Categories[$k]
                    
                    if ($null -ne $Category -and $ExtensionMap[$Category] -contains $Extension) {
                        $DestFolder = Join-Path $Target $Category
                        if (!(Test-Path $DestFolder)) { New-Item -ItemType Directory -Path $DestFolder | Out-Null }

                        try {
                            if ($DryRun) {
                                Write-Host "[DRY RUN] Would file '$($File.Name)' in $Category" -ForegroundColor Gray
                            } else {
                                Write-Host "Filing '$($File.Name)' in $Category" -ForegroundColor Yellow
                                Move-Item -Path $File.FullName -Destination $DestFolder -Force -ErrorAction Stop
                            }
                            $Moved = $true
                        }
                        catch { Write-Warning "Could not file $($File.Name)" }
                        break
                    }
                }

                if (-not $Moved -and $Extension -ne "") {
                    $OtherFolder = Join-Path $Target "Others"
                    if (!(Test-Path $OtherFolder)) { New-Item -ItemType Directory -Path $OtherFolder | Out-Null }
                    Move-Item -Path $File.FullName -Destination $OtherFolder -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
catch {
    Write-Error "An error occurred during triage: $_"
    Stop-Transcript; exit 1
}

Write-Host "Triage complete." -ForegroundColor Green
Stop-Transcript