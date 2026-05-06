<#
.SYNOPSIS
    Audits and disables unnecessary startup applications and scheduled tasks.
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Guard.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Starting Startup Optimization (Guard)..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$StartupBlacklist = @() # Default empty
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.Guard -and $null -ne $Config.Guard.StartupBlacklist) {
        $StartupBlacklist = $Config.Guard.StartupBlacklist
    }
}
if ($null -eq $StartupBlacklist) { throw "NASA Rule 5: StartupBlacklist not initialized." }


try {
    # 1. Registry Run Keys (HKCU and HKLM)
    $RegistryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )

    # NASA Rule 2: Use bounded for-loops for collection iteration
    for ($i = 0; $i -lt $RegistryPaths.Count; $i++) {
        $Path = $RegistryPaths[$i]
        if (Test-Path $Path) {
            # NASA Rule 7: Check return values
            $Items = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
            if ($null -ne $Items -and $null -ne $Items.PSObject) {
                $Props = @($Items.PSObject.Properties)
                for ($j = 0; $j -lt $Props.Count; $j++) {
                    $Item = $Props[$j]
                    
                    if ($null -ne $Item -and $null -ne $Item.Name) {
                        # NASA Rule 2: Inner bounded loop
                        for ($k = 0; $k -lt $StartupBlacklist.Count; $k++) {
                            $App = $StartupBlacklist[$k]
                            if ($null -ne $App -and $Item.Name -like "*$App*") {
                                Write-Host "Removing Registry Startup: $($Item.Name) from $Path" -ForegroundColor Yellow
                                # NASA Rule 7: Check return values
                                Remove-ItemProperty -Path $Path -Name $Item.Name -ErrorAction SilentlyContinue
                            }
                        }
                    }
                }
            }
        }
    }
    # 2. Startup Folders (Shortcuts)
    $FolderPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    for ($i = 0; $i -lt $FolderPaths.Count; $i++) {
        $FolderPath = $FolderPaths[$i]
        if (Test-Path $FolderPath) {
            # NASA Rule 7: Check return values
            $Files = Get-ChildItem -Path $FolderPath -Filter "*.lnk" -ErrorAction SilentlyContinue
            if ($null -ne $Files) {
                for ($j = 0; $j -lt $Files.Count; $j++) {
                    $File = $Files[$j]
                    
                    if ($null -ne $File -and $null -ne $File.Name) {
                        for ($k = 0; $k -lt $StartupBlacklist.Count; $k++) {
                            $App = $StartupBlacklist[$k]
                            if ($null -ne $App -and $File.Name -like "*$App*") {
                                Write-Host "Deleting Startup Shortcut: $($File.Name)" -ForegroundColor Yellow
                                # NASA Rule 7: Check return values
                                Remove-Item -Path $File.FullName -Force
                            }
                        }
                    }
                }
            }
        }
    }


    # 3. Common Bloatware Scheduled Tasks
    # Many apps use Task Scheduler to bypass 'Startup' visibility.
    Write-Host "Checking for common third-party update tasks..."
    $TaskKeywords = @("*Adobe*", "*GoogleUpdate*", "*EdgeUpdate*") # NASA Rule 5: Assert array is not null
    if ($null -ne $TaskKeywords) {
        for ($i = 0; $i -lt $TaskKeywords.Count; $i++) {
            $Keyword = $TaskKeywords[$i]
            
            # NASA Rule 7: Check return values
            $Tasks = Get-ScheduledTask -TaskName $Keyword -ErrorAction SilentlyContinue
            if ($null -ne $Tasks) {
                $TCount = @($Tasks).Count
                for ($j = 0; $j -lt $TCount; $j++) {
                    $Task = $Tasks[$j]
                    if ($null -ne $Task -and $null -ne $Task.State) {
                        if ($Task.State -ne "Disabled") {
                            Write-Host "Disabling Scheduled Task: $($Task.TaskName)" -ForegroundColor Yellow
                            # NASA Rule 7: Check return values
                            Disable-ScheduledTask -TaskName $Task.TaskName -Confirm:$false
                        }
                    }
                }
            }
        }
    }
}
catch {
    Write-Error "An error occurred during startup optimization: $_"
    Stop-Transcript; exit 1
}

Write-Host "Startup optimization complete." -ForegroundColor Green
Stop-Transcript