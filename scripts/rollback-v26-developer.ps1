[CmdletBinding(SupportsShouldProcess=$true)]
param([ValidateSet('ControlCenter','TopBar','All')][string]$Component='All')
& "$PSScriptRoot\rollback-v25-ux.ps1" -Component $Component -Checkpoint pre-v26-developer-workspace -AppliedState v26-applied-files -WhatIf:$WhatIfPreference
