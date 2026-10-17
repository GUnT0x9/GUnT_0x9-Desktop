. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type 'using System;using System.Runtime.InteropServices;public static class GuntShortcutRestore{[DllImport("user32.dll")]public static extern bool IsIconic(IntPtr h);[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int n);}'
$originalForeground=[GuntEnhanceUi]::GetForegroundWindow();$before=@(Get-Process Taskmgr -ErrorAction SilentlyContinue);$states=@($before|ForEach-Object {@{Id=$_.Id;Handle=$_.MainWindowHandle;Minimized=[GuntShortcutRestore]::IsIconic($_.MainWindowHandle)}})
$task=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::Taskbar())
$frame=$task.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'TaskbarFrame')))
$r=$frame.Current.BoundingRectangle;$point=$null
$probes=@()
foreach($offset in 4,8,12,20){foreach($vertical in 0.2,0.5,0.8){
 $probe=New-Object Windows.Point ($r.Left+$offset),($r.Top+$r.Height*$vertical);$element=[Windows.Automation.AutomationElement]::FromPoint($probe)
 $probes+=@{X=$probe.X;Y=$probe.Y;Class=$element.Current.ClassName;Name=$element.Current.Name}
 if($element.Current.ClassName -in 'Taskbar.TaskbarFrameAutomationPeer','Shell_TrayWnd','Windows.UI.Input.InputSite.WindowClass'){$point=$probe;break}
 }if($point){break}}
Write-Json $probes (Join-Path $Root 'logs\enhancement-empty-area-probes.json')
if(!$point){throw '현재 Dock 안에서 안전한 빈 영역을 찾지 못했습니다.'}
try{
 [GuntEnhanceUi]::Key(0xa2,$true)
 try{[GuntEnhanceUi]::DoubleClick([int]$point.X,[int]$point.Y)}finally{[GuntEnhanceUi]::Key(0xa2,$false)}
 $matched=$false
 for($i=0;$i -lt 30;$i++){Start-Sleep -Milliseconds 100;$h=[GuntEnhanceUi]::GetForegroundWindow();$w=[Windows.Automation.AutomationElement]::FromHandle($h);if(@((Get-Process Taskmgr -ErrorAction SilentlyContinue).Id) -contains $w.Current.ProcessId){$matched=$true;break}}
 if(!$matched){throw 'Ctrl+빈 Dock 두 번 클릭으로 작업 관리자가 열리지 않았습니다.'}
 Save-EnhancementShot 'taskbar-shortcut'
 Write-Json @{Time=(Get-Date).ToString('o');Point=@{X=$point.X;Y=$point.Y};EmptyAreaClass=$element.Current.ClassName;Foreground=$w.Current.Name;Status='passed';Shortcut='왼쪽 Ctrl + 주 화면 Dock 빈 영역 두 번 클릭';ConfiguredOnlyCtrlDouble=$true} (Join-Path $Root 'logs\enhancement-taskbar-shortcut.json')
 Write-Log 'enhancement-taskbar-shortcut' 'passed' 'Ctrl+빈 Dock 두 번 클릭으로 실제 작업 관리자를 열었습니다.'
}finally{
 foreach($s in $states){if($s.Minimized){[GuntShortcutRestore]::ShowWindow($s.Handle,6)|Out-Null}}
 if(!$before.Count){foreach($p in Get-Process Taskmgr -ErrorAction SilentlyContinue){$p.CloseMainWindow()|Out-Null}}
 [GuntEnhanceUi]::SetForegroundWindow($originalForeground)|Out-Null
}
