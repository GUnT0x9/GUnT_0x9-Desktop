. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;public static class UxPrint{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);public static IntPtr Dialog(){return FindWindow(null,"미저장 설정");}[DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);}
'@
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
function Root-Window { $p=Get-Process GUNT.ControlCenter -ErrorAction Stop|Select-Object -First 1;[Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle) }
function Find-Name($parent,[string]$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
function Open-Page([string]$id){Start-Process $exe -ArgumentList ('"'+$Root+'" '+$id);Start-Sleep -Milliseconds 800;return Root-Window}
function Click-Name($parent,[string]$name){$item=Find-Name $parent $name;if(!$item){throw ('실제 버튼 누락: '+$name)};($item.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();Start-Sleep -Milliseconds 250}
function Decision([string]$name){$dialog=$null;for($i=0;$i -lt 30 -and !$dialog;$i++){Start-Sleep -Milliseconds 100;$h=[UxPrint]::Dialog();if($h -ne [IntPtr]::Zero){$dialog=[Windows.Automation.AutomationElement]::FromHandle($h)}};if(!$dialog){throw '미저장 변경 보호 창이 나타나지 않았습니다.'};Click-Name $dialog $name}

function Shot($window,[string]$name){$r=$window.Current.BoundingRectangle;$bitmap=New-Object Drawing.Bitmap([int]$r.Width,[int]$r.Height);$graphics=[Drawing.Graphics]::FromImage($bitmap);$dc=$graphics.GetHdc();try{if(![UxPrint]::PrintWindow([IntPtr]$window.Current.NativeWindowHandle,$dc,2)){throw '화면 단독 캡처 실패'}}finally{$graphics.ReleaseHdc($dc);$graphics.Dispose()};try{$bitmap.Save((Join-Path $Root ('screenshots\v25-'+$name+'.png')))}finally{$bitmap.Dispose()}}
$results=New-Object Collections.Generic.List[object]
function Check($name,$value,$evidence){$results.Add(@{Test=$name;Status=$(if($value){'passed'}else{'failed'});Evidence=$evidence});if(!$value){throw ($name+': '+$evidence)};Write-Output ('[passed] '+$name)}
$left=[UxPrint]::Dialog();if($left -ne [IntPtr]::Zero){Click-Name ([Windows.Automation.AutomationElement]::FromHandle($left)) '계속 편집'}
$baselineDock=(Get-FileHash (Join-Path $Root 'config\dock.json')).Hash
$wallpaperPath=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json';$wallpaperHash=(Get-FileHash $wallpaperPath).Hash
$win=Open-Page 'dock';$held=Test-Path (Join-Path $Root 'state\dock-live-apply-hold.json')
if($held){Check 'Dock 전용 페이지·안전 보류' ($null -ne (Find-Name $win 'Dock 자동 적용 보류')) '원인 확인 전 읽기 전용·Windhawk 연결'}else{Check 'Dock 전용 페이지' ($null -ne (Find-Name $win 'Dock 높이 (DIP)')) 'Windhawk가 아닌 실제 Dock 입력'}
# Dirty protection is exercised on a safe monitor field; no live Dock changes.
$win=Open-Page 'monitor';$height=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.AndCondition((New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'모니터 너비 (DIP)')),(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::Edit)))))
$pattern=$height.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern);$original=$pattern.Current.Value;$pattern.SetValue(([int]$original+2).ToString());Start-Sleep -Milliseconds 300
Check '미저장 변경·적용 활성' ((Find-Name $win '변경 사항 적용').Current.IsEnabled) '실제 편집 후 버튼 활성'
# A second instance routes a real navigation request to the already-open window.
Start-Process $exe -ArgumentList ('"'+$Root+'" projects');Start-Sleep -Milliseconds 500;Decision '계속 편집';$win=Root-Window
Check '이동 취소·편집 보존' ($pattern.Current.Value -eq ([int]$original+2).ToString()) '값 유지'
Start-Process $exe -ArgumentList ('"'+$Root+'" projects');Start-Sleep -Milliseconds 500;Decision '버리고 이동';$win=Root-Window
Check '프로젝트 경로 연결' ($null -ne (Find-Name $win '프로젝트 추가')) '실제 프로젝트 관리 페이지'
Check '버리기 후 실제 설정 보존' ((Get-FileHash (Join-Path $Root 'config\dock.json')).Hash -eq $baselineDock) 'JSON 해시 동일'
foreach($id in 'overview','dock','projects','profiles','wallpaper','monitor','sensors','diagnostics','automation','topbar','displays'){
 $win=Open-Page $id;$tree=Get-EnhancementTree $win
 Shot $win $id
 Write-Json $tree (Join-Path $Root ('logs\v25-ui-'+$id+'.json'))
 $text=($tree|ForEach-Object Name) -join '\n'
 Check ('페이지 '+$id) ($text -notmatch '설정 읽기 실패') '실제 UI 트리·PrintWindow 캡처'
}
Check '갤러리 관찰 중 배경 보존' ((Get-FileHash $wallpaperPath).Hash -eq $wallpaperHash) '배경 배치 SHA256 동일'
$win=Open-Page 'overview';Check '개요 구조화 상태' ($null -ne (Find-Name $win 'Rainmeter')) '실제 구성 요소 상태 행'
Write-Json @{Time=(Get-Date).ToString('o');Results=$results.ToArray();WallpaperPreserved=$true;Limitations='페이지 렌더링만으로 모든 기능을 통과 표시하지 않음. 실제 적용·프로젝트 실행·프로필·배경 전환은 별도 시험.'} (Join-Path $Root 'logs\v25-ui-verification.json')
