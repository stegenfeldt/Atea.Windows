# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

[CmdletBinding()]
Param(
	[ValidateSet("CreationTime","LastWriteTime","LastAccessTime")]
	[Parameter(Mandatory=$true)]
	[string] $FileTimeAttribute
)

$RegistryPath = "hklm:\Software\Atea\FileTimeMonitoring\"
$EventLogSourceName = "Atea FileTime Monitor"
$SubKeys = Get-ChildItem $RegistryPath
$omApi = New-Object -ComObject "MOM.ScriptAPI"

if (![System.Diagnostics.EventLog]::SourceExists($EventLogSourceName)) {
	New-EventLog -Source $EventLogSourceName -logname "Application"
}

ForEach ($SubKey in $SubKeys) {
	$FriendlyName = ($SubKey.Name.Substring($SubKey.Name.LastIndexOfAny("\")+1))
	$FolderPath = $SubKey.GetValue("FolderPath")
	$Recursive = $SubKey.GetValue("Recursive")
	$FilePattern = $SubKey.GetValue("FilePattern")
	$AgeInMinutes = $SubKey.GetValue("AgeInMinutes")
	$Operator = $SubKey.GetValue("Operator")

	if (($FolderPath -ne $null) -and ($Recursive -ne $null) -and ($FilePattern -ne $null) -and ($AgeInMinutes -ne $null) -and ($Operator -ne $null)) {
		$Operator = $Operator.Trim()

		switch ($Operator)
		{
			"<" {$Operator = "-lt"}
			"<=" {$Operator = "-le"}
			">" {$Operator = "-gt"}
			">=" {$Operator = "-ge"}
			default {$Operator = "-gt"}
		}

		if ($Recursive.Trim() -eq "false")
		{
			$Recursive = ""
		} else {
			$Recursive = "-Recurse "
		}

		$command = "Get-ChildItem $FolderPath $Recursive| where {(`$_.Name -like '$FilePattern') -and ((((Get-Date) - `$_.$FileTimeAttribute).TotalMinutes) $Operator $AgeInMinutes)}"
		$ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($command)
		#$command
		$Files = @(Invoke-Command -ScriptBlock $ScriptBlock)
		If ($Files.Count -gt 0)
		{
			ForEach ($File in $Files)
			{
				$FileName = $File.Name
				$FileFullname = $File.FullName
				$FileDateTime = $File.CreationTime
				$FileAgeMinutes = [math]::Round(((Get-Date) - $FileDateTime).TotalMinutes,0)

				#Add values to propertybag for monitoring
				$propertyBag = $omApi.CreatePropertyBag()
				$propertyBag.AddValue("FileName",$FileName)
				$propertyBag.AddValue("FileFullname",$FileFullname)
				$propertyBag.AddValue("FileTime",$FileDateTime)
				$propertyBag.AddValue("FileTimeAttribute",$FileTimeAttribute)
				$propertyBag.AddValue("FileAgeMinutes",$FileAgeMinutes)
				$propertyBag.AddValue("FolderFriendlyName",$FriendlyName)

				$propertyBag
				Write-EventLog -LogName "Application" -Source $EventLogSourceName -EventID "400" -Message "Filename: $FileName `nFilepath: $FileFullname `nFileAge: $FileAgeMinutes minutes`nFileDateTime: $FileDateTime `n`nFolder FriendlyName=$FriendlyName"
			}
		}
	}
}
