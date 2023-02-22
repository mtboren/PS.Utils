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
            $(if ($String.Substring(0, 1) -match "\d") {"ToString"}
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