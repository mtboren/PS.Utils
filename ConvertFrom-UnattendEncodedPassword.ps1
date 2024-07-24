<#	.Description
	Create a credential object whose password value is from an encoded password string (say, from an unattend.xml Windows setup answer file)

	.Example
	"cwB3AGUAZQB0AFAAYQBzAHMAdwBvAHIAZABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAFAAYQBzAHMAdwBvAHIAZAA=" | ConvertFrom-UnattendEncodedPassword.ps1 -UsageXMLNode AdministratorPassword
	Using the given encoded password string (say, from an unattend.xml Windows setup answer file), create a credential object whose password value is that which is encoded in the string

	.Notes
	The UsageXMLNode refers to the XML node in the Unattend.xml answer file in which the encoded password shall be used. That node name is used in the encoding/decoding of the string in combination with the password value itself.
#>
[CmdletBinding()]
[OutputType([System.Management.Automation.PSCredential])]
param(
	## Encoded password from which to create a credential object
	[parameter(Mandatory=$true, ValueFromPipeline = $true)][String[]]$EncodedPassword,

	## XML node name in which credential shall be used (Like "Password" or "AdministratorPassword")
	[parameter(Mandatory=$true)][ValidateSet("Password", "AdministratorPassword")][String]$UsageXMLNode
)

process {
	$EncodedPassword | Foreach-Object {
		## From a legitimate, encoded AdministratorPassword string, create a PSCredential
		$strPlaintextPasswd = ([System.Text.Encoding]::Unicode.GetChars([System.Convert]::FromBase64String($_)) -join "") -replace "$UsageXMLNode`$", ""
		New-Object System.Management.Automation.PsCredential("someUser", (ConvertTo-SecureString -String $strPlaintextPasswd -AsPlainText))
	} ## end Foreach-Object
} ## end process