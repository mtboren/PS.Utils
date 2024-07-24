<#	.Description
	Get resource utilization on given Windows machine(s), like CPU and Memory consumption

	.Example
	Get-ResourceUtilization.ps1
	Get resource utilization for localhost

	.Example
	Get-ResourceUtilization.ps1 -ComputerName puter0, puter1
	Get resource utilization for the given computers

	.Example
	Get-ResourceUtilization.ps1 -ComputerName puter0, puter1 -Credential $myCred
	Get resource utilization for the given computers using the specified credentials
#>
param(
	## Name(s) of Windows computer(s) for which to get resource utilization. If none, will get information for localhost
	[String[]]$ComputerName,

	## Credential to use for remote computer
	[System.Management.Automation.PSCredential]$Credential
)

process {
	$hshParamForGetCimInstance = @{}
	if ($PSBoundParameters.ContainsKey("ComputerName")) {
		$hshParamForNewCimSession = @{ComputerName = $ComputerName}
		if ($PSBoundParameters.ContainsKey("Credential")) {$hshParamForNewCimSession["Credential"] = $Credential}
		$hshParamForGetCimInstance["CimSession"] = New-CimSession @hshParamForNewCimSession
	}
	## get processor and memory info
	$arrProcessorInfo = Get-CimInstance @hshParamForGetCimInstance -Class Win32_Processor -Property LoadPercentage
	$arrOSInfo = Get-CimInstance @hshParamForGetCimInstance -Class Win32_OperatingSystem -Property FreePhysicalMemory, TotalVisibleMemorySize
	$arrProcessorInfo, $arrOSInfo | Foreach-Object {$_} | Group-Object PSComputerName | Foreach-Object {
		$oProcessorInfo_thisComputer = $_.Group | Where-Object {$_.CimClass -match "Win32_Processor$"}
		$oOSInfo_thisComputer = $_.Group | Where-Object {$_.CimClass -match "Win32_OperatingSystem$"}
		## get the average LoadPercentage (useful when there is more than one processor)
		$mioProcessorUsage = $oProcessorInfo_thisComputer | Measure-Object -Property LoadPercentage -Average
		## make a new object with a few choice properties
		New-Object -Type PSObject -Property ([ordered]@{
			ComputerName = if ($PSBoundParameters.ContainsKey("ComputerName")) {$_.Name} else {${env:ComputerName}.ToLower()}
			NumCPU = $mioProcessorUsage.Count
			CPUUsedPct = $mioProcessorUsage.Average
			MemUsedPct = [Math]::Round(($oOSInfo_thisComputer.TotalVisibleMemorySize - $oOSInfo_thisComputer.FreePhysicalMemory) / $oOSInfo_thisComputer.TotalVisibleMemorySize * 100, 1)
		})
	}
}
end {
	## if this created any CIM sessions, remove them
	if ($hshParamForGetCimInstance["CimSession"]) {$hshParamForGetCimInstance["CimSession"] | Remove-CimSession}
}