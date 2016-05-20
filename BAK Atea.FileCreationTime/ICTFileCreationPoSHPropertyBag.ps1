# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

$RegistryPath = "hklm:\Software\ICT\FileCreation\"
$EventLogSourceName = "ICT FCT Monitor"
$SubKeys = Get-ChildItem $RegistryPath
$OpsmgrAPI = New-Object -ComObject "MOM.ScriptAPI"
if (![System.Diagnostics.EventLog]::SourceExists($EventLogSourceName))
{
	New-EventLog -Source $EventLogSourceName -logname "Application"
}
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

		switch ($Operator)
		{
			"<" {$Operator = "-lt"}
			"<=" {$Operator = "-le"}
			">" {$Operator = "-gt"}
			">=" {$Operator = "-ge"}
			default {$Operator = "-lt"}
		}
		
		if ($Recursive.Trim() -eq "false")
		{	
			$Recursive = ""
		} else {
			$Recursive = "-Recurse "
		}
		
		$command = "Get-ChildItem $FolderPath $Recursive| where {(`$_.Name -like '$FilePattern') -and ((((Get-Date) - `$_.CreationTime).TotalMinutes) $Operator $AgeInMinutes)}"
		$ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($command)
		#$command
		$Files = @(Invoke-Command -ScriptBlock $ScriptBlock)
		If ($Files.Count -gt 0)
		{
			ForEach ($File in $Files)
			{
				$FileName = $File.Name
				$FileFullname = $File.FullName
				$FileCreationTime = $File.CreationTime
				$FileAgeMinutes = [math]::Round(((Get-Date) - $FileCreationTime).TotalMinutes,0)
				
				#Add values to propertybag for monitoring
				$propertyBag = $OpsmgrAPI.CreatePropertyBag()
				$propertyBag.AddValue("FileName",$FileName)
				$propertyBag.AddValue("FileFullname",$FileFullname)
				$propertyBag.AddValue("FileCreationTime",$FileCreationTime)
				$propertyBag.AddValue("FileAgeMinutes",$FileAgeMinutes)
				$propertyBag.AddValue("FolderFriendlyName",$FriendlyName)
				
				$propertyBag
				Write-EventLog -LogName "Application" -Source $EventLogSourceName -EventID "400" -Message "Filename: $FileName `nFilepath: $FileFullname `nFileAge: $FileAgeMinutes minutes`nFileCreationTime: $FileCreationTime `n`nFolder FriendlyName=$FriendlyName"
			}
		}
	}
}
