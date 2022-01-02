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
