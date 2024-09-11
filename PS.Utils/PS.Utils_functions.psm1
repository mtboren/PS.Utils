function Get-ArgumentCompleter {
    <#
.SYNOPSIS
    Get custom argument completers registered in the current session.
.DESCRIPTION
    Get custom argument completers registered in the current session.

    By default Get-ArgumentCompleter lists all of the completers registered in the session.
.EXAMPLE
    Get-ArgumentCompleter
    Get all of the argument completers for PowerShell commands in the current session.
.EXAMPLE
    Get-ArgumentCompleter -CommandName Invoke-ScriptAnalyzer
    Get all of the argument completers used by the Invoke-ScriptAnalyzer command.
.EXAMPLE
    Get-ArgumentCompleter -Native
    Get all of the argument completers for native commands in the current session.
.Notes
    Awesome function by Chris Dent (@indented-automation on GitHub). From gist at https://gist.github.com/indented-automation/26c637fb530c4b168e62c72582534f5b
    Simply made CommandName also a positional parameter, for ease of use.  All credit goes to @indented-automation
#>

    [CmdletBinding(DefaultParameterSetName = 'PSCommand')]
    param (
        # Filter results by command name.
        [Parameter(Position = 0)]
        [String]$CommandName = '*',

        # Filter results by parameter name.
        [Parameter(ParameterSetName = 'PSCommand')]
        [String]$ParameterName = '*',

        # Get argument completers for native commands.
        [Parameter(ParameterSetName = 'Native')]
        [Switch]$Native
    )

    $getExecutionContextFromTLS = [PowerShell].Assembly.GetType('System.Management.Automation.Runspaces.LocalPipeline').GetMethod(
        'GetExecutionContextFromTLS',
        [System.Reflection.BindingFlags]'Static,NonPublic'
    )
    $internalExecutionContext = $getExecutionContextFromTLS.Invoke(
        $null,
        [System.Reflection.BindingFlags]'Static, NonPublic',
        $null,
        $null,
        $psculture
    )

    if ($Native) {
        $argumentCompletersProperty = $internalExecutionContext.GetType().GetProperty(
            'NativeArgumentCompleters',
            [System.Reflection.BindingFlags]'NonPublic, Instance'
        )
    }
    else {
        $argumentCompletersProperty = $internalExecutionContext.GetType().GetProperty(
            'CustomArgumentCompleters',
            [System.Reflection.BindingFlags]'NonPublic, Instance'
        )
    }

    $argumentCompleters = $argumentCompletersProperty.GetGetMethod($true).Invoke(
        $internalExecutionContext,
        [System.Reflection.BindingFlags]'Instance, NonPublic, GetProperty',
        $null,
        @(),
        $psculture
    )
    foreach ($completer in $argumentCompleters.Keys) {
        $name, $parameter = $completer -split ':'

        if ($name -like $CommandName -and $parameter -like $ParameterName) {
            [PSCustomObject]@{
                CommandName   = $name
                ParameterName = $parameter
                Definition    = $argumentCompleters[$completer]
            }
        }
    }
}


function Get-DataFromMemoryStream {
    <#	.Description
	Get data from a System.IO.MemoryStream object (converting the byte array to some goodness).

	.Example
	Get-DataFromMemoryStream -InputObject $oMyMemoryStream
	Get the data from the given MemoryStream object

	.Example
	Invoke-LMFunction -FunctionName testEnvScr0 -Payload (@{queryStringParameters = @{param0 = "mehhh"}} | ConvertTo-Json -Depth 4) | Get-DataFromMemoryStream
	Invoke an Amazon Lambda function (which returns an object with a Payload property of type System.IO.MemoryStream), and get the data from the resultant Payload
#>
    [CmdletBinding()]
    param(
        ## Object(s) whose data to get
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("Payload")][System.IO.MemoryStream[]]$InputObject
    )

    process {
        $InputObject | Foreach-Object {
            $oThisInputObject = $_
            ## using ASCII encoding here; may need to using something else, like UTF8 or so, in the future
            [System.Text.Encoding]::ASCII.GetString($oThisInputObject.ToArray())
        } ## end Foreach-Object
    } ## end process
}


function Get-EffectiveFSAccessRule {
    <#	.Description
	Determine effective filesystem permissions for a user, and the ACE from which they come

	.Example
	Get-ADUser Mikey | Get-EffectiveFSAccessRule -Path \\some\remote\path\folder, \\some\remote\otherpath
	Get the effective permissions for this user and at the given remote path
#>
    [CmdletBinding()]
    param(
        ## Filesystem path (local or UNC) on which to check permissions; ex: "\\server.dom.com\path\tmp"
        [parameter(Mandatory = $true)][ValidateScript({ Test-Path $_ })][string[]]$Path,

        ## Identity (user -- not group) for which to check rights; ex: "userName" or "username@domain.com"
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName)][Alias("SamAccountName")][string[]]$Identity
    )

    begin {
        ## some arguments to use in getting Access Rules
        $bIncludeExplicit = $bIncludeInherited = $true
    }

    process {
        $Path | Foreach-Object {
            $strThisPath = $_

            $Identity | Foreach-Object {
                $strThisIdentity = $_
                ## requires minimum .NET Framework version v1.1 -- real high demands, here
                #   ref: https://msdn.microsoft.com/en-us/library/system.security.principal.windowsprincipal.aspx
                $oWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($strThisIdentity)

                ## using Get-Acl, get the AccessRules
                ## GetAccessRules():  System.Security.AccessControl.AuthorizationRuleCollection GetAccessRules(Boolean includeExplicit, Boolean includeInherited, Type targetType)
			(Get-Acl $strThisPath).GetAccessRules($bIncludeExplicit, $bIncludeInherited, [System.Security.Principal.NTAccount]) | Foreach-Object {
                    ## of type System.Security.AccessControl.FileSystemAccessRule
                    $oThisFilesystemAccessRule = $_
                    ## if WindowsPrincipal is in the role specified by this rule
                    if ($oWindowsPrincipal.IsInRole($oThisFilesystemAccessRule.IdentityReference)) {
                        Write-Verbose "Yes! '$strThisIdentity' is part of '$($oThisFilesystemAccessRule.IdentityReference.Value)'"
                        New-Object -Type PSObject -Property ([ordered]@{
                                Path              = $strThisPath
                                ThisIdentity      = $strThisIdentity
                                FileSystemRights  = $oThisFilesystemAccessRule.FileSystemRights
                                AccessControlType = $oThisFilesystemAccessRule.AccessControlType
                                IdentityReference = $oThisFilesystemAccessRule.IdentityReference
                                IsInherited       = $oThisFilesystemAccessRule.IsInherited
                                InheritanceFlags  = $oThisFilesystemAccessRule.InheritanceFlags
                                PropagationFlags  = $oThisFilesystemAccessRule.PropagationFlags
                            }) ## end new-object
                    } ## end if
                    else { Write-Verbose "$strThisIdentity' is not part of '$($oThisFilesystemAccessRule.IdentityReference.Value)'" } ## end else
                } ## end foreach-object
            }
        }
    } ## end process
}


function Get-FileEndOfLineType {
    <#	.Description
	Get the type of end of line ("EOL") character sequences present in the given file(s). If any CRLF, the EOL type for the file is considered "Windows", else, it is considered "Linux"

	.Example
	Get-Item c:\temp\somefile.sh | Get-FileEndOfLineType
	Get the EOL type for the given file
#>
    [CmdletBinding()]
    param(
        ## The path(s) to the file(s) whose EOL type to determine
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.IO.FileInfo[]]$Path
    )

    process {
        $Path | Foreach-Object {
            $oThisFile = $_
            $strEOLType = if (($strFileContents = Get-Content -Raw $oThisFile) | Select-String "`r`n") { "Windows" } else { if ($strFileContents | Select-String "`n") { "Linux" } else { Write-Verbose -Verbose "no EOL sequences detected at all in file '$($oThisFile.FullName)'. Is it more than one line long?" } }
            $oThisFile | Select-Object @{n = "EOLSequenceType"; e = { $strEOLType } }, LastWriteTime, Length, Name, FullName
        } ## end Foreach-Object
    } ## end process
}


function Get-ParameterSetInformation {
    <#  .Description
    Get the ParameterSet information for the given Command

    .Example
    Get-Command Get-Date | Get-ParameterSetInformation
    Get the parameters for all parameter sets of the command

    .Example
    Get-Command Get-Date | Get-ParameterSetInformation -GroupOutput
    Get the parameters for all parameter sets of the command, grouping output by ParameterSet and returning tabular data instead of the consumable Parameter objects themselves (handy for human consumption of the info)
#>
    [CmdletBinding()]
    param (
        ## The command(s) for which to get ParameterSet information
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Management.Automation.CommandInfo]$Command,

        ## Switch: return the table-ized and grouped Parameter objects? By default, returns just the Parameter objects for all ParameterSets, for further consumption/manipulation by the consumer
        [Switch]$GroupOutput
    )

    begin {
        ## the properties of the PowerShell Common parameters (for use in excluding Common params from param set info)
        $arrCommonParamsProperties = [System.Management.Automation.Internal.CommonParameters].GetProperties()
    }

    process {
        $Command | Foreach-Object {
            $oThisCommand = $_
            Write-Verbose "ParameterSet information for command '$($oThisCommand.Name)'"
            ## foreach parameterset, get the param info; most commonly in PS, we would just emit objects and do something interesting with them down the pipeline, but in this case, with needing all of the items together if doing tabular/grouped output, assigning to a variable for further consumption in this function
            $arrParamsInfo = $oThisCommand | Foreach-Object { $_.ParameterSets } -PipelineVariable oThisParamSet | Foreach-Object {
                $_.Parameters | Where-Object { $_.Name -NotIn $arrCommonParamsProperties.Name } | Select-Object -Property Name, ParameterType, IsMandatory, IsDynamic, @{n = "Position"; e = { if ($_.Position -lt 0) { "Named" } else { $_.Position } } }, @{n = "Alias"; e = { $_.Aliases } }, @{n = "ParameterSet"; e = { $oThisParamSet.Name } }, @{n = "IsDefaultParameterSet"; e = { $oThisParamSet.IsDefault } }, ValueFrom*
            }
            if ($GroupOutput) {
                $hshParamForFormatTable = @{
                    InputObject = $arrParamsInfo
                    AutoSize    = $true
                    GroupBy     = @{n = "ParameterSet"; e = { "{0}{1}" -f $_.ParameterSet, $(if ($_.IsDefaultParameterSet) { " (default)" }) } }
                    Property    = (Write-Output Name, ParameterType, IsMandatory, IsDynamic) + @{n = "VFP"; e = { $_.ValueFromPipeline } }, @{n = "VFPBPN"; e = { $_.ValueFromPipelineByPropertyName } } + (Write-Output Position, Alias, ParameterSet)
                }
                Format-Table @hshParamForFormatTable
            }
            else { $arrParamsInfo }
        } ## end Foreach-Object
    }
}


function Get-StringCasePermutation_Recursive {
    <#  .Description
    Get the character-case permutations of a string using recursion (all variations of lower/upper chars for the given string). Optimized to proceed if given character is a digit (instead of giving duplicate results)

    .Example
    Get-StringCasePermutation_Recursive hi
    Get all the character case permutations for the string 'hi'; the strings returned are hi, hI, Hi, and HI

    .Notes
    Recursion from https://www.reddit.com/r/PowerShell/comments/9ccubs/generate_every_upperlowercase_option_for_word/
#>
    [CmdletBinding()]
    param (
        ## String for which to get all of the character-case permutations
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$InputObject
    )

    begin {
        ## the internal function that does the actual doing
        function _Get-StrCasePerm_Recurs {
            param (
                ## String for which to get all of the character-case permutations
                [String]$String,
                ## The portion of the string already transformed, for use in the recursion
                $Prefix = @()
            )
            if ([String]::IsNullOrEmpty($String)) {
                return (-join $prefix)
            }
            else {
                Write-Verbose "String is '$String', Prefix is '$prefix'"
                ## if the next character is a digit, recurse on rest of string as is
                $(if ($String.Substring(0, 1) -match "\d") { "ToString" }
                    ## else, recurse on both lower and upper of next char
                    else {
                        ## for ToLower and ToUpper, add first char of string to Prefix, set string to "all but first char"
                        #    and, $PSCmdlet.MyInvocation.InvocationName is the name/path of the current script (used since this is an invokable script, instead of a function definition)
                        "ToUpper", "ToLower"
                    }) | Foreach-Object {
                    $strThisMethodToInvoke = $_
                    Write-Verbose -Message "Using String method '$_' for substring transformation"
                    _Get-StrCasePerm_Recurs -Prefix ("$prefix{0}" -f $String.Substring(0, 1).psobject.methods.Item($strThisMethodToInvoke).Invoke()) -String $String.Substring(1)
                }
            }
        }
    }

    process {
        _Get-StrCasePerm_Recurs -String $InputObject
    }
}


function Get-StringCasePermutation {
    <#  .Description
    Get the character-case permutations of a string (all variations of lower/upper chars for the given string)

    .Example
    Get-StringCasePermutation hi
    Get all the character case permutations for the string 'hi'; the strings returned are hi, hI, Hi, and HI
#>
    [CmdletBinding()]
    param (
        ## String for which to get all of the character-case permutations
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$InputObject
    )

    process {
        ## the lower- and uppercase variation of the input string
        $arrVariations = $InputObject.ToLower(), $InputObject.ToUpper()

        ## from me
        0..([math]::Pow(2, $InputObject.length) - 1) | ForEach-Object {
            $strThisIteration_inBinary = [Convert]::ToString($_, 2).PadLeft($InputObject.Length, '0')
            Write-Verbose "Using lower/upper case of strings as represented by binary '$strThisIteration_inBinary'"
            ## get the chars from the lower/upper case versions of the string at the given offset, and either lower or upper as indicated by 0 or 1 in the binary number
            -join (
                ## get the chars of the string, lower or upper as dictated by 0 or 1 as the iteration item character (the 0 or 1 at this index offset in the binary number string representation)
                0..($InputObject.Length - 1) | ForEach-Object {
                    $intThisIndexOffset = [int]($strThisIteration_inBinary[$_].ToString())
                    $arrVariations[$intThisIndexOffset][$_]
                    # $intThisIndexOffset
                }
            )
        }
    } ## end process
}


function Invoke-ActivatePythonVirtualenv {
    <#  .Description
	Function to activate a Python virtualenv, updated to work with UNC paths. Also creates a function, "Invoke-DeactivatePythonVirtualenv" in the current PowerShell session for deactivating the Python virtualenv

	.Example
	Invoke-ActivatePythonVirtualenv -Path C:\temp\pyVirtualEnvs\myVirtualEnv0
	Activate the virtual env that resides at the given path. Deactivate the virtual env via Invoke-DeactivatePythonVirtualenv

	.Example
	Invoke-ActivatePythonVirtualenv -Path \\path\to\virtualenvs\someCoolVirtualenv
	Activate the virtual env that resides at the given UNC path. Deactivate the virtual env via Invoke-DeactivatePythonVirtualenv

	.Notes
	This is originally from a default Python virtualenv Scripts directory
#>

    param(
        ## Path to the virtualenv folder to "activate"
        [parameter(Mandatory = $true)][String]$Path
    ) ## end param

    process {
        ## name of function to make for deactivating python virtualenv
        $strDeactivate_fnName = "Invoke-DeactivatePythonVirtualenv"
        ## make a new function that can be used to "deactivate" the virtualenv
        function global:Invoke-DeactivatePythonVirtualenv ( [switch] $NonDestructive ) {
            if (Test-Path variable:\_OLD_VIRTUAL_PATH) {
                $env:PATH = $variable:_OLD_VIRTUAL_PATH
                Remove-Variable "_OLD_VIRTUAL_PATH" -Scope global
            } ## end if

            if (Test-Path function:\_old_virtual_prompt) {
                $function:prompt = $function:_old_virtual_prompt
                Remove-Item function:\_old_virtual_prompt
            } ## end if

            if ($env:VIRTUAL_ENV) { Remove-Item env:\VIRTUAL_ENV -ErrorAction SilentlyContinue } ## end if

            # Self destruct!
            if (-not $NonDestructive) { Remove-Item function:\Invoke-DeactivatePythonVirtualenv }
        } ## end fn

        # unset irrelevant variables
        & global:$strDeactivate_fnName -NonDestructive

        ## set environment item
        $env:VIRTUAL_ENV = $Path

        $global:_OLD_VIRTUAL_PATH = $env:PATH
        $env:PATH = "$env:VIRTUAL_ENV/Scripts;" + $env:PATH
        if (! $env:VIRTUAL_ENV_DISABLE_PROMPT) {
            function global:_old_virtual_prompt { "" }
            $function:_old_virtual_prompt = $function:prompt
            function global:prompt {
                # Add a prefix to the current prompt
                Write-Host "($(split-path $env:VIRTUAL_ENV -leaf)) " -nonewline
                & $function:_old_virtual_prompt
            } ## end fn
        } ## end if

        Write-Verbose -Verbose "Virtualenv 'activated'. Use function '$strDeactivate_fnName' to deactivate this virtualenv"
    } ## end process
}


function New-CertificateSigningRequest {
    <#	.Description
	Make a new X509 Certificate Signing Request with given properties. Uses openssl binary for CSR/key generation

	.Notes
	Based on code by the vScorpion from Feb 2016

	.Example
	New-CertificateSigningRequest -SubjectHost myserver.dom.com -HostnameAlias myalias0.dom.com, anotheraliasforthisserver.dom.com -Organization MyCompany -Country US -State Indiana -City Indianapolis -OrganizationalUnit MyTeamName -EmailAddress mygroup@dom.com
	Create a new CSR  and corresponding private key in c:\temp\newCSR-myserver.dom.com-<someGuid>\ with the given attributes

	.Example
	Import-Csv c:\temp\myNewCsrItems.csv | New-CertificateSigningRequest -OpenSSLFilespec \\server.dom.com\share\openssl\openssl.exe
	For every row in the given CSV, create a new CSR for each subjecthost in c:\temp\newCSR-<subjecthostname>-<someGuid>\ with the given attributes
#>
    [CmdLetBinding()]

    Param(
        ## Credential whose password will be set for the private key file (to secure the private key file; this is the password to use when later consuming the private key file)
        [System.Management.Automation.PSCredential]$Credential = (Get-Credential -Message "Password to set on private key file" -User "<no username needed>"),

        ## The Common Name ("CN") value in the subject of the CSR. This is often the FQDN of the machine. If none specified, will try to use the FQDN of the local machine computername
        [parameter(ValueFromPipelineByPropertyName = $true)][String]$SubjectHost = $env:computername,

        ## DNS Alias FQDN(s) for use in the new certificate in the Subject Alternative Name field
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][String[]]$HostnameAlias,

        ## Organization name to use (like company name, say)
        [parameter(ValueFromPipelineByPropertyName = $true)][String]$Organization = "Eli Lilly and Company",

        ## Two-letter country code
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][ValidateLength(2, 2)][String]$Country,

        ## State (fully spelled out)
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][String]$State,

        ## City
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][String]$City,

        ## Organizational unit (say, like, department or team name)
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][String]$OrganizationalUnit,

        ## Email address of point of contact. Like, the name of a mail-enabled AD group or a mailing list whose members would be responsible for the eventual certificate
        [parameter(ValueFromPipelineByPropertyName = $true)][String]$EmailAddress,

        ## Path to openssl.exe for use in generating CSR (defaults to "C:\Program Files\OpenSSL\bin\openssl.exe")
        [ValidateScript({ Test-Path $_ })][String]$OpenSSLFilespec = "C:\Program Files\OpenSSL\bin\openssl.exe"
    )

    process {
        $strBaseOutputDir = "c:\temp\newCSR-{0}-{1}" -f $SubjectHost, [System.Guid]::NewGuid().Guid
        Try {
            if (-not (Test-Path "$strBaseOutputDir")) { $oTmp = mkdir "$strBaseOutputDir" }
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
        $strSubjectHostToUse = if ($PSBoundParameters.ContainsKey("SubjectHost")) { $SubjectHost } else { ([System.Net.DNS]::GetHostByName($SubjectHost) | Select-Object -Expand HostName).ToLower() }

        ## make, for the hostname and aliases, a string like "DNS:hostname.dom.com, DNS:alias0.dom.com, DNS:alias1.dom.com"
        $strHostnameAndAliases_commaJoined = ($strSubjectHostToUse, $HostnameAlias | Foreach-Object { $_ } | Where-Object { -not [String]::IsNullOrEmpty($_) } | Foreach-Object { "DNS:$_" }) -join ", "
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
}


function New-MarkdownCommandExample {
    <#	.Description
	Create Markdown from commands' examples. Useful for, say, an examples.md summary file in the docs for a PowerShell module's repository. And, might get called as a part of a new module "build", so as to have current examples in the module's docs

	.Example
	Get-Command Get-Date | New-MarkdownCommandExample
	Create Markdown that displays the examples for the given command

	.Example
	Get-Command -Module MyCoolModule | New-MarkdownCommandExample | Out-File c:\temp\coolstuff.md -Encoding ASCII
	Create Markdown that displays the examples for the commands from the given module
#>
    [CmdletBinding()]
    param(
        ## Command(s) for which to write Markdown'd example from said commands' help
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][System.Management.Automation.CommandInfo[]]$Command,

        ## Title string to include in the Markdown output
        [String]$Title = "### Examples for some cool PowerShell module for doing interesting things"
    )

    begin {
        function New-CodeBlockFromExample {
            <#  .Description
			Internal function to make the contents of a Markdown code block, based on the PowerShell version in which the function is running.
			For the given example, make string like:
			## example's comment line 0 here
			## example's comment line 1 here
			## example's comment line ... here
			example's actual code here

			.Example
			Get-Help -Name Get-Date -Example | New-CodeBlockFromExample

			.Notes
			PowerShell versions' MamlCommandHelpInfo#examples objects differ between Windows PowerShell (PS v1-5) and PowerShell (v6+). Thus, this function, so as to be able to consistently render Markdown examples, taking said differences into account.
		#>
            param (
                ## The .example property's value from a MamlCommandHelpInfo#examples object, for which to return a Markdown string of an example
                [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][System.Management.Automation.PSObject[]]$Example
            )

            process {
                $Example | ForEach-Object {
                    ## note:  joining with newline here to make single string, so as to then be able to join multiple examples with two new lines later
                    ## if this is running in Windows PowerShell (version of less than v6)
                    $(if ($PSVersionTable.PSVersion -lt [System.Version]"6.0") {
                            $_.remarks.Text | Where-Object { -not [System.String]::IsNullOrEmpty($_) } | Foreach-Object { $_.Split("`n") } | Foreach-Object { "## $_" }
                            $_.code
                        }
                        ## else, it's PowerShell (v6+)
                        else {
                            $arrCodeLines = $_.code | Where-Object { -not [System.String]::IsNullOrEmpty($_) } | Foreach-Object { $_.Split("`n") }
                            $arrCodeLines | Select-Object -Skip 1 | Foreach-Object { "## $_" }
                            $arrCodeLines | Select-Object -First 1
                        }) -join "`n"
                }
            }
        } ## end function

        ## Return the title string
        $Title
        ## return some strings for some CSS style to use word-wrap in rendered code blocks
        @'
<style>
.force-word-wrap pre code {
	white-space: break-spaces;
	word-wrap: break-word;
}
</style>
<div class="force-word-wrap">
'@
    }

    process {
        $Command | Foreach-Object {
            $oThisCommand = $_
            ## get the help (with examples) for this command
            $oHelp_ThisCommand = Get-Help -Examples -Name $(if ($oThisCommand.Name -like "*.ps1" -or $oThisCommand.CommandType -eq "ExternalScript") { $oThisCommand.Source } else { $oThisCommand.Name })
            ## make a string that has the command name and description followed by a code block with example(s)
            "`n#### ``{0}``: {1}" -f `
                $oThisCommand.Name,
            $oHelp_ThisCommand.Description.Text
            ## "open" the code-fence in Markdown
            '```PowerShell'
            ## make a string with the example description(s) and example code(s) for this command
            if (($oHelp_ThisCommand.examples | Measure-Object).Count -gt 0) { ($oHelp_ThisCommand.examples | New-CodeBlockFromExample) -join "`n`n" } else { "## no examples for command '$($oThisCommand.Name)'" }

            ## "close" the code-fence in Markdown
            '```'
        } ## end Foreach-Object
    }

    end {
        ## close the HTML div that is enabling word-wrap; may actually need whitespace before closing div tag -- unclear
        @'

</div>
'@
    }
}


function Optimize-PSReadlineHistory {
    <#
.SYNOPSIS
    Optimizes your PSReadline history save file.
.DESCRIPTION
    Optimizes your PSReadline history save file by removing duplicate
    entries and optionally removing commands that are not longer than
    a minimum length
.EXAMPLE
    C:\PS> Optimize-PSReadlineHistory
    Removes all the duplicate commands.
.EXAMPLE
    C:\PS> Optimize-PSReadlineHistory -MinimumCommandLength 3
    Removes all the duplicate commands and any commands less than 3 characters in length.
.NOTES
    May 15, 2017 - fix bug in handling of multiline commands.
    From @rkeithhill gist at https://gist.github.com/rkeithhill/4099bfd8420eed0e6dbc
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Path to the PSReadline history file to optimize.
        [Parameter()]
        [string]
        $HistoryPath,

        # If specified, any commands less than $MinimumCommandLength will be removed from the history file.
        [Parameter()]
        [int]
        $MinimumCommandLength = 1,

        # If specified, removes leading whitespace from the beginning of the command or the beginning of
        # the first line of multiline commands.
        [Parameter()]
        [switch]
        $TrimLeadingWhitespace,

        # If specified, the check for other PowerShell processes is skipped. You can do this when you are operating on a
        # copy of PSReadline history file.
        [Parameter()]
        [switch]
        $SkipRunningPowerShellCheck
    )

    if (!$SkipRunningPowerShellCheck -and ((Get-PSHostProcessInfo | Where-Object ProcessId -ne $pid).Count -gt 0)) {
        throw "This command can only be run when other PowerShell hosts are not running. Other hosts may have PSReadline loaded."
    }

    if (!$HistoryPath) {
        if (Get-Module PSReadline -ErrorAction SilentlyContinue) {
            $HistoryPath = (Get-PSReadlineOption).HistorySavePath
        }
        else {
            throw "You must provide a value for the HistoryPath parameter."
        }

        Remove-Module PSReadline
        if (Get-Module PSReadline -ErrorAction SilentlyContinue) {
            throw "Failed to remove the PSReadline module. This command can only be run when PSReadline is not loaded."
        }
    }

    if (![System.IO.Path]::IsPathRooted($HistoryPath)) {
        $HistoryPath = Convert-Path $HistoryPath
    }

    $history = Get-Content -LiteralPath $HistoryPath -Encoding UTF8
    $origFileSize = (Get-Item -LiteralPath $HistoryPath).Length

    $strBld = New-Object System.Text.StringBuilder
    $commands = New-Object System.Collections.Generic.List[string] -ArgumentList $history.Length
    $uniqCommands = New-Object System.Collections.Generic.List[string] -ArgumentList $history.Length

    $comparer = if ($IsLinux) { [System.StringComparer]::Ordinal } else { [System.StringComparer]::OrdinalIgnoreCase }
    $uniqCommandSet = New-Object System.Collections.Generic.HashSet[string] -ArgumentList $comparer

    $numCommands = 0
    $numMinLengthCommandsRemoved = 0
    $numMultilineCommands = 0

    $whatIfMsg = if ($PSBoundParameters['WhatIf']) { 'WHAT IF: ' } else { '' }
    $activityMsg = "${whatIfMsg}Optimizing $HistoryPath"

    # Process multiline commands in the history file contents
    $Ten
    for ($i = 0; $i -lt $history.Count; $i++) {
        $percentComplete = [int](33 * (($i + 1) / $history.Count))
        if ($percentComplete % 10 -eq 0) {
            Write-Progress -Activity $activityMsg -Status "Processing multiline commands" -PercentComplete $percentComplete
        }

        $line = $history[$i].TrimEnd()

        if ($line[-1] -eq '`') {
            $null = $strBld.Append($line + [System.Environment]::NewLine)
        }
        else {
            $numCommands++

            if ($strBld.Length -gt 0) {
                $null = $strBld.Append($line)
                $commandStr = $strBld.ToString()
                $null = $strBld.Clear()
                $numMultilineCommands++
            }
            else {
                $commandStr = $line
            }

            # Trim leading whitesapce if requested
            if ($TrimLeadingWhitespace) {
                $commandStr = $commandStr.TrimStart()
            }

            # This is where we filter out commands that are less than the specified minimum length
            if ($commandStr.Length -ge $MinimumCommandLength) {
                $null = $commands.Add($commandStr)
            }
            else {
                $numMinLengthCommandsRemoved++
            }
        }
    }

    # Walk the history file backwards so we preserve the most recent duplicate command
    for ($i = $commands.Count - 1; $i -ge 0 ; $i--) {
        $percentComplete = [int](33 + (33 * ($history.Count - 1 - $i) / $history.Count))
        if ($percentComplete % 10 -eq 0) {
            Write-Progress -Activity $activityMsg -Status "Removing duplicate commands" -PercentComplete $percentComplete
        }

        # This is where we check for a duplicate command
        $commandStr = $commands[$i]
        if (!$uniqCommandSet.Contains($commandStr)) {
            $null = $uniqCommandSet.Add($commandStr)
            $null = $uniqCommands.Add($commandStr)
        }
    }

    $uniqCommandSet = $null
    $numUniqCommands = $uniqCommands.Count

    if ($PSCmdlet.ShouldProcess($HistoryPath, "Optimize")) {
        Copy-Item -LiteralPath $HistoryPath "${HistoryPath}.bak"
        Remove-Item -LiteralPath $HistoryPath

        $utf8NoBom = [System.Text.UTF8Encoding]::new($false, $true)
        $writer = [System.IO.StreamWriter]::new($HistoryPath, $false, $utf8NoBom)
        try {
            for ($i = $uniqCommands.Count - 1; $i -ge 0 ; $i--) {
                $percentComplete = [int](66 + (34 * ($uniqCommands.Count - 1 - $i) / $uniqCommands.Count))
                if ($percentComplete % 25 -eq 0) {
                    Write-Progress -Activity $activityMsg -Status "Saving optimized history" -PercentComplete $percentComplete
                }

                $line = $uniqCommands[$i]
                $writer.WriteLine($line)
            }
        }
        finally {
            if ($writer) { $writer.Dispose() }
        }

        $newFileSize = (Get-Item -LiteralPath $HistoryPath).Length
    }
    else {
        # Estimate the resulting file size for -WhatIf
        $newFileSize = 0
        foreach ($command in $uniqCommands) {
            $newFileSize += $command.Length + [System.Environment]::NewLine.Length
        }
    }

    $strBld = $commands = $uniqCommands = $null

    Write-Verbose "Removed $($numCommands - $numUniqCommands) duplicate commands."
    if ($MinimumCommandLength -gt 0) {
        Write-Verbose "Removed $numMinLengthCommandsRemoved commands with less than $MinimumCommandLength characters."
    }
    Write-Verbose "Number of commands reduced from $numCommands to $numUniqCommands."
    Write-Verbose "Number of multiline commands $numMultilineCommands."
    Write-Verbose ("History file size reduced from {0:F1} KB to {1:F1} KB." -f ($origFileSize / 1KB), ($newFileSize / 1KB))

    Write-Progress -Activity $activityMsg -Completed
}


function Start-Demo {
    <#  .DESCRIPTION
    This script completely transforms the experience of giving a demo, allowing you to focus on your messages instead of typing.

    It is REAL in the sense that the commands REALLY run, the script just eliminates your typing.

    Demo controls (type these at the end of any displayed line of code):
    ?:  Display Start-Demo help
    q:  Quit the demo
    !:  Suspend the demo, entering a nested PowerShell prompt (from which you can run any desired commands)
    #x:  Go to line/command # X in the demo file
    fx:  Find commands using string "X"
    t:  Time check
    s:  Skip this line (do not execute it, and proceed to the next line in the demo)
    d:  Dump the demo

    .Notes
    This script was originally published by Jeffrey Snover at https://blogs.msdn.microsoft.com/powershell/2007/03/03/start-demo-help-doing-demos-using-powershell/
    These upates are based on script version 1.0.1
    Added:
        - comment-based help, so one can now Get-Help on Start-Demo and have reasonable help
        - comment coloring -- comments in demo file are now written to console in comment-y color
        - tidbit to return window TitleBar to original text (that it was before starting demo)
        - handling of blank lines from demo file (now displays them and just continues on to next line)
        - adjusted -Command to be the command line number, so that when referring to the demo txt file, the correlation is there between command and line number (for illustration purposes when discussing with audience)
        - other various enhancements
#>
    param(
        ## Path to the script file which to demo
        [parameter(Position = 0)][ValidateScript({ Test-Path -Path $_ })][string]$File = ".\demo.txt",

        ## Command line number on which to begin the demo
        [int]$Command = 1,

        ## Prompt string to use. By default, prompt is written as "[<lineNumber>] PS>", like "[51] PS>". A space character will be appended to the end of this prompt string.
        [string]$Prompt
    )

    begin {
        ## grab the current WindowTitle, to use to return this session's WindowTitle back to original after the demo completes
        $strOriginalWindowTitle = $Host.UI.RawUI.WindowTitle
        ## use custom prompt?
        $bUseCustomPrompt = $PSBoundParameters.ContainsKey("Prompt")
    } ## end begin

    process {
        Clear-Host

        try {
            $_lines = Get-Content $file
            $_starttime = [DateTime]::now
            Write-Host -ForeGroundColor Yellow "<Demo [$file] Started>"

            # We use a FOR and an INDEX ($_i) instead of a FOREACH because
            # it is possible to start at a different location and/or jump
            # around in the order.
            for ($_i = $Command - 1; $_i -lt $_lines.count; $_i++) {
                ## the line number from the file on which this iteration currently is operating (1-based index, so, $_i + 1) -- used for things like line number display in the simulated prompt
                $strThisLineNumber = $_i + 1
                ## write the prompt
                $_LinePrompt = if ($bUseCustomPrompt) { "`n$Prompt " } else { "`n[$strThisLineNumber] PS> " }
                Write-Host -NoNewLine $_LinePrompt
                ## write the simulated command after the prompt
                $_SimulatedCommand = $_Lines[$_i]
                $hshParamForWritingSimulatedCommand = @{NoNewLine = $true; Object = $_SimulatedCommand }
                if ($_SimulatedCommand.Trim().StartsWith("#")) { $hshParamForWritingSimulatedCommand["ForeGroundColor"] = "Green" }
                Write-Host @hshParamForWritingSimulatedCommand

                # Put the current command in the Window Title along with the demo duration
                $_Duration = [DateTime]::Now - $_StartTime
                $Host.UI.RawUI.WindowTitle = "[{0}m {1}s]        {2}" -f [int]$_Duration.TotalMinutes, [int]$_Duration.Seconds, $($_Lines[$_i])
                if (([System.String]::IsNullOrEmpty($_SimulatedCommand)) -or $_SimulatedCommand.Trim().StartsWith("#")) {
                    continue
                } ## end if
                $_input = [System.Console]::ReadLine()
                switch ($_input) {
                    "?" {
                        Write-Host -ForeGroundColor Yellow "Running demo: $file`n(q) Quit  (!) Suspend  (#x) Goto Command #x  (fx) Find cmds using X`n(t) Timecheck  (s) Skip line  (d) Dump demo"
                        $_i -= 1
                    }
                    "q" {
                        Write-Host -ForeGroundColor Yellow "<Quit demo>"
                        return
                    }
                    "s" { Write-Host -ForeGroundColor Yellow "<Skipping command from line $strThisLineNumber>" }
                    "d" {
                        for ($_ni = 0; $_ni -lt $_lines.Count; $_ni++) {
                            if ($_i -eq $_ni) { Write-Host -ForeGroundColor Red ("*" * 80) }
                            Write-Host -ForeGroundColor Yellow ("[{0,2}] {1}" -f $_ni, $_lines[$_ni])
                        } ## end for
                        $_i -= 1
                    }
                    "t" {
                        $_Duration = [DateTime]::Now - $_StartTime
                        Write-Host -ForeGroundColor Yellow $("Demo has run {0} Minutes and {1} Seconds" -f [int]$_Duration.TotalMinutes, [int]$_Duration.Seconds)
                        $_i -= 1
                    }
                    { $_.StartsWith("f") } {
                        for ($_ni = 0; $_ni -lt $_lines.Count; $_ni++) {
                            if ($_lines[$_ni] -match $_.SubString(1)) { Write-Host -ForeGroundColor Yellow ("[{0,2}] {1}" -f $_ni, $_lines[$_ni]) }
                        } ## end for
                        $_i -= 1
                    }
                    { $_.StartsWith("!") } {
                        if ($_.Length -eq 1) {
                            Write-Host -ForeGroundColor Yellow "<Suspended demo - type ?Exit? to resume>"
                            $host.EnterNestedPrompt()
                        }
                        else {
                            trap [System.Exception] { Write-Error $_; continue; }
                            Invoke-Expression $($_.SubString(1) + "| out-host")
                        } ## end else
                        $_i -= 1
                    }
                    { $_ -match "^#\d+$" } {
                        ## "- 2" to make up for zero-based index and 1-based line numbers in a file
                        $_i = [int]($_.SubString(1)) - 2
                        continue
                    }
                    default {
                        trap [System.Exception] { Write-Error $_; continue; }
                        $strItemToInvoke = $_lines[$_i]
                        ## if caller appended some tidbit, prefixed with a space (as in, attempted to edit the line), add their edit to the item to invoke
                        if ($_input -match "^ .+") { $strItemToInvoke += $_input }
                        ## if this is not an assignment operation, append " | Out-Default" to the command
                        if ($strItemToInvoke -notmatch "=") { $strItemToInvoke = "$strItemToInvoke | Out-Default" }
                        Invoke-Expression $strItemToInvoke
                        $_Duration = [DateTime]::Now - $_StartTime
                        $Host.UI.RawUI.WindowTitle = "[{0}m {1}s]        {2}" -f [int]$_Duration.TotalMinutes, [int]$_Duration.Seconds, $($_Lines[$_i])
                        [System.Console]::ReadLine()
                    }
                } ## end switch
            } ## end for
        } ## end try
        catch { $_ }
        finally {
            $_Duration = [DateTime]::Now - $_StartTime
            Write-Host -ForeGroundColor Yellow $("`n<Demo Complete {0} Minute{1} and {2} Second{3}>" -f [int]$_Duration.TotalMinutes, $(if ([int]$_Duration.TotalMinutes -ne 1) { "s" }), [int]$_Duration.Seconds, $(if ([int]$_Duration.Seconds -ne 1) { "s" }))
            Write-Host -ForeGroundColor Yellow "Done at $([DateTime]::now)"
            $Host.UI.RawUI.WindowTitle = $strOriginalWindowTitle
        } ## end finally
    } ## end process

    <#PSScriptInfo

.VERSION 1.0.2

.GUID ae18572c-2e51-4c38-86e4-2e8fe9c8869f

.AUTHOR Jeffrey Snover originally, updated to v1.0.2 by Matt Boren (not associated with Microsoft)

.COMPANYNAME Microsoft Corporation

.COPYRIGHT (C) Microsoft Corporation. All rights reserved.

.TAGS

.LICENSEURI

.PROJECTURI
https://blogs.msdn.microsoft.com/powershell/2007/03/03/start-demo-help-doing-demos-using-powershell/

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
 - You can specify which file you want to demo (it defaults to ".\demo.txt")
 - You can specify which command to start with (it defaults to 0)
 - It shows you the command (both at the prompt and in the Window Title [for the folks at the back of the room) and waits for input. If your input is <CR>, it runs the command.
 - You can provide other input and it will do other actions. You can:
 - Ask for help using "?"
    ? Quit at any point
    ? Dump the list of commands in the demo. It produces a red line above your current point in the demo
    ? Run another command or Suspend the demo and enter into a nested prompt to explore a topic
    ? Go to a specified command in the demo
    ? Find all the commands in the demo using a regular expression
    ? Check your time. It displays how many minutes and seconds since the start of the demo. This information is also displayed in the Window title on an ongoing basis.
#>
}


function Test-ArgumentCompleter {
    <# .Description
    Invoke the registered parameter completer for a specified command, if any, to enable testing of a completer

    .Example
    Test-ArgumentCompleter -CommandName Get-VM -ParameterName Name -WordToComplete des
    Return what would be completed if Get-VM -Name des<Tab> was typed in PowerShell

    .Notes
    Completely based on @lzybkr's Test-ArgumentCompleter function at https://github.com/lzybkr/TabExpansionPlusPlus/blob/master/TabExpansionPlusPlus.psm1, adopted for use outside of TabExpansionPlusPluss
#>


    [CmdletBinding()]
    param(
        ## The command whose argument completer to test
        [Parameter(Mandatory, Position = 1)][string]$CommandName,

        ## The parameter name to test for the given command
        [Parameter(Mandatory, Position = 2)][string]$ParameterName,

        ## The word to "tab-complete" in this test
        [Parameter(Position = 3)][string]$WordToComplete,

        ## The command AST to use
        [System.Management.Automation.Language.CommandAst]$commandAst,

        ## Any "fake" bound parameter to use for the testing
        [Hashtable]$FakeBoundParameters = @{}
    )

    begin {
        $strGetArgCompleterCommand = "PS.Utils\Get-ArgumentCompleter"
    }
    process {
        ## get the completer (if any) for this command and parameter
        $completer = & $strGetArgCompleterCommand -CommandName $CommandName -ParameterName $ParameterName
        if ($null -ne $completer) {
            ## if there is a completer registered, invoke its definition with some params
            & $completer.Definition $CommandName $ParameterName $WordToComplete $commandAst $FakeBoundParameters
        }
        else { throw "No argument completer registered for command '$CommandName' and paramater '$ParameterName'" }
    }
}


