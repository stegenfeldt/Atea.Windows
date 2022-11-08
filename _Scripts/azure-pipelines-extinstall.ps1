$vsaeUrl = "https://download.microsoft.com/download/4/6/e/46e6f247-d7fb-4923-84c7-38dffe6bc9be/VisualStudio2022AuthoringConsole_x64.msi"
$vsaeFileName = "VisualStudio2022AuthoringConsole_x64.msi"
## $vsaePackageName = "System Center Visual Studio Authoring Extensions"

Invoke-WebRequest -Uri $vsaeUrl -Method Get -OutFile $vsaeFileName -Verbose
$msiFilePath = (Get-ChildItem -Path ".\$vsaeFileName").FullName

# $vsaeInstalled = Get-CimInstance -Query 'select Name from Win32_Product where Name like "%Visual Studio Autoring%"'
$vsaeInstalled = $false
$installedSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach ($obj in $InstalledSoftware) {
    write-host $obj.GetValue('DisplayName')
    # write-host " - " -NoNewline; write-host $obj.GetValue('DisplayVersion')
    if ($obj.GetValue('DisplayName') -like '*Visual Studio Authoring*') {
        $vsaeInstalled = $true
    }
}
if (!$vsaeInstalled) {
    Write-Output "VSAE Not Installed!"
    Write-Output "Attempting install..."
    Start-Process msiexec.exe -Wait -ArgumentList "/I $msiFilePath /quiet"
}
else {
    Write-Output "VSAE Already installed!"
}

Write-Output "Copying SignKey..."
Copy-Item -Path $env:DOWNLOADSECUREFILE_SECUREFILEPATH -Destination ".\" -Verbose