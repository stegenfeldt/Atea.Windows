param($computerName)
### Gather vars and modules before script execution
$startVars = (Get-Variable -Scope Global).Name
$startModules = Get-Module
###

[string] $registryPath = "HKLM:\SOFTWARE\CommunityMP\WinEvents"

$knownDebugHosts = "Visual Studio Code Host","Windows PowerShell ISE Host"

if ((Get-Host).Name -in $knownDebugHosts) {
	# script is running in a known debug environment, set debug values
	$sourceId = '{172B8F37-C292-F5DF-B486-30CC30866928}' #dummy value for debugging
	$targetId = '{5EEDD73A-F918-8A67-E63D-53C15FE4E4A3}' #dummy value for debugging
	$isDebugging = $true
}
else {
	$sourceId = '$MPElement$'
	$targetId = '$Target/Id$'
	$isDebugging = false
}

$omApi = New-Object -ComObject "MOM.ScriptAPI"
if ($isDebugging) {
	if ((Get-WmiObject win32_computersystem).Domain -ne "WORKGROUP") {
		$computerName = "$((Get-WmiObject win32_computersystem).DNSHostName).$((Get-WmiObject win32_computersystem).Domain)"
	}
	else {
		$computerName = "$((Get-WmiObject win32_computersystem).DNSHostName)"
	}
}

[int] $eventCount = 0
$discoData = $omApi.CreateDiscoveryData(0, $sourceId, $targetId)

if (Test-Path -Path $registryPath) {
	$subKeys = Get-ChildItem -Path $registryPath
	foreach ($subKey in $subKeys) {
		$discoInstance = $discoData.CreateClassInstance("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']$")
		$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/EventMonitorName$", $subKey.PSChildName)
		$discoInstance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $subKey.PSChildName)
		$discoInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $computerName)
		foreach ($itemProperties in (Get-ItemProperty -Path $subKey.PSPath)) {
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/ErrorEventId$", $itemProperties.ErrorEventId)
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/ErrorEventLog$", $itemProperties.ErrorEventLog)
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/ErrorEventSource$", $itemProperties.ErrorEventSource)
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/HealthyEventId$", $itemProperties.HealthyEventId)
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/HealthyEventLog$", $itemProperties.HealthyEventLog)
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/HealthyEventSource$", $itemProperties.HealthyEventSource)
			$discoInstance.AddProperty("$MPElement[Name='Atea.Windows.Server.Monitoring.MonitoredEvent']/ShortDescription$", $itemProperties.EventShortDescription)
		}
		$discoData.AddInstance($discoInstance)
		$eventCount++
	}
}

# Return discovery data to workflow...
if ($isDebugging) {
	# or console/file, if we're debugging
	$omAPI.AddItem($discoData)
	$omAPI.ReturnItems()
}
else {
	$discoData
}

$omApi.LogScriptEvent("Get-MonitoredEventDiscoveryDS.ps1", 6110, 0, "Ran eventlog discovery, found $($eventCount) events to monitor.`n`nSourceId: $sourceId`nTargetId: $targetId`nPrincipalName: $computerName`nDebug: $isDebugging")

### Unload generated vars and modules
foreach ($module in (Get-Module)) {
	if ($module -notin $startModules) {
		Remove-Module $module
	}
}
foreach ($var in (Get-Variable -Scope Global).Name) {
	if ($var -notin $startVars) {
		Remove-Variable $var -ErrorAction SilentlyContinue
	}
}
###
