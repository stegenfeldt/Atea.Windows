On Error Resume Next
CONST GB = 1073741824
 
Dim oAPI, oBag
Set oAPI = CreateObject("MOM.ScriptAPI")
Set oArgs = WScript.Arguments
drive = oArgs(0)
 
strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
 
Set colLogicalDisk = objWMIService.ExecQuery("Select * from Win32_LogicalDisk Where DeviceID= '" & drive & "'")
 
For each objLogicalDisk in colLogicalDisk
diskUsedGB = ((objLogicalDisk.size - objLogicalDisk.freespace)/GB)
Next
 
Set oBag = oAPI.CreatePropertyBag()
Call oBag.AddValue("DiskUsed",diskUsedGB)
Call oAPI.Return(oBag)