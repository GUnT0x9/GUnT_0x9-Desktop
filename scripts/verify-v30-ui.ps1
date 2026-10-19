# 실제 Windows 대화형 세션에서 실행. 화면·UIA 검사는 읽기/탐색만 수행한다.
param([ValidateSet('before','after')][string]$Label='after',[ValidateRange(3,10)][int]$Samples=5)
. "$PSScriptRoot\enhancement-ui-common.ps1"
if(Get-Process 'GUNT.ControlCenter' -ErrorAction SilentlyContinue){throw '열려 있는 제어 센터와 빠른 패널을 먼저 닫으세요. 미저장 작업은 자동으로 닫지 않습니다.'}
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class V30Capture {
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr window,IntPtr dc,uint flags);
 [DllImport("user32.dll")]public static extern uint GetDpiForWindow(IntPtr window);
}
'@
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
$directory=Join-Path $Root ('screenshots\v30-'+$Label)
New-Item -ItemType Directory -Force $directory|Out-Null
$windowFile=Join-Path $Root 'state\control-center-window.json'
$originalWindow=if(Test-Path $windowFile){[IO.File]::ReadAllBytes($windowFile)}else{$null}
$oldMetrics=$env:GUNT_UI_METRICS
$env:GUNT_UI_METRICS='1'
$owned=New-Object Collections.ArrayList
$startup=@();$navigation=@();$captures=@();$idle=@()
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
function Wait-Window($process){
 $watch=[Diagnostics.Stopwatch]::StartNew()
 do{$process.Refresh();if($process.HasExited){throw '제어 센터 프로세스가 종료됐습니다.'};if($process.MainWindowHandle -ne [IntPtr]::Zero){return [Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)};Start-Sleep -Milliseconds 25}while($watch.Elapsed.TotalSeconds -lt 20)
 throw '창 표시 시간 초과'
}
function Close-Owned($window,$process){($window.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();if(!$process.WaitForExit(10000)){throw '창이 정상 종료되지 않았습니다. 강제 종료하지 않습니다.'}}
function Capture($window,$name){
 Start-Sleep -Milliseconds 400
 $rect=$window.Current.BoundingRectangle
 $bitmap=New-Object Drawing.Bitmap([int]$rect.Width,[int]$rect.Height)
 $graphics=[Drawing.Graphics]::FromImage($bitmap);$dc=$graphics.GetHdc()
 try{if(![V30Capture]::PrintWindow([IntPtr]$window.Current.NativeWindowHandle,$dc,2)){throw '창 캡처 실패'}}finally{$graphics.ReleaseHdc($dc);$graphics.Dispose()}
 try{$bitmap.Save((Join-Path $directory ($name+'.png')))}finally{$bitmap.Dispose()}
 $script:captures+=@{File=$name+'.png';Width=$rect.Width;Height=$rect.Height;ActualDpi=[V30Capture]::GetDpiForWindow([IntPtr]$window.Current.NativeWindowHandle);VisualReview='미검토: 이미지 파일을 실제로 열어 확인해야 함'}
}
function Median($values){$sorted=@($values|Sort-Object);if(!$sorted.Count){return $null};$middle=[int][math]::Floor($sorted.Count/2);if($sorted.Count%2){return $sorted[$middle]};return ($sorted[$middle-1]+$sorted[$middle])/2}
try{
 for($sample=0;$sample -lt $Samples;$sample++){
  $watch=[Diagnostics.Stopwatch]::StartNew();$process=Start-Process $exe -ArgumentList ('"'+$Root+'" overview') -PassThru;$null=$owned.Add($process);$window=Wait-Window $process;$watch.Stop()
  $startup+=@{Sample=$sample;WindowHandleMs=$watch.Elapsed.TotalMilliseconds;CacheState=if($sample -eq 0){'첫 실행: OS 캐시 초기화 안 함'}else{'반복 실행'}}
  if($sample -lt $Samples-1){Close-Owned $window $process;Start-Sleep -Milliseconds 300}
 }
 $pages=@(@('overview','개요'),@('developer-setup','개발 세팅'),@('projects','프로젝트'),@('development-sessions','개발 세션'),@('wsl-environments','WSL 환경'),@('appearance','외관'),@('dock','Dock'),@('topbar','상단 바'),@('wallpaper','배경화면'),@('profiles','프로필'),@('displays','디스플레이'),@('monitor','시스템 모니터'),@('sensors','하드웨어 센서'),@('windhawk','Windhawk'),@('commands','명령어 관리'),@('smart-automation','스마트 자동화'),@('automation','시작 · 자동화'),@('diagnostics','진단 및 복구'),@('about','프로그램 정보'))
 $nav=Find-Name $window '페이지 탐색'
 if(!$nav){$nav=$window} # v2.6 기준 화면에서도 동일 스크립트로 캡처 가능
 foreach($page in $pages){
  $item=Find-Name $nav $page[1];if(!$item){throw ('탐색 항목 없음: '+$page[0])}
  $watch=[Diagnostics.Stopwatch]::StartNew();($item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern)).Select()
  # UIA 선택 응답의 왕복 시간이며 전체 렌더링 완료 시간은 아님.
  $watch.Stop();$navigation+=@{Page=$page[0];SelectionRoundTripMs=$watch.Elapsed.TotalMilliseconds}
  Capture $window $page[0]
 }
 # 표시 가능한 실제 화면 작업 영역 안의 크기만 시험. DPI는 OS 설정을 변경하지 않는다.
 $handle=[IntPtr]$window.Current.NativeWindowHandle;$scale=[V30Capture]::GetDpiForWindow($handle)/96.0
 $work=[Windows.Forms.Screen]::FromHandle($handle).WorkingArea
 foreach($size in @(@(780,560),@(1180,800),@(1500,900))){
  $width=[int][math]::Min($size[0]*$scale,$work.Width);$height=[int][math]::Min($size[1]*$scale,$work.Height)
  [GuntEnhanceUi]::SetWindowPos($handle,[IntPtr]::Zero,$work.Left,$work.Top,$width,$height,0x14)|Out-Null
  $item=Find-Name $nav '개발 세팅';($item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern)).Select();Capture $window ('developer-'+$size[0]+'x'+$size[1]+'-requested')
 }
 # 유휴 상태 표본은 기존 화면을 유지하며 다른 프로세스를 종료하지 않는다.
 $process.Refresh();$cpu=$process.TotalProcessorTime.TotalSeconds;$watch=[Diagnostics.Stopwatch]::StartNew()
 for($sample=0;$sample -lt 5;$sample++){Start-Sleep -Seconds 2;$process.Refresh();$idle+=@{WorkingSetMiB=$process.WorkingSet64/1MB;PrivateMiB=$process.PrivateMemorySize64/1MB}}
 $cpuPercent=100*($process.TotalProcessorTime.TotalSeconds-$cpu)/$watch.Elapsed.TotalSeconds/[Environment]::ProcessorCount
 Close-Owned $window $process
 foreach($kind in @('palette','quick-panel')){$popup=Start-Process $exe -ArgumentList ('"'+$Root+'" '+$kind) -PassThru;$null=$owned.Add($popup);$popupWindow=Wait-Window $popup;Capture $popupWindow $kind;Close-Owned $popupWindow $popup}
 Write-Json @{Label=$Label;Time=(Get-Date).ToString('o');Startup=$startup;StartupMedianMs=Median @($startup.WindowHandleMs);StartupMinMs=($startup.WindowHandleMs|Measure-Object -Minimum).Minimum;StartupMaxMs=($startup.WindowHandleMs|Measure-Object -Maximum).Maximum;Navigation=$navigation;IdleCpuPercent=$cpuPercent;IdleWorkingSetMedianMiB=Median @($idle.WorkingSetMiB);IdleSamples=$idle;Captures=$captures;ConnectedDisplays=@([Windows.Forms.Screen]::AllScreens|ForEach-Object {@{Primary=$_.Primary;Bounds=$_.Bounds.ToString()}});Limitations='콜드 OS 캐시 미초기화. 캡처 자동 저장은 시각 검토 통과를 뜻하지 않음. 실제 DPI만 기록. 키보드·외부 도구 실행·다른 DPI·다중 화면은 별도 검증.'} (Join-Path $Root ('logs\v30-ui-'+$Label+'.json'))
}finally{
 foreach($process in $owned){try{if(!$process.HasExited){$process.CloseMainWindow()|Out-Null;$null=$process.WaitForExit(5000)}}finally{$process.Dispose()}}
 $env:GUNT_UI_METRICS=$oldMetrics
 if(!@(Get-Process 'GUNT.ControlCenter' -ErrorAction SilentlyContinue).Count){if($null -ne $originalWindow){[IO.File]::WriteAllBytes($windowFile,$originalWindow)}elseif(Test-Path $windowFile){Remove-Item -LiteralPath $windowFile}}
}
