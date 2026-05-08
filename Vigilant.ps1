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
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJk0ybrNC+zX8s2HJmu0838oF
# vKOgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUZhz2Jys3AMWOuR3uRfFGKn4J6/wwDQYJKoZIhvcN
# AQEBBQAEggEAe1qSLcfxSVE6gRgSjRV0tQr8m4O2Uk1YZ+cI6OVQBLW0rBpnr3Nk
# A3qI6VG7R8koSSE7OQIWQALR4L6n8y3/k10X83arg6j7aAJ+XF3DrDsNx27ASyGW
# XZlPmX2VLRPknHlFgHbyN2C+bIQFnyx7zoMMqL59c5VN1+Gxqk4bzbIp0GJ9hS42
# sGBq8muCUgnbxobjaLuV0SOq8Q/IInRd+cOwfqMAn5scsQ0Wy+CjGxv4fUXGyY4j
# UJ/VxwYAjO6cqYRgZ8V+EVw8aPj4PXEYZP5wSxrsMlHWp7xvkaqYw5tNGcLAnO96
# oNSGtNZeZ2wvPxO9fdGR/7fz9cln0FNEvQ==
# SIG # End signature block
