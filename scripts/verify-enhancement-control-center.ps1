. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntCcConfirm{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);[DllImport("user32.dll")]static extern IntPtr GetDlgItem(IntPtr h,int id);[DllImport("user32.dll")]static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);public static IntPtr Dialog(){return FindWindow(null,"Windhawk 구성 복구");}public static void No(IntPtr h){var button=GetDlgItem(h,7);if(button==IntPtr.Zero)throw new Exception("아니요 버튼을 찾지 못했습니다.");PostMessage(button,0xf5,IntPtr.Zero,IntPtr.Zero);}}
'@
$already=@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count -gt 0
Start-Process (Join-Path $Root 'bin\GUNT.ControlCenter.exe') -ArgumentList ('"'+$Root+'" windhawk')
Start-Sleep -Milliseconds 1500
$h=[IntPtr]::Zero
for($i=0;$i -lt 50 -and $h -eq [IntPtr]::Zero;$i++){$p=Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue|Where-Object {$_.MainWindowHandle -ne [IntPtr]::Zero}|Select-Object -First 1;if($p){$h=$p.MainWindowHandle}else{Start-Sleep -Milliseconds 100}}
if($h -eq [IntPtr]::Zero){throw '제어 센터 창이 준비되지 않았습니다.'}
[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-1),0,0,0,0,0x13)|Out-Null
try{
 $win=[Windows.Automation.AutomationElement]::FromHandle($h)
 $list=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'설치된 Windhawk 모드')))
 if(!$list){throw '제어 센터의 실제 모드 목록을 찾지 못했습니다.'}
 $items=@($list.FindAll([Windows.Automation.TreeScope]::Children,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::ListItem))))
 $actual=@(Get-ChildItem (Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods') -Filter '*.ini')
 $visibleNames=@($items|ForEach-Object {$_.Current.Name})
 $scroll=$null
 if($list.TryGetCurrentPattern([Windows.Automation.ScrollPattern]::Pattern,[ref]$scroll) -and $scroll.Current.VerticallyScrollable){
  $scroll.SetScrollPercent(-1,100);Start-Sleep -Milliseconds 200
  $items=@($list.FindAll([Windows.Automation.TreeScope]::Children,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::ListItem))))
  $visibleNames+=@($items|ForEach-Object {$_.Current.Name})
 }
 $visibleNames=@($visibleNames|Select-Object -Unique)
 Save-EnhancementShot 'control-center' $win.Current.BoundingRectangle
 Write-Json @{Expected=$actual.Count;UiUniqueRows=$visibleNames.Count;Names=$visibleNames;Elements=(Get-EnhancementTree $win)} (Join-Path $Root 'logs\enhancement-control-center-probe.json')
 if($visibleNames.Count -ne $actual.Count){throw '제어 센터 스크롤 목록과 실제 모드 개수가 다릅니다.'}
 $buttons=@($win.FindAll([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::Button))))
 foreach($name in 'Windhawk 열기','목록 새로고침','선택 모드 공식 문서','호환성 표','최근 오류','이전 Windhawk 구성 복구'){
  if(!@($buttons|Where-Object {$_.Current.Name -eq $name -and $_.Current.IsEnabled}).Count){throw ('제어 센터 동작 항목 누락: '+$name)}
 }
 $select=$items|Where-Object {$_.Current.Name -like '*Windows 11 File Explorer Styler*'}|Select-Object -First 1
 if(!$select){throw '비활성 탐색기 Styler 항목을 찾지 못했습니다.'}
 $select.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern).Select();Start-Sleep -Milliseconds 200
 $texts=@($win.FindAll([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::Edit))))
 $values=@(foreach($box in $texts){$pattern=$null;if($box.TryGetCurrentPattern([Windows.Automation.ValuePattern]::Pattern,[ref]$pattern)){$pattern.Current.Value}})
 if(!@($values|Where-Object {$_ -like '*충돌로 비활성*'}).Count){throw '제어 센터의 실제 충돌 설명을 찾지 못했습니다.'}
 Save-EnhancementShot 'control-center' $win.Current.BoundingRectangle
 ($buttons|Where-Object {$_.Current.Name -eq '최근 오류'}|Select-Object -First 1).GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke();Start-Sleep -Milliseconds 400
 ($buttons|Where-Object {$_.Current.Name -eq '이전 Windhawk 구성 복구'}|Select-Object -First 1).GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke()
 $dialog=[IntPtr]::Zero
 for($i=0;$i -lt 30 -and $dialog -eq [IntPtr]::Zero;$i++){Start-Sleep -Milliseconds 100;$dialog=[GuntCcConfirm]::Dialog()}
 if($dialog -eq [IntPtr]::Zero){throw '구성 복구 확인 창이 나타나지 않았습니다.'}
 [GuntCcConfirm]::No($dialog);Start-Sleep -Milliseconds 300
 Write-Json @{Time=(Get-Date).ToString('o');ActualModFiles=$actual.Count;UiRows=$visibleNames.Count;Buttons=@($buttons|ForEach-Object {$_.Current.Name});ConflictExplanationVisible=$true;RecentErrorsInvoked=$true;RestoreConfirmationShown=$true;RestoreCancelled=$true;ActualRollbackExecuted=$false;Status='passed'} (Join-Path $Root 'logs\enhancement-control-center.json')
 Write-Log 'enhancement-control-center' 'passed' '실제 목록 개수·충돌 설명·오류 진입점·복구 확인/취소 검증. 복구는 실행하지 않았습니다.'
}finally{[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-2),0,0,0,0,0x13)|Out-Null;if(!$already){$p.CloseMainWindow()|Out-Null}}
