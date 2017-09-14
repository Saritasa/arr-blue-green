Framework 4.6
$InformationPreference = 'Continue'
$env:PSModulePath += ";$PSScriptRoot\scripts\modules"

. .\scripts\Saritasa.AdminTasks.ps1
. .\scripts\Saritasa.PsakeExtensions.ps1
. .\scripts\Saritasa.PsakeTasks.ps1

. .\scripts\AdminTasks.ps1
. .\scripts\BuildTasks.ps1
. .\scripts\MonitoringTasks.ps1
. .\scripts\PublishTasks.ps1

Properties `
{
    $AdminUsername = $env:AdminUsername
    $AdminPassword = $env:AdminPassword
    $DeployUsername = $env:DeployUsername
    $DeployPassword = $env:DeployPassword

    $Environment = $env:Environment
    $Slot = $env:Slot
}

TaskSetup `
{
    if (!$Environment)
    {
        Expand-PsakeConfiguration @{ Environment = 'Development' }
    }
    Import-PsakeConfigurationFile ".\Config.$Environment.ps1"
}
