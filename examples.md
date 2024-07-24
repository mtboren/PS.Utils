## Examples for `PS.Utils` PowerShell script collection for doing interesting things
<style>
.force-word-wrap pre code {
	white-space: break-spaces;
	word-wrap: break-word;
}
</style>
<div class="force-word-wrap">

#### `ConvertFrom-UnattendEncodedPassword.ps1`: From a PSCredential object (using the password value), make an encoded password string suitable for use in the AdministratorPassword portion of an unattend.xml Wndows setup answer file
```PowerShell
## Using the given encoded password string (say, from an unattend.xml Windows setup answer file), create a credential object whose password value is that which is encoded in the string
"cwB3AGUAZQB0AFAAYQBzAHMAdwBvAHIAZABBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAFAAYQBzAHMAdwBvAHIAZAA=" | ConvertFrom-UnattendEncodedPassword.ps1 -UsageXMLNode AdministratorPassword
```

#### `ConvertTo-UnattendEncodedPassword.ps1`: From a PSCredential object (using the password value), make an encoded password string suitable for use in the AdministratorPassword portion of an unattend.xml Wndows setup answer file
```PowerShell
## Using the given credential, convert the password property to an encoded string suitable for use in an unattend.xml Windows setup answer file
Get-Credential administrator | ConvertTo-UnattendEncodedPassword.ps1 -UsageXMLNode AdministratorPassword
```

#### `Get-ArgumentCompleter.ps1`: Get custom argument completers registered in the current session.

By default Get-ArgumentCompleter lists all of the completers registered in the session.
```PowerShell
## Get all of the argument completers for PowerShell commands in the current session.
Get-ArgumentCompleter

## Get all of the argument completers used by the Invoke-ScriptAnalyzer command.
Get-ArgumentCompleter -CommandName Invoke-ScriptAnalyzer

## Get all of the argument completers for native commands in the current session.
Get-ArgumentCompleter -Native
```

#### `Get-DataFromMemoryStream.ps1`: Get data from a System.IO.MemoryStream object (converting the byte array to some goodness).
```PowerShell
## Get the data from the given MemoryStream object
Get-DataFromMemoryStream.ps1 -InputObject $oMyMemoryStream

## Invoke an Amazon Lambda function (which returns an object with a Payload property of type System.IO.MemoryStream), and get the data from the resultant Payload
Invoke-LMFunction -FunctionName testEnvScr0 -Payload (@{queryStringParameters = @{param0 = "mehhh"}} | ConvertTo-Json -Depth 4) | Get-DataFromMemoryStream.ps1
```

#### `Get-EffectiveFSAccessRule.ps1`: Determine effective filesystem permissions for a user, and the ACE from which they come
```PowerShell
## Get the effective permissions for this user and at the given remote path
Get-ADUser Mikey | Get-EffectiveFSAccessRule.ps1 -Path \\some\remote\path\folder, \\some\remote\otherpath
```

#### `Get-FileEndOfLineType.ps1`: Get the type of end of line ("EOL") character sequences present in the given file(s). If any CRLF, the EOL type for the file is considered "Windows", else, it is considered "Linux"
```PowerShell
## Get the EOL type for the given file
Get-Item c:\temp\somefile.sh | Get-FileEndOfLineType.ps1
```

#### `Get-ParameterSetInformation.ps1`: Get the ParameterSet information for the given Command
```PowerShell
## Get the parameters for all parameter sets of the command
Get-Command Get-Date | Get-ParameterSetInformation.ps1

## Get the parameters for all parameter sets of the command, grouping output by ParameterSet and returning tabular data instead of the consumable Parameter objects themselves (handy for human consumption of the info)
Get-Command Get-Date | Get-ParameterSetInformation.ps1 -GroupOutput
```

#### `Get-ResourceUtilization.ps1`: Get resource utilization on given Windows machine(s), like CPU and Memory consumption
```PowerShell
## Get resource utilization for localhost
Get-ResourceUtilization.ps1

## Get resource utilization for the given computers
Get-ResourceUtilization.ps1 -ComputerName puter0, puter1

## Get resource utilization for the given computers using the specified credentials
Get-ResourceUtilization.ps1 -ComputerName puter0, puter1 -Credential $myCred
```

#### `Get-StringCasePermutation_Recursive.ps1`: Get the character-case permutations of a string using recursion (all variations of lower/upper chars for the given string). Optimized to proceed if given character is a digit (instead of giving duplicate results)
```PowerShell
## Get all the character case permutations for the string 'hi'; the strings returned are hi, hI, Hi, and HI
Get-StringCasePermutation_Recursive hi
```

#### `Get-StringCasePermutation.ps1`: Get the character-case permutations of a string (all variations of lower/upper chars for the given string)
```PowerShell
## Get all the character case permutations for the string 'hi'; the strings returned are hi, hI, Hi, and HI
Get-StringCasePermutation hi
```

#### `Get-Weather.ps1`: Get the weather for some location
```PowerShell
## Get the weather for the default location
Get-Weather
```

#### `Invoke-ActivatePythonVirtualenv.ps1`: Function to activate a Python virtualenv, updated to work with UNC paths. Also creates a function, "Invoke-DeactivatePythonVirtualenv" in the current PowerShell session for deactivating the Python virtualenv
```PowerShell
## Activate the virtual env that resides at the given path. Deactivate the virtual env via Invoke-DeactivatePythonVirtualenv
Invoke-ActivatePythonVirtualenv.ps1 -Path C:\temp\pyVirtualEnvs\myVirtualEnv0

## Activate the virtual env that resides at the given UNC path. Deactivate the virtual env via Invoke-DeactivatePythonVirtualenv
Invoke-ActivatePythonVirtualenv.ps1 -Path \\path\to\virtualenvs\someCoolVirtualenv
```

#### `New-CertificateSigningRequest.ps1`: Make a new X509 Certificate Signing Request with given properties. Uses openssl binary for CSR/key generation
```PowerShell
## Create a new CSR  and corresponding private key in c:\temp\newCSR-myserver.dom.com-<someGuid>\ with the given attributes
New-CertificateSigningRequest.ps1 -SubjectHost myserver.dom.com -HostnameAlias myalias0.dom.com, anotheraliasforthisserver.dom.com -Organization MyCompany -Country US -State Indiana -City Indianapolis -OrganizationalUnit MyTeamName -EmailAddress mygroup@dom.com

## For every row in the given CSV, create a new CSR for each subjecthost in c:\temp\newCSR-<subjecthostname>-<someGuid>\ with the given attributes
Import-Csv c:\temp\myNewCsrItems.csv | New-CertificateSigningRequest.ps1 -OpenSSLFilespec \\server.dom.com\share\openssl\openssl.exe
```

#### `New-MarkdownCommandExample.ps1`: Create Markdown from commands' examples. Useful for, say, an examples.md summary file in the docs for a PowerShell module's repository. And, might get called as a part of a new module "build", so as to have current examples in the module's docs
```PowerShell
## Create Markdown that displays the examples for the given command
Get-Command Get-Date | New-MarkdownCommandExample.ps1

## Create Markdown that displays the examples for the commands from the given module
Get-Command -Module MyCoolModule | New-MarkdownCommandExample.ps1 | Out-File c:\temp\coolstuff.md -Encoding ASCII
```

#### `Optimize-PSReadlineHistory.ps1`: Optimizes your PSReadline history save file by removing duplicate
entries and optionally removing commands that are not longer than
a minimum length
```PowerShell
## Removes all the duplicate commands.
Optimize-PSReadlineHistory

## Removes all the duplicate commands and any commands less than 3 characters in length.
Optimize-PSReadlineHistory -MinimumCommandLength 3
```

#### `Start-Demo.ps1`: This script completely transforms the experience of giving a demo, allowing you to focus on your messages instead of typing.

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
```PowerShell
## no examples for command 'Start-Demo.ps1'
```

#### `Test-ArgumentCompleter.ps1`: Invoke the registered parameter completer for a specified command, if any, to enable testing of a completer
```PowerShell
## Return what would be completed if Get-VM -Name des<Tab> was typed in PowerShell
Test-ArgumentCompleter -CommandName Get-VM -ParameterName Name -WordToComplete des
```

</div>
