# Begin with getting all the subkeys
# http://technet.microsoft.com/en-us/library/ff730937.aspx
# http://powershell.com/cs/blogs/tips/archive/2009/12/03/dynamically-create-script-blocks.aspx
# http://technet.microsoft.com/sv-se/library/ee176852(en-us).aspx

[CmdletBinding()]
Param(
	[ValidateSet("CreationTime","LastWriteTime","LastAccessTime")]
	[Parameter(Mandatory=$true)]
	[string] $FileAgeAttribute
)

$RegistryPath = "hklm:\Software\Atea\FileAgeMonitoring\"
$EventLogSourceName = "Atea FileAge Monitor"
$omApi = New-Object -ComObject "MOM.ScriptAPI"
if (![System.Diagnostics.EventLog]::SourceExists($EventLogSourceName)) {
	New-EventLog -Source $EventLogSourceName -logname "Application"
}

if (Test-Path -Path $RegistryPath) {
	# Yes, we can read from $RegistryPath
	$SubKeys = Get-ChildItem $RegistryPath

    if ($SubKeys -ne $null) {
        # Found configuration keys, processing folders
	    ForEach ($SubKey in $SubKeys) {
		    $FriendlyName = ($SubKey.Name.Substring($SubKey.Name.LastIndexOfAny("\")+1))
		    $FolderPath = $SubKey.GetValue("FolderPath")
		    $Recursive = $SubKey.GetValue("Recursive")
		    $FilePattern = $SubKey.GetValue("FilePattern")
		    $AgeInMinutes = $SubKey.GetValue("AgeInMinutes")
		    $Operator = $SubKey.GetValue("Operator")
		    # $AgeAttribute = $SubKey.GetValue("FileAgeAttribute") # Don't know if I really need this

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

                $summaryMessage = "File Age Monitor on '$FriendlyName', looking for '$FilePattern' where $FileAgeAttribute $Operator $AgeInMinutes in $FolderPath"

			    if ($Recursive.Trim() -eq "false")
			    {
				    $Recursive = ""
					$summaryMessage += "`n`n"
			    } else {
				    $Recursive = "-Recurse "
                    $summaryMessage += ", Recursive`n`n"
			    }

			    $command = "Get-ChildItem $FolderPath $Recursive -Attributes !Directory | where {(`$_.Name -like '$FilePattern') -and ((((Get-Date) - `$_.$FileAgeAttribute).TotalMinutes) $Operator $AgeInMinutes)}"
			    $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($command)
			    $Files = @(Invoke-Command -ScriptBlock $ScriptBlock)
			    if ($Files.Count -gt 0) {
                    $summaryMessage += "Found $($Files.Count) matching files:`n"
                    #$summaryMessage += "File Name`tFile Path`t`tAge (minutes)`tTimeStamp`n"
				    ForEach ($File in $Files)
				    {
					    $FileName = $File.Name
					    $FileFullname = $File.FullName
                        switch ($FileAgeAttribute) {
                            "CreationTime" {$FileDateTime = $File.CreationTime}
                            "LastWriteTime" {$FileDateTime = $File.LastWriteTime}
                            "LastAccessTime" {$FileDateTime = $File.LastAccessTime}
                        }
					    $FileAgeMinutes = [math]::Round(((Get-Date) - $FileDateTime).TotalMinutes,0)
                        $summaryMessage += "$FileName`n`tMinutes since $($FileAgeAttribute): $FileAgeMinutes`n`tTimestamp: $($FileDateTime -f "o")`n`tFile Path: $FileFullName`n`n"
				    }
                    #We have old files, and a message. Build the property bag
                    $propertyBag = $omApi.CreatePropertyBag()
                    $propertyBag.AddValue("FolderFriendlyName",$FriendlyName)
                    $propertyBag.AddValue("Summary",$summaryMessage)
                    $propertyBag.AddValue("FileCount",$Files.Count)

                    $propertyBag
                    Write-EventLog -LogName "Application" -Source $EventLogSourceName -EventID "400" -Message $summaryMessage -EntryType Information -Category 0

			    } else {
                    # No matching files found
                    $propertyBag = $omApi.CreatePropertyBag()
                    $propertyBag.AddValue("FolderFriendlyName",$FriendlyName)
                    $propertyBag.AddValue("Summary",$summaryMessage)
                    $propertyBag.AddValue("FileCount",$Files.Count)

                    $propertyBag
                }
		    }
	    }
    } else {
        # Registry does not contain any configured File Age Monitoring
        # or we don't have access to read the keys
        $propertyBag = $omApi.CreatePropertyBag()
	    $propertyBag
    }
} else {
	#Nope, not able to read from the registry path
	Write-EventLog -LogName "Application" -Source $EventLogSourceName -EventID "404" -Message "$RegistryPath is not found on this system, unable to read file age monitoring configuration.`n`nReturning an empty property bag." -EntryType Error -Category 0
	$propertyBag = $omApi.CreatePropertyBag()
	$propertyBag
}