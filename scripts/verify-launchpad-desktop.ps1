param([string]$Label='dev6',[switch]$SkipCore)
. "$PSScriptRoot\enhancement-ui-common.ps1"
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';$records=@();$owned=@();$originalCursor=[GuntEnhanceUi]::Cursor();$failure=$null
Add-Type @'
using System;using System.Runtime.InteropServices;public static class LaunchpadDesktopNative {
 [DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int cmd);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")]static extern void mouse_event(uint flags,uint x,uint y,uint data,UIntPtr extra);
 public static void Mouse(uint flags){mouse_event(flags,0,0,0,UIntPtr.Zero);}
 [DllImport("user32.dll")]public static extern uint GetDpiForWindow(IntPtr h);
}
'@
function Check($Value,[string]$Name){if(!$Value){throw ('FAIL '+$Name)};$script:records+=@{Name=$Name;Passed=$true}}
function Launchpad-Window {Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUNT Launchpad' -and !$_.Current.IsOffscreen -and [LaunchpadDesktopNative]::IsWindowVisible([IntPtr]$_.Current.NativeWindowHandle)}|Select-Object -First 1}
function Wait-Window([int]$ExpectedPid=0) {for($i=0;$i -lt 100;$i++){$win=Launchpad-Window;if($win -and (!$ExpectedPid -or $win.Current.ProcessId -eq $ExpectedPid)){return $win};Start-Sleep -Milliseconds 50};throw 'Launchpad 창 준비 시간 초과'}
function Chord {[GuntEnhanceUi]::Key(0x11,$true);[GuntEnhanceUi]::Key(0x12,$true);[GuntEnhanceUi]::Tap(0x4c);[GuntEnhanceUi]::Key(0x12,$false);[GuntEnhanceUi]::Key(0x11,$false);Start-Sleep -Milliseconds 140}
function Find-Id($Window,[string]$Id){$Window.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,$Id)))}
function Find-Name($Window,[string]$Name){$Window.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$Name)))}
function Invoke-Name($Window,[string]$Name){$control=Find-Name $Window $Name;if(!$control){throw ('컨트롤 없음: '+$Name)};($control.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();Start-Sleep -Milliseconds 120}
function Exit-Launchpad($Window){$launcherPid=$Window.Current.ProcessId;Invoke-Name $Window '관리';$exit=$null;for($i=0;$i -lt 20 -and !$exit;$i++){foreach($candidate in Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $launcherPid}){$exit=Find-Name $candidate '종료';if($exit){break}};if(!$exit){Start-Sleep -Milliseconds 50}};if(!$exit){throw 'Launchpad 종료 메뉴 없음'};($exit.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();$p=Get-Process -Id $launcherPid -ErrorAction SilentlyContinue;if($p){if(!$p.WaitForExit(3000)){throw 'Launchpad 정상 종료 시간 초과'};$p.Dispose()}}
function Drag($From,$To,[IntPtr]$TargetWindow) {
 if(!$From -or !$To -or $TargetWindow -eq [IntPtr]::Zero){throw '드래그 대상 또는 창 핸들이 없습니다.'}
 [GuntEnhanceUi]::SetForegroundWindow($TargetWindow)|Out-Null
 Start-Sleep -Milliseconds 120
 $a=$From.Current.BoundingRectangle;$b=$To.Current.BoundingRectangle
 $x=[int]($a.X+$a.Width/2);$y=[int]($a.Y+$a.Height/2)
 $tx=[int]($b.X+$b.Width/2);$ty=[int]($b.Y+$b.Height/2)
 [GuntEnhanceUi]::MouseAt($x,$y)
 if([GuntEnhanceUi]::At($x,$y) -ne $TargetWindow){throw '드래그 시작 위치를 다른 창이 가립니다. 입력 검증을 중단했습니다.'}
 [LaunchpadDesktopNative]::Mouse(2)
 try {
  Start-Sleep -Milliseconds 80
  for($step=1;$step -le 12;$step++){[GuntEnhanceUi]::MouseAt([int]($x+($tx-$x)*$step/12),[int]($y+($ty-$y)*$step/12))}
 } finally {[LaunchpadDesktopNative]::Mouse(4)}
 Start-Sleep -Milliseconds 350
}
try{
 Check (!(Launchpad-Window)) '검증 전에 기존 Launchpad 없음'
 $state=Get-Content -Raw -LiteralPath (Join-Path $Root 'state\launchpad-hotkey.json') -Encoding UTF8|ConvertFrom-Json
 Check ($state.Available -and $state.Shortcut -eq 'Ctrl+Alt+L') '실행 중인 상단 바가 기본 단축키 등록'
 if(!$SkipCore){Chord;$win=Wait-Window;$handle=[IntPtr]$win.Current.NativeWindowHandle;$launcherPid=$win.Current.ProcessId;$owned+=,$launcherPid
 Check ([LaunchpadDesktopNative]::IsWindowVisible($handle)) '전역 키로 실제 Launchpad 열림'
 Chord;Check (![LaunchpadDesktopNative]::IsWindowVisible($handle)) '반복 전역 키로 숨김'
 Chord;$win=Wait-Window;Check ($win.Current.ProcessId -eq $launcherPid -and $win.Current.NativeWindowHandle -eq $handle.ToInt64()) '재열기에서 같은 프로세스와 창 재사용'
 $query=Find-Id $win 'LaunchpadSearch';Check $query.Current.HasKeyboardFocus '열릴 때 검색 포커스'
 ($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('존재하지않는검증검색999');Start-Sleep -Milliseconds 150
 [GuntEnhanceUi]::Tap(0x1b);Start-Sleep -Milliseconds 100;Check (($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).Current.Value -eq '' -and [LaunchpadDesktopNative]::IsWindowVisible($handle)) 'Escape는 먼저 검색어 지움'
 [GuntEnhanceUi]::Tap(0x1b);Check (![LaunchpadDesktopNative]::IsWindowVisible($handle)) '다음 Escape로 닫힘'
 Chord;$win=Wait-Window;Exit-Launchpad $win;Check (!(Get-Process -Id $launcherPid -ErrorAction SilentlyContinue)) '관리 메뉴에서 정상 종료'}
 # Isolated actual Windows executable used only as a controlled custom-shortcut launch target.
 $fixture=Join-Path ([IO.Path]::GetPathRoot($env:WINDIR)) ('GUNT-DocDemo\desktop-qa-'+[guid]::NewGuid().ToString('N').Substring(0,8));New-Item -ItemType Directory -Force (Join-Path $fixture 'assets'),(Join-Path $fixture 'config'),(Join-Path $fixture 'state'),(Join-Path $fixture 'logs')|Out-Null
 Copy-Item (Join-Path $Root 'assets\branding') (Join-Path $fixture 'assets') -Recurse
 foreach($name in @('theme','ux','topbar')){Copy-Item (Join-Path $Root ('config\'+$name+'.json')) (Join-Path $fixture 'config')}
 Write-Json @{SchemaVersion=2;Projects=@()} (Join-Path $fixture 'config\projects.json')
 $target=Join-Path $fixture 'Launchpad.QA.Target.exe';$source='using System;using System.Windows.Forms;public static class T {[STAThread]public static void Main(string[] args){System.IO.File.WriteAllText(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"received-args.json"),new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(args));Application.Run(new Form{Text="GUNT Launchpad QA Target",Width=420,Height=220});}}'
 Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms,System.Web.Extensions -OutputAssembly $target -OutputType WindowsApplication
 $config=Get-Content -Raw -LiteralPath (Join-Path $Root 'config\examples\launchpad.example.json') -Encoding UTF8|ConvertFrom-Json
 $config.Folders=@(@{Id='group-qa';Name='검증 폴더';Category='utilities';Pose='folder'})
 $config.Shortcuts=@(@{Id='custom-qa-a';Name='QA A';Kind='exe';Target=$target;Arguments=@();Source='사용자';Category='utilities';Context='검증 앱'},@{Id='custom-qa-b';Name='QA B';Kind='exe';Target=$target;Arguments=@('argument with spaces','유니코드','quoted"value','tail\','$(not-a-shell-command)','a&b');Source='사용자';Category='utilities';Context='검증 앱'},@{Id='custom-qa-missing';Name='QA Missing';Kind='exe';Target=(Join-Path $fixture 'missing.exe');Arguments=@();Source='사용자';Category='utilities';Context='검증용 없는 대상'})
 Write-Json $config (Join-Path $fixture 'config\launchpad.json');Write-Json @{SchemaVersion=1;Refreshed=[DateTimeOffset]::Now.ToString('o');Apps=@();Warnings=@()} (Join-Path $fixture 'state\launchpad-catalog.json')
 $env:GUNT_UI_METRICS='1';$qa=Start-Process $exe -ArgumentList ('"'+$fixture+'" launchpad') -PassThru;Remove-Item Env:\GUNT_UI_METRICS;$owned+=,$qa.Id;$win=Wait-Window $qa.Id;$handle=[IntPtr]$win.Current.NativeWindowHandle;Start-Sleep -Milliseconds 800;[LaunchpadDesktopNative]::ShowWindow($handle,5)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($handle)|Out-Null;[LaunchpadDesktopNative]::PostMessage($handle,0x8006,[IntPtr]1,[IntPtr]::Zero)|Out-Null;Start-Sleep -Milliseconds 300
 Drag (Find-Id $win 'custom-qa-b') (Find-Id $win 'custom-qa-a') $handle;$saved=Get-Content -Raw -LiteralPath (Join-Path $fixture 'config\launchpad.json') -Encoding UTF8|ConvertFrom-Json
 Check ($saved.Items.'custom-qa-b'.Order -lt $saved.Items.'custom-qa-a'.Order) '실제 마우스 드래그 순서 저장'
 Check (!(Get-Process Launchpad.QA.Target -ErrorAction SilentlyContinue)) '드래그는 앱을 실행하지 않음'
 Drag (Find-Id $win 'custom-qa-a') (Find-Id $win 'group-qa') $handle;$saved=Get-Content -Raw -LiteralPath (Join-Path $fixture 'config\launchpad.json') -Encoding UTF8|ConvertFrom-Json;Check ($saved.Items.'custom-qa-a'.Folder -eq 'group-qa') '실제 폴더 드롭 저장'
 $folder=Find-Id $win 'group-qa';($folder.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();Start-Sleep -Milliseconds 200;Check ($null -ne (Find-Id $win 'custom-qa-a')) '폴더 안의 앱 표시';[GuntEnhanceUi]::Tap(0x1b);Start-Sleep -Milliseconds 100;Check ([LaunchpadDesktopNative]::IsWindowVisible($handle)) 'Escape로 폴더에서 돌아오기'
 Drag (Find-Id $win 'custom-qa-b') (Find-Name $win '개발') $handle;$saved=Get-Content -Raw -LiteralPath (Join-Path $fixture 'config\launchpad.json') -Encoding UTF8|ConvertFrom-Json;Check ($saved.Items.'custom-qa-b'.Category -eq 'development') '실제 카테고리 드롭 저장'
 $query=Find-Id $win 'LaunchpadSearch';($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('QA Missing');Start-Sleep -Milliseconds 120;[GuntEnhanceUi]::Tap(0x0d);Start-Sleep -Milliseconds 300;Check ([LaunchpadDesktopNative]::IsWindowVisible($handle)) '없는 앱 실행 실패 후 창 유지';Check ((Find-Id $win 'LaunchpadStatus').Current.Name -like '*없*') '실행 오류가 화면에 표시'
 ($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue('QA B');$query.SetFocus();Start-Sleep -Milliseconds 150;[GuntEnhanceUi]::Tap(0x28);[GuntEnhanceUi]::Tap(0x0d);Start-Sleep -Milliseconds 500
 $targetProcess=Get-Process Launchpad.QA.Target -ErrorAction SilentlyContinue|Select-Object -First 1;Check ($null -ne $targetProcess) '화살표·Enter로 실제 검증 앱 실행';$owned+=,$targetProcess.Id;Check (![LaunchpadDesktopNative]::IsWindowVisible($handle)) '실행 요청 후 Launchpad 닫힘'
 $received=(Get-Content -Raw -LiteralPath (Join-Path $fixture 'received-args.json') -Encoding UTF8|ConvertFrom-Json);Check (($received -join "`n") -eq ($config.Shortcuts[1].Arguments -join "`n")) '공백·한글·따옴표·역슬래시·셸 기호를 실제 argv로 전달'
 # Actual connected displays and negative desktop coordinates; no synthetic display claim.
 $screens=@([Windows.Forms.Screen]::AllScreens);foreach($screen in $screens){[GuntEnhanceUi]::MouseAt([int]($screen.WorkingArea.Left+$screen.WorkingArea.Width/2),[int]($screen.WorkingArea.Top+$screen.WorkingArea.Height/2));[LaunchpadDesktopNative]::ShowWindow($handle,5)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($handle)|Out-Null;[LaunchpadDesktopNative]::PostMessage($handle,0x8006,[IntPtr]1,[IntPtr]::Zero)|Out-Null;$win=Wait-Window $qa.Id;Start-Sleep -Milliseconds 150;$rect=$win.Current.BoundingRectangle;$work=$screen.WorkingArea;Check ($rect.X -ge $work.Left-2 -and $rect.Y -ge $work.Top-2 -and $rect.Right -le $work.Right+2 -and $rect.Bottom -le $work.Bottom+2) ('연결 화면 작업 영역에 배치 · DPI '+[LaunchpadDesktopNative]::GetDpiForWindow($handle));[LaunchpadDesktopNative]::PostMessage($handle,0x8006,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null;Start-Sleep -Milliseconds 100}
 if($screens.Count -gt 1){$screen=$screens[1];$targetProcess.Refresh();$targetHandle=$targetProcess.MainWindowHandle;[GuntEnhanceUi]::SetWindowPos($targetHandle,[IntPtr]::Zero,$screen.WorkingArea.Left+80,$screen.WorkingArea.Top+80,600,320,0x14)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($targetHandle)|Out-Null;$saved=Get-Content -Raw -LiteralPath (Join-Path $fixture 'config\launchpad.json') -Encoding UTF8|ConvertFrom-Json;$saved.Monitor='foreground';Write-Json $saved (Join-Path $fixture 'config\launchpad.json');$primary=$screens[0].WorkingArea;[GuntEnhanceUi]::MouseAt($primary.Right-10,$primary.Bottom-10);[LaunchpadDesktopNative]::ShowWindow($handle,5)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($handle)|Out-Null;[LaunchpadDesktopNative]::PostMessage($handle,0x8006,[IntPtr]1,$targetHandle)|Out-Null;$win=Wait-Window $qa.Id;Start-Sleep -Milliseconds 150;$rect=$win.Current.BoundingRectangle;Check ($rect.X -ge $screen.WorkingArea.Left-2 -and $rect.Right -le $screen.WorkingArea.Right+2) '마우스와 다른 전경 창 화면에 배치';[LaunchpadDesktopNative]::PostMessage($handle,0x8006,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null;Start-Sleep -Milliseconds 100}
 $targetProcess.CloseMainWindow()|Out-Null;$null=$targetProcess.WaitForExit(2000);$targetProcess.Dispose()
 [LaunchpadDesktopNative]::ShowWindow($handle,5)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($handle)|Out-Null;[LaunchpadDesktopNative]::PostMessage($handle,0x8006,[IntPtr]1,[IntPtr]::Zero)|Out-Null;$win=Wait-Window $qa.Id;Exit-Launchpad $win
 # Existing palette remains independently addressable.
 $keyState=Get-Content -Raw -LiteralPath (Join-Path $Root 'state\developer-hotkey.json') -Encoding UTF8|ConvertFrom-Json
 if($keyState.Available){[GuntEnhanceUi]::Key(0x11,$true);$other=if($keyState.Shortcut -eq 'Ctrl+Alt+Space'){0x12}else{0x10};[GuntEnhanceUi]::Key($other,$true);[GuntEnhanceUi]::Tap(0x20);[GuntEnhanceUi]::Key($other,$false);[GuntEnhanceUi]::Key(0x11,$false);Start-Sleep -Milliseconds 100;$palette=$null;for($attempt=0;$attempt -lt 100 -and !$palette;$attempt++){Start-Sleep -Milliseconds 50;$paletteWindow=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 명령 팔레트'}|Select-Object -First 1;if($paletteWindow){$palette=Get-Process -Id $paletteWindow.Current.ProcessId}};Check ($null -ne $palette) '기존 전역 명령 팔레트 단축키 호환'}else{$palette=Start-Process $exe -ArgumentList ('"'+$Root+'" palette') -PassThru}
$owned+=,$palette.Id;Start-Sleep -Milliseconds 700;$pw=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $palette.Id -and $_.Current.Name -eq 'GUnT_0x9 명령 팔레트'}|Select-Object -First 1;Check ($null -ne $pw) '기존 명령 팔레트 진입점 호환';($pw.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();$null=$palette.WaitForExit(2000);$palette.Dispose()
 $quick=Start-Process $exe -ArgumentList ('"'+$Root+'" quick-panel') -PassThru;$owned+=,$quick.Id;Start-Sleep -Milliseconds 650;$qw=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $quick.Id -and $_.Current.Name -eq 'GUnT_0x9 빠른 패널'}|Select-Object -First 1;Check ($null -ne $qw -and $null -ne (Find-Name $qw '작업공간') -and $null -ne (Find-Name $qw 'Launchpad')) '기존 빠른 패널과 새 영역 이동 호환';($qw.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();$null=$quick.WaitForExit(2000);$quick.Dispose()
}catch{$failure=$_.Exception.Message;throw}finally{
 Write-Json @{Label=$Label;Failure=$failure;Passed=$records.Count;Checks=$records;ExecutableSha256=(Get-FileHash $exe).Hash;Screens=@([Windows.Forms.Screen]::AllScreens|ForEach-Object {@{Bounds=$_.Bounds.ToString()}});Note='실제 상단 바 키 등록·Windows 입력·UIA·드래그·별도 검증 앱 실행. 사용자 설정에 정렬 데이터를 쓰지 않음.'} (Join-Path $Root ('logs\launchpad-'+$Label+'-desktop-tests.json'))
 foreach($ownedPid in $owned){$p=Get-Process -Id $ownedPid -ErrorAction SilentlyContinue;if($p){if($p.ProcessName -in @('GUNT.ControlCenter','Launchpad.QA.Target')){$p.CloseMainWindow()|Out-Null;if(!$p.WaitForExit(700)){Stop-Process -Id $p.Id}};$p.Dispose()}}
 [GuntEnhanceUi]::MouseAt($originalCursor.X,$originalCursor.Y)
}
Write-Output ($records.Count.ToString()+' desktop checks passed')
