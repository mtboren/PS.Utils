<#	.Description
	Get the weather for some location

	.Notes
	Uses https://wttr.in for the forecast information
	See https://wttr.in/:help for other options

	.Example
	Get-Weather
	Get the weather for the default location
#>
[CmdletBinding()]
param(
	## Location(s) for which to get weather information. Takes things like city name, any location ("Eiffel Tower"), unicode name of any location in any language ("Москва"), airport code (3 letters, like "IND"), domain name ("@stackoverflow.com"), "area code" (possibly a postal code?) ("94107"), GPS coordinate ("-78.46,106.79")
	[String[]]$Location = "Indianapolis",

	## Switch: Get "narrow" format for each day (just day & night's weather)
	[Switch]$Narrow,

	## Switch: no color / ANSI terminal sequences?
	[Switch]$NoColor
) ## end param

begin {
	$oConfig = @{
		## Web URI of the weather forecast service
		strWebURI = "https://wttr.in"
		arrQueryStringItems = & {
			if ($Narrow) {"n"}
			if ($NoColor) {"T"}
		}
	}
} ## end begin

process {
	$Location | Foreach-Object {
		$strThisLocation = $_
		$hshParamForInvokeRestMethod = @{URI = ($oConfig.strWebURI, $strThisLocation -join "/"), ($oConfig.arrQueryStringItems -join "") -join "?"}
		Invoke-RestMethod @hshParamForInvokeRestMethod
	} ## end Foreach-Object
} ## end process