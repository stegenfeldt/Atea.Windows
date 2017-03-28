# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

param([string]$sourceId,  [string]$managedEntityId, [string]$computerName)

$EventLogSourceName = "Atea FileAge Monitor"
$eventlogMessage = "Running FileAgeFolder discovery.`n"
$eventlogMessage += "Params:`n`tsourceId=$sourceId`n`tmanagedEntityId=$managedEntityId`n`tcomputerName=$computerName`n`n"
if (![System.Diagnostics.EventLog]::SourceExists($EventLogSourceName)) {
	New-EventLog -Source $EventLogSourceName -logname "Application"
}

$RegistryPath = "hklm:\Software\Atea\FileAgeMonitoring\"
$omApi = New-Object -ComObject "MOM.ScriptAPI"
$discoveryData = $omApi.CreateDiscoveryData(0, $sourceId, $managedEntityId)
if (Test-Path -Path $RegistryPath) {
	# Registry path is accessible
	$SubKeys = Get-ChildItem $RegistryPath
	ForEach ($SubKey in $SubKeys)
	{
		$FriendlyName = ($SubKey.Name.Substring($SubKey.Name.LastIndexOfAny("\")+1))
		$FolderPath = $SubKey.GetValue("FolderPath")
		$Recursive = $SubKey.GetValue("Recursive")
		$FilePattern = $SubKey.GetValue("FilePattern")
		$AgeInMinutes = $SubKey.GetValue("AgeInMinutes")
		$Operator = $SubKey.GetValue("Operator")
		$FileAgeAttribute = $SubKey.GetValue("FileAgeAttribute")


		if (($FolderPath -ne $null) -and ($Recursive -ne $null) -and ($FilePattern -ne $null) -and ($AgeInMinutes -ne $null) -and ($Operator -ne $null) -and ($FileAgeAttribute -ne $null))
		{
			$Operator = $Operator.Trim()

			#Add values to property bag for Discovery
			$discoveryInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Atea.Windows.File.FileAgeFolder']$")
			$discoveryInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $computerName)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/FriendlyName$",$FriendlyName)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/FolderPath$",$FolderPath)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/Recursive$",$Recursive)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/FilePattern$",$FilePattern)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/AgeInMinutes$",$AgeInMinutes)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/Operator$",$Operator)
			$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileAgeFolder']/FileAgeAttribute$",$FileAgeAttribute)
			$discoveryData.AddInstance($discoveryInstance)
			$eventlogMessage += "- Added $($FriendlyName) to discovery data`n"
		}
	}
}

Write-EventLog -LogName "Application" -Source $EventLogSourceName -EventID "200" -Message "" -EntryType Information -Category 0
$discoveryData
