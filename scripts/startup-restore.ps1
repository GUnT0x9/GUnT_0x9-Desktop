param([switch]$Force)
. "$PSScriptRoot\common.ps1"
$settings=Get-Content (Join-Path $Root 'config\startup.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(!$Force -and !$settings.enabled){Write-Log 'startup-restore' 'disabled' '자동 복원이 꺼져 있습니다.';return}
$created=$false;$mutex=New-Object Threading.Mutex($false,'Local\GUNTDesktopRestore',[ref]$created)
if(!$mutex.WaitOne(0)){$mutex.Dispose();return}
$failures=New-Object Collections.Generic.List[string]
function Try-Step([string]$name,[scriptblock]$action){try{& $action;Write-Log $name 'passed' '복원 단계를 완료했습니다.'}catch{$failures.Add($name+': '+$_.Exception.Message);Write-Log $name 'failed' $_.Exception.Message}}
try{
 $s=Get-State;if(!$s -or $s.RolledBack){return}
 if($settings.delaySeconds -gt 0){Start-Sleep -Seconds ([math]::Min(10,$settings.delaySeconds))}
 if(!(Get-Process explorer -ErrorAction SilentlyContinue)){Start-Sleep -Seconds 2}
 Try-Step 'storage-topology' {& "$PSScriptRoot\inspect-storage-topology.ps1"|Out-Null}
 Try-Step 'layout' {if($settings.restoreLayout){& "$PSScriptRoot\update-monitor.ps1"}}
 $r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if($settings.restoreWallpaper){Try-Step 'wallpaper' {& "$PSScriptRoot\restore-wallpaper.ps1"}}
 $components=@(@('Rainmeter',$r.rainmeter,''),@('Flow.Launcher',$r.flow,''),@('windhawk',$r.windhawk,'-tray-only'),@('GUNT-Bar',(Join-Path $Root 'bin\GUNT-Bar.exe'),('"'+$Root+'"')))
 for($attempt=0;$attempt -le [math]::Max(0,[math]::Min(2,$settings.retryCount));$attempt++){
  foreach($component in $components){
   $name=$component[0];$exe=$component[1];$arguments=$component[2]
   if(!$exe -or !(Test-Path -LiteralPath $exe)){Write-Log 'startup-component' 'missing' ("실행 파일이 없습니다: "+$name);continue}
   if(!(Get-Process $name -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $exe})){
    Try-Step ('start-'+$name) {if($arguments){Start-Process $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe -Parent)|Out-Null}else{Start-Process $exe -WorkingDirectory (Split-Path $exe -Parent)|Out-Null}}
   }
  }
  if($attempt -lt $settings.retryCount){Start-Sleep -Seconds ([math]::Min(5,$settings.retryDelaySeconds))}
 }
 Try-Step 'rainmeter-layout' {Start-Process $r.rainmeter -ArgumentList '!ActivateConfig "GUNT-System-Monitor" "GUNT-System-Monitor.ini"' -WindowStyle Hidden|Out-Null}
 $monitorConfig=Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if($null -ne $monitorConfig.visible){$bang=if($monitorConfig.visible){'!Show'}else{'!Hide'};Try-Step 'widget-visibility' {Start-Process $r.rainmeter -ArgumentList ($bang+' "GUNT-System-Monitor"') -WindowStyle Hidden|Out-Null}}
 $wallpaper=Get-Content (Join-Path $Root 'config\wallpaper.json') -Raw -Encoding UTF8|ConvertFrom-Json
 # Wallpaper restoration above preserves the already running engine.
  Start-Sleep -Seconds 3
  $health=@(foreach($component in $components){
   $name=$component[0];$exe=$component[1]
   $running=@(Get-Process $name -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $exe}|Sort-Object Id)
   if(!$running.Count){$message='구성 요소가 실행되지 않았습니다: '+$name;if(!$failures.Contains($message)){$failures.Add($message)};Write-Log 'startup-health' 'failed' $message}
   $primary=$running|Select-Object -First 1
   foreach($process in $running){
    if($primary -and $process.Id -ne $primary.Id){Write-Log 'startup-health' 'duplicate' ('중복 인스턴스(종료 과도기로 추정, 강제 종료하지 않음): '+$name+' Id='+$process.Id);continue}
    if(!$process.Responding){$message='구성 요소가 응답하지 않습니다: '+$name;$failures.Add($message);Write-Log 'startup-health' 'failed' $message}
    $process|Select-Object ProcessName,Id,Path,Responding
   }
  })
 Write-Json ([ordered]@{Time=(Get-Date).ToString('o');Status=$(if($failures.Count){'partial'}else{'passed'});Processes=$health;Errors=@($failures);MonitorLayout=(Get-Content (Join-Path $Root 'config\layout.json') -Raw -Encoding UTF8|ConvertFrom-Json);Limitations='로그아웃·재부팅은 실행하지 않았습니다. 같은 복원 스크립트의 직접 실행으로 확인합니다.'}) (Join-Path $Root 'logs\startup-restore.json')
}finally{$mutex.ReleaseMutex();$mutex.Dispose()}
