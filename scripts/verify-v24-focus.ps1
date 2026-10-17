. "$PSScriptRoot\common.ps1"
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '이 검사는 제어 센터를 닫은 상태에서 실행하세요.'}
$monitorFile=Join-Path $Root 'config\monitor.json';$before=Get-Content $monitorFile -Raw -Encoding UTF8|ConvertFrom-Json
$files=@('state\profile-active.json','state\profile-previous.json');$prior=@{}
foreach($name in $files){$p=Join-Path $Root $name;if(Test-Path $p){$prior[$name]=[IO.File]::ReadAllText($p)}}
$applied=$false
try{
 & "$PSScriptRoot\desktop-actions.ps1" -Action profile-apply -Value Focus;$applied=$true
 $focused=Get-Content $monitorFile -Raw -Encoding UTF8|ConvertFrom-Json;$play=Get-Content (Join-Path $Root 'state\wallpaper-playback.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if($focused.visible -or !$play.ManualPaused){throw '집중 프로필의 실제 표시·재생 정책이 다릅니다.'}
 Start-Sleep -Seconds 3;$a=Get-Content (Join-Path $Root 'state\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json;Start-Sleep -Seconds 4;$b=Get-Content (Join-Path $Root 'state\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if($a.Sample -ne $b.Sample){throw '위젯 숨김 상태에서 네이티브 수집이 계속됩니다.'}
 & "$PSScriptRoot\desktop-actions.ps1" -Action profile-restore;$applied=$false
 $after=Get-Content $monitorFile -Raw -Encoding UTF8|ConvertFrom-Json
 if($before.visible -ne $after.visible -or $before.compact -ne $after.compact -or ($before.position|ConvertTo-Json -Compress) -ne ($after.position|ConvertTo-Json -Compress)){throw '집중 복귀 후 원래 모드·배치가 복원되지 않았습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';ActualMonitorHidden=$true;LivelyManualPolicyPaused=$true;NativeSamplingSuspended=$true;OriginalLayoutRestored=$true;LivelyActualFrameRendering='자동 정책·가림 상태에 따른 실제 프레임 상태는 별도 검증'} (Join-Path $Root 'logs\v24-focus-verification.json')
 Write-Log 'focus-v24-test' 'passed' '집중 모드 숨김·배경 정지 정책·수집 중단과 이전 배치 복원을 확인했습니다.'
}finally{
 if($applied){& "$PSScriptRoot\desktop-actions.ps1" -Action profile-restore}
 foreach($name in $prior.Keys){[IO.File]::WriteAllText((Join-Path $Root $name),$prior[$name],$Utf8)}
}
