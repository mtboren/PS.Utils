<#	.Description
	Make a new X509 Certificate Signing Request with given properties. Uses openssl binary for CSR/key generation

	.Notes
	Based on code by the vScorpion from Feb 2016

	.Example
	New-CertificateSigningRequest.ps1 -SubjectHost myserver.dom.com -HostnameAlias myalias0.dom.com, anotheraliasforthisserver.dom.com -Organization MyCompany -Country US -State Indiana -City Indianapolis -OrganizationalUnit MyTeamName -EmailAddress mygroup@dom.com
	Create a new CSR  and corresponding private key in c:\temp\newCSR-myserver.dom.com-<someGuid>\ with the given attributes

	.Example
	Import-Csv c:\temp\myNewCsrItems.csv | New-CertificateSigningRequest.ps1 -OpenSSLFilespec \\server.dom.com\share\openssl\openssl.exe
	For every row in the given CSV, create a new CSR for each subjecthost in c:\temp\newCSR-<subjecthostname>-<someGuid>\ with the given attributes
#>
[CmdLetBinding()]

Param(
	## Credential whose password will be set for the private key file (to secure the private key file; this is the password to use when later consuming the private key file)
	[System.Management.Automation.PSCredential]$Credential = (Get-Credential -Message "Password to set on private key file" -User "<no username needed>"),

	## The Common Name ("CN") value in the subject of the CSR. This is often the FQDN of the machine. If none specified, will try to use the FQDN of the local machine computername
	[parameter(ValueFromPipelineByPropertyName=$true)][String]$SubjectHost = $env:computername,

	## DNS Alias FQDN(s) for use in the new certificate in the Subject Alternative Name field
	[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][String[]]$HostnameAlias,

	## Organization name to use (like company name, say)
	[parameter(ValueFromPipelineByPropertyName=$true)][String]$Organization = "MyCompany",

	## Two-letter country code
	[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][ValidateLength(2,2)][String]$Country,

	## State (fully spelled out)
	[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][String]$State,

	## City
	[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][String]$City,

	## Organizational unit (say, like, department or team name)
	[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][String]$OrganizationalUnit,

	## Email address of point of contact. Like, the name of a mail-enabled AD group or a mailing list whose members would be responsible for the eventual certificate
	[parameter(ValueFromPipelineByPropertyName=$true)][String]$EmailAddress,

	## Path to openssl.exe for use in generating CSR (defaults to "C:\Program Files\OpenSSL\bin\openssl.exe")
	[ValidateScript({Test-Path $_})][String]$OpenSSLFilespec = "C:\Program Files\OpenSSL\bin\openssl.exe"
)

process {
	$strBaseOutputDir = "c:\temp\newCSR-{0}-{1}" -f $SubjectHost, [System.Guid]::NewGuid().Guid
	Try {
		if (-not (Test-Path "$strBaseOutputDir")) {$oTmp = mkdir "$strBaseOutputDir"}
	}
	Catch {
		Throw "Encountered issue creating '$strBaseOutputDir'. Please address this and then try again"
	}
	## name to use for new OpenSSL CFG file
	$strNewOpenSSLCfgFilename = "csr_openssl.cfg"
	## name to use for new CSR file
	$strNewCSRFilename = "${SubjectHost}-newCertSigningReq.csr"

	## a string for the SAN field that is the IPv4 IPs for the given machine -- not currently used (would include this in the "subjectAltName" portion of the openssl config body below)
	# $strIP = if ($IncludeIP) {"IP:{0}" -f (Get-Wmiobject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled} | Select-Object -ExpandProperty IPAddress | Where-Object {$_ -match "(\d{1,3}.){3}\d{1,3}"})} else {$null}
	## the full subjecthost to use of the local machine (only get/use if SubjectHost was not provided as a param)
	$strSubjectHostToUse = if ($PSBoundParameters.ContainsKey("SubjectHost")) {$SubjectHost} else {([System.Net.DNS]::GetHostByName($SubjectHost) | Select-Object -Expand HostName).ToLower()}

	## make, for the hostname and aliases, a string like "DNS:hostname.dom.com, DNS:alias0.dom.com, DNS:alias1.dom.com"
	$strHostnameAndAliases_commaJoined = ($strSubjectHostToUse, $HostnameAlias | Foreach-Object {$_} | Where-Object {-not [String]::IsNullOrEmpty($_)} | Foreach-Object {"DNS:$_"}) -join ", "
	## string to use for CSR creation config file body
	$strOpenSSLConfigBody = @"
[ req ]
default_bits = 2048
default_keyfile = ${SubjectHost}.key
distinguished_name = req_distinguished_name
# encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
# extendedKeyUsage = serverAuth, clientAuth
subjectAltName = $strHostnameAndAliases_commaJoined

[ req_distinguished_name ]
countryName = $Country
stateOrProvinceName = $State
localityName = $City
0.organizationName = $Organization
organizationalUnitName = "$OrganizationalUnit"
commonName = $strSubjectHostToUse
$(if ($PSBoundParameters.ContainsKey('EmailAddress')) {"emailAddress='$EmailAddress'"})
"@

	Write-Verbose "Creating OpenSSL config file '$strBaseOutputDir\$strNewOpenSSLCfgFilename'"
	$strOpenSSLConfigBody | Out-File -Encoding ASCII -FilePath $strBaseOutputDir\$strNewOpenSSLCfgFilename

	Write-Verbose "Creating CSR file '$strBaseOutputDir\$strNewCSRFilename' and corresponding private key"
	$oTmpOutput = & $OpenSSLFilespec req -new -passout pass:"$($Credential.GetNetworkCredential().Password)" -out $strBaseOutputDir\$strNewCSRFilename -keyout $strBaseOutputDir\${SubjectHost}.key -config $strBaseOutputDir\$strNewOpenSSLCfgFilename

	Write-Verbose -Verbose "Below: outputting the values in the CSR.  How does this look?"
	Write-Verbose -Verbose  (& $OpenSSLFilespec req -in $strBaseOutputDir\$strNewCSRFilename -noout -text | Out-String)

	Write-Verbose -Verbose "New CSR and associated files output to '$strBaseOutputDir\' -- have a look there, and take the next steps with the given files to get a certificate"
	Write-Verbose -Verbose "And, Note: the private key there is encrypted, using the password of the credential provided to this script. Use that same password for when it's time to use/consume/import the private key"
	Write-Verbose -Verbose "To test decrypting the new private key, use the command (and enter the password you used to generate the CSR/key pair):"
	Write-Verbose -Verbose "  $OpenSSLFilespec rsa -in $strBaseOutputDir\${SubjectHost}.key"
	Get-Item -Path $strBaseOutputDir\$strNewCSRFilename
} ## end process
