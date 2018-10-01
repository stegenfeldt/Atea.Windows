Option Explicit

Dim computerName, keyPath, wmiObject, automaticServices, automaticService, serviceName, debugEnabled, scriptParameters, serviceClass, serviceExceptions, standardExclusions, wmiQuery, xylemExclusions
Dim scomApi, scomPropertyBag, serviceObject, returnValue

'''
' Get registry values into array
'''

CONST HKLM = &H80000002
CONST REG_SZ = 1
CONST REG_EXPAND_SZ = 2
CONST REG_BINARY = 3
CONST REG_DWORD = 4
CONST REG_MULTI_SZ = 7
CONST SCOM_INFO = 2
CONST SCOM_WARNING = 1
CONST SCOM_ERROR = 0
CONST SCOM_SCRIPT_INFORMATION = 19200
CONST SCOM_SCRIPT_WARNING = 19201
CONST SCOM_SCRIPT_ERROR = 19202
CONST SCOM_DEBUG = 19999


CheckParameters 3
computerName = CStr(scriptParameters(0))
debugEnabled = CBool(scriptParameters(1))
serviceExceptions = Split(scriptParameters(2),",")

wmiQuery = "Select * from Win32_Service where StartMode = 'Auto' AND NOT DisplayName Like 'Windows%' AND NOT DisplayName Like 'SQL%'"
standardExclusions = Split("sppsvc,RemoteRegistry,clr_optimization_v4.0.30319_32,clr_optimization_v4.0.30319_64,clr_optimization_v2.0.50727_32,VSS,gupdate,TrustedInstaller,SysmonLog,msiserver,OMSDK,healthservice,cshost,LanmanWorkstation,LanmanServer,WinRM,MpsSvc,EventLog,lmhosts,Browser,Dhcp,Winmgmt,clussvc,wuauserv,gpsvc,MSMQ,DiagTrack,Spooler,RpcSs,MSDTC,Slsvc,SNMP",",")
xylemExclusions = Split("PatrolAgent,Citrix.Xip.ClientService",",")

Set wmiObject = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & computerName & "\root\cimv2")
Set automaticServices = wmiObject.ExecQuery(wmiQuery)

If NOT IsNull(automaticServices) Then
	If automaticServices.Count >= 0 And Err.Number = 0 Then
		' We got a "hit" on a service name configured in the registry
		' Create the SCOM property bag instances and return them to SCOM
		Set scomApi = CreateObject("MOM.ScriptAPI")

		For Each automaticService In automaticServices
			serviceName = automaticService.Name
			' Add one property bag per service
			LogEvent SCOM_DEBUG,SCOM_INFO,"Found automatic service: " & serviceName

			If Ubound(Filter(serviceExceptions, serviceName,True,1)) > -1 Then
				'Got match, service shound be excluded from discovery
				LogEvent SCOM_DEBUG,SCOM_INFO,"Service is ignored due to exclusion list: " & serviceName
			ElseIf Ubound(Filter(standardExclusions, serviceName,True,1)) > -1 Then
				'Got match, service shound be excluded from discovery
				LogEvent SCOM_DEBUG,SCOM_INFO,"Service is ignored due to standard exclusion list: " & serviceName
			ElseIf Ubound(Filter(xylemExclusions, serviceName,True,1)) > -1 Then
				'Got match, service shound be excluded from discovery
				LogEvent SCOM_DEBUG,SCOM_INFO,"Service is ignored due to Xylem exclusion list: " & serviceName
			Else
				' No match, service is not in exclusion list.
				' Process and add to property bag
				If Err.Number = 0 Then
					With automaticService
						Set scomPropertyBag = scomApi.CreatePropertyBag()	' Instance of a new property bag

						' Start adding values to the propertybag
						Call scomPropertyBag.AddValue("Name",Cstr(.Name))
						Call scomPropertyBag.AddValue("DisplayName",Cstr(.DisplayName))
						If .Description <> vbNull Then
							Call scomPropertyBag.AddValue("Description",Cstr(.Description))
						Else
							Call scomPropertyBag.AddValue("Description","")
						End If
						Call scomPropertyBag.AddValue("SystemName",Cstr(.SystemName))
						Call scomPropertyBag.AddValue("PathName",Cstr(.PathName))
						Call scomPropertyBag.AddValue("ProcessID",Cstr(.ProcessID))
					    If .StartName <> vbNull Then
    						Call scomPropertyBag.AddValue("ServiceUser",Cstr(.StartName))
					    Else
						    Call scomPropertyBag.AddValue("ServiceUser","")
					    End If
						Call scomPropertyBag.AddValue("State",Cstr(.State))
						Call scomPropertyBag.AddValue("Status",Cstr(.Status))
						Call scomPropertyBag.AddValue("StartMode",Cstr(.StartMode))
						Call scomPropertyBag.AddValue("ServiceType",Cstr(.ServiceType))
						Call scomPropertyBag.AddValue("TagID",Cstr(.TagID))

						Call scomApi.AddItem(scomPropertyBag)	' Add the property bag to the collection
					End With
				Else
					Select Case returnValue
						Case 242100
							LogEvent SCOM_SCRIPT_WARNING, SCOM_WARNING, "Could not properly connect to the service repository on " & computerName & ", check RunAs user rights."
						Case 242101
							LogEvent SCOM_SCRIPT_WARNING, SCOM_WARNING, "Could not match registry value """ & serviceName & """to an existing service."
						Case 424
							LogEvent SCOM_SCRIPT_WARNING, SCOM_WARNING, "Connection to WMI-service on " & computerName & " failed. Check network connections and RunAs user rights."
						Case Else
							LogEvent SCOM_SCRIPT_WARNING, SCOM_WARNING, "An unhandled script event occured, please contact your SCOM admins." & vbCrLf & "Err.number = " & Err.Number
					End Select
				End If 'End error check
			End If 'End exclusion check

			Set serviceObject = Nothing
		Next
		Call scomApi.ReturnItems()	' Return the property bag collection to SCOM
		Set scomApi = Nothing
	Else
		' Got no services from WMI query
		LogEvent SCOM_DEBUG,SCOM_INFO,"Found no automatic services" & vbCrLf & _
		"Error code: " & Err.Num & vbCrLf & _
		"Error Description: " & Err.Description
	End If
Else
	' Could not read from WMI, perhaps user rights is insufficent?
	LogEvent SCOM_DEBUG,SCOM_INFO,"Could not connect to WMI, check user rights!"
End If


'''
' Clean things up
'''
Set wmiObject = Nothing


'''
' Helper funktions
'''

Sub CheckParameters(numRequiredParams)
	'''
	' Simple check to verify the number of arguments passed
	' to the script
	' Sets the global variable scriptParameters to a Wscript.Arguments array
	'
	' Bit of a hack, yes, but it works for now.
	'''
	Dim scriptArguments
	Set scriptArguments = WScript.Arguments

	If IsNumeric(numRequiredParams) Then
		If scriptArguments.Count >= numRequiredParams Then
			Set scriptParameters = scriptArguments
		Else
			LogEvent SCOM_SCRIPT_ERROR,SCOM_ERROR,"Script was not called with all the required parameters."
			WScript.Quit
		End If
	Else
		LogEvent SCOM_SCRIPT_ERROR,SCOM_ERROR,"The CheckParameters() sub was called with numRequiredParams as not numeric."
		WScript.Quit
	End If
	Set scriptArguments = Nothing
End Sub


Sub LogEvent(logEventID, logSeverity, logMessage)
	'''
	' Logs a MOM ScriptEvent into the Operations Manager eventlog
	'''
	Dim scomApi, scriptName
	scriptName = WScript.ScriptName

	If logEventID <> SCOM_DEBUG Then
		Set scomApi = CreateObject("MOM.ScriptAPI")
		Call scomApi.LogScriptEvent(scriptName,logEventID,logSeverity,logMessage)
		Set scomApi = Nothing
	Else
		If debugEnabled Then
			Set scomApi = CreateObject("MOM.ScriptAPI")
			Call scomApi.LogScriptEvent(scriptName,logEventID,logSeverity,logMessage)
			Set scomApi = Nothing
		End If
	End If
End Sub
