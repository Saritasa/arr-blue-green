Properties `
{
    $ServerHost = $null
    $SiteName = $null
    $Slots = $null
    $AdminUsername = $null
    $AdminPassword = $null
    $DeployUsername = $null
    $DeployPassword = $null
    $WwwrootPath = $null
}

$root = $PSScriptRoot

Task setup-web-server -depends trust-host, setup-web-deploy, setup-sites -description 'Configure IIS and install required software.' `
{
}

Task setup-web-deploy -depends init-winrm -description 'Install IIS, web management service, web deploy handler, ARR.' `
    -requiredVariables @('ServerHost') `
{
    Install-Iis $ServerHost -ManagementService -WebDeploy -UrlRewrite -Arr
}

Task setup-sites -depends init-winrm -description 'Create site, deployment user, permissions delegation.' `
    -requiredVariables @('ServerHost', 'SiteName', 'WwwrootPath', 'DeployUsername', 'DeployPassword') `
{
    $session = Start-RemoteSession -ServerHost $ServerHost

    SetupSharedSite $session

    if ($Slots)
    {
        SetupFarm

        foreach ($slotName in $Slots)
        {
            Write-Information "Setting up $SiteName site in slot $slotName..."
            SetupSite $slotName $session $Environment
            Write-Information "Finished $SiteName configuration in slot $slotName."

            # Add a record to hosts.
            Invoke-Command -Session $session -ScriptBlock `
                {
                    Add-Content -Encoding UTF8 "$env:SystemRoot\System32\drivers\etc\hosts" `
                        "127.0.0.1    $using:SiteName-$using:slotName".ToLowerInvariant()
                }
        }
    }
    else
    {
        Write-Information "Setting up $SiteName site..."
        SetupSite $null $session $Environment
        Write-Information "Finished $SiteName configuration."
    }

    Remove-PSSession $session
}

function SetupSharedSite([System.Management.Automation.Runspaces.PSSession] $Session)
{
    Write-Information "Setting up $SiteName shared site..."
    SetupSite $null $Session "$($Environment)Shared"
    Write-Information "Finished $SiteName shared configuration."

    # Copy web.config with UrlRewrite rules.
    Copy-Item "$root\IIS\ExampleShared\web.config" "$WwwrootPath\$SiteName" -ToSession $Session
}

function SetupFarm()
{
    # Set up web farm.
    Invoke-Command -Session $session -ScriptBlock `
    {
        $webFarmName = "$using:SiteName-farm"

        $webFarm = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter "webFarms/webFarm[@name='$webFarmName']" -Name '.'

        if ($webFarm)
        {
            Write-Information "Web farm $webFarmName already exists."
        }
        else
        {
            Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter "webFarms" -Name "." -Value @{ name = $webFarmName }
            Write-Information "Created $webFarmName web farm."
        }
    }
}

function SetupSite([string] $Slot,
                   [System.Management.Automation.Runspaces.PSSession] $Session,
                   [string] $Environment)
{
    if ($Slot)
    {
        $siteNameWithSlot = "$SiteName-$Slot".ToLowerInvariant()
        $siteNameHash = GetShortHash $siteNameWithSlot

        Invoke-Command -Session $Session -ScriptBlock `
        {
            $webFarmName = "$using:SiteName-farm"
            $serverName = $using:siteNameWithSlot

            $server = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter "webFarms/webFarm[@name='$webFarmName']/server[@address='$serverName']" `
                -Name '.'

            if ($server)
            {
                Write-Information "Web farm server $serverName already exists."
            }
            else
            {
                Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                    -Filter "webFarms/webFarm[@name='$webFarmName']" -Name "." `
                    -Value @{ address = $serverName; enabled = 'True' }
                Write-Information "Created $serverName web farm server."
            }

            $httpPort = [int]"8$using:siteNameHash"
            $httpsPort = [int]"4$using:siteNameHash"

            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter "webFarms/webFarm[@name='$webFarmName']/server[@address='$serverName']/applicationRequestRouting" `
                -Name "httpPort" -Value $httpPort
            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter "webFarms/webFarm[@name='$webFarmName']/server[@address='$serverName']/applicationRequestRouting" `
                -Name "httpsPort" -Value $httpsPort
            Write-Information "Set $httpPort and $httpsPort ports for $serverName web farm server."
        }
    }
    else
    {
        $siteNameWithSlot = $SiteName
    }

    $properties = `
        @{
            ServerHost = $ServerHost
            SiteName = $siteNameWithSlot
            AdminCredential = $AdminCredential
            Environment = $Environment
            Slot = $Slot
            WwwrootPath = $WwwrootPath
        }

    Invoke-psake import-sites -properties $properties

    $parameters = @{ siteName = $siteNameWithSlot; deploymentUserName = $DeployUsername; deploymentUserPassword = $DeployPassword; }

    Invoke-RemoteScript -ServerHost $ServerHost -Path "$root\WebDeploy\AddDelegationRules.ps1"
    'Delegation rules are configured.'
    Invoke-RemoteScript -ServerHost $ServerHost -Path "$root\WebDeploy\SetupSiteForPublish.ps1" -Parameters $parameters
    'Site is configured for publish.'

    # TODO: Set permissions for deploy user to site root directory.
}
