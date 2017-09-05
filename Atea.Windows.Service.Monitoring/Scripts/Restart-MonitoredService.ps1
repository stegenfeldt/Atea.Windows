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
	[int] $RepeatIntervalSeconds = 10,
	[string] $omAlertId,
	[switch] $Debuglogging
)

function Get-TimeStamp
{
	[string] $timeStamp = Get-Date -Format o
	Return $timeStamp
}

function Write-SCOMEvent
{
	param(
		[Parameter(Mandatory=$true)][string] $LogMessage,
		[ValidateSet(0,1,2)][int] $LogSeverity,
		[ValidateRange(0,20000)][int] $LogEventId
	)

	[string] $ScriptName = "Restart-MonitoredService.ps1"

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

function Start-ServiceAndWait ([string] $ServiceName, [int] $WaitSeconds)
{
	Write-SCOMTaskLog -Message "Attempting to restart $ServiceName" -ElapsedSeconds $timer.Elapsed.TotalSeconds
	Write-SCOMEvent -LogMessage "Attempting to restart $ServiceName" -LogSeverity 0 -LogEventId 10101
	Restart-Service -Name $ServiceName
	Write-SCOMTaskLog -Message "Waiting for $WaitSeconds seconds to verify service state..." -ElapsedSeconds $timer.Elapsed.TotalSeconds
	Write-SCOMEvent -LogMessage "Waiting for $WaitSeconds seconds to verify `"$ServiceName`" state..." -LogSeverity 0 -LogEventId 10101
	Start-Sleep -Seconds $WaitSeconds
	$serviceObject = Get-Service -Name $ServiceName
	return [string] $serviceObject.Status
}

function Restart-ServiceWithRepeats ([int] $MaxRepeatCount, [int] $RepeatIntervalSeconds) {
	if ($MaxRepeatCount -gt 0) {
		for ($i = 1; $i -le $MaxRepeatCount; $i++) {
			Write-SCOMTaskLog -Message "Trying again ($i of $MaxRepeatCount)" -ElapsedSeconds $timer.Elapsed.TotalSeconds
			Write-SCOMEvent -LogMessage "Trying to restart `'$ServiceName`' again ($i of $MaxRepeatCount)" -LogSeverity 0 -LogEventId 10101
			[string] $serviceStatus = Start-ServiceAndWait -ServiceName $ServiceName -WaitSeconds $Delay

			if ($serviceStatus -ne "Running") {
				if ($i -eq $MaxRepeatCount) {
					Write-SCOMTaskLog -Message "$ServiceName is still not running. This was the last attempt!" -ElapsedSeconds $timer.Elapsed.TotalSeconds
					Write-SCOMEvent -LogMessage "`'$ServiceName`' is still not running. This was the last attempt!" -LogSeverity 0 -LogEventId 10101
					Write-SCOMEvent -LogMessage "Failed to recover service `'$ServiceName`' after $MaxRepeatCount attempts!" -LogSeverity 1 -LogEventId 10100
				} else {
					Write-SCOMTaskLog -Message "$ServiceName is still not running, waiting $RepeatIntervalSeconds before next try..." -ElapsedSeconds $timer.Elapsed.TotalSeconds
					Write-SCOMEvent -LogMessage "`'$ServiceName`' is still not running, waiting $RepeatIntervalSeconds before next try..." -LogSeverity 0 -LogEventId 10101
				}
				Start-Sleep -Seconds $RepeatIntervalSeconds
			} else {
				# Service has started and has been running for $Delay seconds
				$i = $MaxRepeatCount
				Write-SCOMTaskLog -Message "$ServiceName is now running..." -ElapsedSeconds $timer.Elapsed.TotalSeconds
				Write-SCOMEvent -LogMessage "`'$ServiceName`' is now running!" -LogSeverity 0 -LogEventId 10101
			}
		}
	}
}

function Write-SCOMTaskLog ([string]$Message, [single]$ElapsedSeconds = 0)
{
     Write-Host ("{0}`t{1:N2}`t{2}" -f (Get-TimeStamp),$ElapsedSeconds,$Message)
}

function Main () {
	Write-SCOMTaskLog -Message "Starting Advanced Recovery Script" -ElapsedSeconds 0
	$timer = [System.Diagnostics.Stopwatch]::StartNew()

	if ((Test-ServiceExist -ServiceName $ServiceName) -eq $false) {
		Write-SCOMTaskLog -Message "$ServiceName - No such service exists on the system." -ElapsedSeconds $timer.Elapsed.TotalSeconds
	} else {
		[string] $serviceStatus = Start-ServiceAndWait $ServiceName -WaitSeconds $Delay

		if ($serviceStatus -ne "Running") {
			Write-SCOMTaskLog -Message "$ServiceName is not running..." -ElapsedSeconds $timer.Elapsed.TotalSeconds
			Restart-ServiceWithRepeats -MaxRepeatCount $MaxRepeatCount -RepeatIntervalSeconds $RepeatIntervalSeconds
		} else {
			Write-SCOMTaskLog -Message "$ServiceName is running..." -ElapsedSeconds $timer.Elapsed.TotalSeconds
		}
	}
	$timer.Stop()
}

Main