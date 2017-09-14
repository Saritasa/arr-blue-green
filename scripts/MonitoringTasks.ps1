Properties `
{
    $Slots = $null
    $AdminUsername = $null
    $AdminPassword = $null

    $ServerHost = $null
    $Apps = $null # Comma-separated names of applications.
    $AppServer = 0 # 1, 2 or 3

    $WwwrootPath = $null

    $FileName = $null
    $Files = $null # Comma-separated names of XML files.
}

$root = $PSScriptRoot

Task show-web-version -depends init-winrm -description '* Show versions of deployed applications.' `
    -requiredVariables @('ServerHost', 'AdminCredential', 'FileName') `
{
    $result = @{}
    $servers = @($ServerHost)
    foreach ($server in $servers)
    {
        $serverResult = ShowWebVersion $server $SiteName $Slots
        $result[$server] = $serverResult
    }

    SaveVersionInfo $result $FileName
}

function GetSlotStatusServerFarm([string] $SiteName, [string] $Slot)
{
    $siteNameWithSlot = "$SiteName-$Slot".ToLowerInvariant()
    $serverFarmName = "$SiteName-farm"

    $property = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' `
        -Filter "webFarms/webFarm[@name='$serverFarmName']/server[@address='$siteNameWithSlot']" `
        -Name 'enabled'
    [bool]$property.Value
}

function ShowWebVersion([string] $ServerHost, [string] $SiteName, [string[]] $Slots)
{
    $slotStatuses = @{}
    foreach ($slot in $Slots)
    {
        $slotStatuses[$slot] = GetSlotStatusServerFarm $ServerHost $SiteName $slot
    }

    $session = Start-RemoteSession -ServerHost $ServerHost

    Invoke-Command -Session $session -ScriptBlock `
        {
            $wwwRoot = $using:WwwrootPath
            $newSlots = @('Default') + $using:Slots
            $result = @()


            $resultApp = @{ Name = '/' }
            $resultApp.Slots = @{}

            foreach ($slot in $newSlots)
            {
                $resultApp.Slots[$slot] = @{}

                if ($slot -ne 'Default')
                {
                    $siteNameWithSlot = "$using:SiteName-$slot".ToLowerInvariant()
                    $resultApp.Slots[$slot].Enabled = ($using:slotStatuses)[$slot]
                }
                else
                {
                    $siteNameWithSlot = $using:SiteName
                    $resultApp.Slots[$slot].Enabled = $true
                }

                $version = $null
                $file = Get-Item "$wwwRoot\$siteNameWithSlot\bin\BlueGreenTest.dll" `
                    -ErrorAction SilentlyContinue

                if ($file)
                {
                    $version = $file.VersionInfo.FileVersion
                    Write-Information "$using:ServerHost $siteNameWithSlot/`: $version"
                }

                $resultApp.Slots[$slot].Version = $version
            }

            $result += $resultApp


            $result
        }

    Remove-PSSession $session
}

function SaveVersionInfo([hashtable] $VersionInfo, [string] $FileName)
{
    $doc = New-Object System.Xml.XmlDocument
    $xmlServers = $doc.CreateNode('element', 'Servers', $null)

    foreach ($server in $VersionInfo.Keys)
    {
        $xmlServer = $doc.CreateNode('element', 'Server', $null)
        $xmlServer.SetAttribute('Name', $server)

        foreach ($app in $VersionInfo[$server])
        {
            $xmlApp = $doc.CreateElement('element', 'App', $null)
            $xmlApp.SetAttribute('Name', $app.Name)

            foreach ($slot in $app.Slots.Keys)
            {
                $xmlSlot = $doc.CreateElement('element', 'Slot', $null)
                $xmlSlot.SetAttribute('Name', $slot)
                $xmlSlot.SetAttribute('Enabled', $app.Slots[$slot].Enabled)
                $xmlSlot.SetAttribute('Version', $app.Slots[$slot].Version)
                $xmlApp.AppendChild($xmlSlot)
            }

            $xmlServer.AppendChild($xmlApp)
        }

        $xmlServers.AppendChild($xmlServer)
    }

    $doc.AppendChild($xmlServers)
    $doc.Save($FileName)
}

Task generate-version-report `
    -requiredVariables @('Files') `
{
    $fileName = 'VersionInfo.xml'
    $doc = New-Object System.Xml.XmlDocument
    $servers = $doc.CreateElement('Servers')
    $doc.AppendChild($servers) | Out-Null

    foreach ($file in $Files.Split(','))
    {
        $tmpDoc = [xml](Get-Content $file)

        foreach ($node in $tmpDoc.DocumentElement.ChildNodes)
        {
            $servers.AppendChild($doc.ImportNode($node, $true))
        }
    }

    $doc.Save($fileName)

    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
    $xslt.Load("$root\VersionInfo\VersionInfo.xslt")
    $xslt.Transform($fileName, "$root\VersionInfo\Index.html")

    Write-Information "$fileName is created."
}
