<#	.Description
	Get the type of end of line ("EOL") character sequences present in the given file(s). If any CRLF, the EOL type for the file is considered "Windows", else, it is considered "Linux"

	.Example
	Get-Item c:\temp\somefile.sh | Get-FileEndOfLineType.ps1
	Get the EOL type for the given file
#>
[CmdletBinding()]
param(
	## The path(s) to the file(s) whose EOL type to determine
	[parameter(Mandatory=$true, ValueFromPipeline = $true)][System.IO.FileInfo[]]$Path
)

process {
	$Path | Foreach-Object {
		$oThisFile = $_
		$strEOLType = if (($strFileContents = Get-Content -Raw $oThisFile) | Select-String "`r`n") {"Windows"} else {if ($strFileContents | Select-String "`n") {"Linux"} else {Write-Verbose -Verbose "no EOL sequences detected at all in file '$($oThisFile.FullName)'. Is it more than one line long?"}}
		$oThisFile | Select-Object @{n="EOLSequenceType"; e={$strEOLType}}, LastWriteTime, Length, Name, FullName
	} ## end Foreach-Object
} ## end process