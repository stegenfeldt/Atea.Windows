# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

param([string]$mpe,  [string]$targetId, [string]$computerName)

if ($host.Name -in @('Visual Studio Code Host')) {
	$mpe = ([guid]::NewGuid()).ToString()
	$targetId = ([guid]::NewGuid()).ToString()
	$computerName = $env:COMPUTERNAME
}

$EventLogSourceName = "Atea FileShare Watcher"
$eventlogMessage = "Running FileShareFolder discovery.`n"
$eventlogMessage += "Params:`n`tmpe=$mpe`n`ttargetId=$targetId`n`tcomputerName=$computerName`n`n"
if (![System.Diagnostics.EventLog]::SourceExists($EventLogSourceName)) {
	New-EventLog -Source $EventLogSourceName -logname "Application"
}

$RegistryPath = "hklm:\Software\Atea\FileShareMonitoring\"
$omApi = New-Object -ComObject "MOM.ScriptAPI"
$discoveryData = $omApi.CreateDiscoveryData(0, $mpe, $targetId)
if (Test-Path -Path $RegistryPath) {
	# Registry path is accessible
	$SubKeys = Get-ChildItem $RegistryPath
	ForEach ($SubKey in $SubKeys)
	{
		$ShareName = ($SubKey.Name.Substring($SubKey.Name.LastIndexOfAny("\")+1))
		$UNCPath = $SubKey.GetValue("UNCPath")
		$DisplayName = $ShareName + " Watcher ($($computerName.Split('.')[0]))"


		if (($null -ne $UNCPath) -and ($null -ne $ShareName))
		{
			#Add values to property bag for Discovery
			$discoveryInstance = $discoveryData.CreateClassInstance('$MPElement[Name="Atea.Windows.File.Monitoring.FileShareWatcher"]$')
			$discoveryInstance.AddProperty('$MPElement[Name="System!System.Entity"]/DisplayName$',$DisplayName)
			$discoveryInstance.AddProperty('$MPElement[Name="Windows!Microsoft.Windows.Computer"]/PrincipalName$', $computerName)
			$discoveryInstance.AddProperty('$MPElement[Name="Atea.Windows.File.Monitoring.FileShareWatcher"]/ShareName$',$ShareName)
			$discoveryInstance.AddProperty('$MPElement[Name="Atea.Windows.File.Monitoring.FileShareWatcher"]/UNCPath$',$UNCPath)
			$discoveryData.AddInstance($discoveryInstance)
			$eventlogMessage += "- Added $($DisplayName) to discovery data`n"
		}
	}
}

if ($PSVersionTable.PSVersion.Major -lt 6) {
	Write-EventLog -LogName "Application" -Source $EventLogSourceName -EventID "200" -Message $eventlogMessage -EntryType Information -Category 0
}
$discoveryData
