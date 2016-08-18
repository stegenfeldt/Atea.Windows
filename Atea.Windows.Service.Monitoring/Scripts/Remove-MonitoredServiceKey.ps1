param(
	[string] $serviceName,
	[string] $registryPath = "SOFTWARE\Atea\WinSvc"
)

$registryPath = "HKLM:\$registryPath"

if (!(Test-Path $registryPath)) {
	Write-Host ("{0} does not exist, will skip task." -f $registryPath)
	Exit
} else {
	$regKey = Get-Item -Path $registryPath
	if (($regKey.GetValue($serviceName)) -ne $null) {
		Write-Host ("Deleting monitoring configuration for service '{0}'" -f $serviceName)
		Remove-ItemProperty -Path $registryPath -Name $serviceName -Force
		Write-Host "Done!"
		if ($regKey.GetValueNames().Count -lt 1) {
			Write-Host "No Service values left, deleting key"
			Remove-Item -Path $registryPath
			Write-Host "Done!"
		}
	} else {
		Write-Host ("Configuration for service '{0}' was not found." -f $serviceName)
	}
}
