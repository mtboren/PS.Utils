<#  .Description
	Function to activate a Python virtualenv, updated to work with UNC paths. Also creates a function, "Invoke-DeactivatePythonVirtualenv" in the current PowerShell session for deactivating the Python virtualenv

	.Example
	Invoke-ActivatePythonVirtualenv.ps1 -Path C:\temp\pyVirtualEnvs\myVirtualEnv0
	Activate the virtual env that resides at the given path. Deactivate the virtual env via Invoke-DeactivatePythonVirtualenv

	.Example
	Invoke-ActivatePythonVirtualenv.ps1 -Path \\path\to\virtualenvs\someCoolVirtualenv
	Activate the virtual env that resides at the given UNC path. Deactivate the virtual env via Invoke-DeactivatePythonVirtualenv

	.Notes
	This is originally from a default Python virtualenv Scripts directory
#>

param(
	## Path to the virtualenv folder to "activate"
	[parameter(Mandatory=$true)][String]$Path
) ## end param

process {
	## name of function to make for deactivating python virtualenv
	$strDeactivate_fnName = "Invoke-DeactivatePythonVirtualenv"
	## make a new function that can be used to "deactivate" the virtualenv
	function global:Invoke-DeactivatePythonVirtualenv ( [switch] $NonDestructive ){
		if (Test-Path variable:\_OLD_VIRTUAL_PATH) {
			$env:PATH = $variable:_OLD_VIRTUAL_PATH
			Remove-Variable "_OLD_VIRTUAL_PATH" -Scope global
		} ## end if

		if (Test-Path function:\_old_virtual_prompt) {
			$function:prompt = $function:_old_virtual_prompt
			Remove-Item function:\_old_virtual_prompt
		} ## end if

		if ($env:VIRTUAL_ENV) {Remove-Item env:\VIRTUAL_ENV -ErrorAction SilentlyContinue} ## end if

		# Self destruct!
		if (-not $NonDestructive) {Remove-Item function:\Invoke-DeactivatePythonVirtualenv}
	} ## end fn

	# unset irrelevant variables
	& global:$strDeactivate_fnName -NonDestructive

	## set environment item
	$env:VIRTUAL_ENV = $Path

	$global:_OLD_VIRTUAL_PATH = $env:PATH
	$env:PATH = "$env:VIRTUAL_ENV/Scripts;" + $env:PATH
	if (! $env:VIRTUAL_ENV_DISABLE_PROMPT) {
		function global:_old_virtual_prompt { "" }
		$function:_old_virtual_prompt = $function:prompt
		function global:prompt {
			# Add a prefix to the current prompt
			Write-Host "($(split-path $env:VIRTUAL_ENV -leaf)) " -nonewline
			& $function:_old_virtual_prompt
		} ## end fn
	} ## end if

	Write-Verbose -Verbose "Virtualenv 'activated'. Use function '$strDeactivate_fnName' to deactivate this virtualenv"
} ## end process