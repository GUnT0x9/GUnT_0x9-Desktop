param([Parameter(Mandatory=$true)][string]$Distribution)
. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root
$dist=$Distribution;$account=$s.WslUser($dist)
$fixture=Join-Path $Root ('tests\v26-live-'+[guid]::NewGuid().ToString('N')+'\한글 프로젝트 (검증) apostrophe'' & $ ; %')
New-Item -ItemType Directory -Force $fixture|Out-Null
$p=New-Object Gunt.ControlCenter.Models.ProjectEntry;$p.Id='qa-live';$p.Directory=$fixture;$p.Name='GUNT v26 QA';$p.Ide='vscode';$p.Terminal='powershell'
$prefs=New-Object Gunt.ControlCenter.Models.DeveloperPreferences;$prefs.TerminalHost='windows-terminal';$prefs.WslDistribution=$dist;$prefs.WslUser=$account;$prefs.CodexExecutable='codex';$prefs.OpenCodeExecutable='opencode'
$converted=$s.WslPath($fixture,$dist);$actual=$s.WslQuery($dist,('cd -- '+[Gunt.ControlCenter.Services.DesktopService]::Posix($converted)+' && printf %s "$PWD"'),$account)
if($actual -cne $converted){throw '한글·공백·따옴표·특수문자 폴더의 실제 WSL cwd 불일치'}
$results=New-Object Collections.Generic.List[object]
function Cli-Directories([string]$tool){$script='for p in $(pgrep -u "$(id -u)" -x '+$tool+'); do readlink "/proc/$p/cwd" 2>/dev/null || true; done';@(($s.WslQuery($dist,$script,$account)) -split "`n"|ForEach-Object {$_.TrimEnd("`r")})}
function Terminal-Window([string]$title){Get-EnhancementWindows|Where-Object {$_.Current.ClassName -in @('CASCADIA_HOSTING_WINDOW_CLASS','ConsoleWindowClass') -and $_.Current.Name -like ('*'+$title+'*')}|Select-Object -First 1}
$cases=@(@{Tool='codex';Host='windows-terminal'},@{Tool='opencode';Host='windows-terminal'},@{Tool='codex';Host='cmd'})
foreach($case in $cases){$tool=$case.Tool;$prefs.TerminalHost=$case.Host;$p.Directory=Join-Path $fixture ($case.Host+'-'+$tool);New-Item -ItemType Directory -Force $p.Directory|Out-Null;$converted=$s.WslPath($p.Directory,$dist)
 $p.Name='GUNT v26 QA '+$tool+' '+$case.Host;$opened=$null
 try{
  $result=$s.LaunchDeveloper($p,$tool,$prefs);$verified=$false
  for($probe=0;$probe -lt 60;$probe++){Start-Sleep -Milliseconds 500;$opened=Terminal-Window $p.Name;if((Cli-Directories $tool) -ccontains $converted -and $opened){$verified=$true;break}}
  if(!$verified){if($opened){Write-Json (Get-EnhancementTree $opened) (Join-Path $Root 'logs\v26-terminal-failed-tree.json')};throw ($tool+' 대화형 프로세스·지정 cwd·테스트 터미널을 확인하지 못했습니다.')}
  $tree=Get-EnhancementTree $opened;Write-Json $tree (Join-Path $Root ('logs\v26-live-'+$tool+'-tree.json'))
  $results.Add(@{Tool=$tool;Host=$case.Host;Status='passed';DirectoryExact=$true;InteractiveWindow=$true;NormalAccount=$true;Scope='대화형 프로세스와 실제 /proc cwd. 프롬프트·대화·코드 실행은 수행하지 않음.'})
  Write-Output ($case.Host+' · '+$tool+' 실제 대화형 프로세스·한글/특수문자 cwd·독립 터미널 확인')
 }finally{if($opened){try{($opened.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close()}catch{}}}
}
Write-Json @{Time=(Get-Date).ToString('o');Results=$results.ToArray();UnicodePath=$true;NoCommandsSubmitted=$true;Fixture=$fixture} (Join-Path $Root 'logs\v26-live-cli.json')
