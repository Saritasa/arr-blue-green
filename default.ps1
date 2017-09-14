Framework 4.6
$InformationPreference = 'Continue'
$env:PSModulePath += ";$PSScriptRoot\scripts\modules"

. .\scripts\Saritasa.AdminTasks.ps1
. .\scripts\Saritasa.PsakeExtensions.ps1
. .\scripts\Saritasa.PsakeTasks.ps1

. .\scripts\BuildTasks.ps1
. .\scripts\PublishTasks.ps1

Properties `
{
    $AdminUsername = $env:AdminUsername
    $AdminPassword = $env:AdminPassword
    $DeployUsername = $env:DeployUsername
    $DeployPassword = $env:DeployPassword

    $Configuration = 'Debug'
    $Environment = 'Development'
    $SiteName = 'example.com'
    $WwwrootPath = 'C:\inetpub\wwwroot'

}
