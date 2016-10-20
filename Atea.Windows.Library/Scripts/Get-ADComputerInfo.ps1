# Quick little script that queries AD for properties on the current computer.
# Requires Powershell v2 or later and a computer connected to AD, that's it. 
# Base script is available at https://gist.github.com/stegenfeldt/da6f512f8dd5c3a2dabd527adf918087


function Get-ADComputerObject {
	<#
	Take computername (or get localhost) and get it's AD Computer Object
	#>
	param(
		[string] $ComputerName = $env:COMPUTERNAME
	)
	$filter = "(&(objectCategory=computer)(objectClass=computer)(cn=$ComputerName))"
	$computerProperties = ([adsisearcher]$filter).FindOne().Properties

	$computerADObject = [adsi]"LDAP://$($computerProperties.distinguishedname)"

	return $computerADObject
}

function Get-ADUserFromSID {
	param (
		[string] $SID
	)

	if ($SID -eq "") { Write-Error -Message "Please pass a SID." }

	$userADObject = [adsi] "LDAP://<SID=$($SID.TrimStart("O:"))>"
    if ($userADObject -eq $null) {
        $userADObject = [string] "Unknown"
    }

	return $userADObject
}

function Main {
	<#
	Main function, this is where is all comes together.
	#>
    Param (
        [string] $ComputerName = $env:COMPUTERNAME
    )

	$computerADObject = Get-ADComputerObject
	if ($computerADObject) {
		[string] $computerDescription = $computerADObject.Description #ADDescription
	} else {
		$computerDescription = ""
	}
	
	[string] $computerOwner = $computerADObject.PSBase.ObjectSecurity.Owner #ADCustodian
}

# Now... Go!
Main