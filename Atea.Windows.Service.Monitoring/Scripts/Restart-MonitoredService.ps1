<#
	.Synopsis
	Restarts a windows service, with settings for wait-time for verification and repeated retries.

	.Example
	Restart-MonitoredService.ps1 -ServiceName "spooler"

	.Example
	Restart-MonitoredService.ps1 -ServiceName "spooler" -Delay 30

	.Example
	Restart-MonitoredService.ps1 -ServiceName "spooler" -Delay 30 -MaxRepeatCount 3 -RepeatIntervalSeconds 10
#>
param(
	# Name of service (not display name)
	[Parameter(Mandatory=$true)][string] $ServiceName,
	[int] $Delay = 0,
	[int] $MaxRepeatCount = 0,
	[int] $RepeatIntervalSeconds = 30,
	[string] $omAlertId,
	[switch] $Debuglogging
)

function Write-SCOMEvent
{
	param(
		[string] $LogMessage,
		[ValidateSet(0,1,2)][int] $LogSeverity,
		[ValidateRange(0,20000)][int] $LogEventId
	)

	[string] $ScriptName = split-path $MyInvocation.PSCommandPath -Leaf

	$omApi = New-Object -ComObject "MOM.ScriptAPI"
	$omApi.LogScriptEvent($ScriptName,$LogEventId,$LogSeverity,$LogMessage)
	$omApi = $null
}

function Test-ServiceExist ($ServiceName) {
	if (!(Get-Service -Name $ServiceName)) {
		return $false
	} else {
		return $true
	}
}

function Start-ServiceAndWait ([string] $ServiceName, [int] $WaitSeconds) {
	Write-Host "Attempting to restart $ServiceName"
	Write-SCOMEvent "Attempting to restart $ServiceName", 0,10101
	Restart-Service -Name $ServiceName
	Write-Host "Waiting for $WaitSeconds seconds to verify service state..."
	Write-SCOMEvent "Waiting for $WaitSeconds seconds to verify `"$ServiceName`" state...", 0,10101
	Start-Sleep -Seconds $WaitSeconds
	$serviceObject = Get-Service -Name $ServiceName
	return [string] $serviceObject.Status
}

function Restart-ServiceWithRepeats ([int] $MaxRepeatCount, [int] $RepeatIntervalSeconds) {
	if ($MaxRepeatCount -gt 0) {
		for ($i = 1; $i -le $MaxRepeatCount; $i++) {
			Write-Host "Trying again ($i of $MaxRepeatCount)"
			Write-SCOMEvent "Trying to restart `'$ServiceName`' again ($i of $MaxRepeatCount)",0,10101
			[string] $serviceStatus = Start-ServiceAndWait -ServiceName $ServiceName -WaitSeconds $Delay

			if ($serviceStatus -ne "Running") {
				if ($i -eq $MaxRepeatCount) {
					Write-Host "Service is still not running. This was the last attempt!" -ForegroundColor DarkRed
					Write-SCOMEvent "`'$ServiceName`' is still not running. This was the last attempt!", 0, 10101
					Write-SCOMEvent "Failed to recover service `'$ServiceName`' after $MaxRepeatCount attempts!", 1, 10100
				} else {
					Write-Host "Service is still not running, waiting $RepeatIntervalSeconds before next try..."
					Write-SCOMEvent "`'$ServiceName`' is still not running, waiting $RepeatIntervalSeconds before next try...",0,10101
				}
				Start-Sleep -Seconds $RepeatIntervalSeconds
			} else {
				# Service has started and has been running for $Delay seconds
				$i = $MaxRepeatCount
				Write-Host "`'$ServiceName`' is now running!" -ForegroundColor Green
				Write-SCOMEvent "`'$ServiceName`' is now running!", 0, 10101
			}
		}
	}
}

function Main () {
	if ((Test-ServiceExist -ServiceName $ServiceName) -eq $false) {
		Write-Host "$ServiceName - No such service exists on the system."
	} else {
		[string] $serviceStatus = Start-ServiceAndWait $ServiceName -WaitSeconds $Delay

		if ($serviceStatus -ne "Running") {
			Write-Host "Service is not running..." -ForegroundColor DarkRed
			Restart-ServiceWithRepeats -MaxRepeatCount $MaxRepeatCount -RepeatIntervalSeconds $RepeatIntervalSeconds
		} else {
			Write-Host "Service is Running!" -ForegroundColor Green
		}
	}
}

Main