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

    # Add more 'It' blocks for other nested objects (Butler, Master) as needed
    # For Butler.ExtensionMap, you might need to iterate through its keys and check types.
}
