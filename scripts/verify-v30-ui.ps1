param([ValidatePattern('^[a-z0-9.-]+$')][string]$Label='dev2',[ValidateRange(3,10)][int]$Samples=5,[string]$Executable,[switch]$IncludeSizes)
. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class Dev2Native {
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
 [DllImport("user32.dll")]public static extern uint GetDpiForWindow(IntPtr h);
}
'@
$exe=if($Executable){$Executable}else{Join-Path $Root 'bin\GUNT.ControlCenter.exe'};if(!(Test-Path $exe)){throw '실행 파일 없음'};$shots=Join-Path $Root ('screenshots\v30-'+$Label);New-Item -ItemType Directory -Force $shots|Out-Null
$records=@();$captures=@();$owned=@();$oldMetrics=$env:GUNT_UI_METRICS;$env:GUNT_UI_METRICS='1'
$metricFile=Join-Path $Root 'logs\v30-ui-timings.jsonl';$initialLines=if(Test-Path $metricFile){@(Get-Content $metricFile).Count}else{0}
function Find-Id($win,$id){$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,$id)))}
function Wait-Ready($p,$title='GUnT_0x9 Desktop',$page='개요'){
 $watch=[Diagnostics.Stopwatch]::StartNew()
 do{Start-Sleep -Milliseconds 30;$win=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $p.Id -and $_.Current.Name -eq $title}|Select-Object -First 1
 if($win){if($title -ne 'GUnT_0x9 Desktop'){if(@(Get-EnhancementTree $win).Count -gt 10){return $win}}else{$heading=Find-Id $win 'PageTitle';if($heading -and $heading.Current.Name -eq $page){return $win}}}
 if($p.HasExited){throw '대상 앱 종료'}
 }while($watch.Elapsed.TotalSeconds -lt 20)
 throw ('화면 준비 시간 초과: '+$page)
}
function Capture($win,$name){
 Start-Sleep -Milliseconds 650;$r=$win.Current.BoundingRectangle
 if($r.X -lt -10000 -or $r.Width -lt 200){throw '최소화된 창 캡처 거절'}
 $b=New-Object Drawing.Bitmap([int]$r.Width,[int]$r.Height);$g=[Drawing.Graphics]::FromImage($b);$dc=$g.GetHdc()
 try{if(![Dev2Native]::PrintWindow([IntPtr]$win.Current.NativeWindowHandle,$dc,2)){throw 'PrintWindow 실패'}}finally{$g.ReleaseHdc($dc);$g.Dispose()}
 try{$b.Save((Join-Path $shots ($name+'.png')))}finally{$b.Dispose()}
 $script:captures+=@{Name=$name;Width=$r.Width;Height=$r.Height;Dpi=[Dev2Native]::GetDpiForWindow([IntPtr]$win.Current.NativeWindowHandle)}
 Write-Json (Get-EnhancementTree $win) (Join-Path $Root ('logs\v30-'+$Label+'-'+$name+'-tree.json'))
}
function Close-App($win,$p){if($p.HasExited){return};if($win.Current.Name -ne 'GUnT_0x9 Desktop'){[GuntEnhanceUi]::SetForegroundWindow([IntPtr]$win.Current.NativeWindowHandle)|Out-Null;[GuntEnhanceUi]::Tap(27)}else{$p.CloseMainWindow()|Out-Null};if(!$p.WaitForExit(10000)){throw '정상 종료 실패: 강제 종료하지 않음'}}
$existing=Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue
if($existing){throw '열려 있는 제어 센터/빠른 패널을 먼저 닫으세요. 기존 창과 미저장 편집을 자동으로 닫지 않습니다.'}
$windowFile=Join-Path $Root 'state\control-center-window.json';$originalWindow=if(Test-Path $windowFile){[IO.File]::ReadAllBytes($windowFile)}else{$null}
$failure=$null

try{
 for($i=0;$i -lt $Samples;$i++){$watch=[Diagnostics.Stopwatch]::StartNew();$p=Start-Process $exe -ArgumentList ('"'+$Root+'" overview') -PassThru;$owned+=,$p;$win=Wait-Ready $p;$records+=@{Metric='ready';Sample=$i;Ms=$watch.Elapsed.TotalMilliseconds};if($i -lt $Samples-1){Close-App $win $p;Start-Sleep -Milliseconds 250}}
 foreach($page in @(@('overview','개요'),@('developer-setup','개발 세팅'),@('development-sessions','개발 세션'),@('wsl-environments','WSL 환경'),@('smart-automation','스마트 자동화'),@('wallpaper','배경화면'),@('monitor','시스템 모니터'),@('diagnostics','진단 및 복구'))){
  $watch=[Diagnostics.Stopwatch]::StartNew();$request=Start-Process $exe -ArgumentList ('"'+$Root+'" '+$page[0]) -PassThru;$null=$request.WaitForExit(10000);$request.Dispose();$win=Wait-Ready $p 'GUnT_0x9 Desktop' $page[1];$records+=@{Metric='navigate';Page=$page[0];Ms=$watch.Elapsed.TotalMilliseconds};Capture $win $page[0]
 }
 if($IncludeSizes){
  $h=[IntPtr]$win.Current.NativeWindowHandle;$scale=[Dev2Native]::GetDpiForWindow($h)/96.0;$work=[Windows.Forms.Screen]::FromHandle($h).WorkingArea
  foreach($size in @(@(780,560),@(1180,800),@(1500,900))){
   $width=[int][math]::Min($size[0]*$scale,$work.Width-16);$height=[int][math]::Min($size[1]*$scale,$work.Height-16)
   [GuntEnhanceUi]::SetWindowPos($h,[IntPtr]::Zero,$work.Left+8,$work.Top+8,$width,$height,0x14)|Out-Null
   foreach($page in @(@('developer-setup','개발 세팅'),@('development-sessions','개발 세션'),@('wallpaper','배경화면'))){$request=Start-Process $exe -ArgumentList ('"'+$Root+'" '+$page[0]) -PassThru;$null=$request.WaitForExit(10000);$request.Dispose();$win=Wait-Ready $p 'GUnT_0x9 Desktop' $page[1];Capture $win ($page[0]+'-'+$size[0]+'x'+$size[1])}
  }
 }
 # Same idle screen for both versions.
 $request=Start-Process $exe -ArgumentList ('"'+$Root+'" overview') -PassThru;$null=$request.WaitForExit(10000);$request.Dispose();$win=Wait-Ready $p
 Start-Sleep -Seconds 2;$p.Refresh();$cpu=$p.TotalProcessorTime.TotalSeconds;$idleWatch=[Diagnostics.Stopwatch]::StartNew();$memory=@()
 for($i=0;$i -lt 5;$i++){Start-Sleep -Seconds 2;$p.Refresh();$memory+=@{WorkingSetMiB=$p.WorkingSet64/1MB;PrivateMiB=$p.PrivateMemorySize64/1MB}}
 $cpuPercent=100*($p.TotalProcessorTime.TotalSeconds-$cpu)/$idleWatch.Elapsed.TotalSeconds/[Environment]::ProcessorCount
 Close-App $win $p
 foreach($kind in @('palette','quick-panel')){$title=if($kind -eq 'palette'){'GUnT_0x9 명령 팔레트'}else{'GUnT_0x9 빠른 패널'};$p=Start-Process $exe -ArgumentList ('"'+$Root+'" '+$kind) -PassThru;$owned+=,$p;$win=Wait-Ready $p $title;Capture $win $kind;Close-App $win $p}

}catch{$failure=$_.Exception.Message;throw}finally{
 $metrics=@(Get-Content $metricFile|Select-Object -Skip $initialLines|ForEach-Object {$_|ConvertFrom-Json})
 Write-Json @{Version=$Label;Failure=$failure;ExecutableSha256=(Get-FileHash $exe).Hash;Records=$records;Metrics=$metrics;Captures=$captures;Memory=$memory;IdleCpuPercent=$cpuPercent;Screens=@([Windows.Forms.Screen]::AllScreens|ForEach-Object {$_.Bounds.ToString()});Notes='첫 실행도 OS 캐시 초기화 안 함. ready는 PageTitle UIA 준비까지. navigation은 IPC 포함. 비동기 데이터 완료 제외. 실제 화면 검토는 별도.'} (Join-Path $Root ('logs\v30-'+$Label+'-results.json'))
foreach($process in $owned){try{if(!$process.HasExited){$process.CloseMainWindow()|Out-Null;$null=$process.WaitForExit(5000)}}finally{$process.Dispose()}};$env:GUNT_UI_METRICS=$oldMetrics
if(!@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count){if($null -ne $originalWindow){[IO.File]::WriteAllBytes($windowFile,$originalWindow)}elseif(Test-Path $windowFile){Remove-Item -LiteralPath $windowFile}}
}
