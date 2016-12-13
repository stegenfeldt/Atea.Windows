<#
.Synopsis
Downloads, installs and optionally imports the latest builds of the Atea.Windows MP package.

.Parameter Version
Select which build to install. 
"Stable" will download from the master branch (tested and true)
"Latest" will download from the develop branch (latest build)

.Parameter ImportMP
Will attempt to import installed MPs into SCOM. 
This will likely fail if you move from "Latest" to "Stable" version as the prior tend to have a higher version number.

.Parameter OMMSComputerName
Defaults to the local computer. Set this to connect to a different SCOM Management Server for the import.

.Example
# Download, install and import the latest build on the local management server
.\Install-AteaWindowsMP.ps1 -Version Latest -ImportMP

.Example
# Download and install latest version locally, import to a different SCOM Management Server
.\Install-AteaWindowsMP.ps1 -Version Latest -ImportMP -OMMSComputerName <omms1.domain.fqdn>

.Example
# Download and install stable version locally. Don't import.
.\Install-AteaWindowsMP.ps1 -Version Stable
#>
[CmdletBinding()]
param(
    [ValidateSet("Stable","Latest")][string] $Version,
    [switch] $ImportMP,
    [string] $OMMSComputerName = "."
)

[string] $developURL = "https://github.com/stegenfeldt/Atea.Windows/raw/develop/Released/Atea.Windows.Installer.msi"
[string] $masterURL = "https://github.com/stegenfeldt/Atea.Windows/raw/master/Released/Atea.Windows.Installer.msi"

[string] $installDir = "$(${env:ProgramFiles(x86)})\System Center Management Packs\Atea.Windows\"
[string] $msiFilePath = "$($env:TEMP)\Atea.Windows.Installer.msi"

[string] $packageName = "Atea Windows - MP Package"

if ($Version = "Stable") {
   Invoke-WebRequest -Uri $masterURL -OutFile $msiFilePath
   if (Get-Package -Name $packageName -ErrorAction SilentlyContinue) {Uninstall-Package -Name $packageName -Force}
   Install-Package -Name $msiFilePath -Force
} elseif ($Version = "Latest") {
   Invoke-WebRequest -Uri $developURL -OutFile $msiFilePath
   if (Get-Package -Name $packageName -ErrorAction SilentlyContinue) {Uninstall-Package -Name $packageName -Force}
   Install-Package -Name $msiFilePath -Force
}

if ($ImportMP -and (($Version = "Stable") -or ($Version = "Latest"))) {
    Import-Module -Name OperationsManager
    New-SCOMManagementGroupConnection -ComputerName $OMMSComputerName

    $mps = Get-SCOMManagementPack -ManagementPackFile (Get-ChildItem -Path $installDir -Filter "*.mp").FullName
    Import-SCOMManagementPack -ManagementPack $mps -Verbose
}
