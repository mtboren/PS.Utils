<#	.Description
	Get data from a System.IO.MemoryStream object (converting the byte array to some goodness).

	.Example
	Get-DataFromMemoryStream.ps1 -InputObject $oMyMemoryStream
	Get the data from the given MemoryStream object

	.Example
	Invoke-LMFunction -FunctionName testEnvScr0 -Payload (@{queryStringParameters = @{param0 = "mehhh"}} | ConvertTo-Json -Depth 4) | Get-DataFromMemoryStream.ps1
	Invoke an Amazon Lambda function (which returns an object with a Payload property of type System.IO.MemoryStream), and get the data from the resultant Payload
#>
[CmdletBinding()]
param(
	## Object(s) whose data to get
	[parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("Payload")][System.IO.MemoryStream[]]$InputObject
)

process {
	$InputObject | Foreach-Object {
		$oThisInputObject = $_
		## using ASCII encoding here; may need to using something else, like UTF8 or so, in the future
		[System.Text.Encoding]::ASCII.GetString($oThisInputObject.ToArray())
	} ## end Foreach-Object
} ## end process