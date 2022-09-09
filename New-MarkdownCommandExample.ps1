<#	.Description
	Create Markdown from commands' examples. Useful for, say, an examples.md summary file in the docs for a PowerShell module's repository. And, might get called as a part of a new module "build", so as to have current examples in the module's docs

	.Example
	Get-Command Get-Date | New-MarkdownCommandExample.ps1
	Create Markdown that displays the examples for the given command

	.Example
	Get-Command -Module MyCoolModule | New-MarkdownCommandExample.ps1 | Out-File c:\temp\coolstuff.md -Encoding ASCII
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
			[parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][System.Management.Automation.PSObject[]]$Example
		)

		process {
			$Example | ForEach-Object {
				## note:  joining with newline here to make single string, so as to then be able to join multiple examples with two new lines later
				## if this is running in Windows PowerShell (version of less than v6)
				$(if ($PSVersionTable.PSVersion -lt [System.Version]"6.0") {
					$_.remarks.Text | Where-Object {-not [System.String]::IsNullOrEmpty($_)} | Foreach-Object {$_.Split("`n")} | Foreach-Object {"## $_"}
					$_.code
				}
				## else, it's PowerShell (v6+)
				else {
					$arrCodeLines = $_.code | Where-Object {-not [System.String]::IsNullOrEmpty($_)} | Foreach-Object {$_.Split("`n")}
					$arrCodeLines | Select-Object -Skip 1 | Foreach-Object {"## $_"}
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
'@}

process {
	$Command | Foreach-Object {
		$oThisCommand = $_
		## get the help (with examples) for this command
		$oHelp_ThisCommand = Get-Help -Examples -Name $(if ($oThisCommand.Name -like "*.ps1" -or $oThisCommand.CommandType -eq "ExternalScript") {$oThisCommand.Source} else {$oThisCommand.Name})
		## make a string that has the command name and description followed by a code block with example(s)
		"`n#### ``{0}``: {1}" -f `
			$oThisCommand.Name,
			$oHelp_ThisCommand.Description.Text
		## "open" the code-fence in Markdown
		'```PowerShell'
		## make a string with the example description(s) and example code(s) for this command
		if (($oHelp_ThisCommand.examples | Measure-Object).Count -gt 0) {($oHelp_ThisCommand.examples | New-CodeBlockFromExample) -join "`n`n"} else {"## no examples for command '$($oThisCommand.Name)'"}

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