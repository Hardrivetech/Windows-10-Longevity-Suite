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
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUM1HDmVeyqvCpRwiDl2IpGSMu
# Fj2gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUpmB8UmMbDgC4vIOy7nFoQ+ACz7kwDQYJKoZIhvcN
# AQEBBQAEggEAAe6k96dCZnXiuOTjG3Xdl4y6sT8cltf9Y/GuxrzZMqfdKlkpmwya
# /XS5sADPLByv71ue4MGAKGaR6HMOnqEgzACUPCupMshnYTw4eEtHlW1RI6oPYbkE
# nVUjUkreAf5uR3/VgAUsqQ7+PjapeQfq8V/srkKig19UZBlwOHOsZ/OpiGGBYx0l
# o8BCtn/lxnhhfEkD68rUoHud/LNMxY0wF9trvQTmtloqsCPC5c9FatmKF3IAF+ny
# ebNXfox3oWR+ZD1fhcPnT8t+eo18ZSEXfJKxod2I7SCt1ZCjQhUS2pJUrXORnzy9
# orsNmXLFozsIRWGFqpLA2ps3iPj86N43Gg==
# SIG # End signature block
