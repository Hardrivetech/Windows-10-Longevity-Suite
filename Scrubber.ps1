<#
.SYNOPSIS
    Clears cache for Google Chrome, Microsoft Edge, and Mozilla Firefox. (Scrubber)
#>

Set-StrictMode -Version Latest

$LogPath = "$env:SystemDrive\Scripts\Logs\Scrubber.log"
if (!(Test-Path (Split-Path $LogPath))) { New-Item -ItemType Directory -Path (Split-Path $LogPath) }

Start-Transcript -Path $LogPath -Append
Write-Host "Data Scouring (Scrubber): Cleaning Browser Caches..." -ForegroundColor Cyan

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "config.json"
$DryRun = $false
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json # NASA Rule 5: Assert valid JSON
    if ($null -ne $Config.DryRun) { $DryRun = $Config.DryRun }
}

try {
    # Chromium-based browsers (Chrome/Edge)
    $Browsers = @(
        @{ Name = "Chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" },
        @{ Name = "Edge";   Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" }
    )

    # NASA Rule 2: Use bounded for-loops for collection iteration
    for ($i = 0; $i -lt $Browsers.Count; $i++) {
        $Browser = $Browsers[$i]
        # NASA Rule 5: Assert Browser.Path is not null
        if ($null -ne $Browser.Path) {
            if (Test-Path $Browser.Path) {
                Write-Host "Cleaning $($Browser.Name)..." -ForegroundColor Yellow
                # NASA Rule 7: Check return values
                if ($DryRun) { Write-Host "[DRY RUN] Would remove items from $($Browser.Path)" -ForegroundColor Gray }
                else { Remove-Item -Path "$($Browser.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    # Firefox (dynamic profile search)
    $FFPath = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $FFPath) {
        # NASA Rule 7: Check return values
        $FFProfiles = Get-ChildItem -Path $FFPath -Directory -ErrorAction SilentlyContinue
        if ($null -ne $FFProfiles) {
            Write-Host "Cleaning Firefox profiles..." -ForegroundColor Yellow
            $ProfileCount = @($FFProfiles).Count
            for ($j = 0; $j -lt $ProfileCount; $j++) {
                $FFProfile = $FFProfiles[$j]
                $CachePath = Join-Path $FFProfile.FullName "cache2"
                if (Test-Path $CachePath) {
                    # NASA Rule 7: Check return values
                    if ($DryRun) { Write-Host "[DRY RUN] Would remove items from $CachePath" -ForegroundColor Gray }
                    else { Remove-Item -Path "$CachePath\*" -Recurse -Force -ErrorAction SilentlyContinue }
                }
            }
        }
    }
}
catch {
    Write-Error "An error occurred during scouring: $_"
    Stop-Transcript; exit 1
}

Write-Host "Scouring complete." -ForegroundColor Green
Stop-Transcript
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTetYH69U1dL6Hao3f36Nnhtq
# eDygggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUi4rVm++6L+/wtcCdFhw8UaMhXuUwDQYJKoZIhvcN
# AQEBBQAEggEAkMnNS07yDktRWsxzpoy5o+j8CPWwB+jFJzNzxt6ZfLdKLyWiwAUl
# 2+uiJrvGGAUtwMawcy5i26CTG4jQPavyKsMnOjV1FNA5kwaD9LD8LZH8I8y2+jW9
# FEBk8ZaxVIc0b6rIr6t+ixNXE7nliJgn7nGrmPJ/n8aD5QlUALbV7Lgz50Fqofil
# uTB5wneFvIfmLpOCbDiBXYXOFzzhxlAhauHSSOUpF8w61m//dBBzsMa3XV9/541K
# MHntDRYA5UHqySqd2bB/T14GTRw6DTsurYTuLebd0Na9EfDgdLwnrc3h7QJL2JH1
# ebNxFtrqPMVIgmcuQfWk+lF7rr3crdPplQ==
# SIG # End signature block
