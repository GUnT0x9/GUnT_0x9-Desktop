. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;public static class V26Shot{[DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);}
'@
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
function Main-Window {$h=[IntPtr]::Zero;for($i=0;$i -lt 50;$i++){Start-Sleep -Milliseconds 100;$h=@(Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 Desktop'})|Select-Object -First 1;if($h){return $h}};throw '제어 센터 창 없음'}
function Shot($win,$name){$r=$win.Current.BoundingRectangle;$b=New-Object Drawing.Bitmap([int]$r.Width,[int]$r.Height);$g=[Drawing.Graphics]::FromImage($b);$dc=$g.GetHdc();try{if(![V26Shot]::PrintWindow([IntPtr]$win.Current.NativeWindowHandle,$dc,2)){throw '창 캡처 실패'}}finally{$g.ReleaseHdc($dc);$g.Dispose()};$b.Save((Join-Path $Root ('screenshots\v26-'+$name+'.png')));$b.Dispose()}
$results=@()
foreach($page in @(@('developer-setup','개발 프로젝트 목록'),@('development-sessions','개발 세션 목록'),@('wsl-environments','WSL 배포판 선택'),@('commands','등록된 GUNT 명령'),@('smart-automation','스마트 자동화 규칙'))){Start-Process $exe -ArgumentList ('"'+$Root+'" '+$page[0]);Start-Sleep -Milliseconds 900;$win=Main-Window;$target=Find-Name $win $page[1];if(!$target){throw ('실제 페이지 누락: '+$page[0])};Shot $win $page[0];Write-Json (Get-EnhancementTree $win) (Join-Path $Root ('logs\v26-ui-'+$page[0]+'.json'));$results+=@{Page=$page[0];Status='passed'};Write-Output ('실제 화면 확인: '+$page[0])}
Start-Process $exe -ArgumentList ('"'+$Root+'" quick-panel');Start-Sleep -Seconds 2;$popup=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 빠른 패널'}|Select-Object -First 1;if(!$popup){throw '빠른 패널 없음'};if(!(Find-Name $popup 'Codex')){throw '빠른 개발 동작 없음'};Shot $popup 'quick-panel';($popup.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();Start-Sleep -Milliseconds 500
[GuntEnhanceUi]::Key(17,$true);[GuntEnhanceUi]::Key(18,$true);[GuntEnhanceUi]::Tap(32);[GuntEnhanceUi]::Key(18,$false);[GuntEnhanceUi]::Key(17,$false);Start-Sleep -Seconds 2
$palette=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 명령 팔레트'}|Select-Object -First 1;if(!$palette){throw '전역 단축키로 명령 팔레트를 찾지 못했습니다.'}
$query=Find-Name $palette 'GUNT 명령 검색';($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('cdx');Start-Sleep -Milliseconds 300;$tree=Get-EnhancementTree $palette;if(!@($tree|Where-Object {$_.Name -like '*Codex*'}).Count){throw '실제 fuzzy 검색 결과 누락'};Shot $palette 'command-palette';[GuntEnhanceUi]::SetForegroundWindow([IntPtr]$palette.Current.NativeWindowHandle)|Out-Null;[GuntEnhanceUi]::Tap(27);Start-Sleep -Milliseconds 300
$results+=@{Page='quick-panel';Status='passed';Scope='실제 패널·동작 버튼. 도구 실행은 별도 검증.'};$results+=@{Page='command-palette';Status='passed';Scope='전역 Ctrl+Alt+Space·fuzzy 검색·Escape'}
Write-Json @{Time=(Get-Date).ToString('o');Results=$results;Limitations='페이지 존재와 별개로 CLI·세션·자동화 실제 검사를 수행함.'} (Join-Path $Root 'logs\v26-ui.json')
Start-Process $exe -ArgumentList ('"'+$Root+'" developer-setup')
