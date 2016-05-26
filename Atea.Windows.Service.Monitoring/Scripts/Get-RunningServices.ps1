gwmi -query "select * from Win32_Service where State='Running'" | ft Name,DisplayName -AutoSize
