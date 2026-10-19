. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root
$initial=$s.Workspace();$wall=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json';$hash=(Get-FileHash $wall).Hash
$names=@('automation-owned','automation-times','automation-history','profile-active','wallpaper-playback');$originals=@{};foreach($name in $names){$path=Join-Path $Root ('state\'+$name+'.json');if(Test-Path $path){$originals[$name]=[IO.File]::ReadAllBytes($path)}}
$rule=New-Object Gunt.ControlCenter.Models.AutomationRule;$rule.Id='qa-'+[guid]::NewGuid().ToString('N');$rule.Name='QA monitor ownership';$rule.Trigger='session-started';$rule.Action='monitor-hide';$restored=$false
try{
 $s.SaveRule($rule);$before=$s.MonitorVisible();$s.RunAutomationRule($rule.Id)|Out-Null;if($s.MonitorVisible() -ne $before){throw '중지 규칙이 실행됐습니다.'}
 $rule.Enabled=$true;$s.SaveRule($rule);$s.RunAutomationRule($rule.Id)|Out-Null;if($s.MonitorVisible()){throw '실제 자동화 모니터 숨김 실패'}
 $s.RestoreAutomationOwnership()|Out-Null;$now=$s.Workspace();foreach($key in 'compact','monitorVisible','manualPaused'){if([bool]$now[$key] -ne [bool]$initial[$key]){throw ('자동화 소유 값 복구 불일치: '+$key)}};$restored=$true
 if((Get-FileHash $wall).Hash -ne $hash){throw '자동화 시험이 배경 선택을 바꿨습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';DisabledRuleNoEffect=$true;EnabledHideVerified=$true;PreviousOwnedWorkspaceRestored=$true;WallpaperPreserved=$true;Limitations='실제 전원 분리·모니터 재연결·앱 실행 조건의 장시간 감시는 미시험.'} (Join-Path $Root 'logs\v26-automation-live.json')
 Write-Output '중지 규칙 무효·사용 규칙 실제 모니터 숨김·소유 상태 복원·배경 선택 보존 통과'
}finally{
 $s.DeleteRule($rule.Id)
 if(!$restored){$s.Action($(if([bool]$initial.monitorVisible){'monitor-show'}else{'monitor-hide'}))}
 foreach($name in $names){$path=Join-Path $Root ('state\'+$name+'.json');if($originals.ContainsKey($name)){[IO.File]::WriteAllBytes($path,$originals[$name])}elseif(Test-Path $path){$archive=Join-Path $Root ('backups\qa-v26-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $archive|Out-Null;Move-Item $path $archive}}
}
