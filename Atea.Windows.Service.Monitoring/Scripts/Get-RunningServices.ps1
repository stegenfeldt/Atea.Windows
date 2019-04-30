Get-WMIObject -query "select * from Win32_Service where State='Running'" | Format-Table Name,DisplayName -AutoSize
