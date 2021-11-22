## PS.Utils -- some useful things
Herein are some useful PowerShell things
|  Item  | Description |
|--------|-------------|
| Get-ArgumentCompleter.ps1 | get the argument completers that are registered in the current PowerShell session; super minor update to the [awesome function](https://gist.github.com/indented-automation/26c637fb530c4b168e62c72582534f5b) by Chris Dent ([@indented-automation](https://github.com/indented-automation) on GitHub)
| Get-ParameterSetInformation.ps1 | get information about commands' Parameters and ParameterSets; can either get the Parameter objects themselves for further consumption, or can specify that the command return the Parameter information group and in tabular format (handy for human / eyeball consumption)
| Invoke-ActivatePythonVirtualenv.ps1 | updated/improved (more "PowerShell-y") way to activate a Python virtual environment; based on the default `activate.ps1` that comes with a virtual environment created by `virtualenv`
| Start-Demo.ps1 | extended version of the beloved `Start-Demo` script for presenting / stepping through code for demo in presentations / talks (which is originally by Jeffrey Snover himself)
