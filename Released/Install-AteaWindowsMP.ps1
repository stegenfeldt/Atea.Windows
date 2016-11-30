param(
    [switch] $Stable,
    [switch] $Latest,
    [switch] $ImportMP,
    [string] $OMMSComputerName = "."
)

[string] $developURL = "https://github.com/stegenfeldt/Atea.Windows/raw/develop/Released/Atea.Windows.Installer.msi"
[string] $masterURL = "https://github.com/stegenfeldt/Atea.Windows/raw/master/Released/Atea.Windows.Installer.msi"

[string] $installDir = "$(${env:ProgramFiles(x86)})\System Center Management Packs\Atea.Windows\"
[string] $msiFilePath = "$($env:TEMP)\Atea.Windows.Installer.msi"

if ($Stable) {
   Invoke-WebRequest -Uri $masterURL -OutFile $msiFilePath
   Install-Package -Name $msiFilePath -Force
} elseif ($Latest) {
   Invoke-WebRequest -Uri $developURL -OutFile $msiFilePath
   Install-Package -Name $msiFilePath -Force
}

if ($ImportMP -and ($Stable -or $Latest)) {
    Import-Module -Name OperationsManager
    New-SCOMManagementGroupConnection -ComputerName $OMMSComputerName

    $mps = Get-SCOMManagementPack -ManagementPackFile (Get-ChildItem -Path $installDir -Filter "*.mp").FullName
    Import-SCOMManagementPack -ManagementPack $mps -Verbose
}
