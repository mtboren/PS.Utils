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
        - comment-based help, so one can now Get-Help on Start-Demo.ps1 and have reasonable help
        - comment coloring -- comments in demo file are now written to console in comment-y color
        - tidbit to return window TitleBar to original text (that it was before starting demo)
        - handling of blank lines from demo file (now displays them and just continues on to next line)
        - adjusted -Command to be the command line number, so that when referring to the demo txt file, the correlation is there between command and line number (for illustration purposes when discussing with audience)
        - other various enhancements
#>
param(
    ## Path to the script file which to demo
    [parameter(Position=0)][ValidateScript({Test-Path -Path $_})][string]$File = ".\demo.txt",

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
            $_LinePrompt = if ($bUseCustomPrompt) {"`n$Prompt "} else {"`n[$strThisLineNumber] PS> "}
            Write-Host -NoNewLine $_LinePrompt
            ## write the simulated command after the prompt
            $_SimulatedCommand = $_Lines[$_i]
            $hshParamForWritingSimulatedCommand = @{NoNewLine = $true; Object = $_SimulatedCommand}
            if ($_SimulatedCommand.Trim().StartsWith("#")) {$hshParamForWritingSimulatedCommand["ForeGroundColor"] = "Green"}
            Write-Host @hshParamForWritingSimulatedCommand

            # Put the current command in the Window Title along with the demo duration
            $_Duration = [DateTime]::Now - $_StartTime
            $Host.UI.RawUI.WindowTitle = "[{0}m {1}s]        {2}" -f [int]$_Duration.TotalMinutes, [int]$_Duration.Seconds, $($_Lines[$_i])
            if (([System.String]::IsNullOrEmpty($_SimulatedCommand)) -or $_SimulatedCommand.Trim().StartsWith("#")) {
                continue
            } ## end if
            $_input=[System.Console]::ReadLine()
            switch ($_input) {
                "?" {
                    Write-Host -ForeGroundColor Yellow "Running demo: $file`n(q) Quit  (!) Suspend  (#x) Goto Command #x  (fx) Find cmds using X`n(t) Timecheck  (s) Skip line  (d) Dump demo"
                    $_i -= 1
                }
                "q" {
                    Write-Host -ForeGroundColor Yellow "<Quit demo>"
                    return
                }
                "s" {Write-Host -ForeGroundColor Yellow "<Skipping command from line $strThisLineNumber>"}
                "d" {
                    for ($_ni = 0; $_ni -lt $_lines.Count; $_ni++) {
                         if ($_i -eq $_ni) {Write-Host -ForeGroundColor Red ("*" * 80)}
                         Write-Host -ForeGroundColor Yellow ("[{0,2}] {1}" -f $_ni, $_lines[$_ni])
                    } ## end for
                    $_i -= 1
                }
                "t" {
                     $_Duration = [DateTime]::Now - $_StartTime
                     Write-Host -ForeGroundColor Yellow $("Demo has run {0} Minutes and {1} Seconds" -f [int]$_Duration.TotalMinutes, [int]$_Duration.Seconds)
                     $_i -= 1
                }
                {$_.StartsWith("f")} {
                    for ($_ni = 0; $_ni -lt $_lines.Count; $_ni++) {
                         if ($_lines[$_ni] -match $_.SubString(1)) {Write-Host -ForeGroundColor Yellow ("[{0,2}] {1}" -f $_ni, $_lines[$_ni])}
                    } ## end for
                    $_i -= 1
                }
                {$_.StartsWith("!")} {
                    if ($_.Length -eq 1) {
                        Write-Host -ForeGroundColor Yellow "<Suspended demo - type ‘Exit’ to resume>"
                        $host.EnterNestedPrompt()
                    } else {
                        trap [System.Exception] {Write-Error $_;continue;}
                        Invoke-Expression $($_.SubString(1) + "| out-host")
                    } ## end else
                    $_i -= 1
                }
                {$_ -match "^#\d+$"} {
                    ## "- 2" to make up for zero-based index and 1-based line numbers in a file
                    $_i = [int]($_.SubString(1)) - 2
                    continue
                }
                default {
                    trap [System.Exception] {Write-Error $_;continue;}
                    $strItemToInvoke = $_lines[$_i]
                    ## if caller appended some tidbit, prefixed with a space (as in, attempted to edit the line), add their edit to the item to invoke
                    if ($_input -match "^ .+") {$strItemToInvoke += $_input}
                    ## if this is not an assignment operation, append " | Out-Default" to the command
                    if ($strItemToInvoke -notmatch "=") {$strItemToInvoke = "$strItemToInvoke | Out-Default"}
                    Invoke-Expression $strItemToInvoke
                    $_Duration = [DateTime]::Now - $_StartTime
                    $Host.UI.RawUI.WindowTitle = "[{0}m {1}s]        {2}" -f [int]$_Duration.TotalMinutes, [int]$_Duration.Seconds, $($_Lines[$_i])
                    [System.Console]::ReadLine()
                }
            } ## end switch
        } ## end for
    } ## end try
    catch {$_}
    finally {
        $_Duration = [DateTime]::Now - $_StartTime
        Write-Host -ForeGroundColor Yellow $("`n<Demo Complete {0} Minute{1} and {2} Second{3}>" -f [int]$_Duration.TotalMinutes, $(if ([int]$_Duration.TotalMinutes -ne 1) {"s"}), [int]$_Duration.Seconds, $(if ([int]$_Duration.Seconds -ne 1) {"s"}))
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
    • Quit at any point
    • Dump the list of commands in the demo. It produces a red line above your current point in the demo
    • Run another command or Suspend the demo and enter into a nested prompt to explore a topic
    • Go to a specified command in the demo
    • Find all the commands in the demo using a regular expression
    • Check your time. It displays how many minutes and seconds since the start of the demo. This information is also displayed in the Window title on an ongoing basis.
#>
