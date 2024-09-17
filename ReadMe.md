# `PS.Utils` -- some useful things
A PowerShell module with various utilities, some from other places in the world, some original. This is a consolidation for ease of distribution/consumption some of those various, one-off functions/scripts that are not already themselves part of a module.

Contents:
- [General Info](#general-info)
- [Getting Started](#getting-started)
- [Examples](#examples)

## General Info

|  Item  | Description | Origin |
|--------|-------------|--------|
| `Get-ArgumentCompleter` | get the argument completers that are registered in the current PowerShell session; super minor update to the [awesome function](https://gist.github.com/indented-automation/26c637fb530c4b168e62c72582534f5b) | [@indented-automation](https://github.com/indented-automation)
| `Get-DataFromMemoryStream` | get data from a `System.IO.MemoryStream` object (converting the byte array to some goodness); like, the MemoryStream returned from an AWS Lambda function invocation | [@mtboren](https://github.com/mtboren)
| `Get-EffectiveFSAccessRule` | get effective filesystem permissions for users (so as to know exactly the effective permissions, instead of trying to calculate/deduce them by inspecting ACLs) | [@mtboren](https://github.com/mtboren)
| `Get-FileEndOfLineType` | get the type of end of line ("EOL") character sequences present in the given file(s); if any `CRLF`, the EOL type for the file is considered "Windows", else, it is considered "Linux" | [@mtboren](https://github.com/mtboren)
| `Get-ParameterSetInformation` | get information about commands' Parameters and ParameterSets; can either get the Parameter objects themselves for further consumption, or can specify that the command return the Parameter information group and in tabular format (handy for human / eyeball consumption) | [@mtboren](https://github.com/mtboren)
| `Get-StringCasePermutation` | Get the character-case permutations of a string (all variations of lower/upper chars for the given string) | [@mtboren](https://github.com/mtboren)
| `Get-StringCasePermutation_Recursive` | Get the character-case permutations of a string using recursion (all variations of lower/upper chars for the given string) | [@mtboren](https://github.com/mtboren)
| `Invoke-ActivatePythonVirtualenv` | updated/improved (more "PowerShell-y") way to activate a Python virtual environment; based on the default `activate.ps1` that comes with a virtual environment created by `virtualenv` | [@mtboren](https://github.com/mtboren)
| `New-CertificateSigningRequest` | Make a new X509 Certificate Signing Request with given properties. Uses openssl binary for CSR/key generation | [@mtboren](https://github.com/mtboren), vScorpion
| `New-MarkdownCommandExample` | Create Markdown from commands' examples. Useful for, say, an examples.md summary file in the docs for a PowerShell module | [@mtboren](https://github.com/mtboren)
| `Optimize-PSReadlineHistory` | optimize your PSReadline history file by doing things like removing duplicate command lines | [@rkeithhill](https://github.com/rkeithhill)
| `Start-Demo` | extended version of the beloved `Start-Demo` script for presenting / stepping through code for demo in presentations / talks | Jeffrey Snover himself!
| `Test-ArgumentCompleter` | for testing the registered parameter completer for a specified command, adopted from Jason Shirk | [@lzybkr](https://github.com/lzybkr)

## Getting Started
### Install the module
This module is availabe in the PowerShell Gallery, so install it like you would any other module:
```PowerShell
## using Microsoft.PowerShell.PSResourceGet module , and for the current user
Find-PSResource PS.Utils | Install-PSResource -Scope CurrentUser

## or, using the older (and slower) PowerShellGet module , and for the current user
Find-Module PS.Utils | Install-Module -Scope CurrentUser
```
### Importing the module
To import the module, use the `Import-Module` cmdlet, of course! Like:
```PowerShell
Import-Module PS.Utils
```

Or, just invoke a command from the module, and (by default), PowerShell automatically imports the module.

### Getting commands in the module
```PowerShell
Get-Command -Module PS.Utils
```

### Getting help for a command in the module
```PowerShell
Get-Help -Full Test-ArgumentCompleter
```

## Examples
See the examples from the help for each function/command in [examples.md](./examples.md)