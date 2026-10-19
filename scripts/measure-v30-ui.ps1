# 동일 사용자 데이터·창 크기에서 두 Windows 네이티브 빌드를 번갈아 측정한다.
param([Parameter(Mandatory=$true)][string]$BaselineExecutable,[string]$CandidateExecutable,[ValidateRange(3,10)][int]$Samples=5)
. "$PSScriptRoot\enhancement-ui-common.ps1"
if(!$CandidateExecutable){$CandidateExecutable=Join-Path $Root 'bin\GUNT.ControlCenter.exe'}
foreach($file in @($BaselineExecutable,$CandidateExecutable)){if(!(Test-Path $file)){throw ('실행 파일 없음: '+$file)}}
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '기존 제어 센터/팝업을 먼저 닫으세요. 미저장 창은 자동 종료하지 않습니다.'}
Add-Type '[System.Runtime.InteropServices.DllImport("user32.dll")]public static extern uint GetDpiForWindow(System.IntPtr h);[System.Runtime.InteropServices.DllImport("user32.dll",CharSet=System.Runtime.InteropServices.CharSet.Unicode)]public static extern System.IntPtr FindWindow(string c,string t);' -Name V30BenchmarkDpi -Namespace Native
$oldMetrics=$env:GUNT_UI_METRICS;$env:GUNT_UI_METRICS='1';$metricFile=Join-Path $Root 'logs\v30-ui-timings.jsonl'
$windowFile=Join-Path $Root 'state\control-center-window.json';$original=if(Test-Path $windowFile){[IO.File]::ReadAllBytes($windowFile)}else{$null}
$results=@();$owned=@();$failure=$null
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
function Wait-Page($process,$page){
 $watch=[Diagnostics.Stopwatch]::StartNew()
 do{Start-Sleep -Milliseconds 25;$win=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id -and $_.Current.Name -eq 'GUnT_0x9 Desktop'}|Select-Object -First 1
 if($win){$title=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'PageTitle')));if($title -and $title.Current.Name -eq $page){return $win}}
 if($process.HasExited){throw '측정 대상 프로세스 종료'}
 }while($watch.Elapsed.TotalSeconds -lt 20)
 if($win){Write-Json (Get-EnhancementTree $win) (Join-Path $Root 'logs\v30-benchmark-timeout.json');Save-EnhancementShot 'v30-benchmark-timeout' $win.Current.BoundingRectangle}
 throw ('화면 준비 시간 초과: '+$page+' / PID '+$process.Id+' / 실제 '+$(if($title){$title.Current.Name}else{'제목 없음'}))
}
try{
 for($sample=0;$sample -lt $Samples;$sample++){
  $variants=if($sample%2){@('candidate','baseline')}else{@('baseline','candidate')}
  foreach($variant in $variants){
   if($null -ne $original){[IO.File]::WriteAllBytes($windowFile,$original)}
   $exe=if($variant -eq 'baseline'){$BaselineExecutable}else{$CandidateExecutable}
   Write-Output ("측정 "+$variant+" "+($sample+1)+"/"+$Samples)
   $offset=if(Test-Path $metricFile){@(Get-Content $metricFile).Count}else{0}
   $watch=[Diagnostics.Stopwatch]::StartNew();$process=Start-Process $exe -ArgumentList ('"'+$Root+'" overview') -PassThru;$owned+=,$process;$win=Wait-Page $process '개요';$ready=$watch.Elapsed.TotalMilliseconds
   $handle=[IntPtr]$win.Current.NativeWindowHandle;$dpi=[Native.V30BenchmarkDpi]::GetDpiForWindow($handle);$scale=$dpi/96.0;$work=[Windows.Forms.Screen]::FromHandle($handle).WorkingArea
   [GuntEnhanceUi]::SetWindowPos($handle,[IntPtr]::Zero,$work.Left+8,$work.Top+8,[int][math]::Min(1180*$scale,$work.Width-16),[int][math]::Min(800*$scale,$work.Height-16),0x14)|Out-Null
   foreach($page in @(@('developer-setup','개발 세팅'),@('development-sessions','개발 세션'),@('wallpaper','배경화면'),@('overview','개요'))){
    Write-Output ('이동 '+$page[0]);$request=Start-Process $exe -ArgumentList ('"'+$Root+'" '+$page[0]) -PassThru;$null=$request.WaitForExit(10000);$request.Dispose();$win=Wait-Page $process $page[1];Start-Sleep -Milliseconds 350
   }
   $paletteAction=(Get-EnhancementTree $win|Where-Object {$_.Type -eq 'ControlType.Button' -and $_.Name -like '명령 찾기*'}|Select-Object -First 1).Name
   if(!$paletteAction){throw '명령 팔레트 열기 동작 없음'}
   $open=Find-Name $win $paletteAction;($open.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
   $palette=$null
   for($probe=0;$probe -lt 100 -and !$palette;$probe++){Start-Sleep -Milliseconds 30;$palette=Find-Name $win 'GUnT_0x9 명령 팔레트'}
   if(!$palette){throw '실제 명령 찾기 버튼으로 팔레트가 열리지 않았습니다.'}
   $query=Find-Name $palette 'GUNT 명령 검색';if(!$query){throw '팔레트 검색 입력 없음'}
   foreach($text in @('codex','개발','없는검색어','')){($query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue($text);Start-Sleep -Milliseconds 80}
   ($palette.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern)).Close();Start-Sleep -Milliseconds 250
   $foregroundReturned=[GuntEnhanceUi]::GetForegroundWindow() -eq $handle
   $memory=@();$cpu=$null
   if($sample -eq $Samples-1){Start-Sleep -Seconds 2;$process.Refresh();$startCpu=$process.TotalProcessorTime.TotalSeconds;$idle=[Diagnostics.Stopwatch]::StartNew();for($i=0;$i -lt 5;$i++){Start-Sleep -Seconds 1;$process.Refresh();$memory+=@{WorkingSetMiB=$process.WorkingSet64/1MB;PrivateMiB=$process.PrivateMemorySize64/1MB}};$cpu=100*($process.TotalProcessorTime.TotalSeconds-$startCpu)/$idle.Elapsed.TotalSeconds/[Environment]::ProcessorCount}
   $process.CloseMainWindow()|Out-Null;if(!$process.WaitForExit(10000)){throw '측정 창 정상 종료 실패'}
   $metrics=@(Get-Content $metricFile|Select-Object -Skip $offset|ForEach-Object {$_|ConvertFrom-Json})
   $results+=@{Variant=$variant;Sample=$sample;ReadyMs=$ready;Dpi=$dpi;ForegroundReturned=$foregroundReturned;Metrics=$metrics;Memory=$memory;IdleCpuPercent=$cpu}
  }
 }
}catch{$failure=$_.Exception.Message;throw}finally{
 Write-Json @{Failure=$failure;Samples=$Samples;BaselineSha256=(Get-FileHash $BaselineExecutable).Hash;CandidateSha256=(Get-FileHash $CandidateExecutable).Hash;Results=$results;Notes='각 빌드 5회 교차 실행. OS 캐시 초기화 안 함. 동일 1180x800 DIP·동일 사용자 데이터. 팔레트는 UIA Invoke로 열기. 전역 키 입력 시험과 분리. first-render는 비동기 상태 조회 완료를 포함하지 않음. UIA·계측 비용 포함. 마지막 표본에서 유휴 5초 관찰.'} (Join-Path $Root 'logs\v30-dev2-benchmark.json')
 foreach($process in $owned){try{if(!$process.HasExited){$process.CloseMainWindow()|Out-Null;$null=$process.WaitForExit(5000)}}finally{$process.Dispose()}}
 $env:GUNT_UI_METRICS=$oldMetrics
 if(!@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count){if($null -ne $original){[IO.File]::WriteAllBytes($windowFile,$original)}elseif(Test-Path $windowFile){Remove-Item -LiteralPath $windowFile}}
}
