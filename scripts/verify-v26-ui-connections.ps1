. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
Add-Type @'
using System;using System.Runtime.InteropServices;public static class V26Modal{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);public static IntPtr Find(string t){return FindWindow(null,t);}}
'@
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root;$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
Start-Process $exe -ArgumentList ('"'+$Root+'" development-sessions');Start-Sleep -Seconds 2;$main=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 Desktop'}|Select-Object -First 1
$button=Find-Name $main '개발 세션 시작';($button.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();$h=[IntPtr]::Zero;for($i=0;$i -lt 50 -and $h -eq [IntPtr]::Zero;$i++){Start-Sleep -Milliseconds 100;$h=[V26Modal]::Find('개발 세션 실행')};if($h -eq [IntPtr]::Zero){throw '실제 세션 요약 창 없음'}
$dialog=[Windows.Automation.AutomationElement]::FromHandle($h);$text=((Get-EnhancementTree $dialog)|ForEach-Object Name) -join "`n";if(!$text.Contains($s.ActiveProject().Directory) -or !$text.Contains('VS Code')){throw '실행 요약의 대상 폴더/도구 불일치'};($dialog.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();Start-Sleep -Seconds 1
$bar=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 Desktop 한국어 메뉴 바'}|Select-Object -First 1;$brand=Find-Name $bar 'GUnT_0x9';$rect=$brand.Current.BoundingRectangle;[GuntEnhanceUi]::Click([int]($rect.X+$rect.Width/2),[int]($rect.Y+$rect.Height/2));Start-Sleep -Milliseconds 300
$quick=[Windows.Automation.AutomationElement]::RootElement.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'빠른 패널')));if(!$quick){throw '상단 바 빠른 패널 메뉴 없음'};($quick.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();Start-Sleep -Seconds 2
$popup=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 빠른 패널'}|Select-Object -First 1;if(!$popup){throw '실제 메뉴에서 빠른 패널 열기 실패'};($popup.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close()
Write-Json @{Time=(Get-Date).ToString('o');Status='passed';SessionPreviewActualPath=$true;SessionCancelledWithoutLaunch=$true;TopBarQuickPanelConnected=$true} (Join-Path $Root 'logs\v26-ui-connections.json')
Start-Process $exe -ArgumentList ('"'+$Root+'" developer-setup')
Write-Output '실제 세션 요약·취소·상단 바 메뉴 → 빠른 패널 연결 통과'
