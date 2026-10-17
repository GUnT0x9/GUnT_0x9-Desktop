. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;public static class DockDialog{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);public static IntPtr Find(){return FindWindow(null,"적용할 설정");}}
'@
if(Test-Path (Join-Path $Root 'state\dock-live-apply-hold.json')){throw 'Dock 자동 적용 보류 중입니다. 실시간 모드 변경 시험을 실행하지 않았습니다.'}
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';Start-Process $exe -ArgumentList ('"'+$Root+'" dock');Start-Sleep -Seconds 2
$p=Get-Process GUNT.ControlCenter|Select-Object -First 1;$win=[Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
function Item($parent,$name,$type){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.AndCondition((New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)),(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,$type)))))}
function Click($parent,$name){$b=Item $parent $name ([Windows.Automation.ControlType]::Button);if(!$b){throw ('버튼 없음: '+$name)};($b.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()}
$path=Join-Path $Root 'config\dock.json';$before=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$original=[int]$before.radius;$target=$(if($original -eq 10){12}else{10});$explorer=@(Get-Process explorer|ForEach-Object Id)
# Only radius is tested; no pinned applications or display settings change.
$edit=Item $win '모서리 반경 (DIP)' ([Windows.Automation.ControlType]::Edit)
if(!$edit){$edits=$win.FindAll([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::Edit)));$edits|ForEach-Object {$_.Current.Name};throw '모서리 입력 이름을 확인해야 합니다.'}
($edit.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue([string]$target);Click $win '변경 사항 적용'
$h=[IntPtr]::Zero;for($i=0;$i -lt 30 -and $h -eq [IntPtr]::Zero;$i++){Start-Sleep -Milliseconds 100;$h=[DockDialog]::Find()};if($h -eq [IntPtr]::Zero){throw 'Dock 변경 요약 없음'};Click ([Windows.Automation.AutomationElement]::FromHandle($h)) '설정 적용'
$restored=$false
try{
 $undo=$null;for($i=0;$i -lt 150;$i++){Start-Sleep -Milliseconds 200;$undo=Item $win '직전 적용 취소' ([Windows.Automation.ControlType]::Button);if($undo.Current.IsEnabled){break}}
 if(!$undo.Current.IsEnabled){throw 'Dock 적용 완료 상태 없음'}
 $ini=Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods\windows-11-taskbar-styler.ini';$actual=[IO.File]::ReadAllText($ini)
 if($actual -notmatch ('CornerRadius='+$target+'\r?\n')){throw '실제 모드 INI 모서리 불일치'}
 Click $win '직전 적용 취소'
 for($i=0;$i -lt 150;$i++){Start-Sleep -Milliseconds 200;$m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;if([int]$m.radius -eq $original -and !$undo.Current.IsEnabled -and [IO.File]::ReadAllText($ini) -match ('CornerRadius='+$original+'\r?\n')){$restored=$true;break}}
 if(!$restored){throw 'Dock 실행 취소 확인 실패'}
 $same=(@(Get-Process explorer|ForEach-Object Id) -join ',') -eq ($explorer -join ',');if(!$same){throw 'Explorer PID가 시험 중 바뀌었습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';RadiusBefore=$original;RadiusApplied=$target;RadiusRestored=$m.radius;ExplorerPreserved=$same;Limitations='실제 설정과 Windhawk INI 일치 검증. 픽셀 단위 모서리·모든 Dock 속성 조합은 별도.'} (Join-Path $Root 'logs\v25-dock-live.json')
 Write-Output 'Dock 실제 적용·Windhawk 내보내기·실행 취소·Explorer 유지 통과'
}finally{if(!$restored){Write-Output 'Dock 복구 상태를 별도로 확인해야 합니다. 전체 롤백하지 않았습니다.'}}
