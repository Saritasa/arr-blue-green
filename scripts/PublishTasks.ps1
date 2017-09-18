Properties `
{
    $Configuration = $null
    $ServerHost = $null
    $SiteName = $null
    $AdminUsername = $null
    $AdminPassword = $null
    $DeployUsername = $null
    $DeployPassword = $null

    $Slot = $null # Enabled, Disabled, Blue or Green.
    $SourceSlot = $null
    $DestinationSlot = $null
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

Task publish-web -depends pre-publish, init-winrm -description '* Publish all web apps to specified server.' `
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

Task swap-slots -depends init-winrm -description 'Swap deployment slots.' `
    -requiredVariables @('ServerHost', 'SiteName', 'AdminCredential', 'SourceSlot', 'DestinationSlot') `
{
    $servers = @($ServerHost)
    foreach ($server in $servers)
    {
        Write-Information "Swapping $SourceSlot and $DestinationSlot slots on $server server..."
        SwapSlotsServerFarm $server $SiteName $SourceSlot $DestinationSlot
    }

    Write-Information 'Done swapping slots.'
}

function SwapSlotsServerFarm([string] $ServerHost, [string] $SiteName, [string] $SourceSlot, [string] $DestinationSlot)
{
    $session = Start-RemoteSession -ServerHost $ServerHost

    $serverFarmName = "$SiteName-farm"
    $sourceSite = "$SiteName-$SourceSlot".ToLowerInvariant()
    $destinationSite = "$SiteName-$DestinationSlot".ToLowerInvariant()

    Invoke-Command -Session $session -ScriptBlock `
    {
        $sourceEnabled = [bool](Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter "webFarms/webFarm[@name='$using:serverFarmName']/server[@address='$using:sourceSite']" `
            -Name 'enabled').Value
        $destinationEnabled = [bool](Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter "webFarms/webFarm[@name='$using:serverFarmName']/server[@address='$using:destinationSite']" `
            -Name 'enabled').Value

        if ($sourceEnabled -eq $destinationEnabled)
        {
            throw "Both slots have the same state. Enabled: $sourceEnabled"
        }

        $sourceEnabledNew = !$sourceEnabled
        $destinationEnabledNew = !$destinationEnabled

        Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter "webFarms/webFarm[@name='$using:serverFarmName']/server[@address='$using:sourceSite']" `
            -Name 'enabled' -Value $sourceEnabledNew
        Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter "webFarms/webFarm[@name='$using:serverFarmName']/server[@address='$using:destinationSite']" `
            -Name 'enabled' -Value $destinationEnabledNew

        Write-Information "$using:ServerHost/$using:sourceSite`: $sourceEnabled -> $sourceEnabledNew"
        Write-Information "$using:ServerHost/$using:destinationSite`: $destinationEnabled -> $destinationEnabledNew"
    }

    Remove-PSSession $session
}
