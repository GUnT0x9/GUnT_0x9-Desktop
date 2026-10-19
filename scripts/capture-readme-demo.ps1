param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9.-]+$')][string]$Version,[string[]]$Pages=@('developer-setup','development-sessions','palette','quick-panel'),[ValidateRange(780,1600)][int]$WidthDip=1400,[ValidateRange(560,1000)][int]$HeightDip=860,[switch]$ProjectEditor)
. "$PSScriptRoot\enhancement-ui-common.ps1"
# 실제 앱을 별도 문서용 설정으로 실행한다. 실행/적용 버튼은 누르지 않는다.
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '기존 제어 센터를 정상 종료한 뒤 실행하세요. 미저장 창은 자동 종료하지 않습니다.'}
if(!(Test-Path $Executable)){throw '검증한 Windows 빌드 경로를 지정하세요.'}
foreach($page in $Pages){if($page -notin @('developer-setup','development-sessions','palette','quick-panel')){throw '개인 환경을 읽는 화면은 이 공개용 캡처 대상에서 제외합니다.'}}
$run=[guid]::NewGuid().ToString('N').Substring(0,8)
$demo=Join-Path ([IO.Path]::GetPathRoot($env:WINDIR)) ('GUNT-DocDemo\'+$run)
$raw=Join-Path $Root ('screenshots\readme-'+$Version+'-'+$run)
New-Item -ItemType Directory -Force $demo,$raw,(Join-Path $demo 'config'),(Join-Path $demo 'state'),(Join-Path $demo 'logs'),(Join-Path $demo 'assets')|Out-Null
foreach($name in @('theme','ux','topbar')){Copy-Item (Join-Path $Root ('config\'+$name+'.json')) (Join-Path $demo 'config')}
Copy-Item (Join-Path $Root 'assets\branding') (Join-Path $demo 'assets') -Recurse
foreach($file in Get-ChildItem (Join-Path $Root 'config\examples') -Filter '*.example.json'){
 $name=$file.Name.Replace('.example','');$text=[IO.File]::ReadAllText($file.FullName).Replace('{projectRoot}', $demo.Replace('\','\\')).Replace('{userProfile}','C:\\GUNT-DocDemo\\PublicUser')
 [IO.File]::WriteAllText((Join-Path $demo ('config\'+$name)),$text,$Utf8)
}
$theme=(Get-Content -Raw -LiteralPath (Join-Path $demo 'config\theme.json')|ConvertFrom-Json);$theme.version=$Version;Write-Json $theme (Join-Path $demo 'config\theme.json')
$git=Join-Path $env:ProgramFiles 'Git\cmd\git.exe';if(!(Test-Path $git)){throw '실제 예제 Git 상태를 생성하려면 Git for Windows가 필요합니다.'}
$apps=(Get-Content -Raw -LiteralPath (Join-Path $demo 'config\apps.json')|ConvertFrom-Json);$apps.git=$git;Write-Json $apps (Join-Path $demo 'config\apps.json')
$projects=@();$workspace=Join-Path $demo 'workspace';New-Item -ItemType Directory -Force $workspace|Out-Null
foreach($name in @('atlas-web','notes-cli','native-toolkit')){
 $dir=Join-Path $workspace $name;New-Item -ItemType Directory -Force $dir|Out-Null
 $marker=if($name -eq 'atlas-web'){'package.json'}elseif($name -eq 'notes-cli'){'pyproject.toml'}else{'native-toolkit.csproj'}
 [IO.File]::WriteAllText((Join-Path $dir $marker),$(if($marker -eq 'package.json'){'{"name":"atlas-web","private":true}'}else{'# Documentation demonstration'}),$Utf8)
 & $git -C $dir init -q -b main;if($LASTEXITCODE){throw '예제 저장소 초기화 실패'}
 & $git -C $dir add --all
 & $git -C $dir -c user.name='Documentation Demo' -c user.email='demo@example.invalid' -c commit.gpgsign=false commit -q -m 'Documentation sample';if($LASTEXITCODE){throw '예제 저장소 커밋 실패'}
 $projects+=@{Id=$name;Name=$name;Directory=$dir;Ide='vscode';Terminal='powershell';Pinned=($name -eq 'atlas-web');Order=$projects.Count;Commands=@()}
}
# 실제 수정/미추적 상태를 만들어 표시한다. 최근 실행 성공 기록은 만들어 넣지 않는다.
[IO.File]::AppendAllText((Join-Path $workspace 'atlas-web\package.json'),"`n",$Utf8)
[IO.File]::WriteAllText((Join-Path $workspace 'atlas-web\README.md'),'Public documentation example',$Utf8)
Write-Json @{SchemaVersion=2;Projects=$projects} (Join-Path $demo 'config\projects.json')
Write-Json @{SchemaVersion=1;Roots=@($workspace);ScanDepth=1;ShowHidden=$false;SelectedProjectId='atlas-web';Tools=@();Defaults=@{TerminalHost='windows-terminal';DefaultAiCli='codex';Editor='vscode';SessionPreset='ai-coding';CodexExecutable='codex';OpenCodeExecutable='opencode'}} (Join-Path $demo 'config\developer.json')
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class ReadmeCaptureNative {
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint flags);
 [DllImport("user32.dll")]public static extern uint GetDpiForWindow(IntPtr h);
}
'@
$captures=@();$process=$null;$originalCursor=[GuntEnhanceUi]::Cursor()
try{
 foreach($page in $Pages){
  $process=Start-Process $Executable -ArgumentList ('"'+$demo+'" '+$page) -PassThru
  $title=if($page -eq 'palette'){'GUnT_0x9 명령 팔레트'}elseif($page -eq 'quick-panel'){'GUnT_0x9 빠른 패널'}else{'GUnT_0x9 Desktop'}
  $win=$null;for($attempt=0;$attempt -lt 100 -and !$win;$attempt++){Start-Sleep -Milliseconds 60;$win=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id -and $_.Current.Name -eq $title}|Select-Object -First 1}
  if(!$win){throw ('실제 창 준비 실패: '+$page)}
  $h=[IntPtr]$win.Current.NativeWindowHandle;$scale=[ReadmeCaptureNative]::GetDpiForWindow($h)/96.0;$work=[Windows.Forms.Screen]::FromHandle($h).WorkingArea
  if($title -eq 'GUnT_0x9 Desktop'){[GuntEnhanceUi]::SetWindowPos($h,[IntPtr]::Zero,$work.Left+8,$work.Top+8,[int][math]::Min($WidthDip*$scale,$work.Width-16),[int][math]::Min($HeightDip*$scale,$work.Height-16),0x14)|Out-Null}
  [GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;Start-Sleep -Seconds 2
  if($page -eq 'palette'){
   $query=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'GUNT 명령 검색')))
   ($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('codex');Start-Sleep -Milliseconds 200
  }
  [GuntEnhanceUi]::MouseAt($work.Right-8,$work.Bottom-8)
  $r=$win.Current.BoundingRectangle;if($r.X -lt -10000 -or $r.Width -lt 200){throw '최소화된 창은 캡처하지 않습니다.'}
  $bitmap=New-Object Drawing.Bitmap([int]$r.Width,[int]$r.Height);$graphics=[Drawing.Graphics]::FromImage($bitmap);$dc=$graphics.GetHdc()
  try{if(![ReadmeCaptureNative]::PrintWindow($h,$dc,2)){throw 'PrintWindow 실패'}}finally{$graphics.ReleaseHdc($dc);$graphics.Dispose()}
  $file=Join-Path $raw ($page+'.png');try{$bitmap.Save($file,[Drawing.Imaging.ImageFormat]::Png)}finally{$bitmap.Dispose()}
  $captures+=@{Page=$page;File=$file;Dpi=[ReadmeCaptureNative]::GetDpiForWindow($h);Width=$r.Width;Height=$r.Height}
  if($ProjectEditor -and $page -eq 'developer-setup'){
   $settings=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'프로젝트 개발 설정')))
   ($settings.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
   $dialog=$null;for($i=0;$i -lt 60 -and !$dialog;$i++){Start-Sleep -Milliseconds 60;$dialog=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id -and $_.Current.Name -eq '프로젝트 개발 설정'}|Select-Object -First 1}
   if(!$dialog){$dialog=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'프로젝트 개발 설정')))}
   if(!$dialog -or $dialog.Current.NativeWindowHandle -eq 0){throw '실제 설정 편집창 준비 실패'}
   Start-Sleep -Milliseconds 600;$dr=$dialog.Current.BoundingRectangle;$dh=[IntPtr]$dialog.Current.NativeWindowHandle
   $db=New-Object Drawing.Bitmap([int]$dr.Width,[int]$dr.Height);$dg=[Drawing.Graphics]::FromImage($db);$ddc=$dg.GetHdc()
   try{if(![ReadmeCaptureNative]::PrintWindow($dh,$ddc,2)){throw '편집창 캡처 실패'}}finally{$dg.ReleaseHdc($ddc);$dg.Dispose()}
   try{$db.Save((Join-Path $raw 'project-editor.png'),[Drawing.Imaging.ImageFormat]::Png)}finally{$db.Dispose()}
   $captures+=@{Page='project-editor';File=(Join-Path $raw 'project-editor.png');Dpi=[ReadmeCaptureNative]::GetDpiForWindow($dh);Width=$dr.Width;Height=$dr.Height}
   # No values were edited. Cancel keeps both demo configuration and user settings untouched.
   ($dialog.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();Start-Sleep -Milliseconds 200
  }
  ($win.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();if(!$process.WaitForExit(10000)){throw '자체 캡처 창 정상 종료 실패. 강제 종료하지 않았습니다.'};$process.Dispose();$process=$null
 }
 Write-Json @{Version=$Version;CapturedAt=[DateTimeOffset]::Now.ToString('o');ExecutableSha256=(Get-FileHash $Executable).Hash;Mode='실제 앱 / 별도 문서용 설정 / 예제 Git 저장소 / 프로세스 실행 및 배경 적용 안 함';Captures=$captures} (Join-Path $raw 'capture-manifest.json')
 Write-Output ('공개 검토 전 원본: '+$raw)
}finally{[GuntEnhanceUi]::MouseAt($originalCursor.X,$originalCursor.Y);if($process){if(!$process.HasExited){$process.CloseMainWindow()|Out-Null;$null=$process.WaitForExit(5000)};$process.Dispose()}}
