param (
    [string] $FilePath
)

#signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /sha1 5E1D01C6F02199D1A39D806EB17A961F5C476EE2 "$(OutDir)$(TargetFileName)"
Set-AuthenticodeSignature -Certificate (dir Cert:\CurrentUser\My\5E1D01C6F02199D1A39D806EB17A961F5C476EE2) -TimestampServer "http://timestamp.digicert.com" -FilePath "$($FilePath)"
Set-AuthenticodeSignature -Certificate (dir Cert:\CurrentUser\My\5E1D01C6F02199D1A39D806EB17A961F5C476EE2) -TimestampServer "http://timestamp.digicert.com" -FilePath "$($FilePath.Substring(0,$FilePath.LastIndexOfAny("\"))+"\Setup.exe")"
