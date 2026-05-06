<#
.SYNOPSIS
    Defines the expected schema for the config.json file.
    This function is used by master.ps1 for runtime validation and by Pester tests.
#>

Set-StrictMode -Version Latest

function Get-SuiteConfigSchema {
    return [PSCustomObject]@{
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