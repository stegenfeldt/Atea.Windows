<#
.Synopsis
Downloads, installs and optionally imports the latest builds of the Atea.Windows MP package.

.Parameter Version
Select which build to install. 
"Stable" will download from the master branch (tested and true)
"Latest" will download from the develop branch (latest build)

.Parameter ImportMP
Will attempt to import installed MPs into SCOM. 
This will likely fail if you move from "Latest" to "Stable" version as the prior tend to have a higher version number.

.Parameter OMMSComputerName
Defaults to the local computer. Set this to connect to a different SCOM Management Server for the import.

.Example
# Download, install and import the latest build on the local management server
.\Install-AteaWindowsMP.ps1 -Version Latest -ImportMP

.Example
# Download and install latest version locally, import to a different SCOM Management Server
.\Install-AteaWindowsMP.ps1 -Version Latest -ImportMP -OMMSComputerName <omms1.domain.fqdn>

.Example
# Download and install stable version locally. Don't import.
.\Install-AteaWindowsMP.ps1 -Version Stable
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Stable","Latest")] [string] $Version,
    [switch] $ImportMP,
    [string] $OMMSComputerName = "."
)

$Error.Clear()

[string[]] $mpFiles = @(
    "Atea.Windows.Library.mp",
    "Atea.Windows.Server.Monitoring.mp",
    "Atea.Windows.Service.Monitoring.mp",
    "Atea.Windows.File.Monitoring.mp"
)

[string] $developURL = "https://github.com/stegenfeldt/Atea.Windows/raw/develop/Released/"
[string] $masterURL = "https://github.com/stegenfeldt/Atea.Windows/raw/master/Released/"
[string] $installDir = "$(${env:ProgramFiles(x86)})\System Center Management Packs\Atea.Windows\"
$startLocation = Get-Location

if ((Test-Path $installDir) -eq $false) {
    if (!(New-Item -Path $installDir -ItemType Directory -Force -ErrorAction SilentlyContinue)) {
        Write-Host "Unable to create directory." -ForegroundColor Red
        Write-Host "Using current directory instead."
        $installDir = "$($Script:PWD.Path)\"
    }
}

foreach ($mpFile in $mpFiles) {
    switch ($Version) {
        "Stable" {
            $mpFilePath = $installDir + $mpFile
            $mpFileURL = $masterURL + $mpFile
        }
        "Latest" {
            $mpFilePath = $installDir + $mpFile
            $mpFileURL = $developURL + $mpFile
        }
        default {
            $mpFilePath = $installDir + $mpFile
            $mpFileURL = $masterURL + $mpFile
        }
    }
    Write-Verbose "Saving $mpFileURL to $mpFilePath"
    Invoke-WebRequest -Uri $mpFileURL -OutFile $mpFilePath
}

if ($ImportMP -and (($Version = "Stable") -or ($Version = "Latest"))) {
    Import-Module -Name OperationsManager
    New-SCOMManagementGroupConnection -ComputerName $OMMSComputerName

    $mps = Get-SCOMManagementPack -ManagementPackFile (Get-ChildItem -Path $installDir -Filter "*.mp").FullName
    Write-Verbose "Importing managementpacks to $((Get-SCOMManagementGroup).Name)"
    Import-SCOMManagementPack -ManagementPack $mps -Verbose
}

# SIG # Begin signature block
# MIIdGQYJKoZIhvcNAQcCoIIdCjCCHQYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2Ocvbmr8ERmgRnPwUnP5QWcG
# 4pGgghg5MIIE3jCCA8agAwIBAgIQazJqDwMo03odUwv9I71I4jANBgkqhkiG9w0B
# AQsFADB+MQswCQYDVQQGEwJQTDEiMCAGA1UEChMZVW5pemV0byBUZWNobm9sb2dp
# ZXMgUy5BLjEnMCUGA1UECxMeQ2VydHVtIENlcnRpZmljYXRpb24gQXV0aG9yaXR5
# MSIwIAYDVQQDExlDZXJ0dW0gVHJ1c3RlZCBOZXR3b3JrIENBMB4XDTE1MTAyOTEx
# MzAyOVoXDTI3MDYwOTExMzAyOVowgYAxCzAJBgNVBAYTAlBMMSIwIAYDVQQKDBlV
# bml6ZXRvIFRlY2hub2xvZ2llcyBTLkEuMScwJQYDVQQLDB5DZXJ0dW0gQ2VydGlm
# aWNhdGlvbiBBdXRob3JpdHkxJDAiBgNVBAMMG0NlcnR1bSBDb2RlIFNpZ25pbmcg
# Q0EgU0hBMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALfbqNjI47za
# 2oO6ub/W1VdTQbdAuhcMRJXU6WY7f7S+kKOUCaWtISAXgEa0QyY+jksaZOwOQDJD
# /IKf/0ot6pTdWhE2i2Hv7BbUSQPY513DZVvyTgsrw8FT+kAtwqszJAWBcH7Ih0yf
# 0YDCGHsOFL1OA0PLKEiwLeY23xs9i8OMnTee4QbXJVDfeT3at1/rRr52KDa4AgBG
# A9A0G3i0KMdRx8iVP26NiRjcSfHCDxr0gYHHbdQEd8Uhoy5T+XfP3Kmbw8Hl1Wcv
# MbzAwmicSpblH/HzSDUO9uSxxe+HgDrigAw0nfoUZHHkHKGqss8Ap+M3cvlArZ4o
# lQINzpDjW8UCAwEAAaOCAVMwggFPMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYE
# FMB7tMi3blanCUia+HJP19ckLDY+MB8GA1UdIwQYMBaAFAh2zcsH/yT2xc3tu5C8
# 4oQ3RnX3MA4GA1UdDwEB/wQEAwIBBjATBgNVHSUEDDAKBggrBgEFBQcDAzAvBgNV
# HR8EKDAmMCSgIqAghh5odHRwOi8vY3JsLmNlcnR1bS5wbC9jdG5jYS5jcmwwawYI
# KwYBBQUHAQEEXzBdMCgGCCsGAQUFBzABhhxodHRwOi8vc3ViY2Eub2NzcC1jZXJ0
# dW0uY29tMDEGCCsGAQUFBzAChiVodHRwOi8vcmVwb3NpdG9yeS5jZXJ0dW0ucGwv
# Y3RuY2EuY2VyMDkGA1UdIAQyMDAwLgYEVR0gADAmMCQGCCsGAQUFBwIBFhhodHRw
# Oi8vd3d3LmNlcnR1bS5wbC9DUFMwDQYJKoZIhvcNAQELBQADggEBAKrlP3ZUAkxw
# DimpOZYGDzG3C/Gmi1L7EI9PQluMvTEjAWad6CmhTcNQ+vf4RQ4dgtf8/qYyBHP9
# cezMiA+jkgjFgVgC/QtpO824P0k90I0cExRoLpsNmq2wGeKe0nw5d4hvI/17hPxE
# bbW6a3CSVWyUsdg3/alZHbRjstwTzXiOJTXBmo83hC7URczj9cyNc6jjOm3nlZRw
# V5FQtm3vc3JPLwKHYOLqIqHtPv3Ri2aNLnJtT8ZdNe6TqJjSZ2rp2hnNAoP5dPxf
# ehgEKB7dIjM7dmxHBV3VUv4OunbzgxDHbjBfp2DH+nQnMZsog+0hihvxI1KE7ZW8
# rTqlo0IBnbwwggYUMIIE/KADAgECAhBurXO+EeW89wo8twyKIm/WMA0GCSqGSIb3
# DQEBCwUAMIGAMQswCQYDVQQGEwJQTDEiMCAGA1UECgwZVW5pemV0byBUZWNobm9s
# b2dpZXMgUy5BLjEnMCUGA1UECwweQ2VydHVtIENlcnRpZmljYXRpb24gQXV0aG9y
# aXR5MSQwIgYDVQQDDBtDZXJ0dW0gQ29kZSBTaWduaW5nIENBIFNIQTIwHhcNMTYx
# MDI3MDkxOTM2WhcNMTcxMDI3MDkxOTM2WjCBjTELMAkGA1UEBhMCU0UxHjAcBgNV
# BAoMFU9wZW4gU291cmNlIERldmVsb3BlcjExMC8GA1UEAwwoT3BlbiBTb3VyY2Ug
# RGV2ZWxvcGVyLCBTYW11ZWwgVGVnZW5mZWxkdDErMCkGCSqGSIb3DQEJARYcc2Ft
# dWVsLnRlZ2VuZmVsZHRAaGFydGF0aS5zZTCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBANwPjeTu0SLUiZc1k8pkKP8IZk7Id0obvTTQeXmp9xhvxsypLJUk
# eC33s5avefEjOJVf8oYW99XGUyYdgcJO22XWkxIq5uWbN+idhxI13kcwGTX9xp0a
# pH6FCvDkraCwtqmUSEl1dISOY4JBv1pMRf+919K/7qEQW7YH9Cl/3nH/qYTpUMkG
# TUwY58YB8qUwxCVa8A0w4FY0rHwx7Ds4VPWwq8zbPEKX7OO7HBQ2tQb4tc4Yuq5v
# HY5o60zPE8ZuYJllOfn9p6TFUBSQ3T2+zX14fF/Wz3cIfwDEzVZ1jX10CuF81yxP
# ihgdxOxI5ujh/jfJsS8svmsTrmiuODLdO00CAwEAAaOCAnkwggJ1MAwGA1UdEwEB
# /wQCMAAwMgYDVR0fBCswKTAnoCWgI4YhaHR0cDovL2NybC5jZXJ0dW0ucGwvY3Nj
# YXNoYTIuY3JsMHEGCCsGAQUFBwEBBGUwYzArBggrBgEFBQcwAYYfaHR0cDovL2Nz
# Y2FzaGEyLm9jc3AtY2VydHVtLmNvbTA0BggrBgEFBQcwAoYoaHR0cDovL3JlcG9z
# aXRvcnkuY2VydHVtLnBsL2NzY2FzaGEyLmNlcjAfBgNVHSMEGDAWgBTAe7TIt25W
# pwlImvhyT9fXJCw2PjAdBgNVHQ4EFgQUlV5XwtpXLs0CQdomBbg3c6JM0xcwHQYD
# VR0SBBYwFIESY3NjYXNoYTJAY2VydHVtLnBsMA4GA1UdDwEB/wQEAwIHgDCCATgG
# A1UdIASCAS8wggErMIIBJwYFZ4EMAQQwggEcMCUGCCsGAQUFBwIBFhlodHRwczov
# L3d3dy5jZXJ0dW0ucGwvQ1BTMIHyBggrBgEFBQcCAjCB5TAgFhlVbml6ZXRvIFRl
# Y2hub2xvZ2llcyBTLkEuMAMCAQEagcBVc2FnZSBvZiB0aGlzIGNlcnRpZmljYXRl
# IGlzIHN0cmljdGx5IHN1YmplY3RlZCB0byB0aGUgQ0VSVFVNIENlcnRpZmljYXRp
# b24gUHJhY3RpY2UgU3RhdGVtZW50IChDUFMpIGluY29ycG9yYXRlZCBieSByZWZl
# cmVuY2UgaGVyZWluIGFuZCBpbiB0aGUgcmVwb3NpdG9yeSBhdCBodHRwczovL3d3
# dy5jZXJ0dW0ucGwvcmVwb3NpdG9yeS4wEwYDVR0lBAwwCgYIKwYBBQUHAwMwDQYJ
# KoZIhvcNAQELBQADggEBAIkXhtrsJL9eEUKfia5fS1s5S5RI3JlLV0sFFl72zvGV
# F2bxxQkAf8xh30ft5N5N7ZwM3jDc52Q+vjttiXsBwTkqId2MgF8p7YvEGTMoDQiU
# rYOB82QY3Fbdz3dKViRi7/xm6aUHNsWmw/fUWZC8HAncRTQr5t35q3XmmFR+Xc+W
# Qgpfpjqbge9K2MEhLU6/wIUnqLsXXz3fHVEMwKqO6rQKo8nHUNGK9wxzZhBZIQJh
# Dw+c0KJl7k4Avqqriv/NtkwSYepgV1tCU2wFcwTiwuuUGe3rfgrW1vT5Fb7D3ddw
# gVj1HZNtmWcP9eRF2Uv5P6iblqN+H557h3yHYgR5QSkwggZqMIIFUqADAgECAhAD
# AZoCOv9YsWvW1ermF/BmMA0GCSqGSIb3DQEBBQUAMGIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# ITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTAeFw0xNDEwMjIwMDAw
# MDBaFw0yNDEwMjIwMDAwMDBaMEcxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdp
# Q2VydDElMCMGA1UEAxMcRGlnaUNlcnQgVGltZXN0YW1wIFJlc3BvbmRlcjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKNkXfx8s+CCNeDg9sYq5kl1O8xu
# 4FOpnx9kWeZ8a39rjJ1V+JLjntVaY1sCSVDZg85vZu7dy4XpX6X51Id0iEQ7Gcnl
# 9ZGfxhQ5rCTqqEsskYnMXij0ZLZQt/USs3OWCmejvmGfrvP9Enh1DqZbFP1FI46G
# RFV9GIYFjFWHeUhG98oOjafeTl/iqLYtWQJhiGFyGGi5uHzu5uc0LzF3gTAfuzYB
# je8n4/ea8EwxZI3j6/oZh6h+z+yMDDZbesF6uHjHyQYuRhDIjegEYNu8c3T6Ttj+
# qkDxss5wRoPp2kChWTrZFQlXmVYwk/PJYczQCMxr7GJCkawCwO+k8IkRj3cCAwEA
# AaOCAzUwggMxMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB
# /wQMMAoGCCsGAQUFBwMIMIIBvwYDVR0gBIIBtjCCAbIwggGhBglghkgBhv1sBwEw
# ggGSMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMIIB
# ZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkA
# cwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUA
# cwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkA
# QwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkA
# aQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMA
# aAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIA
# ZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkA
# IAByAGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTAfBgNVHSMEGDAWgBQV
# ABIrE5iymQftHt+ivlcNK2cCzTAdBgNVHQ4EFgQUYVpNJLZJMp1KKnkag0v0HonB
# yn0wfQYDVR0fBHYwdDA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwOKA2oDSGMmh0dHA6Ly9jcmw0LmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMHcGCCsGAQUFBwEBBGsw
# aTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUF
# BzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURDQS0xLmNydDANBgkqhkiG9w0BAQUFAAOCAQEAnSV+GzNNsiaBXJuGziMgD4CH
# 5Yj//7HUaiwx7ToXGXEXzakbvFoWOQCd42yE5FpA+94GAYw3+puxnSR+/iCkV61b
# t5qwYCbqaVchXTQvH3Gwg5QZBWs1kBCge5fH9j/n4hFBpr1i2fAnPTgdKG86Ugnw
# 7HBi02JLsOBzppLA044x2C/jbRcTBu7kA7YUq/OPQ6dxnSHdFMoVXZJB2vkPgdGZ
# dA0mxA5/G7X1oPHGdwYoFenYk+VVFvC7Cqsc21xIJ2bIo4sKHOWV2q7ELlmgYd3a
# 822iYemKC23sEhi991VUQAOSK2vCUcIKSK+w1G7g9BQKOhvjjz3Kr2qNe9zYRDCC
# Bs0wggW1oAMCAQICEAb9+QOWA63qAArrPye7uhswDQYJKoZIhvcNAQEFBQAwZTEL
# MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3
# LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290
# IENBMB4XDTA2MTExMDAwMDAwMFoXDTIxMTExMDAwMDAwMFowYjELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6IItmfnKwkKVpYBzQHDSnlZUXKnE0kEG
# j8kz/E1FkVyBn+0snPgWWd+etSQVwpi5tHdJ3InECtqvy15r7a2wcTHrzzpADEZN
# k+yLejYIA6sMNP4YSYL+x8cxSIB8HqIPkg5QycaH6zY/2DDD/6b3+6LNb3Mj/qxW
# BZDwMiEWicZwiPkFl32jx0PdAug7Pe2xQaPtP77blUjE7h6z8rwMK5nQxl0SQoHh
# g26Ccz8mSxSQrllmCsSNvtLOBq6thG9IhJtPQLnxTPKvmPv2zkBdXPao8S+v7Iki
# 8msYZbHBc63X8djPHgp0XEK4aH631XcKJ1Z8D2KkPzIUYJX9BwSiCQIDAQABo4ID
# ejCCA3YwDgYDVR0PAQH/BAQDAgGGMDsGA1UdJQQ0MDIGCCsGAQUFBwMBBggrBgEF
# BQcDAgYIKwYBBQUHAwMGCCsGAQUFBwMEBggrBgEFBQcDCDCCAdIGA1UdIASCAckw
# ggHFMIIBtAYKYIZIAYb9bAABBDCCAaQwOgYIKwYBBQUHAgEWLmh0dHA6Ly93d3cu
# ZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9yeS5odG0wggFkBggrBgEFBQcC
# AjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBlAHIA
# dABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBjAGMA
# ZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0ACAA
# QwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAgAFAA
# YQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABpAG0A
# aQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBuAGMA
# bwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBmAGUA
# cgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMBIGA1UdEwEB/wQIMAYBAf8CAQAweQYI
# KwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
# b20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmww
# OqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwHQYDVR0OBBYEFBUAEisTmLKZB+0e36K+Vw0rZwLNMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUAA4IBAQBG
# UD7Jtygkpzgdtlspr1LPUukxR6tWXHvVDQtBs+/sdR90OPKyXGGinJXDUOSCuSPR
# ujqGcq04eKx1XRcXNHJHhZRW0eu7NoR3zCSl8wQZVann4+erYs37iy2QwsDStZS9
# Xk+xBdIOPRqpFFumhjFiqKgz5Js5p8T1zh14dpQlc+Qqq8+cdkvtX8JLFuRLcEwA
# iR78xXm8TBJX/l/hHrwCXaj++wc4Tw3GXZG5D2dFzdaD7eeSDY2xaYxP+1ngIw/S
# qq4AfO6cQg7PkdcntxbuD8O9fAqg7iwIVYUiuOsYGk38KiGtSTGDR5V3cdyxG0tL
# HBCcdxTBnU8vWpUIKRAmMYIESjCCBEYCAQEwgZUwgYAxCzAJBgNVBAYTAlBMMSIw
# IAYDVQQKDBlVbml6ZXRvIFRlY2hub2xvZ2llcyBTLkEuMScwJQYDVQQLDB5DZXJ0
# dW0gQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxJDAiBgNVBAMMG0NlcnR1bSBDb2Rl
# IFNpZ25pbmcgQ0EgU0hBMgIQbq1zvhHlvPcKPLcMiiJv1jAJBgUrDgMCGgUAoHgw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQUa/R0nwlVeyne5Vbw6COxLmsNVwwwDQYJKoZIhvcNAQEBBQAEggEAmgkqvheB
# qmFWz3l8ZRQ/rJ1pYAIcpJyiJuyhr5WRumWLQuY+EFqumL00eRiAUDX8VJV3eCFM
# 3rojWPXbPFdOmA3HLaaL0spBS0HMSHivgIw+nGP9emNDjoENcTiZQVeld2cwEslk
# 1VTKwDrxOqikbfxCpKjkDNCj800Uu6KGkmR4pY/dpZ8/aUHQJBgA1bggkmPO4FCy
# eWi9cBUjE2Fv6NV4c02Ob06yOqnDqeRWpWOsJiL3fzlO0ELswYm7zRPrjF7Ell/K
# p+2a6YVceAbuN+hewBeCh6AQ8GOv+AReRdzn2FhnJPXtxfxn3CKqhPI2OEakp1TF
# KfNWh6HYlPA+A6GCAg8wggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQ
# AwGaAjr/WLFr1tXq5hfwZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqG
# SIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTcwNDA2MTMwMDAwWjAjBgkqhkiG9w0B
# CQQxFgQUiytB1wxiYtV0tXKzdsWvzY8/RLMwDQYJKoZIhvcNAQEBBQAEggEAA81G
# vmmZtrwxKybdjFwanXGUasZQKZVFuB5I7fPRx+U5v4qCxaWYupfisKOhKmftIMFW
# +6zW1aq6TVVdYOjxtftkigQ962Q/vgH+aw7s0+PFm/s7+AdSMSUEq2ZT0x/VaWYB
# X53VXBpgwdJI7gTadryH2zSf8MMkfZKLMKDU+j6YdfhUH950IC0cELDc/PolQoQu
# PDqiSv+jmzTMGVsdjVRo2iiT6cW/dDJ+bvGhzPPxk3wHhYahgHJFrYVgHvZxn2PY
# dDvL8hsdJfKoc6FZ2Irjvn0Ud1Sb4bsyKghx+WFPOvIV/Y3RRJ9Ljog79X5HX19m
# 2UCBHdjyddFDobvMYg==
# SIG # End signature block
