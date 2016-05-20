$files = Get-ChildItem C:\Temp\ -Recurse | where {($_.Name -like '*.txt') -and ((((Get-Date) - $_.CreationTime).Minutes) -le 5)}
$files.FullName