# Atea.Windows.File.Monitoring

Atea Windows File Monitoring management pack provides simplified file monitoring using a few registry based discoveries, using powershell, to instantiate monitored folders and monitors. 

## Instructions

### Monitor Files of a certain Age

Can be used to monitor a folder for files matching a certain age. It could be that file should not linger for too long or that there should be files recently updated. This monitor allows for monitoring both creation time and updated time. 

It is configured by planting a registry key and values for the settings.

Available settings are:
- FolderPath = Full path to folder
- Recursive = true/false - search recursively from FolderPath
- FilePattern = Filename(s) to look for, using wildcards
- AgeInMinutes = What file age, in minutes, to trigger on
- Operator = Can be `<`, `>`, `>=`, `<=`, `=` or powershell operators are supported.
- FileAgeAttribute = What file attribute to chek against. `CreationTime`,`LastWriteTime`, `LastAccessTime` is supported.

The name of the registry key will be the displayname used for the folder object as well as in the alert description. 

#### Example 1 - Monitor backup files:
```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Atea\FileAgeMonitoring\DB Backups]
"FolderPath"="D:\\DBBackups"
"Recursive"="true"
"FilePattern"="*.bak"
"AgeInMinutes"="1440"
"Operator"=">"
"FileAgeAttribute"="LastWriteTime"
```
Alert if there are `.bak` files in `D:\DBBackups` that has not been written to in `1440` minutes (24 hours). This is an actual example from a customer where DB Backups are run daily, and old files are removed each run. Files older than 24 hours means the backup jobs have not been executed successfully today. 

#### Example 2 - Monitor print job processing. 

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Atea\FileAgeMonitoring\XYZ Print Jobs]
"FolderPath"="\\\\fileshare\\jobs"
"Recursive"="false"
"FilePattern"="*.prt"
"AgeInMinutes"="10"
"Operator"=">"
"FileAgeAttribute"="CreationTime"
```
Another example from a customer. This time we're looking for `prt`-files that are older than `5` minutes. This indicates, in this case, that print job processing is lagging behind. 

#### Example 3 - Alert on error files

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Atea\FileAgeMonitoring\UiPath Error Files]
"FolderPath"="\\filesshare\appX\err"
"Recursive"="false"
"FilePattern"="*"
"AgeInMinutes"="0"
"Operator"=">="
"FileAgeAttribute"="CreationTime"
```

If any file is found in the Err-folder, it's bad. Here we use `>= 0` minutes to trigger on all existing files. This will raise one error with the first found files in the description. Error will be cleared when there is no longer any files in the error folder. 