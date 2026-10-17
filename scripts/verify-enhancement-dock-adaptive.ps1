. "$PSScriptRoot\enhancement-ui-common.ps1"
function Geometry {
 $bar=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::Taskbar());$items=$bar.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)
 $app=$items|Where-Object {$_.Current.AutomationId -eq 'TaskbarFrame'}|Select-Object -First 1;$tray=$items|Where-Object {$_.Current.ClassName -eq 'TrayNotifyWnd'}|Select-Object -First 1
 $a=$app.Current.BoundingRectangle;$t=$tray.Current.BoundingRectangle
 @{AppX=$a.X;AppWidth=$a.Width;AppRight=$a.Right;TrayX=$t.X;GapPx=$t.X-$a.Right;Count=@($items|Where-Object {$_.Current.ClassName -eq 'Taskbar.TaskListButtonAutomationPeer' -and !$_.Current.IsOffscreen}).Count}
}
$already=@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count -gt 0
if($already){throw '제어 센터가 이미 열려 있어 앱 수 변화 시험을 분리할 수 없습니다.'}
$before=Geometry;$process=$null
try{
 Start-Process (Join-Path $Root 'bin\GUNT.ControlCenter.exe') -ArgumentList ('"'+$Root+'" windhawk')
 for($i=0;$i -lt 50;$i++){Start-Sleep -Milliseconds 150;$process=Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue|Where-Object {$_.MainWindowHandle -ne [IntPtr]::Zero}|Select-Object -First 1;$open=Geometry;if($process -and $open.Count -gt $before.Count){break}}
 Start-Sleep -Milliseconds 350;$open=Geometry
 if($open.Count -le $before.Count -or $open.AppWidth -le $before.AppWidth){throw '새 제어 센터 앱 버튼의 폭 증가를 확인하지 못했습니다.'}
 if($open.GapPx -lt 20 -or [math]::Abs($open.AppRight-$before.AppRight) -gt 4){throw '앱 수 증가 후 Dock 간격이 유지되지 않았습니다.'}
 $process.CloseMainWindow()|Out-Null;$process.WaitForExit(4000)|Out-Null;$process=$null;Start-Sleep -Milliseconds 400;$after=Geometry
 if($after.GapPx -lt 20 -or $after.Count -ne $before.Count){throw '앱 종료 후 Dock 배치가 복원되지 않았습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Before=$before;WithControlCenter=$open;After=$after;Status='passed';Method='Windhawk ActualWidth 캡처·실시간 Margin 표현식';ExplorerRestarted=$false} (Join-Path $Root 'logs\enhancement-dock-adaptive.json')
 Write-Log 'enhancement-dock-adaptive' 'passed' ('앱 '+$before.Count+'→'+$open.Count+'→'+$after.Count+'개, 오른쪽 간격 '+$before.GapPx+'→'+$open.GapPx+'→'+$after.GapPx+'px')
}finally{if($process -and !$process.HasExited){$process.CloseMainWindow()|Out-Null}}
