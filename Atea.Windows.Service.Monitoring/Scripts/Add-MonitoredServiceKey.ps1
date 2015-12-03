param(
	[string] $serviceName,
	[string] $registryPath = "SOFTWARE\Atea\WinSvc"
)

$registryPath = "HKLM:\$registryPath"

if (!(Test-Path $registryPath)) {
	Write-Host ("{0} does not exist, will create key." -f $registryPath)
	New-Item $registryPath -Force
}
New-ItemProperty -Path $registryPath -Name $serviceName -PropertyType String -Force

Write-Host "`nNew service key added`n`nPlease wait for next discovery, `nor restart the Microsoft Monitoring agent to force a discovery."
