<#	.Description
	From a PSCredential object (using the password value), make an encoded password string suitable for use in the AdministratorPassword portion of an unattend.xml Wndows setup answer file

	.Example
	Get-Credential administrator | ConvertTo-UnattendEncodedPassword.ps1 -UsageXMLNode AdministratorPassword
	Using the given credential, convert the password property to an encoded string suitable for use in an unattend.xml Windows setup answer file

	.Notes
	The UsageXMLNode refers to the XML node in the Unattend.xml answer file in which the encoded password shall be used. That node name is used in the encoding/decoding of the string in combination with the password value itself.
#>
[CmdletBinding()]
param(
	## Credential whose password to encode into a string
	[parameter(Mandatory=$true, ValueFromPipeline = $true)][System.Management.Automation.PSCredential]$Credential,

	## XML node name in which credential shall be used (Like "Password" or "AdministratorPassword")
	[parameter(Mandatory=$true)][ValidateSet("Password", "AdministratorPassword")][String]$UsageXMLNode
)

process {
	$Credential | Foreach-Object {
		## get the Unicode bytes of the string that is the password suffixed by the string "AdministratorPassword", which is apparently what the unattend answer file encoded password expects
		[System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("$($_.GetNetworkCredential().Password)$UsageXMLNode"))
	} ## end Foreach-Object
} ## end process