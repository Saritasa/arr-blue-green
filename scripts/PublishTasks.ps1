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
$src = Resolve-Path "$root\..\src"
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
    DeployWebProject "$src\BlueGreenTest\BlueGreenTest.csproj"
}

function DeployWebProject([string] $ProjectPath, [string] $AppName)
{
    $packagePath = "$src\BlueGreenTest.zip"
    Invoke-PackageBuild $ProjectPath $packagePath

    if ($Slot)
    {
        if ($Slot -eq 'Enabled')
        {
            $newSlot = FindSlot $ServerHost $SiteName $Slots $true
        }
        elseif ($Slot -eq 'Disabled')
        {
            $newSlot = FindSlot $ServerHost $SiteName $Slots $false
        }
        else
        {
            $newSlot = $Slot
        }

        if (!$newSlot)
        {
            throw "$Slot slot is not found."
        }

        $siteNameWithSlot = "$SiteName-$newSlot".ToLowerInvariant()
    }
    else
    {
        $siteNameWithSlot = $SiteName
    }

    Invoke-WebDeployment $packagePath $ServerHost $siteNameWithSlot $AppName
    Write-Information "Published $siteNameWithSlot/$AppName to $PrimaryWebServer server."
}

function FindSlotServerFarm([string] $ServerHost, [string] $SiteName, [string[]] $Slots, [bool] $State)
{
    Write-Information "Looking for slot with Enabled=$State state..."
    $session = Start-RemoteSession -ServerHost $ServerHost

    $serverFarmName = "$SiteName-farm"

    $foundSlot = Invoke-Command -Session $session -ScriptBlock `
        {
            $resultSlot = $null

            foreach ($slot in $using:Slots)
            {
                $siteNameWithSlot = "$using:SiteName-$slot".ToLowerInvariant()
                $property = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                    -Filter "webFarms/webFarm[@name='$using:serverFarmName']/server[@address='$siteNameWithSlot']" `
                    -Name 'enabled'
                $enabled = [bool]$property.Value
                Write-Information "$using:ServerHost/$siteNameWithSlot`: $enabled"

                if ($enabled -eq $using:State)
                {
                    if ($resultSlot)
                    {
                        throw "Multiple slots have Enabled=$enabled state."
                    }
                    $resultSlot = $slot
                }
            }

            $resultSlot
        }

    Remove-PSSession $session

    if ($foundSlot)
    {
        Write-Information "Found slot: $foundSlot"
    }
    else
    {
        Write-Information 'Slot not found.'
    }

    $foundSlot
}

function FindSlot([string] $ServerHost, [string] $SiteName, [string[]] $Slots, [bool] $State)
{
    FindSlotServerFarm $ServerHost $SiteName $Slots $State
}
