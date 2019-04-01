$vsaeUrl = "https://download.microsoft.com/download/4/4/6/446B60D0-4409-4F94-9433-D83B3746A792/VisualStudioAuthoringConsole_x64.msi"
$vsaeFileName = "VisualStudioAuthoringConsole_x64.msi"
$vsaePackageName = "System Center Visual Studio Authoring Extensions"

Invoke-WebRequest -Uri $vsaeUrl -Method Get -OutFile $vsaeFileName -Verbose

$vsaeInstalled = Get-Package -IncludeWindowsInstaller -Name $vsaePackageName -Verbose
if (!$vsaeInstalled) {
    Write-Host "VSAE Not Installed!"
    Write-Host "Attempting install..."
    Install-Package -InputObject (Find-Package -Name ".\$vsaeFileName") -Verbose
} else {
    Write-Host "VSAE Already installed!"
}

Write-Host "Copying SignKey..."
Copy-Item -Path $env:DOWNLOADSECUREFILE_SECUREFILEPATH -Destination ".\" -Verbose