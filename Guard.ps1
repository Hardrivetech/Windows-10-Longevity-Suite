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
 $DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -eq $Config) { throw "NASA Rule 5: Failed to parse config.json." }
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
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
                                if ($DryRun) {
                                    Write-Host "[DRY RUN] Would remove Registry Startup: $($Item.Name) from $Path" -ForegroundColor Gray
                                } else {
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
                                if ($DryRun) {
                                    Write-Host "[DRY RUN] Would delete Startup Shortcut: $($File.Name)" -ForegroundColor Gray
                                } else {
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
                            if ($DryRun) {
                                Write-Host "[DRY RUN] Would disable Scheduled Task: $($Task.TaskName)" -ForegroundColor Gray
                            } else {
                                # NASA Rule 7: Check return values
                                Disable-ScheduledTask -TaskName $Task.TaskName -Confirm:$false
                            }
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
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTGPbfnXUyhwf5qhT05JXv0y6
# uLagggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
# AQsFADAiMSAwHgYDVQQDDBdXaW5kb3dzTWFpbnRlbmFuY2VTdWl0ZTAeFw0yNjA1
# MDgyMTAxMjNaFw0yNzA1MDgyMTIxMjNaMCIxIDAeBgNVBAMMF1dpbmRvd3NNYWlu
# dGVuYW5jZVN1aXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3/92
# wnIIt1llLFV+0SjNEzyfmSk2LRqCY0G+SI1SRoBlPy4HXmQw9MGBFV4t2BoM202A
# cfNL8TTzhHblkwoUYpOEP4/NpWFdMFeQ+ord/qP2AcXvEChI2yOQXM7BGcyOfeOv
# UE8I9UgHVXdECumzfGwgwWPheypDu8faj4G8YhMv/OgaofxtxWEDjVGLcjruSYQ0
# gekSLdIqhi4X8lCroO5J6/4ZoO94UH8tgSfN6BS2GYwCLaOfrhhDiSvuOCl7X0x2
# 5yxvpMPAzrwI4OMMj5gyZaseXhcQ1Mi5lBTyjpIiaeEtiwBpFPOSIgMYcfTEGFUy
# pwkmw1q0SQbn5lOaFQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFJwEMfRj/lYgIdengr8i4zW0cFZqMA0GCSqG
# SIb3DQEBCwUAA4IBAQBM0i2BcZ6KmpbZv0ksmLj6QQ4qVLVh2P9pRcK2C8xz8EZ2
# jK1BWPSyPar5CqLw2ZNubAEAZxbFQlCxmWEgzjZ3QybsxLDmHv4uhljvU2nWnnty
# rze/8DJiSp9fiA4xu/H4W36dSJcvYfAisAxBJKV/fzIbHNrQWRCvzySygTyGjRb2
# x7li8UsU+fZAYDnWp5aU9Gw+sTj5ULK/wcvBsKD9y2sN6az/Z4S4xHj3LpmQfDrX
# VYBPP+WnLhwLEqYqq/ZSVvYsWPa/ZzSJMBsIiI+fC/IhHGWNX9/xzFfkGm9xpd9s
# epWLjCEpVE+R3Q85JLVNwYO1MCobYe+Mm8tRAwL9MYIB1zCCAdMCAQEwNjAiMSAw
# HgYDVQQDDBdXaW5kb3dzTWFpbnRlbmFuY2VTdWl0ZQIQMl3zoiC4cYFCMb3KCL1b
# 9jAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAjBgkqhkiG9w0BCQQxFgQUArXIwOQ29NRtAGXvHuBbf6230kEwDQYJKoZIhvcN
# AQEBBQAEggEAAScmlh7nN0HzMvhXMYiDqwjPMMbeCMWjJeNWID4ZbhCbtiudA2Sh
# c8ykc6pJd3lWjwoiGbIs3kbPB8ZrM09e4P9Rt4hB35opS+JcOm3SnQ0A+9QSSGUl
# I8uscX1LV7NW1liVYtoBvZch3LQTIu9qFPgKaU0DJLGmmUsaVE+QSru9jLsuoDTr
# FgpforTpCWHWhyN/ykazpGuQe26E+0gkus0mXegOcIlv/D18tUv9XlQPoko2kpEM
# 00o+TdrOfEUa4ETLFJyMcqdFJdpIyfcP9Mg2CbTFDx1m36Ya2Tp3q7d5U4wL+ZqF
# vwe0duaGMDQNglnevs2S1AVoxSjZEhcIbw==
# SIG # End signature block
