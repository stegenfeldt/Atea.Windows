# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

param($sourceId, $managedEntityId, $computerName)
#$sourceId = "{f581dcb0-ebb6-460d-bf5d-9b8e6a07e18d}"
#$managedEntityId = "{6cc513eb-f9f7-43b0-b8cd-07b4d0b55403}"
#$computerName = "hpd0920.banverket.root.local"


$RegistryPath = "hklm:\Software\Atea\FileCreationTime\"
$SubKeys = Get-ChildItem $RegistryPath
$OpsmgrAPI = New-Object -ComObject "MOM.ScriptAPI"
$discoveryData = $OpsmgrAPI.CreateDiscoveryData(0, $sourceId, $managedEntityId)
ForEach ($SubKey in $SubKeys)
{
	$FriendlyName = ($SubKey.Name.Substring($SubKey.Name.LastIndexOfAny("\")+1))
	$FolderPath = $SubKey.GetValue("FolderPath")
	$Recursive = $SubKey.GetValue("Recursive")
	$FilePattern = $SubKey.GetValue("FilePattern")
	$AgeInMinutes = $SubKey.GetValue("AgeInMinutes")
	$Operator = $SubKey.GetValue("Operator")
	
	
	if (($FolderPath -ne $null) -and ($Recursive -ne $null) -and ($FilePattern -ne $null) -and ($AgeInMinutes -ne $null) -and ($Operator -ne $null))
	{
		$Operator = $Operator.Trim()
		
		#Add values to property bag for Discovery
		$discoveryInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Atea.FileCreationTime.Folder']$")
		$discoveryInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $computerName)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.FileCreationTime.Folder']/FriendlyName$",$FriendlyName)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.FileCreationTime.Folder']/FolderPath$",$FolderPath)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.FileCreationTime.Folder']/Recursive$",$Recursive)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.FileCreationTime.Folder']/FilePattern$",$FilePattern)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.FileCreationTime.Folder']/AgeInMinutes$",$AgeInMinutes)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.FileCreationTime.Folder']/Operator$",$Operator)
		$discoveryData.AddInstance($discoveryInstance)
	}
}
$discoveryData
