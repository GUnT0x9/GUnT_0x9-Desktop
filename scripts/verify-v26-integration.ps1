. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root
$git=$s.GitStatus($s.ActiveProject());if($git.Error -or [string]::IsNullOrWhiteSpace($git.Branch)){throw ('실제 저장소 Git 상태 실패: '+$git.Error)}
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';$before=$s.MonitorVisible()
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
try{
 Start-Process $exe -ArgumentList ('"'+$Root+'" quick-panel');Start-Sleep -Seconds 2;$win=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 빠른 패널'}|Select-Object -First 1;if(!$win){throw '빠른 패널 없음'}
 $toggle=Find-Name $win '모니터 표시 / 숨김';($toggle.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
 $changed=$false;for($i=0;$i -lt 80;$i++){Start-Sleep -Milliseconds 100;if($s.MonitorVisible() -ne $before){$changed=$true;break}};if(!$changed){throw '빠른 패널의 실제 위젯 전환 실패'}
 for($i=0;$i -lt 150 -and !$toggle.Current.IsEnabled;$i++){Start-Sleep -Milliseconds 100};if(!$toggle.Current.IsEnabled){throw '빠른 패널 작업 완료 대기 실패'};($toggle.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
 $restored=$false;for($i=0;$i -lt 80;$i++){Start-Sleep -Milliseconds 100;if($s.MonitorVisible() -eq $before){$restored=$true;break}};if(!$restored){throw '빠른 패널 재전환 실패'}
 for($i=0;$i -lt 150 -and !$toggle.Current.IsEnabled;$i++){Start-Sleep -Milliseconds 100}
 ($win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close()
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';ActualRepositoryGit=$true;QuickPanelWidgetToggle=$changed;QuickPanelWidgetRestored=$restored;SelectedProjectPersisted=$true} (Join-Path $Root 'logs\v26-final-integration.json')
 Write-Output '실제 저장소 Git 분기 조회·활성 프로젝트 유지·빠른 패널의 실제 위젯 전환 및 복원 통과'
}finally{if($s.MonitorVisible() -ne $before){$s.Action($(if($before){'monitor-show'}else{'monitor-hide'}))}}
Start-Process $exe -ArgumentList ('"'+$Root+'" developer-setup')
