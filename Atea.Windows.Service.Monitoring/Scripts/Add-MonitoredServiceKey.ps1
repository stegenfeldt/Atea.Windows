param(
	[string] $serviceName,
	[string] $registryPath = "SOFTWARE\Atea\WinSvc"
)

$registryPath = "HKLM:\$registryPath"

New-Item $registryPath -Force
New-ItemProperty -Path $registryPath -Name $serviceName -PropertyType String -Force
