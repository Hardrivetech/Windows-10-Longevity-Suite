<#
.SYNOPSIS
    Pester tests for the Setup.ps1 script.
    Verifies setup and uninstall functionality.
#>

Set-StrictMode -Version Latest

$TestScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SetupScriptPath = Join-Path $TestScriptRoot "..\Setup.ps1"
$ConfigFile = Join-Path $TestScriptRoot "..\config.json"
$CredentialFile = Join-Path $TestScriptRoot "..\smtp.credential"
$TaskName = "Windows Maintenance Suite"

Describe "Setup.ps1 Script Functionality" {
    # Clean up before each test to ensure a fresh state
    BeforeEach {
        if (Test-Path $ConfigFile) { Remove-Item $ConfigFile -Force }
        if (Test-Path $CredentialFile) { Remove-Item $CredentialFile -Force }
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
    }

    Context "Setup Flow" {
        It "should create config.json and scheduled task with default values" {
            # Mock Read-Host for default choices
            Mock Read-Host {
                param($Prompt)
                switch ($Prompt) {
                    "Choose an action" { return "setup" }
                    "Enter backup destination path (Default: D:\Backups\SystemMaintenance)" { return "" } # Default
                    "CPU Usage Alert Threshold % (Default: 70)" { return "" } # Default
                    "Memory Usage Alert Threshold MB (Default: 500)" { return "" } # Default
                    "Free Disk Space Alert Threshold % (Default: 15)" { return "" } # Default
                    "Days to keep temporary files (Default: 30)" { return "" } # Default
                    "Enable Email Reports? (y/n)" { return "n" } # Disable email
                    "Enter comma-separated app names to disable at startup (e.g., Teams,Spotify). Leave blank to keep current." { return "" } # Default
                    "Enable Heartbeat (sends a signal on completion)?" { return "n" } # Disable heartbeat
                    "Script Execution Priority (Lower priority means less impact on active use)" { return "Normal" } # Default
                    "Enter comma-separated folders to organize (e.g., %USERPROFILE%\Downloads,%USERPROFILE%\Desktop). Leave blank to keep current." { return "" } # Default
                    default { throw "Unexpected Read-Host prompt: $Prompt" }
                }
            }
            # Mock scheduled task cmdlets
            Mock New-ScheduledTaskAction { return [PSCustomObject]@{ Action = "Mocked" } }
            Mock New-ScheduledTaskTrigger { return [PSCustomObject]@{ Trigger = "Mocked" } }
            Mock New-ScheduledTaskPrincipal { return [PSCustomObject]@{ Principal = "Mocked" } }
            Mock New-ScheduledTaskSettingsSet { return [PSCustomObject]@{ Settings = "Mocked" } }
            Mock Register-ScheduledTask { return $null } # Just ensure it's called

            # Execute the setup script
            & $SetupScriptPath

            # Assertions
            Test-Path $ConfigFile | Should Be $true `
                -Because "config.json should be created"
            
            $ConfigContent = Get-Content $ConfigFile | ConvertFrom-Json
            $ConfigContent.BackupDestination | Should Be "D:\Backups\SystemMaintenance" `
                -Because "BackupDestination should be default"
            $ConfigContent.Email.EnableEmailReport | Should Be $false `
            $ConfigContent.DryRun | Should Be $false `
                -Because "DryRun should be disabled by default"
                -Because "Email reports should be disabled"
            Test-Path $CredentialFile | Should Be $false `
                -Because "Credential file should not be created if email is disabled"

            # Verify scheduled task registration
            Assert-MockCalled Register-ScheduledTask -Times 1 `
                -Because "Register-ScheduledTask should be called once"
        }

        It "should create config.json and scheduled task with custom values and email enabled" {
            # Mock Read-Host for custom choices
            Mock Read-Host {
                param($Prompt)
                switch ($Prompt) {
                    "Choose an action" { return "setup" }
                    "Enable Dry Run mode (No changes made)?" { return "y" }
                    "Enter backup destination path (Default: D:\Backups\SystemMaintenance)" { return "C:\MyBackup" }
                    "CPU Usage Alert Threshold % (Default: 70)" { return "80" }
                    "Memory Usage Alert Threshold MB (Default: 500)" { return "1024" }
                    "Free Disk Space Alert Threshold % (Default: 15)" { return "10" }
                    "Days to keep temporary files (Default: 30)" { return "60" }
                    "Enable Email Reports? (y/n)" { return "y" }
                    "SMTP Server (Default: smtp.yourprovider.com)" { return "smtp.gmail.com" }
                    "SMTP Port (Default: 587)" { return "465" }
                    "Sender Email Address (Default: maintenance@yourdomain.com)" { return "sender@example.com" }
                    "Recipient Email Address (Default: your-admin-email@domain.com)" { return "recipient@example.com" }
                    "SMTP Username (Default: smtp-username)" { return "myuser" }
                    "Enter SMTP Password (will be encrypted):" { return (ConvertTo-SecureString "mypassword" -AsPlainText -Force) }
                    "Enter comma-separated app names to disable at startup (e.g., Teams,Spotify). Leave blank to keep current." { return "Teams,Slack" }
                    "Enable Heartbeat (sends a signal on completion)?" { return "y" }
                    "Heartbeat URL (e.g., healthchecks.io endpoint)" { return "http://myheartbeat.com" }
                    "Script Execution Priority (Lower priority means less impact on active use)" { return "BelowNormal" }
                    "Enter comma-separated folders to organize (e.g., %USERPROFILE%\Downloads,%USERPROFILE%\Desktop). Leave blank to keep current." { return "%USERPROFILE%\Documents" }
                    default { throw "Unexpected Read-Host prompt: $Prompt" }
                }
            }
            Mock New-ScheduledTaskAction { return [PSCustomObject]@{ Action = "Mocked" } }
            Mock New-ScheduledTaskTrigger { return [PSCustomObject]@{ Trigger = "Mocked" } }
            Mock New-ScheduledTaskPrincipal { return [PSCustomObject]@{ Principal = "Mocked" } }
            Mock New-ScheduledTaskSettingsSet { return [PSCustomObject]@{ Settings = "Mocked" } }
            Mock Register-ScheduledTask { return $null }
            Mock ConvertTo-SecureString { param($String) return $String } # Mock for password input
            Mock Set-Content { param($Path, $Value) if ($Path -eq $CredentialFile) { $Value | Out-File $Path } else { $Value | Out-File $Path } }

            & $SetupScriptPath

            Test-Path $ConfigFile | Should Be $true
            Test-Path $CredentialFile | Should Be $true

            $ConfigContent = Get-Content $ConfigFile | ConvertFrom-Json
            $ConfigContent.DryRun | Should Be $true `
                -Because "DryRun should be enabled"
            $ConfigContent.BackupDestination | Should Be "C:\MyBackup"
            $ConfigContent.CPUThresholdPercent | Should Be 80
            $ConfigContent.Email.EnableEmailReport | Should Be $true
            $ConfigContent.Email.SmtpServer | Should Be "smtp.gmail.com"
            $ConfigContent.Email.ToEmail | Should Be "recipient@example.com"
            $ConfigContent.Guard.StartupBlacklist | Should Be @("Teams", "Slack")
            $ConfigContent.Master.EnableHeartbeat | Should Be $true
            $ConfigContent.Master.HeartbeatURL | Should Be "http://myheartbeat.com"
            $ConfigContent.Master.ScriptExecutionPriority | Should Be "BelowNormal"
            $ConfigContent.Butler.TargetFolders | Should Be @("%USERPROFILE%\Documents")

            Assert-MockCalled Register-ScheduledTask -Times 1
        }
    }

    Context "Uninstall Flow" {
        It "should remove scheduled task, config, and credential files" {
            # Setup a dummy config and credential file for removal
            @{ Test = "Config" } | ConvertTo-Json | Set-Content $ConfigFile
            "SecureString" | Set-Content $CredentialFile
            Mock Get-ScheduledTask { return [PSCustomObject]@{ TaskName = $TaskName } }
            Mock Unregister-ScheduledTask { return $null }
            Mock Read-Host {
                param($Prompt)
                switch ($Prompt) {
                    "Choose an action" { return "uninstall" }
                    "Remove all generated logs in C:\Scripts\Logs?" { return "n" }
                    "Remove all PowerShell scripts in C:\Scripts?" { return "n" }
                    default { throw "Unexpected Read-Host prompt: $Prompt" }
                }
            }

            & $SetupScriptPath

            Test-Path $ConfigFile | Should Be $false `
                -Because "config.json should be removed"
            Test-Path $CredentialFile | Should Be $false `
                -Because "Credential file should be removed"
            Assert-MockCalled Unregister-ScheduledTask -Times 1 `
                -Because "Unregister-ScheduledTask should be called once"
        }
    }
}