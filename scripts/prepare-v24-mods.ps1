. "$PSScriptRoot\common.ps1"
foreach($id in 'taskbar-notification-icon-spacing','taskbar-volume-control','alt-tab-per-monitor','windows-11-start-menu-styler','windows-11-file-explorer-styler'){
 & "$PSScriptRoot\install-optional-mod.ps1" -Id $id
}
