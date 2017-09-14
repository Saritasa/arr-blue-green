Properties `
{
    $Configuration = $null
    $ServerHost = $null
    $SiteName = $null
    $AdminUsername = $null
    $AdminPassword = $null
    $DeployUsername = $null
    $DeployPassword = $null
}

$root = $PSScriptRoot
$src = Resolve-Path "$root\.\src"
$workspace = Resolve-Path "$root\.."


Task pre-publish -depends pre-build -description 'Set common publish settings for all deployments.' `
    -requiredVariables @('DeployUsername', 'DeployPassword') `
{
    $credential = New-Object System.Management.Automation.PSCredential($DeployUsername, (ConvertTo-SecureString $DeployPassword -AsPlainText -Force))
    Initialize-WebDeploy -Credential $credential
}

Task publish-web -depends pre-publish -description '* Publish all web apps to specified server.' `
    -requiredVariables @('Configuration', 'ServerHost', 'SiteName') `
{
    # $packagePath = "$workspace\Example.zip"
    # Invoke-PackageBuild "$src\Example\Example.csproj" $packagePath $Configuration
    # Invoke-WebDeployment $packagePath $ServerHost $SiteName -Application ''
}

