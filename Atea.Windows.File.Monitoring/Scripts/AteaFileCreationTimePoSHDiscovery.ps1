# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

param([string]$sourceId,  [string]$managedEntityId, [string]$computerName)

$RegistryPath = "hklm:\Software\Atea\FileCreationTime\"
$SubKeys = Get-ChildItem $RegistryPath
$omApi = New-Object -ComObject "MOM.ScriptAPI"
#$omApi.LogScriptEvent("AteaFilCreationPoSHDiscovery.ps1", 242, 4, "Running File Creation Folder discovery with parameters $sourceId, $managedEntityId, $computerName")
$discoveryData = $omApi.CreateDiscoveryData(0, $sourceId, $managedEntityId)
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
		$discoveryInstance = $discoveryData.CreateClassInstance("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']$")
		$discoveryInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $computerName)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']/FriendlyName$",$FriendlyName)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']/FolderPath$",$FolderPath)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']/Recursive$",$Recursive)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']/FilePattern$",$FilePattern)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']/AgeInMinutes$",$AgeInMinutes)
		$discoveryInstance.AddProperty("$MPElement[Name='Atea.Windows.File.FileCreationTimeFolder']/Operator$",$Operator)
		$discoveryData.AddInstance($discoveryInstance)
	}
}
$discoveryData
