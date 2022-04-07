## PS.Utils -- some useful things
Herein are some useful PowerShell things
|  Item  | Description |
|--------|-------------|
| Get-ArgumentCompleter.ps1 | get the argument completers that are registered in the current PowerShell session; super minor update to the [awesome function](https://gist.github.com/indented-automation/26c637fb530c4b168e62c72582534f5b) by Chris Dent ([@indented-automation](https://github.com/indented-automation) on GitHub)
| Get-EffectiveFSAccessRule.ps1 | get effective filesystem permissions for users (so as to know exactly the effective permissions, instead of trying to calculate/deduce them by inspecting ACLs)
| Get-FileEndOfLineType.ps1 | get the type of end of line ("EOL") character sequences present in the given file(s); if any CRLF, the EOL type for the file is considered "Windows", else, it is considered "Linux"
| Get-ParameterSetInformation.ps1 | get information about commands' Parameters and ParameterSets; can either get the Parameter objects themselves for further consumption, or can specify that the command return the Parameter information group and in tabular format (handy for human / eyeball consumption)
| Get-StringCasePermutation.ps1 | Get the character-case permutations of a string (all variations of lower/upper chars for the given string)
| Get-StringCasePermutation_Recursive.ps1 | Get the character-case permutations of a string using recursion (all variations of lower/upper chars for the given string)
| Invoke-ActivatePythonVirtualenv.ps1 | updated/improved (more "PowerShell-y") way to activate a Python virtual environment; based on the default `activate.ps1` that comes with a virtual environment created by `virtualenv`
| Optimize-PSReadlineHistory.ps1 | optimize your PSReadline history file by doing things like removing duplicate command lines (by @rkeithhill)
| Start-Demo.ps1 | extended version of the beloved `Start-Demo` script for presenting / stepping through code for demo in presentations / talks (which is originally by Jeffrey Snover himself)
| Test-ArgumentCompleter.ps1 | for testing the registered parameter completer for a specified command, adopted from @lzybkr
