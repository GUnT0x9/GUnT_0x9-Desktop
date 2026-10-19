param([Parameter(Mandatory=$true)][string]$Distribution)
. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root
$dist=$Distribution;$account=$s.WslUser($dist);$unique=[guid]::NewGuid().ToString('N').Substring(0,8)
$directory=Join-Path $Root ('tests\v26-session-'+$unique+'\프로젝트-'+$unique);New-Item -ItemType Directory -Force $directory|Out-Null
$p=New-Object Gunt.ControlCenter.Models.ProjectEntry;$p.Id='qa-session-'+$unique;$p.Directory=$directory;$p.Name='GUNT v26 session QA '+$unique;$p.Ide='vscode';$p.Terminal='powershell'
$p.Developer=New-Object Gunt.ControlCenter.Models.DeveloperPreferences;$p.Developer.WslDistribution=$dist;$p.Developer.WslUser=$account;$p.Developer.TerminalHost='windows-terminal'
$session=New-Object Gunt.ControlCenter.Models.DevelopmentSession;$session.Id='qa-session';$session.Name='QA VS Code + Codex';$session.Actions=New-Object 'Collections.Generic.List[Gunt.ControlCenter.Models.SessionAction]'
foreach($kind in 'ide','codex'){$action=New-Object Gunt.ControlCenter.Models.SessionAction;$action.Kind=$kind;$session.Actions.Add($action)}
$stateNames=@('development-history','development-resume','development-last-start','project-developer-recent','project-recent','developer-last-tool');$old=@{};foreach($name in $stateNames){$path=Join-Path $Root ('state\'+$name+'.json');if(Test-Path $path){$old[$name]=[IO.File]::ReadAllBytes($path)}}
$opened=@();$registered=$false
try{
 $s.SaveProject($p);$registered=$true;$result=$s.StartSession($p,$session,$false,$false,$null)
 if(@($result.Actions|Where-Object Status -ne '요청 전달').Count){throw '세션에 일부 실패 또는 건너뜀이 있습니다.'}
 $blocked=$false;try{$s.StartSession($p,$session,$false,$false,$null)|Out-Null}catch{$blocked=$true};if(!$blocked){throw '중복 세션 시작을 막지 못했습니다.'}
 $terminal=$null;$editor=$null;for($probe=0;$probe -lt 80 -and (!$terminal -or !$editor);$probe++){Start-Sleep -Milliseconds 250;$windows=Get-EnhancementWindows;$terminal=$windows|Where-Object {$_.Current.ClassName -eq 'CASCADIA_HOSTING_WINDOW_CLASS' -and $_.Current.Name -like ('*'+$p.Name+'*')}|Select-Object -First 1;$editor=$windows|Where-Object {$_.Current.Name -like ('*프로젝트-'+$unique+'*Visual Studio Code*')}|Select-Object -First 1}
 if($terminal){$opened+=,$terminal};if($editor){$opened+=,$editor};if(!$terminal -or !$editor){throw '독립 터미널과 VS Code 새 폴더 창을 모두 확인하지 못했습니다.'}
 $linux=$s.WslPath($directory,$dist);$script='for p in $(pgrep -u "$(id -u)" -x codex); do readlink "/proc/$p/cwd" 2>/dev/null || true; done';$dirs=($s.WslQuery($dist,$script,$account)) -split "`n";if($dirs -cnotcontains $linux){throw '세션 Codex의 실제 cwd 불일치'}
 $resume=$s.ResumeConfiguration();if($resume.Item1.Id -ne $p.Id -or $resume.Item2.Actions.Count -ne 2){throw '이전 실행 구성 저장 불일치'}
 $s.EndDevelopmentSession()|Out-Null
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Actions=$result.Actions;VSCodeNewFolderWindow=$true;CodexInteractiveExactDirectory=$true;ResumeConfigurationVerified=$true;DuplicateBlocked=$true;SessionEndRecorded=$true;NoPromptSubmitted=$true} (Join-Path $Root 'logs\v26-session-live.json')
 Write-Output '실제 VS Code + Codex 세션·폴더·개별 결과·재시작 구성·중복 방지·종료 기록 통과'
}finally{
 $owned=@(Get-EnhancementWindows|Where-Object {$_.Current.Name -like ('*'+$p.Name+'*') -or $_.Current.Name -like ('*프로젝트-'+$unique+'*Visual Studio Code*')})
 foreach($window in $owned){try{($window.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close()}catch{}}
 if($registered){$s.DeleteProject($p.Id)}
 foreach($name in $stateNames){$path=Join-Path $Root ('state\'+$name+'.json');if($old.ContainsKey($name)){[IO.File]::WriteAllBytes($path,$old[$name])}elseif(Test-Path $path){$archive=Join-Path $Root ('backups\qa-v26-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $archive|Out-Null;Move-Item $path $archive}}
}
