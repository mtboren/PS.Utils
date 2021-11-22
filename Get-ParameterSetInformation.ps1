<#  .Description
    Get the ParameterSet information for the given Command

    .Example
    Get-Command Get-Date | Get-ParameterSetInformation.ps1
    Get the parameters for all parameter sets of the command

    .Example
    Get-Command Get-Date | Get-ParameterSetInformation.ps1 -GroupOutput
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
    $arrCommonParamsProperties =  [System.Management.Automation.Internal.CommonParameters].GetProperties()
}

process {
    $Command | Foreach-Object {
        $oThisCommand = $_
        Write-Verbose "ParameterSet information for command '$($oThisCommand.Name)'"
        ## foreach parameterset, get the param info; most commonly in PS, we would just emit objects and do something interesting with them down the pipeline, but in this case, with needing all of the items together if doing tabular/grouped output, assigning to a variable for further consumption in this function
        $arrParamsInfo = $oThisCommand | Foreach-Object {$_.ParameterSets} -PipelineVariable oThisParamSet | Foreach-Object {
            $_.Parameters | Where-Object {$_.Name -NotIn $arrCommonParamsProperties.Name} | Select-Object -Property Name, ParameterType, IsMandatory, IsDynamic, @{n="Position"; e={if ($_.Position -lt 0) {"Named"} else {$_.Position}}}, @{n="Alias"; e={$_.Aliases}}, @{n="ParameterSet"; e={$oThisParamSet.Name}}, @{n="IsDefaultParameterSet"; e={$oThisParamSet.IsDefault}}
        }
        if ($GroupOutput) {
            $hshParamForFormatTable = @{
                InputObject = $arrParamsInfo
                AutoSize = $true
                GroupBy = @{n="ParameterSet"; e={"{0}{1}" -f $_.ParameterSet, $(if ($_.IsDefaultParameterSet) {" (default)"})}}
                Property = Write-Output Name, ParameterType, IsMandatory, IsDynamic, Position, Alias, ParameterSet
            }
            Format-Table @hshParamForFormatTable
        } else {$arrParamsInfo}
    } ## end Foreach-Object
}