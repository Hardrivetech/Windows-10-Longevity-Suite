<#
.SYNOPSIS
    Pester tests for the config.json schema.
    Ensures config.json has the expected structure and data types.
#>

Set-StrictMode -Version Latest

$TestScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $TestScriptRoot "..\Get-SuiteConfigSchema.ps1") # Dot-source the schema definition

Describe "config.json Schema Validation" {
    $ConfigFile = Join-Path $TestScriptRoot "..\config.json"
    $ExpectedSchema = Get-SuiteConfigSchema
    $LoadedConfig = $null

    BeforeAll {
        # NASA Rule 5: Assert config file exists before testing
        if (-not (Test-Path $ConfigFile)) {
            throw "NASA Rule 5: config.json not found at $ConfigFile. Cannot run schema tests."
        }
        $LoadedConfig = Get-Content $ConfigFile | ConvertFrom-Json
        # NASA Rule 5: Assert config was loaded successfully
        if ($null -eq $LoadedConfig) {
            throw "NASA Rule 5: Failed to load or parse config.json."
        }
    }

    It "should have all expected top-level properties" {
        $ExpectedSchema.PSObject.Properties | ForEach-Object {
            $PropName = $_.Name
            $LoadedConfig.PSObject.Properties.Contains($PropName) | Should Be $true `
                -Because "config.json should contain property '$PropName'"
        }
    }

    It "should have correct types for top-level properties" {
        $ExpectedSchema.PSObject.Properties | ForEach-Object {
            $PropName = $_.Name
            $ExpectedType = $_.Value.GetType()
            $ActualValue = $LoadedConfig.$PropName
            $ActualType = $ActualValue.GetType()

            # Skip complex objects/arrays for top-level type check, they'll be checked recursively
            if ($ExpectedType -ne [PSCustomObject] -and $ExpectedType -ne [System.Object[]]) {
                $ActualType | Should Be $ExpectedType `
                    -Because "Property '$PropName' should be of type '$ExpectedType'"
            }
        }
    }

    It "should have correct types for Email properties" {
        $ExpectedSchema.Email.PSObject.Properties | ForEach-Object {
            $PropName = $_.Name
            $ExpectedType = $_.Value.GetType()
            $ActualValue = $LoadedConfig.Email.$PropName
            $ActualType = $ActualValue.GetType()
            $ActualType | Should Be $ExpectedType `
                -Because "Email property '$PropName' should be of type '$ExpectedType'"
        }
    }

    It "should have correct types for Guard properties" {
        $ExpectedSchema.Guard.PSObject.Properties | ForEach-Object {
            $PropName = $_.Name
            $ExpectedType = $_.Value.GetType()
            $ActualValue = $LoadedConfig.Guard.$PropName
            $ActualType = $ActualValue.GetType()
            $ActualType | Should Be $ExpectedType `
                -Because "Guard property '$PropName' should be of type '$ExpectedType'"
        }
    }

    It "should have correct type for DryRun property" {
        $PropName = "DryRun"
        $ExpectedType = [bool]
        $ActualValue = $LoadedConfig.$PropName
        $ActualType = $ActualValue.GetType()
        $ActualType | Should Be $ExpectedType `
            -Because "Property '$PropName' should be of type '$ExpectedType'"
    }
    # Add more 'It' blocks for other nested objects (Butler, Master) as needed
    # For Butler.ExtensionMap, you might need to iterate through its keys and check types.
}

# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUW+Re6Uuo0lGNRpY004JpFNho
# 89qgggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUlbEdk2hXhzJPoj+HXndCw3/6a3QwDQYJKoZIhvcN
# AQEBBQAEggEA1GfUG9Qi5Y856pWZXVZ0gHMBAYP1+nhd8NmVgqe8yBNufZQTOSM+
# /PU6RbGZNTp7ZuCHzP+RxltB8Zf7XrropXs4EcIR7UjrXC17obgJXk12RuNgqTyP
# wANcYPkitQW4U5tjQvRnUQuCKHDTdfatzNepdu6P9SkeVSGriZehnyGEp9Lm582P
# 9ubK1Opfv4QzBWloaqcVKoJs4PmaDsCEGIxANSRoaL9ZaN96rKjwBzxzXiYLdj7w
# HVYGRmXWTp23cWEEagO2Xv5xbGN7lOeken1P99ypWycvbirEma4byl/71WzpO2yW
# eQmnGURdlmbI9L5UmlVny5QosIQcrEiCHA==
# SIG # End signature block
