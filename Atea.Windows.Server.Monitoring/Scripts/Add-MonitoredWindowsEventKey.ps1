param(
	[string] $eventMonitorName,
	[string] $eventShortDescription,
	[int] $errorEventId,
	[int] $errorEventLevel,
	[string] $errorEventSource,
	[string] $errorEventLog,
	[int] $healthyEventId,
	[int] $healthyEventLevel,
	[string] $healthyEventSource,
	[string] $healthyEventLog
)

[string] $registryPath = "SOFTWARE\CommunityMP\WinEvents"
[string] $registryPath = "HKLM:\$registryPath"
[string] $monitorRegistryPath = "$registryPath\$EventMonitorName"

if (!(Test-Path $monitorRegistryPath)) {
	Write-Output ("{0} does not exist, will create key." -f $monitorRegistryPath)
	New-Item $monitorRegistryPath -Force
}
New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventId" -Value $errorEventId -PropertyType String -Force
New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventId" -Value $errorEventLevel -PropertyType int -Force
New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventSource"  -Value $errorEventSource -PropertyType String -Force
New-ItemProperty -Path $monitorRegistryPath -Name "ErrorEventLog"  -Value $errorEventLog -PropertyType String -Force
New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventId"  -Value $healthyEventId -PropertyType int -Force
New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventId"  -Value $healthyEventLevel -PropertyType int -Force
New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventSource"  -Value $healthyEventSource -PropertyType String -Force
New-ItemProperty -Path $monitorRegistryPath -Name "HealthyEventLog"  -Value $healthyEventLog -PropertyType String -Force
New-ItemProperty -Path $monitorRegistryPath -Name "EventShortDescription"  -Value $eventShortDescription -PropertyType String -Force

Write-Output "`nNew service key added`n`nPlease wait for next discovery, `nor restart the Microsoft Monitoring agent to force a discovery."