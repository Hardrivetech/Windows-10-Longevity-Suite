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
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0VcUr7UhrcbacVd4h2R9lWC6
# RpSgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUIPJ+1GzXqe4pOiv260xR7uhtP1YwDQYJKoZIhvcN
# AQEBBQAEggEA01OirjJvx8/PFLHtuseEJM63MLApeyk3RPAj2max2WAXtM2Fefct
# CXLNiZpAUustVK5U4YyF06qsBR2bsalPvalwLdAW5zxZhx0viGHYFRpRV7M08zJQ
# qJ8WFzIJo/c3C58mGw7V/46howDJazUwc9P/9m61b26Kvjzab/tJlCqnTHdrUOmu
# dN+ow3WQfnT33CqoK+5AoqPNtJbDS+TGRnm5HyjMYI8H+wjXBarMmYpMVF3WEkRt
# iP1dEAtb4kNRu2eg8jiN5Ol4jO1cQjHdMAgwlg7J0onmfzsKfuvWVqgNrEouhfAk
# aSZRgTDeWVrnzzbIUIIljfJMN9cDIQQRKA==
# SIG # End signature block
