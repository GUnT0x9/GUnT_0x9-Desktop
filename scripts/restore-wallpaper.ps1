. "$PSScriptRoot\common.ps1"
$c=Get-Content (Join-Path $Root 'config\wallpaper.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$c.liveEnabled){& "$PSScriptRoot\apply-wallpaper.ps1";return}
try{
 $engine=$c.enginePath
 if(!$engine -or !(Test-Path $engine)){throw '보존한 Lively 실행 파일이 없습니다.'}
 $layoutFile=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json'
 if(Test-Path $layoutFile){
  $assignments=@(Get-Content $layoutFile -Raw -Encoding UTF8|ConvertFrom-Json)
  $current=$assignments|Where-Object {$_.LivelyInfoPath -and (Test-Path (Join-Path $_.LivelyInfoPath 'LivelyInfo.json'))}|Select-Object -First 1
  if($current -and $c.activeProject -ne $current.LivelyInfoPath){$c.activeProject=$current.LivelyInfoPath;Write-Json $c (Join-Path $Root 'config\wallpaper.json')}
 }
 $running=@(Get-Process Lively -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $engine})
 if(!$running.Count){Start-Process $engine -ArgumentList 'app --showApp false'|Out-Null;Start-Sleep -Seconds 3}
 $engineDir=Split-Path $engine -Parent
 $players=@(Get-Process -ErrorAction SilentlyContinue|Where-Object {$_.Path -and $_.Path.StartsWith($engineDir,[StringComparison]::OrdinalIgnoreCase) -and $_.ProcessName -match 'mpv|Player'})
 if(!$players.Count){
  if(!$c.activeProject -or !(Test-Path (Join-Path $c.activeProject 'LivelyInfo.json'))){throw '보존한 라이브 배경 패키지가 없습니다.'}
  $request=Start-Process $engine -ArgumentList ('setwp --file "'+$c.activeProject+'"') -PassThru
  if(!$request.WaitForExit(10000) -or $request.ExitCode -ne 0){throw 'Lively 배경 복원 요청에 실패했습니다.'}
 }
 $playbackPath=Join-Path $Root 'state\wallpaper-playback.json'
 if(Test-Path $playbackPath){$policy=Get-Content $playbackPath -Raw -Encoding UTF8|ConvertFrom-Json;if([bool]$policy.ManualPaused){try{$pause=Start-Process $engine -ArgumentList 'app --play false' -PassThru -WindowStyle Hidden;if(!$pause.WaitForExit(10000) -or $pause.ExitCode -ne 0){throw '수동 중지 정책 응답을 확인하지 못했습니다.'};Write-Log 'wallpaper-policy-restore' 'requested' '저장된 수동 중지 정책을 요청했습니다. 실제 프레임 재생은 Lively에서 확인하세요.'}catch{Write-Log 'wallpaper-policy-restore' 'partial' $_.Exception.Message}}}
 Write-Log 'wallpaper-restore' 'passed' '기존 Lively 배경과 엔진을 보존했습니다. 재생 정책은 Lively가 관리합니다.'
}catch{
 & "$PSScriptRoot\apply-wallpaper.ps1"
 Write-Log 'wallpaper-restore' 'static-fallback' ('기존 라이브 배경을 복원하지 못해 정적 배경을 적용했습니다: '+$_.Exception.Message)
}
