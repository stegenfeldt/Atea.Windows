Option Explicit

Dim computerName, keyPath, registryObject, registryValues, serviceName, debugEnabled, scriptParameters, serviceClass
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


CheckParameters 2
computerName = CStr(scriptParameters(0))
debugEnabled = CBool(scriptParameters(1))

Set registryObject = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & computerName & "\root\default:StdRegProv")
keyPath = "Software\Atea\WinSvc" ' ToDo: Make this a parameter
registryObject.EnumValues HKLM, keyPath, registryValues

If NOT IsNull(registryValues) Then
	If UBound(registryValues) >= 0 And Err.Number = 0 Then
		' We got a "hit" on a service name configured in the registry
		' Create the SCOM property bag instances and return them to SCOM
		Set scomApi = CreateObject("MOM.ScriptAPI")

		For Each serviceName in registryValues
			' Add one property bag per service
			LogEvent SCOM_DEBUG,SCOM_INFO,"Found value: HKLM\" & keyPath & "\" & serviceName

			Set serviceObject = New Service
			returnValue = serviceObject.GetServiceInfo(serviceName,computerName)
			If returnValue = 0 Then
				With serviceObject
					Set scomPropertyBag = scomApi.CreatePropertyBag()	' Instance of a new property bag

					' Start adding values to the propertybag
					Call scomPropertyBag.AddValue("Name",.Name)
					Call scomPropertyBag.AddValue("DisplayName",.DisplayName)
					Call scomPropertyBag.AddValue("Description",.Description)
					Call scomPropertyBag.AddValue("SystemName",.SystemName)
					Call scomPropertyBag.AddValue("PathName",.PathName)
					Call scomPropertyBag.AddValue("ProcessID",.ProcessID)
					Call scomPropertyBag.AddValue("ServiceUser",.ServiceUser)
					Call scomPropertyBag.AddValue("State",.State)
					Call scomPropertyBag.AddValue("Status",.Status)
					Call scomPropertyBag.AddValue("StartMode",.StartMode)
					Call scomPropertyBag.AddValue("ServiceType",.ServiceType)
					Call scomPropertyBag.AddValue("TagID",.TagID)
					Call scomPropertyBag.AddValue("keyPath",keyPath)

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
						LogEvent SCOM_SCRIPT_WARNING, SCOM_WARNING, "An unhandled script event occured, please contact your SCOM admins." & vbCrLf & "Err.number = " & returnValue
				End Select
			End If

			Set serviceObject = Nothing
		Next
		Call scomApi.ReturnItems()	' Return the property bag collection to SCOM
		Set scomApi = Nothing
	Else
		' No services configured in registry
		LogEvent SCOM_DEBUG,SCOM_INFO,"Found no servicenames in: HKLM\" & keyPath & "\" & vbCrLf & _
		"Error code: " & Err.Num & vbCrLf & _
		"Error Description: " & Err.Description

		' Issue #4
		' Discovery never removing services efter the only remaining string value is deleted.
		' Needs to return an empty property bag.
		Set scomApi = CreateObject("MOM.ScriptingAPI")
		Set scomPropertyBag = scomApi.CreatePropertyBag()
		Call scomApi.Return(scomPropertyBag)
		Set scomApi = Nothing
	End If
Else
	' Could not read from registry, perhaps key is missing?
	LogEvent SCOM_DEBUG,SCOM_INFO,"Failed to read from: HKLM\" & keyPath & "\"

	' Issue #4
	' Discovery never removing services efter the only remaining string value is deleted.
	' Needs to return an empty property bag.
	Set scomApi = CreateObject("MOM.ScriptAPI")
	Set scomApi = CreateObject("MOM.ScriptingAPI")
	Set scomPropertyBag = scomApi.CreatePropertyBag()
	Call scomApi.Return(scomPropertyBag)
	Set scomApi = Nothing
End If


'''
' Clean things up
'''
Set registryObject = Nothing


'''
' Helper functions
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

Class Service
	Public Name
	Public DisplayName
	Public Description
	Public SystemName
	Public ServiceUser
	Public PathName
	Public State
	Public Status
	Public StartMode
	Public ServiceType
	Public ProcessID
	Public TagID



	Private Sub Class_Initialize()
		Name = ""
		DisplayName = ""
		Description = ""
		SystemName = ""
		ServiceUser = ""
		PathName = ""
	End Sub

	Public Function GetServiceInfo(mServiceName, mComputerName)
		Dim wmi, wmiServices, wmiService, serviceClass, returnCode

		returnCode = 0	' 0 = no error
		On Error Resume Next
		Set wmi = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & mComputerName & "\root\cimv2")
		Set wmiServices = wmi.ExecQuery("Select * from Win32_Service where Name='" & mServiceName & "'")
		returnCode = Err.Number
		If wmiServices.Count > 0 And returnCode = 0 Then
			For Each wmiService In wmiServices
				If LCase(wmiService.Name) = LCase(mServiceName) Then
					Name = ClearIllegalReturnValues(wmiService.Name)
					DisplayName = ClearIllegalReturnValues(wmiService.Caption)
					Description = ClearIllegalReturnValues(wmiService.Description)
					ServiceUser = ClearIllegalReturnValues(wmiService.StartName)
					SystemName = ClearIllegalReturnValues(wmiService.SystemName)
					PathName = ClearIllegalReturnValues(wmiService.PathName)
					State = ClearIllegalReturnValues(wmiService.State)
					Status = ClearIllegalReturnValues(wmiService.Status)
					StartMode = ClearIllegalReturnValues(wmiService.StartMode)
					ServiceType = ClearIllegalReturnValues(wmiService.ServiceType)
					ProcessID = ClearIllegalReturnValues(wmiService.ProcessID)
					TagID = ClearIllegalReturnValues(wmiService.TagID)
				Else
					returnCode = 242101
				End If
			Next
		Else
			If Err.Number <> 0 Then
				returnCode = Err.Number
				Err.Clear
			Else
				returnCode = 242100
			End If
		End If
		WScript.Echo returnCode
		GetServiceInfo = returnCode
		Set wmiServices = Nothing
		Set wmi = Nothing
	End Function

	Private Function ClearIllegalReturnValues(StringToClear)
	' Check for NULL
	If IsNull(StringToClear) Then
	  StringToClear = ""
	End If
	ClearIllegalReturnValues = StringToClear
	End Function
End Class