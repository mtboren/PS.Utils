<#	.Description
	Determine effective filesystem permissions for a user, and the ACE from which they come

	.Example
	Get-ADUser Mikey | Get-EffectiveFSAccessRule.ps1 -Path \\some\remote\path\folder, \\some\remote\otherpath
	Get the effective permissions for this user and at the given remote path
#>
[CmdletBinding()]
param(
	## Filesystem path (local or UNC) on which to check permissions; ex: "\\server.dom.com\path\tmp"
	[parameter(Mandatory=$true)][ValidateScript({Test-Path $_})][string[]]$Path,

	## Identity (user -- not group) for which to check rights; ex: "userName" or "username@domain.com"
	[parameter(Mandatory=$true,ValueFromPipelineByPropertyName)][Alias("SamAccountName")][string[]]$Identity
)

begin {
	## some arguments to use in getting Access Rules
	$bIncludeExplicit = $bIncludeInherited = $true
}

process {
	$Path | Foreach-Object {
		$strThisPath = $_

		$Identity | Foreach-Object {
			$strThisIdentity = $_
			## requires minimum .NET Framework version v1.1 -- real high demands, here
			#   ref: https://msdn.microsoft.com/en-us/library/system.security.principal.windowsprincipal.aspx
			$oWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($strThisIdentity)

			## using Get-Acl, get the AccessRules
			## GetAccessRules():  System.Security.AccessControl.AuthorizationRuleCollection GetAccessRules(Boolean includeExplicit, Boolean includeInherited, Type targetType)
			(Get-Acl $strThisPath).GetAccessRules($bIncludeExplicit, $bIncludeInherited, [System.Security.Principal.NTAccount]) | Foreach-Object {
				## of type System.Security.AccessControl.FileSystemAccessRule
				$oThisFilesystemAccessRule = $_
				## if WindowsPrincipal is in the role specified by this rule
				if ($oWindowsPrincipal.IsInRole($oThisFilesystemAccessRule.IdentityReference)) {
					Write-Verbose "Yes! '$strThisIdentity' is part of '$($oThisFilesystemAccessRule.IdentityReference.Value)'"
					New-Object -Type PSObject -Property ([ordered]@{
						Path = $strThisPath
						ThisIdentity = $strThisIdentity
						FileSystemRights = $oThisFilesystemAccessRule.FileSystemRights
						AccessControlType = $oThisFilesystemAccessRule.AccessControlType
						IdentityReference = $oThisFilesystemAccessRule.IdentityReference
						IsInherited = $oThisFilesystemAccessRule.IsInherited
						InheritanceFlags = $oThisFilesystemAccessRule.InheritanceFlags
						PropagationFlags = $oThisFilesystemAccessRule.PropagationFlags
					}) ## end new-object
				} ## end if
				else {Write-Verbose "$strThisIdentity' is not part of '$($oThisFilesystemAccessRule.IdentityReference.Value)'"} ## end else
			} ## end foreach-object
		}
	}
} ## end process
