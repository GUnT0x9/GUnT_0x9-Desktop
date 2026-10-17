. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$service=New-Object Gunt.ControlCenter.Services.DesktopService $Root
$monitor=Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json
$initialVisible=$service.MonitorVisible();$playback=$service.State('wallpaper-playback');$initialPaused=[Gunt.ControlCenter.Services.DesktopService]::B($playback,'ManualPaused')
$wallpaper=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json';$wallHash=(Get-FileHash $wallpaper).Hash
$states=@{};foreach($name in 'profile-active','profile-previous','wallpaper-playback'){$file=Join-Path $Root ('state\'+$name+'.json');if(Test-Path $file){$states[$name]=[IO.File]::ReadAllBytes($file)}}
$qa='user-qa-'+[guid]::NewGuid().ToString('N').Substring(0,8);$qaPath=Join-Path $Root ('config\profiles\'+$qa+'.json')
Write-Json @{schemaVersion=2;name='QA restore';builtin=$false;monitorVisible=$initialVisible;compact=[bool]$monitor.compact;manualPaused=$initialPaused} $qaPath
$results=@()
try{
 foreach($id in 'Developer','Daily','Gaming','Focus'){
  $service.Action('profile-apply',$id);$profile=$service.Profiles()|Where-Object Id -eq $id;$expected=$service.ProfileValues($profile);$actual=$service.Workspace()
  foreach($key in 'monitorVisible','compact','manualPaused'){if([bool]$expected[$key] -ne [bool]$actual[$key]){throw ('프로필 상태 불일치: '+$id+' '+$key)}}
  if((Get-FileHash $wallpaper).Hash -ne $wallHash){throw '프로필 적용 중 배경 선택이 변경됐습니다.'}
  $current=Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json
  if(($current.position|ConvertTo-Json -Compress) -ne ($monitor.position|ConvertTo-Json -Compress)){throw '프로필이 저장된 모니터 위치를 바꿨습니다.'}
  $results+=@{Test=$id;Status='passed';Expected=$expected;Actual=$actual};Write-Output ('[passed] '+$id+' 실제 상태·배경·위치 보존')
 }
 $service.Action('profile-restore');if(Test-Path (Join-Path $Root 'state\profile-previous.json')){throw '이전 상태가 소비되지 않았습니다.'}
 $rejected=$false;try{$service.Action('profile-restore')}catch{$rejected=$true};if(!$rejected){throw '소비한 복원이 다시 실행됐습니다.'};$results+=@{Test='restore-once';Status='passed'};Write-Output '[passed] 이전 상태 복원 1회·재복원 거부'
}finally{
 try{$service.Action('profile-apply',$qa)}finally{foreach($name in 'profile-active','profile-previous','wallpaper-playback'){$file=Join-Path $Root ('state\'+$name+'.json');if($states.ContainsKey($name)){[IO.File]::WriteAllBytes($file,$states[$name])}elseif(Test-Path $file){Remove-Item $file}};if(Test-Path $qaPath){Remove-Item $qaPath}}
}
$restored=$service.Workspace();if([bool]$restored.monitorVisible -ne $initialVisible -or [bool]$restored.compact -ne [bool]$monitor.compact -or [bool]$restored.manualPaused -ne $initialPaused){throw '시험 전 작업공간으로 돌아오지 못했습니다.'}
Write-Json @{Time=(Get-Date).ToString('o');Results=$results;BaselineRestored=$true;WallpaperPreserved=((Get-FileHash $wallpaper).Hash -eq $wallHash);Limitations='재생 상태는 GUNT 수동 정책 요청 기준. Lively의 전체 화면·전원 정책은 별도로 작동함.'} (Join-Path $Root 'logs\v25-live-profiles.json')
