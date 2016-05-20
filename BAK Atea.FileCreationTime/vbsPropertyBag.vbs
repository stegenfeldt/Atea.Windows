'' Recursive search for filepattern
Option Explicit
' Some much needed constants
CONST HKLM = &H80000002
CONST REG_SZ = 1
CONST REG_EXPAND_SZ = 2
CONST REG_BINARY = 3
Const REG_DWORD = 4
Const REG_MULTI_SZ = 7
Const SCOM_INFO = 2
CONST SCOM_WARNING = 1
CONST SCOM_ERROR = 0
CONST SCOM_SCRIPT_INFORMATION = 19200
CONST SCOM_SCRIPT_WARNING = 19201
CONST SCOM_SCRIPT_ERROR = 19202
CONST SCOM_DEBUG = 19999

' Declare all variables ahead, group them by "topic"
Dim fsObject, folderCollection, folderObject, fileCollection, fileObject, subFolder, folderInstance
Dim fileName, fileAge, filePath, fileCreationTime
Dim argFolder, argFilePattern, argRecursive, argFileAge, argFriendlyName, argOperator, argRegKeyPath, argComputerName 
Dim regexObject
Dim regSubKeyCollection, regSubKey, regValueCollection, regValue, regValueContent, regObject
Dim scomAPI, propertyBag, propertyBagExist

Set scomAPI = CreateObject("MOM.ScriptAPI")

argRegKeyPath = "Software\ICT\FileCreation"
'argComputerName = WScript.Arguments(0)
argComputerName = "."

Set regObject = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & argComputerName & "\root\default:StdRegProv")
regObject.EnumKey HKLM, argRegKeyPath, regSubKeyCollection
For each regSubKey in regSubKeyCollection
	argFriendlyName = regSubKey
	regSubKey = argRegKeyPath & "\" & regSubKey
	regObject.EnumValues HKLM, regSubKey, regValueCollection
	If Not IsNull(regValueCollection) Then
		If UBound(regValueCollection) >= 4 And Err.Number = 0 Then
			For Each regValue In regValueCollection
				regObject.GetStringValue HKLM, regSubKey, regValue, regValueContent
				Select Case regValue
					Case "FolderPath"
						argFolder = regValueContent
					Case "Recursive"
						argRecursive = regValueContent
					Case "FilePattern"
						argFilePattern = regValueContent
						argFilePattern = Replace(argFilePattern,".","\.")
						argFilePattern = Replace(argFilePattern,"?",".")
						argFilePattern = Replace(argFilePattern,"*",".*")						
					Case "AgeInMinutes"
						argFileAge = regValueContent
					Case "Operator"
						argOperator = regValueContent
				End Select
			Next
			GetFolderInfo argFolder
		End If
	End If
Next

'' Return whatever propertybags may have been created
If propertyBagExist = True Then
	scomAPI.ReturnItems
End If
Set scomAPI = Nothing
Set regObject = Nothing

'' This will find all files in the specified folderpath,
'' if it does exist, and send them to GetFileInfo()
Sub GetFolderInfo(paramFolderPath)
	If IsEmpty(fsObject) Then
		Set fsObject = CreateObject("Scripting.FileSystemObject")
	End If
	
	If fsObject.FolderExists(paramFolderPath) Then
		Set folderObject = fsObject.GetFolder(paramFolderPath)
		For Each fileObject In folderObject.Files
			GetFileInfo fileObject
		Next
		If CBool(argRecursive) = True Then
			Set folderCollection = folderObject.SubFolders
			For Each subFolder In folderCollection
				GetFolderInfo subFolder.Path
			Next
		End If
	End If
End Sub

'' GetFileInfo() will take a FSO.File object and
'' get Name, Path, CreationTime and Age (in minutes).
'' This information will be inserted into a scomAPI
'' propertybag
Sub GetFileInfo(paramFileObject)
	Dim makePropertyBag
	makePropertyBag = False
	Set regexObject = New RegExp
	regexObject.Pattern = argFilePattern
	regexObject.IgnoreCase = True
	
	If regexObject.Test(paramFileObject.Name) Then
		Select Case argOperator
			Case "<"
				If CDbl(DateDiff("n",paramFileObject.DateCreated,Now)) <= CDbl(argFileAge) Then
					WScript.Echo DateDiff("n",paramFileObject.DateCreated,Now) & argOperator & argFileAge & " case ""<"""
					makePropertyBag = True
				End If
			Case "<="
				If CDbl(DateDiff("n",paramFileObject.DateCreated,Now)) <= CDbl(argFileAge) Then
					WScript.Echo DateDiff("n",paramFileObject.DateCreated,Now) & argOperator & argFileAge & " case ""<="""
					makePropertyBag = True
				End If
			Case ">"
				If CDbl(DateDiff("n",paramFileObject.DateCreated,Now)) >= CDbl(argFileAge) Then
					WScript.Echo DateDiff("n",paramFileObject.DateCreated,Now) & argOperator & argFileAge & " case ""<"""
					makePropertyBag = True
				End If
			Case ">="
				If CDbl(DateDiff("n",paramFileObject.DateCreated,Now)) >= CDbl(argFileAge) Then
					WScript.Echo DateDiff("n",paramFileObject.DateCreated,Now) & argOperator & argFileAge & " case "">="""
					makePropertyBag = True
				End If
		End Select
		If makePropertyBag = True Then
			Set propertyBag = scomAPI.CreatePropertyBag()
			Call propertyBag.AddValue("FileName",paramFileObject.Name)
			Call propertyBag.AddValue("FileFullname",paramFileObject.Path)
			Call propertyBag.AddValue("FileCreationTime",paramFileObject.DateCreated)
			Call propertyBag.AddValue("FileSize",paramFileObject.Size)
			Call propertyBag.AddValue("FileAgeMinutes",DateDiff("n",paramFileObject.DateCreated,Now))
			Call propertyBag.AddValue("FolderFriendlyName",argFriendlyName)
			Call scomAPI.AddItem(propertyBag)
			propertyBagExist = True
			makePropertyBag = False
		End If
	End If	
End Sub


'' Simple Sub to log an event to the Operations Manager
'' event log.
Sub LogEvent(logEventID, logSeverity, logMessage)
	Dim scomApiEvent, scriptName
	scriptName = WScript.ScriptName
	
	If logEventID <> SCOM_DEBUG Then
		Set scomApiEvent = CreateObject("MOM.ScriptAPI")
		Call scomApiEvent.LogScriptEvent(scriptName,logEventID,logSeverity,logMessage)
		Set scomApiEvent = Nothing
	Else
		If debugEnabled Then
			Set scomApiEvent = CreateObject("MOM.ScriptAPI")
			Call scomApiEvent.LogScriptEvent(scriptName,logEventID,logSeverity,logMessage)
			Set scomApiEvent = Nothing
		End If
	End If
End Sub


'' This "Folder" class is mainly to group all it's related
'' functionality into one container
Class FolderClass
	Public Path
	Public FilePattern
	Public Recursive
	Public FileAgeMinutes
	Public FriendlyName
	Public Operator
	
	Private Sub Class_Initialize()
		Path = ""
		FilePattern = ""
		Recursive = ""
		FileAgeMinutes = ""
		FriendlyName = ""
		Operator = ""
	End Sub
	
	'' Receive a regkey object and look for the settings
	Public Function GetFolderSettings(paramRegKeyObject)
		Dim regValueCollection, regValue 
		paramRegKeyObject.EnumValues HKLM, paramRegKeyObject, regValueCollection
		For Each regValue In regValueCollection
			WScript.Echo regValue
		Next
		FilePattern = Replace(FilePattern,".","\.")
		FilePattern = Replace(FilePattern,"?",".")
		FilePattern = Replace(FilePattern,"*",".*")
	End Function
End Class
