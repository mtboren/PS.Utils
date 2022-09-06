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
	## Return the title string
	$Title
}

process {
	$Command | Foreach-Object {
		$oThisCommand = $_
		## get the help (with examples) for this command
		$oHelp_ThisCommand = Get-Help -Examples -Name $oThisCommand.Name
		## make a string that has the command name and description followed by a code block with example(s)
		"`n#### ``{0}``: {1}" -f `
			$oThisCommand.Name,
			$oHelp_ThisCommand.Description.Text
		## "open" the code-fence in Markdown
		'```PowerShell'
		## make a string with the example description(s) and example code(s) for this command
		($oHelp_ThisCommand.examples.example | Foreach-Object {
			## for this example, make string like:
			#   ## example's comment line 0 here
			#   ## example's comment line 1 here
			#   example's actual code here
			## note:  joining with newline here to make single string, so as to then be able to join multiple examples with two new lines later
			$($_.remarks.Text | Where-Object {-not [System.String]::IsNullOrEmpty($_)} | Foreach-Object {$_.Split("`n")} | Foreach-Object {"## $_"}
			$_.code) -join "`n"
		}) -join "`n`n"
		## "close" the code-fence in Markdown
		'```'
	} ## end Foreach-Object
}