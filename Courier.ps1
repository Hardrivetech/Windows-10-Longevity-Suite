<#
.SYNOPSIS
    Checks for available Windows and Driver updates. (Courier)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Courier.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append

Write-Host "Checking for Deliveries (Courier)..." -ForegroundColor Cyan

# --- CONFIGURATION ---

try {
    # NASA Rule 7: Check return values for COM object creation
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    if ($null -eq $UpdateSession) { throw "NASA Rule 7: Failed to create Microsoft.Update.Session COM object." }
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    if ($null -eq $UpdateSearcher) { throw "NASA Rule 7: Failed to create UpdateSearcher COM object." }

    Write-Host "Searching for updates..."
    # NASA Rule 7: Check return values for search operation
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software' or IsInstalled=0 and Type='Driver'")

    $UpdatesFound = $SearchResult.Updates.Count

    if ($UpdatesFound -gt 0) {
        Write-Host "Found $UpdatesFound pending updates:" -ForegroundColor Yellow
        
        for ($i = 0; $i -lt $UpdatesFound; $i++) {
            $Update = $SearchResult.Updates.Item($i)
            if ($null -eq $Update) { continue }
            
            # NASA Rule 5: Assert Update.Categories is not null
            $Categories = if ($null -ne $Update.Categories) { ($Update.Categories | Select-Object -ExpandProperty Name) -join ", " } else { "Unknown" }
            # NASA Rule 5: Assert Update.Title is not null
            Write-Host " - [$($Categories)] $($Update.Title)"
        }
        
        Write-Host "`nPlease use Windows Settings to install these updates." -ForegroundColor Gray
    }
    else {
        Write-Host "Your system is up to date." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred during courier check: $_"
    Stop-Transcript; exit 1
}

Write-Host "Courier delivery check complete." -ForegroundColor Green
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURenr/R9UJ5/Yu3DFALUO4lo6
# 6u2gggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUWpPENnX0bxM+zzxxspO+Xqp+UiwwDQYJKoZIhvcN
# AQEBBQAEggEAk85kcdZfOeXS5gZEiW18QYxjQTj7tBP5w2b42zpfJz3W7/P743fA
# ycM2E5woMFnGC9eM4QuqPo+2eWaCTkVnjHWKQ0abdfmQUSOrpaLVu13Mo6SBfklJ
# W/bcfpi8OenlzitaVSuDfrxmXdV4rpVCtnggCfnMRvUGDJ1HAkYexfgPGmCHkYu3
# 8lRnJyEdSCcgMDsC059KToP9qNGMXjrjdjpCnlDA5693dNPuLvBSnFIbO15OMx34
# DEAol3H6V28S0yslqZUZN1UkqEUAwqVB33mP/w5Y24lKbZ9oVnBU7NHgy+GyllOn
# FqUUiilFrtvjasSUKtbrRlX+PHn34Cz4qw==
# SIG # End signature block
