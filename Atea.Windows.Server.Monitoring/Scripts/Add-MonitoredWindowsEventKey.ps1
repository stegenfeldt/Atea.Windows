param(
	[Parameter(Mandatory = 'true')][string] $eventMonitorName,
	[Parameter(Mandatory = 'true')][string] $shortDescription,
	[Parameter(Mandatory = 'true')][int] $errorEventId,
	[Parameter(Mandatory = 'true')][int] $errorEventLevel,
	[Parameter(Mandatory = 'true')][string] $errorEventSource,
	[Parameter(Mandatory = 'true')][string] $errorEventLog,
	[Parameter(Mandatory = 'true')][int] $healthyEventId,
	[Parameter(Mandatory = 'true')][int] $healthyEventLevel,
	[Parameter(Mandatory = 'true')][string] $healthyEventSource,
	[Parameter(Mandatory = 'true')][string] $healthyEventLog
)

[string] $registryPath = "HKLM:\SOFTWARE\CommunityMP\WinEvents"
[string] $monitorRegistryPath = "$registryPath\$EventMonitorName"

if (!(Test-Path $monitorRegistryPath)) {
	Write-Output ("{0} does not exist, will create key." -f $monitorRegistryPath)
	New-Item $monitorRegistryPath -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventId" -Value $errorEventId -PropertyType DWord -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventLevel" -Value $errorEventLevel -PropertyType DWord -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventSource"  -Value $errorEventSource -PropertyType String -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventLog"  -Value $errorEventLog -PropertyType String -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventId"  -Value $healthyEventId -PropertyType DWord -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventLevel"  -Value $healthyEventLevel -PropertyType DWord -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventSource"  -Value $healthyEventSource -PropertyType String -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventLog"  -Value $healthyEventLog -PropertyType String -Force
	New-ItemProperty -Path $monitorRegistryPath -Name "EventShortDescription"  -Value $shortDescription -PropertyType String -Force

	Write-Output "`nNew service key added`n`nPlease wait for next discovery, `nor restart the Microsoft Monitoring agent to force a discovery."
} else {
	Write-Output "`nKey already exists!`n`nLeaving as is."
}
