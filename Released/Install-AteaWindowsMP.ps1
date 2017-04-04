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

$Error.Clear()

[string[]] $mpFiles = @(
    "Atea.Windows.Library.mp",
    "Atea.Windows.Server.Monitoring.mp",
    "Atea.Windows.Service.Monitoring.mp",
    "Atea.Windows.File.Monitoring.mp"
)

[string] $developURL = "https://github.com/stegenfeldt/Atea.Windows/raw/develop/Released/"
[string] $masterURL = "https://github.com/stegenfeldt/Atea.Windows/raw/master/Released/"
[string] $installDir = "$(${env:ProgramFiles(x86)})\System Center Management Packs\Atea.Windows\"
$startLocation = Get-Location

if ((Test-Path $installDir) -eq $false) {
    if (!(New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue)) {
        Write-Host "Unable to create directory." -ForegroundColor Red
        Write-Host "Using current directory instead."
        $installDir = "$($Script:PWD.Path)\"
    }
}

foreach ($mpFile in $mpFiles) {
    switch ($Version) {
        "Stable" {
            $mpFilePath = $installDir + $mpFile
            $mpFileURL = $masterURL + $mpFile
        }
        "Latest" {
            $mpFilePath = $installDir + $mpFile
            $mpFileURL = $masterURL + $mpFile
        }
        default {
            Write-Host "No -Version selected, using Stable branch."
            $mpFilePath = $installDir + $mpFile
            $mpFileURL = $masterURL + $mpFile
        }
    }
    Invoke-WebRequest -Uri $mpFileURL -OutFile $mpFilePath
}

if ($ImportMP -and (($Version = "Stable") -or ($Version = "Latest"))) {
    Import-Module -Name OperationsManager
    New-SCOMManagementGroupConnection -ComputerName $OMMSComputerName

    $mps = Get-SCOMManagementPack -ManagementPackFile (Get-ChildItem -Path $installDir -Filter "*.mp").FullName
    Import-SCOMManagementPack -ManagementPack $mps -Verbose
}
