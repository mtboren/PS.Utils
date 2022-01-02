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
    [Parameter(Mandatory, Position=1)][string]$CommandName,

    ## The parameter name to test for the given command
    [Parameter(Mandatory, Position=2)][string]$ParameterName,

    ## The word to "tab-complete" in this test
    [Parameter(Position=3)][string]$WordToComplete,

    ## The command AST to use
    [System.Management.Automation.Language.CommandAst]$commandAst,

    ## Any "fake" bound parameter to use for the testing
    [Hashtable]$FakeBoundParameters = @{}
)

begin {
    $strGetArgCompleterCommand = if (Test-Path $PSScriptRoot\Get-ArgumentCompleter.ps1) {"$PSScriptRoot\Get-ArgumentCompleter.ps1"} else {"Get-ArgumentCompleter"}
}
process {
    ## get the completer (if any) for this command and parameter
    $completer = & $strGetArgCompleterCommand -CommandName $CommandName -ParameterName $ParameterName
    if ($null -ne $completer) {
        ## if there is a completer registered, invoke its definition with some params
        & $completer.Definition $CommandName $ParameterName $WordToComplete $commandAst $FakeBoundParameters
    }
    else {throw "No argument completer registered for command '$CommandName' and paramater '$ParameterName'"}
}