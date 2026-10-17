param([Parameter(Mandatory=$true)][string]$Action,[string]$Value='')
. "$PSScriptRoot\common.ps1"
Add-Type @'
using System;using System.Text;using System.Runtime.InteropServices;
public static class GuntActionNative {
 public delegate bool Callback(IntPtr h,IntPtr p);
 [DllImport("user32.dll")]static extern bool EnumWindows(Callback c,IntPtr p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr p);
 public static IntPtr Monitor(){IntPtr found=IntPtr.Zero;EnumWindows(delegate(IntPtr h,IntPtr p){var c=new StringBuilder(128);var t=new StringBuilder(512);GetClassName(h,c,128);GetWindowText(h,t,512);if(c.ToString()=="RainmeterMeterWindow"&&t.ToString().Contains("GUNT-System-Monitor"))found=h;return true;},IntPtr.Zero);return found;}
 public static IntPtr Bar(){IntPtr found=IntPtr.Zero;EnumWindows(delegate(IntPtr h,IntPtr p){var t=new StringBuilder(512);GetWindowText(h,t,512);if(t.ToString()=="GUNT Desktop \u2014 Midnight Purple")found=h;return true;},IntPtr.Zero);return found;}
 public static void Win(byte key,bool shift){keybd_event(0x5b,0,0,UIntPtr.Zero);if(shift)keybd_event(0x10,0,0,UIntPtr.Zero);keybd_event(key,0,0,UIntPtr.Zero);keybd_event(key,0,2,UIntPtr.Zero);if(shift)keybd_event(0x10,0,2,UIntPtr.Zero);keybd_event(0x5b,0,2,UIntPtr.Zero);}
}
'@
$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
function Read-Config([string]$Name){for($readAttempt=0;;$readAttempt++){try{return (Get-Content (Join-Path $Root ('config\'+$Name+'.json')) -Raw -Encoding UTF8|ConvertFrom-Json)}catch{if($readAttempt -ge 5 -or $_.Exception -isnot [IO.IOException]){throw};Start-Sleep -Milliseconds 50}}}
function Backup-Config([string]$Name){$p=Join-Path $Root ('config\'+$Name+'.json');$b=Join-Path $Root ('backups\settings-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'\'+$Name+'.json');New-Item -ItemType Directory -Force (Split-Path $b -Parent)|Out-Null;Copy-Item $p $b;return $b}
function Monitor-Visible { $h=[GuntActionNative]::Monitor();$h -ne [IntPtr]::Zero -and [GuntActionNative]::IsWindowVisible($h) }
function Set-Monitor([bool]$Visible){
 $monitorConfig=Read-Config 'monitor';$null=Backup-Config 'monitor'
 $monitorConfig|Add-Member -NotePropertyName visible -NotePropertyValue $Visible -Force
 Write-Json $monitorConfig (Join-Path $Root 'config\monitor.json')
 if(Test-Path $r.variables){
  $vars=[IO.File]::ReadAllText($r.variables);$action=if($Visible){'!Show'}else{'!Hide'}
  if($vars -match '(?m)^VisibilityAction='){$vars=$vars -replace '(?m)^VisibilityAction=.*$',('VisibilityAction='+$action)}else{$vars+="`r`nVisibilityAction=$action`r`n"}
  [IO.File]::WriteAllText($r.variables,$vars,[Text.Encoding]::Unicode)
 }
 $h=[GuntActionNative]::Monitor()
 if($h -eq [IntPtr]::Zero -and $Visible){Start-Process $r.rainmeter -ArgumentList '!ActivateConfig "GUNT-System-Monitor" "GUNT-System-Monitor.ini"' -Wait|Out-Null;Start-Sleep -Milliseconds 200}
 $measureBang=if($Visible){'!EnableMeasureGroup'}else{'!DisableMeasureGroup'}
 Start-Process $r.rainmeter -ArgumentList ($measureBang+' Monitoring "GUNT-System-Monitor"') -Wait -WindowStyle Hidden|Out-Null
 $bang=if($Visible){'!Show'}else{'!Hide'}
 Start-Process $r.rainmeter -ArgumentList ($bang+' "GUNT-System-Monitor"') -Wait -WindowStyle Hidden|Out-Null
 Start-Sleep -Milliseconds 150
 if((Monitor-Visible) -ne $Visible){throw 'Rainmeter 표시 상태가 요청과 일치하지 않습니다.'}
 $statePath=Join-Path $Root 'state\desktop.json'
 $state=if(Test-Path $statePath){Get-Content $statePath -Raw -Encoding UTF8|ConvertFrom-Json}else{[pscustomobject]@{}}
 $state|Add-Member -NotePropertyName monitorVisible -NotePropertyValue $Visible -Force
 Write-Json $state $statePath
}
function Lively-Command([string]$Arguments){
 $wall=Read-Config 'wallpaper';$engine=$wall.enginePath
 if(!$engine){$engine=Join-Path $env:LOCALAPPDATA 'Programs\Lively Wallpaper\Lively.exe'}
 if(!(Test-Path $engine)){throw 'Lively 엔진을 찾을 수 없습니다.'}
 if(!(Get-Process Lively -ErrorAction SilentlyContinue)){if($Arguments -eq 'app --showApp true'){Start-Process $engine -ArgumentList $Arguments|Out-Null;return};throw 'Lively가 실행되지 않았습니다. 배경 설정에서 엔진을 먼저 열어 주세요.'}
 $process=Start-Process $engine -ArgumentList $Arguments -PassThru -WindowStyle Hidden
 if(!$process.WaitForExit(10000)){throw 'Lively 명령 응답이 지연되고 있습니다. 엔진을 강제 종료하지 않았습니다.'}
 if($process.ExitCode -ne 0){throw ('Lively 명령 반환 코드: '+$process.ExitCode)}
}
function Set-Playback([bool]$Paused){
 Lively-Command ('app --play '+(!$Paused).ToString().ToLowerInvariant())
 Write-Json @{Time=(Get-Date).ToString('o');ManualPaused=$Paused;Policy=$(if($Paused){'alwaysPaused'}else{'automatic'});Verification='Lively 공식 재생 정책 명령 완료. 자동 정책의 실제 재생 여부는 가림·전원 상태에도 좌우됩니다.'} (Join-Path $Root 'state\wallpaper-playback.json')
}
function Set-WallpaperMode([bool]$Live){
 $c=Read-Config 'wallpaper';$backup=Backup-Config 'wallpaper'
 try{
  if($Live){
   $assignmentPath=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json'
   if(Test-Path $assignmentPath){$current=@(Get-Content $assignmentPath -Raw -Encoding UTF8|ConvertFrom-Json)|Where-Object {$_.LivelyInfoPath -and (Test-Path (Join-Path $_.LivelyInfoPath 'LivelyInfo.json'))}|Select-Object -First 1;if($current){$c.activeProject=$current.LivelyInfoPath}}
   if(!$c.activeProject -or !(Test-Path (Join-Path $c.activeProject 'LivelyInfo.json'))){throw '보존한 라이브 배경 패키지를 찾을 수 없습니다.'}
   Lively-Command ('setwp --file "'+$c.activeProject+'"');Set-Playback $false
  }else{
   $assignmentPath=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json'
   if(Test-Path $assignmentPath){$assignments=@(Get-Content $assignmentPath -Raw -Encoding UTF8|ConvertFrom-Json);Write-Json $assignments (Join-Path $Root 'state\lively-last-assignment.json');$current=$assignments|Where-Object {$_.LivelyInfoPath -and (Test-Path (Join-Path $_.LivelyInfoPath 'LivelyInfo.json'))}|Select-Object -First 1;if($current){$c.activeProject=$current.LivelyInfoPath}}
   Lively-Command 'closewp --monitor -1';& "$PSScriptRoot\apply-wallpaper.ps1"
  }
  $c.liveEnabled=$Live;Write-Json $c (Join-Path $Root 'config\wallpaper.json')
 }catch{Copy-Item $backup (Join-Path $Root 'config\wallpaper.json') -Force;throw}
}
function Capture-Profile([string]$Name){
 $monitor=Read-Config 'monitor';$playPath=Join-Path $Root 'state\wallpaper-playback.json'
 $play=if(Test-Path $playPath){Get-Content $playPath -Raw -Encoding UTF8|ConvertFrom-Json}else{[pscustomobject]@{ManualPaused=$false}}
 [ordered]@{schemaVersion=2;name=$Name;created=(Get-Date).ToString('o');restoreScope='workspace';settings=@{monitor=@{compact=[bool]$monitor.compact}};compact=[bool]$monitor.compact;monitorVisible=(Monitor-Visible);manualPaused=[bool]$play.ManualPaused}
}

function Apply-Profile($Profile,[bool]$Restoring=$false){
 $Profile|Add-Member -NotePropertyName restoreScope -NotePropertyValue workspace -Force
 $previous=Capture-Profile '사용자 설정';$previous.restoreScope='workspace';$activeFile=Join-Path $Root 'state\profile-active.json';if(Test-Path $activeFile){$priorActive=Get-Content $activeFile -Raw -Encoding UTF8|ConvertFrom-Json;$previous.name=$priorActive.name;$previous.id=$priorActive.id}

 try{
  if($Profile.restoreScope -eq 'workspace' -and $Profile.settings.monitor){$Profile|Add-Member -NotePropertyName compact -NotePropertyValue ([bool]$Profile.settings.monitor.compact) -Force}
  if($null -ne $Profile.compact){$m=Read-Config 'monitor';$null=Backup-Config 'monitor';$m.compact=[bool]$Profile.compact;Write-Json $m (Join-Path $Root 'config\monitor.json')}
  & "$PSScriptRoot\update-monitor.ps1"
  Set-Monitor ([bool]$Profile.monitorVisible)
  Set-Playback ([bool]$Profile.manualPaused)
  [GuntActionNative]::PostMessage([GuntActionNative]::Bar(),0x8002,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null
  if($Restoring){$priorFile=Join-Path $Root 'state\profile-previous.json';if(Test-Path $priorFile){$consumed=Join-Path $Root ('backups\consumed-profile-'+(Get-Date -Format 'yyyyMMddHHmmssfff')+'.json');Move-Item $priorFile $consumed}}else{Write-Json $previous (Join-Path $Root 'state\profile-previous.json')}
  Write-Json @{id=$Profile.id;name=$Profile.name;Time=(Get-Date).ToString('o')} (Join-Path $Root 'state\profile-active.json')
 }catch{
  $current=Read-Config 'monitor';$current.compact=$previous.settings.monitor.compact;Write-Json $current (Join-Path $Root 'config\monitor.json')
  try{& "$PSScriptRoot\update-monitor.ps1";Set-Monitor ([bool]$previous.monitorVisible);Set-Playback ([bool]$previous.manualPaused)}catch{Write-Log 'profile-rollback' 'failed' $_.Exception.Message}
  throw
 }
}
$actionMutex=New-Object Threading.Mutex($false,'Local\GUNTDesktopAction')
$locked=$actionMutex.WaitOne(15000)
if(!$locked){$actionMutex.Dispose();throw '다른 설정 적용이 진행 중입니다. 잠시 후 다시 시도하세요.'}
try{
 switch($Action){
  'monitor-toggle' {Set-Monitor (!(Monitor-Visible))}
  'monitor-show' {Set-Monitor $true}
  'monitor-hide' {Set-Monitor $false}
  'monitor-compact-toggle' {$null=Backup-Config 'monitor';& "$PSScriptRoot\toggle-monitor.ps1"}
  'monitor-details' {$null=Backup-Config 'monitor';$m=Read-Config 'monitor';$m.compact=$false;Write-Json $m (Join-Path $Root 'config\monitor.json');& "$PSScriptRoot\update-monitor.ps1";Set-Monitor $true}
  'monitor-reload' {& "$PSScriptRoot\update-monitor.ps1"}
  'wallpaper-toggle' {$p=Join-Path $Root 'state\wallpaper-playback.json';$paused=$false;if(Test-Path $p){$paused=[bool](Get-Content $p -Raw -Encoding UTF8|ConvertFrom-Json).ManualPaused};Set-Playback (!$paused)}
  'wallpaper-pause' {Set-Playback $true}
  'wallpaper-play' {Set-Playback $false}
  'wallpaper-static' {Set-WallpaperMode $false}
  'wallpaper-live' {Set-WallpaperMode $true}
  'wallpaper-settings' {Lively-Command 'app --showApp true'}
  'profile-preview' {if($Value -notmatch '^[a-zA-Z0-9가-힣 _-]+$'){throw '프로필 ID를 확인하세요.'};Write-Json @{id=$Value} (Join-Path $Root 'state\profile-request.json');Start-Process (Join-Path $Root 'bin\GUNT.ControlCenter.exe') -ArgumentList ('"'+$Root+'" profiles')}
  'profile-apply'  {if($Value -notmatch '^[a-zA-Z0-9가-힣 _-]+$'){throw '프로필 이름에 허용되지 않는 문자가 있습니다.'};$file=Join-Path $Root ('config\profiles\'+$Value+'.json');if(!(Test-Path $file)){throw '프로필을 찾을 수 없습니다.'};$profile=Get-Content $file -Raw -Encoding UTF8|ConvertFrom-Json;$profile|Add-Member -NotePropertyName id -NotePropertyValue $Value -Force;Apply-Profile $profile}
  'profile-restore' {$file=Join-Path $Root 'state\profile-previous.json';if(!(Test-Path $file)){throw '돌아갈 이전 프로필 상태가 없습니다.'};$profile=Get-Content $file -Raw -Encoding UTF8|ConvertFrom-Json;if($profile.created -and ((Get-Date)-[datetime]$profile.created).TotalDays -gt 7){throw '이전 상태가 7일보다 오래돼 자동 복원하지 않습니다.'};Apply-Profile $profile $true}
  'profile-save' {if($Value -notmatch '^[a-zA-Z0-9가-힣 _-]+$'){throw '프로필 이름을 확인하세요.'};$file=Join-Path $Root ('config\profiles\'+$Value+'.json');if(Test-Path $file){throw '같은 이름의 프로필이 있습니다. 다른 이름으로 저장하세요.'};Write-Json (Capture-Profile $Value) $file}
  'focus-toggle' {$p=Join-Path $Root 'state\profile-active.json';$name=if(Test-Path $p){(Get-Content $p -Raw -Encoding UTF8|ConvertFrom-Json).name}else{''}; $playbackPath=Join-Path $Root 'state\wallpaper-playback.json';$manualPaused=$false;if(Test-Path $playbackPath){$manualPaused=[bool](Get-Content $playbackPath -Raw -Encoding UTF8|ConvertFrom-Json).ManualPaused};if($name -eq '집중' -and !(Monitor-Visible) -and $manualPaused){$prior=Get-Content (Join-Path $Root 'state\profile-previous.json') -Raw -Encoding UTF8|ConvertFrom-Json;$prior|Add-Member -NotePropertyName restoreScope -NotePropertyValue 'workspace' -Force;Apply-Profile $prior $true}else{Apply-Profile (Get-Content (Join-Path $Root 'config\profiles\Focus.json') -Raw -Encoding UTF8|ConvertFrom-Json)}}
  'focus-settings' {Start-Process 'ms-settings:quietmomentshome'}
  'recording' {Apply-Profile (Get-Content (Join-Path $Root 'config\profiles\Focus.json') -Raw -Encoding UTF8|ConvertFrom-Json);[GuntActionNative]::Win(0x52,$true)}
  'clipboard' {[GuntActionNative]::Win(0x56,$false)}
  'layout-restore' {& "$PSScriptRoot\update-monitor.ps1";[GuntActionNative]::PostMessage([GuntActionNative]::Bar(),0x8002,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null}
  'bar-reload' {if(![GuntActionNative]::PostMessage([GuntActionNative]::Bar(),0x8002,[IntPtr]::Zero,[IntPtr]::Zero)){throw '상단 바 창이 없어 새로고침을 전달하지 못했습니다.'}}
  'startup-recover' {& "$PSScriptRoot\startup-restore.ps1" -Force}
  'backup' {& "$PSScriptRoot\checkpoint.ps1" -Name user-v24}
  'settings' {$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';if(Test-Path $exe){Start-Process $exe -ArgumentList ('"'+$Root+'" "'+$Value+'"')}else{Start-Process explorer.exe -ArgumentList ('"'+(Join-Path $Root 'config')+'"')}}
  default {throw ('지원하지 않는 동작입니다: '+$Action)}
 }
 $result=@{Time=(Get-Date).ToString('o');Action=$Action;Value=$Value;Status='passed';MonitorVisible=(Monitor-Visible)}
 Write-Json $result (Join-Path $Root 'state\last-action.json');Write-Log 'desktop-action' 'passed' ($Action+' '+$Value)
}catch{
 Write-Json @{Time=(Get-Date).ToString('o');Action=$Action;Value=$Value;Status='failed';Error=$_.Exception.Message} (Join-Path $Root 'state\last-action.json')
 Write-Log 'desktop-action' 'failed' ($Action+': '+$_.Exception.Message);throw
}
finally{if($locked){$actionMutex.ReleaseMutex()};$actionMutex.Dispose()}
