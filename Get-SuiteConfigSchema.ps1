<#
.SYNOPSIS
    Defines the expected schema for the config.json file.
    This function is used by master.ps1 for runtime validation and by Pester tests.
#>

Set-StrictMode -Version Latest

function Get-SuiteConfigSchema {
    return [PSCustomObject]@{
        # Add DryRun to the schema
        DryRun = [bool]$false
        BackupDestination = [string]::Empty
        CPUThresholdPercent = [int]0
        MemoryThresholdMB = [int]0
        DiskSpaceThresholdPercent = [int]0
        FileRetentionDays = [int]0
        Email = [PSCustomObject]@{
            EnableEmailReport = [bool]$false
            SmtpServer = [string]::Empty
            SmtpPort = [int]0
            FromEmail = [string]::Empty
            ToEmail = [string]::Empty
            EmailUser = [string]::Empty
        }
        Guard = [PSCustomObject]@{
            StartupBlacklist = @([string]::Empty) # Array of strings
        }
        Butler = [PSCustomObject]@{
            TargetFolders = @([string]::Empty) # Array of strings
            ExtensionMap = [PSCustomObject]@{ # Nested object with string arrays
                Documents = @([string]::Empty)
                Images = @([string]::Empty)
                Videos = @([string]::Empty)
                Music = @([string]::Empty)
                Archives = @([string]::Empty)
                Applications = @([string]::Empty)
            }
        }
        Master = [PSCustomObject]@{
            EnableHeartbeat = [bool]$false
            HeartbeatURL = [string]::Empty
            ScriptExecutionPriority = [string]::Empty # e.g., "Normal", "BelowNormal"
        }
    }
}
# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9agK92ciP4FXh2MXqpOJzuGD
# PPigggMYMIIDFDCCAfygAwIBAgIQMl3zoiC4cYFCMb3KCL1b9jANBgkqhkiG9w0B
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
# FTAjBgkqhkiG9w0BCQQxFgQUc4urO8rV6TkskYmNa0fm7s+qUP4wDQYJKoZIhvcN
# AQEBBQAEggEAHVYFtRnLmObLMhmR9d6SaJbL25Jk6xuIB41Y10xgjIkrCIVQI3N6
# H5nGf/qV9mXj5QMB1BTiZNxmqeyncYaWiBqjTWOT4rvBOB/M3/SHaqPMP+Sz+cNs
# 6Ytfqkfb0OTuGe4D1IZGMlkxiMy0os+LcAcupFnrG5a3p45HByBTcazkVkcifFfX
# ezjc+V21YFGZRz00CFU7cPyOCntkPmrmNY4cmgtt3z+/srvScM3IGhLaENPZOkTW
# bcmkMQIHKv0LXsxTBD8e7sPSONcfnOjndnSJCzmCXKMS3WKyFgKOQBEoNeLERCG+
# PTtziU9iicXuO4/WJRbtWLIIOvFsM0ytNw==
# SIG # End signature block
