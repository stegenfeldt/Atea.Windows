﻿[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $UNCPath = '\\server\share'
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
        if ($null -ne $drive.Used -and $drive.Used -ne 0) {
            $usedGB = [math]::Round($($drive.Used / 1GB), 2) -as [double]
        }
        if ($null -ne $drive.Free) {
            $freeGB = [math]::Round($($drive.Free / 1GB), 2) -as [double]
        }
        if ($null -ne $usedGB -and $null -ne $freeGB) {
            $totalGB = [math]::Round($usedGB + $freeGB, 2) -as [double]
        }
        if ($null -ne $totalGB -and $totalGB -ne 0) {
            $usedPct = [math]::Round(($usedGB / $totalGB) * 100, 2) -as [double]
            $freePct = [math]::Round(($freeGB / $totalGB) * 100, 2) -as [double]
        }
        if ($null -eq $usedPct) { $usedPct = -1 -as [double] }
        if ($null -eq $usedGB) { $usedGB = -1 -as [double] }
        if ($null -eq $freePct) { $freePct = -1 -as [double] }
        if ($null -eq $freeGB) { $freeGB = -1 -as [double] }
        if ($null -eq $totalGB) { $totalGB = -1 -as [double] }
        $driveData = @{
            'ShareName' = $ShareName
            'Path'      = $UNCPath
            'TotalGB'   = $totalGB
            'UsedGB'    = $usedGB
            'UsedPct'   = $usedPct
            'FreeGB'    = $freeGB
            'FreePct'   = $freePct
            'RunAs'     = $fsUser
        }
    } else {
        $driveData = @{
            'ShareName' = $ShareName
            'RunAs'     = $fsUser
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

    if ($null -ne $DriveInfo) {
        if ($UsePercent = $true) {
            if ($DriveInfo.FreePct -le $FreeSpaceErrorThreshold -and $DriveInfo.FreePct -ne -1 -and $null -ne $DriveInfo.FreePct) {
                $status = 'ERROR'
            } elseif ($DriveInfo.FreePct -le $FreeSpaceWarningThreshold -and $DriveInfo.FreePct -ne -1 -and $null -ne $DriveInfo.FreePct) {
                $status = 'WARNING'
            } elseif ($DriveInfo.FreePct -gt $FreeSpaceWarningThreshold -and $DriveInfo.FreePct -ne -1 -and $null -ne $DriveInfo.FreePct) {
                $status = 'OK'
            } elseif ($DriveInfo.FreePct -eq -1 -or $null -eq $DriveInfo.FreePct) {
                $status = 'CONNECT_FAILED'
            } else {
                $status = 'UNDECIDED'
            }
        } elseif ($UsePercent = $false) {
            if ($DriveInfo.FreeGB -le $FreeSpaceErrorThreshold -and $DriveInfo.FreeGB -ne -1 -and $null -ne $DriveInfo.FreeGB) {
                $status = 'ERROR'
            } elseif ($DriveInfo.FreeGB -le $FreeSpaceWarningThreshold -and $DriveInfo.FreeGB -ne -1 -and $null -ne $DriveInfo.FreeGB) {
                $status = 'WARNING'
            } elseif ($DriveInfo.FreeGB -gt $FreeSpaceWarningThreshold -and $DriveInfo.FreeGB -ne -1 -and $null -ne $DriveInfo.FreeGB) {
                $status = 'OK'
            } elseif ($DriveInfo.FreeGB -eq -1 -or $null -eq $DriveInfo.FreeGB) {
                $status = 'CONNECT_FAILED'
            } else {
                $status = 'UNDECIDED'
            }
        } else {
            $status = 'WEIRD_INPUT'
        }
    } else {
        $status = 'DRIVEINFO_EMPTY'
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
        , [Parameter()]
        [string]
        $UNCPath
    )

    $omApi = New-Object -ComObject 'MOM.ScriptAPI'
    $pb = $omApi.CreatePropertyBag()

    if (($DriveInfo.Status -ne 'CONNECT_FAILED') -and ($DriveInfo.Status -ne 'DRIVEINFO_EMPTY') -and ($null -ne $DriveInfo)) {
        $logMessage = "`n$($DriveInfo.ShareName)`nRunAs: $($DriveInfo.RunAs)`nDriveInfo:`n"
        $logMessage += ($DriveInfo | ConvertTo-Json)
    } else {
        $logMessage = "`nProbing $UNCPath failed"
    }
    $omApi.LogScriptEvent('FileShareSpace.ps1', 242, 0, $logMessage)
    $DriveInfo.Remove('RunAs') | Out-Null

    foreach ($key in $DriveInfo.Keys) {
        $pb.AddValue($key, $DriveInfo[$key])
    }

    if ($host.Name -in @('Visual Studio Code Host', 'Windows PowerShell ISE Host')) {
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
Send-FSPropertyBag -DriveInfo $driveInfo -UNCPath $UNCPath
