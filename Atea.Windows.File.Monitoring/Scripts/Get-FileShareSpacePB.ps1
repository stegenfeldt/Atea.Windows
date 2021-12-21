[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $UNCPath = '\\tgds01\web'
    , [Parameter()]
    [string]
    $ShareName = 'A ShareName'
    , [Parameter()]
    [double]
    $FreeSpaceErrorThreshold = 3
    , [Parameter()]
    [double]
    $FreeSpaceWarningThreshold = 10
    , [Parameter()]
    [string]
    $UsePercent = 'true'
)


function Get-FileShareFreeSpace {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $UNCPath
        , [Parameter()]
        [string]
        $ShareName
    )

    $fsUser = '$RunAs[Name="Atea.Windows.File.FileShareMonitoring.RunasProfile"]/UserName$'
    $fsPass = '$RunAs[Name="Atea.Windows.File.FileShareMonitoring.RunasProfile"]/Password$'

    if ($fsUser -match '^.RunAs\[.*' -or $fsUser.Length -le 0 -or $fsUser -eq 'nt authority\system') {
        $credentials = $null
        $fsPass = $null
        $fsUser = $(whoami)

    } else {
        $credentials = [PSCredential]::new($fsUser, (ConvertTo-SecureString -String $fsPass -AsPlainText -Force))
    }

    $FolderPath = $UNCPath

    # Try to find a vacant drive-letter to use
    $charCodes = 67..90
    $drives = (Get-PSDrive).Name -as [string[]]
    foreach ($charCode in $charCodes) {
        $driveLetter = [char]$charCode
        if ($driveLetter -notin $drives) {
            $driveName = $driveLetter -as [string]
            break
        }
    }

    # Add a PSDrive with credentials (if needed). 
    # Needs to be -Persist, otherwise we won't get usage information
    if ($null -ne $credentials) {
        $drive = New-PSDrive -Name $driveName -PSProvider 'FileSystem' -Root $FolderPath -Credential $credentials -Persist
    } else {
        $drive = New-PSDrive -Name $driveName -PSProvider 'FileSystem' -Root $FolderPath -Persist
    }


    if ($null -ne $drive) {
        $usedGB = [math]::Round($($drive.Used / 1GB), 2) -as [double]
        $freeGB = [math]::Round($($drive.Free / 1GB), 2) -as [double]
        $totalGB = [math]::Round($usedGB + $freeGB, 2) -as [double]
        $usedPct = [math]::Round(($usedGB / $totalGB) * 100, 2) -as [double]
        $freePct = [math]::Round(($freeGB / $totalGB) * 100, 2) -as [double]
        $driveData = @{
            'Path'    = $UNCPath
            'TotalGB' = $totalGB
            'UsedGB'  = $usedGB
            'UsedPct' = $usedPct
            'FreeGB'  = $freeGB
            'FreePct' = $freePct
        }
    }

    Remove-PSDrive -Name $driveName

    return $driveData
}

function Set-FileShareStatus {
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable]
        $DriveInfo
        , [Parameter()]
        [double]
        $FreeSpaceErrorThreshold = 3
        , [Parameter()]
        [double]
        $FreeSpaceWarningThreshold = 10
        , [Parameter()]
        [bool]
        $UsePercent = $true
    )

    if ($UsePercent = $true) {
        if ($DriveInfo.FreePct -le $FreeSpaceErrorThreshold) {
            $status = 'ERROR'
        } elseif ($DriveInfo.FreePct -le $FreeSpaceWarningThreshold) {
            $status = 'WARNING'
        } elseif ($DriveInfo.FreePct -gt $FreeSpaceWarningThreshold) {
            $status = 'OK'
        } else {
            $status = 'UNDECIDED'
        }
    } elseif ($UsePercent = $false) {
        if ($DriveInfo.FreeGB -le $FreeSpaceErrorThreshold) {
            $status = 'ERROR'
        } elseif ($DriveInfo.FreeGB -le $FreeSpaceWarningThreshold) {
            $status = 'WARNING'
        } elseif ($DriveInfo.FreeGB -gt $FreeSpaceWarningThreshold) {
            $status = 'OK'
        } else {
            $status = 'UNDECIDED'
        }
    } else {
        $status = 'WEIRD_INPUT'
    }

    $DriveInfo['Status'] = $status -as [string]
    return $DriveInfo
}

function Send-FSPropertyBag {
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable]
        $DriveInfo
    )

    $omApi = New-Object -ComObject 'MOM.ScriptAPI'
    $pb = $omApi.CreatePropertyBag()

    foreach ($key in $DriveInfo.Keys) {
        $pb.AddValue($key, $DriveInfo[$key])
    }

    if ($host.Name -in @('Visual Studio Code Host')) {
        $omApi.AddItem($pb)
        $omApi.ReturnItems()
    } else {
        $pb
    }
}

if ($UsePercent -eq 'false') {
    $usePct = $false
} else {
    $usePct = $true
}

$driveInfo = Get-FileShareFreeSpace -UNCPath $UNCPath -ShareName $ShareName
$driveInfo = Set-FileShareStatus -DriveInfo $driveInfo -FreeSpaceErrorThreshold $FreeSpaceErrorThreshold -FreeSpaceWarningThreshold $FreeSpaceWarningThreshold -UsePercent $usePct
Send-FSPropertyBag -DriveInfo $driveInfo
