### Gather vars and modules before script execution
$startVars = (Get-Variable -Scope Global).Name; $startModules = Get-Module
###

[string] $registryPath = "HKLM:\SOFTWARE\CommunityMP\WinEvents"
$omApi = New-Object -ComObject "MOM.ScriptAPI"
if ((Get-WmiObject win32_computersystem).Domain -ne "WORKGROUP"){
    $computerName = "$((Get-WmiObject win32_computersystem).DNSHostName).$((Get-WmiObject win32_computersystem).Domain)"
} else {
    $computerName = "$((Get-WmiObject win32_computersystem).DNSHostName)"
}

$discoData = $omApi.CreateDiscoveryData(0,'$MPElement$','$Target/Id$')

if (Test-Path -Path $registryPath) {
    $subKeys = Get-ChildItem -Path $registryPath
    foreach ($subKey in $subKeys) {
        $discoInstance = $discoData.CreateClassInstance('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]$')
        $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/EventMonitorName$',$subKey.PSChildName)
        $discoInstance.AddProperty('$MPElement[Name="System!System.Entity"]/DisplayName$',$subKey.PSChildName)
        $discoInstance.AddProperty('$MPElement[Name="Windows!Microsoft.Windows.Computer"]/PrincipalName$',$computerName)
        foreach ($itemProperties in (Get-ItemProperty -Path $subKey.PSPath)) {
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/ErrorEventId$',$itemProperties.ErrorEventId)
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/ErrorEventLog$',$itemProperties.ErrorEventLog)
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/ErrorEventSource$',$itemProperties.ErrorEventSource)
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/HealthyEventId$',$itemProperties.HealthyEventId)
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/HealthyEventLog$',$itemProperties.HealthyEventLog)
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/HealthyEventSource$',$itemProperties.HealthyEventSource)
            $discoInstance.AddProperty('$MPElement[Name="Atea.Windows.Server.Monitoring.MonitoredEvent"]/ShortDescription$',$itemProperties.EventShortDescription)
        }
        $discoData.AddInstance($discoInstance)
    }
}
$discoData

### Unload generated vars and modules
foreach ($module in (Get-Module)) {
    if ($module -notin $startModules) {
        Remove-Module $module
    }
}
foreach ($var in (Get-Variable -Scope Global).Name) {
    if ($var -notin $startVars) {
        Remove-Variable $var
    }
}
###