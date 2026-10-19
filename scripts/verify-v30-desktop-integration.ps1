param([ValidatePattern('^[a-z0-9.-]+$')][string]$ResultLabel='dev2')
. "$PSScriptRoot\enhancement-ui-common.ps1"
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '검사 전에 기존 제어 센터를 닫으세요.'}
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class V30DesktopNative {
 [DllImport("user32.dll")]public static extern uint GetGuiResources(IntPtr process,uint flags);
 [DllImport("user32.dll")]public static extern uint GetDpiForWindow(IntPtr window);
}
'@
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
$checks=@();function Check($value,$name){if(!$value){throw $name};$script:checks+=$name}
$windowFile=Join-Path $Root 'state\control-center-window.json';$originalWindow=if(Test-Path $windowFile){[IO.File]::ReadAllBytes($windowFile)}else{$null}
$p=$null
try{
 $p=Start-Process (Join-Path $Root 'bin\GUNT.ControlCenter.exe') -ArgumentList ('"'+$Root+'" overview') -PassThru;Start-Sleep -Seconds 2
 $win=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $p.Id -and $_.Current.Name -eq 'GUnT_0x9 Desktop'}|Select-Object -First 1
 Check ($null -ne $win) '실제 제어 센터 표시'
 $mainHandle=[IntPtr]$win.Current.NativeWindowHandle;[GuntEnhanceUi]::SetForegroundWindow($mainHandle)|Out-Null
 $nav=Find-Name $win '페이지 탐색';$nav.SetFocus();Start-Sleep -Milliseconds 200
 Check ([GuntEnhanceUi]::GetForegroundWindow() -eq $mainHandle) '키 입력 대상 창 확인'
 [GuntEnhanceUi]::Chord(17,75);Start-Sleep -Milliseconds 400
 $palette=Find-Name $win 'GUnT_0x9 명령 팔레트';Check ($null -ne $palette) 'Ctrl+K 팔레트 열기'
 $query=Find-Name $palette 'GUNT 명령 검색';Check $query.Current.HasKeyboardFocus '검색 입력 자동 포커스'
 $list=Find-Name $palette 'GUNT 명령 결과';$pattern=$list.GetCurrentPattern([Windows.Automation.SelectionPattern]::Pattern);$before=$pattern.Current.GetSelection()[0].Current.Name
 [GuntEnhanceUi]::Tap(40);$after=$pattern.Current.GetSelection()[0].Current.Name;Check ($before -ne $after) '방향키 결과 선택'
 [GuntEnhanceUi]::Tap(38);Check ($pattern.Current.GetSelection()[0].Current.Name -eq $before) '위 방향키 선택 복귀'
 ($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('cx');Start-Sleep -Milliseconds 200
 Check (@(Get-EnhancementTree $palette|Where-Object {$_.Name -like '*Codex*'}).Count -gt 0) 'Codex 별칭 실제 결과'
 Save-EnhancementShot ('v30-'+$ResultLabel+'-palette-keyboard') $palette.Current.BoundingRectangle
 ($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('없는검색어');Start-Sleep -Milliseconds 150
 [GuntEnhanceUi]::Tap(13);Check ($null -ne (Find-Name $win 'GUnT_0x9 명령 팔레트')) '빈 결과 Enter 안전 처리'
 [GuntEnhanceUi]::Tap(27);Start-Sleep -Milliseconds 250
 Check ($null -eq (Find-Name $win 'GUnT_0x9 명령 팔레트')) 'Escape 닫기'
 Check ([GuntEnhanceUi]::GetForegroundWindow() -eq $mainHandle) '소유 창으로 포커스 복귀'
 $bar=Get-Process GUNT-Bar -ErrorAction SilentlyContinue|Select-Object -First 1
 Check ($null -ne $bar) '기존 WinForms 상단 바 실행 유지'
 $barWindow=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $bar.Id}|Select-Object -First 1
 Check ($null -ne $barWindow) '실제 상단 바 UIA 노출'
 $gdi=@();for($i=0;$i -lt 3;$i++){$gdi+=@{Gdi=[V30DesktopNative]::GetGuiResources($bar.Handle,0);User=[V30DesktopNative]::GetGuiResources($bar.Handle,1)};Start-Sleep -Milliseconds 500}
 Save-EnhancementShot ('v30-'+$ResultLabel+'-topbar') $barWindow.Current.BoundingRectangle
 $developer=Find-Name $barWindow '개발';Check ($null -ne $developer) '상단 바 개발 메뉴'
 $expand=$null;if($developer.TryGetCurrentPattern([Windows.Automation.ExpandCollapsePattern]::Pattern,[ref]$expand)){$expand.Expand()}else{($developer.GetCurrentPattern([Windows.Automation.LegacyIAccessiblePattern]::Pattern)).DoDefaultAction()}
 Start-Sleep -Milliseconds 250
 $menu=Find-Name $barWindow '개발 세팅'
 if(!$menu){$menu=Find-Name $developer '개발 세팅'}
 Check ($null -ne $menu) '개발 세팅 메뉴 목적지'
 $invoke=$null;if($menu.TryGetCurrentPattern([Windows.Automation.InvokePattern]::Pattern,[ref]$invoke)){$invoke.Invoke()}else{($menu.GetCurrentPattern([Windows.Automation.LegacyIAccessiblePattern]::Pattern)).DoDefaultAction()}
 Start-Sleep -Seconds 2;$title=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'PageTitle')))
 Check ($title.Current.Name -eq '개발 세팅') '상단 바에서 개발 세팅 연결'
 Save-EnhancementShot ('v30-'+$ResultLabel+'-topbar-destination') $win.Current.BoundingRectangle
 Write-Json @{Status='passed';Checks=$checks;Dpi=[V30DesktopNative]::GetDpiForWindow($mainHandle);TopbarGdiSamples=$gdi;Scope='실제 OS 키 입력과 기존 상단 바 목적지. CLI 실행·배경 적용·전역 키 등록 변경 없음.'} (Join-Path $Root ('logs\v30-'+$ResultLabel+'-desktop-integration.json'))
 Write-Output ('데스크톱 통합 검사 '+$checks.Count+'개 통과')
}finally{if($p){if(!$p.HasExited){$p.CloseMainWindow()|Out-Null;$null=$p.WaitForExit(10000)};$p.Dispose()};if(!@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count){if($null -ne $originalWindow){[IO.File]::WriteAllBytes($windowFile,$originalWindow)}elseif(Test-Path $windowFile){Remove-Item -LiteralPath $windowFile}}}
