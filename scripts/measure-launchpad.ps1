param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][string]$DemoRoot,[string]$Label='launchpad',[ValidateRange(1,9)][int]$Samples=5)
. "$PSScriptRoot\enhancement-ui-common.ps1"
if(Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUNT Launchpad'}){throw '열린 Launchpad를 정상 종료한 뒤 측정하세요.'}
Add-Type @'
using System;using System.Runtime.InteropServices;public static class LaunchpadMeasureNative {[DllImport("user32.dll")]public static extern bool PostMessage(IntPtr hwnd,uint message,IntPtr w,IntPtr l);[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int cmd);}
'@
$env:GUNT_UI_METRICS='1';$timing=Join-Path $DemoRoot 'logs\v30-ui-timings.jsonl';$records=@();$process=$null
function Wait-Metric([int]$Count){for($n=0;$n -lt 160;$n++){Start-Sleep -Milliseconds 20;$lines=@(Get-Content -LiteralPath $timing -ErrorAction SilentlyContinue);if($lines.Count -gt $Count){$new=@($lines|Select-Object -Skip $Count|ForEach-Object {$_|ConvertFrom-Json});if($new.metric -contains 'launchpad-warm-open'){return $new}}};throw 'warm render metric timeout'}
try{
 for($sample=0;$sample -lt $Samples;$sample++){
  $initial=@(Get-Content -LiteralPath $timing -ErrorAction SilentlyContinue).Count;$watch=[Diagnostics.Stopwatch]::StartNew();$process=Start-Process $Executable -ArgumentList ('"'+$DemoRoot+'" launchpad') -PassThru;$window=$null
  for($n=0;$n -lt 160 -and !$window;$n++){Start-Sleep -Milliseconds 20;$window=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id -and $_.Current.Name -eq 'GUNT Launchpad'}|Select-Object -First 1};if(!$window){throw 'Launchpad creation timeout'}
  $ready=$watch.Elapsed.TotalMilliseconds;Start-Sleep -Milliseconds 600;$h=[IntPtr]$window.Current.NativeWindowHandle
  $initialMetrics=@(Get-Content -LiteralPath $timing|Select-Object -Skip $initial|ForEach-Object {$_|ConvertFrom-Json});$warm=@()
  for($n=0;$n -lt 7;$n++){
   [GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;[LaunchpadMeasureNative]::PostMessage($h,0x8006,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null;Start-Sleep -Milliseconds 80
   $count=@(Get-Content -LiteralPath $timing).Count
   [LaunchpadMeasureNative]::ShowWindow($h,5)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;[LaunchpadMeasureNative]::PostMessage($h,0x8006,[IntPtr]1,[IntPtr]::Zero)|Out-Null
   $metric=Wait-Metric $count;$warm+=@($metric|Where-Object {$_.metric -eq 'launchpad-warm-open'}|ForEach-Object {$_.ms});Start-Sleep -Milliseconds 60
  }
  $process.Refresh();$memory=$process.WorkingSet64/1MB;$private=$process.PrivateMemorySize64/1MB
  [LaunchpadMeasureNative]::PostMessage($h,0x8006,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null;Start-Sleep -Milliseconds 150;$process.Refresh();$cpu=$process.TotalProcessorTime.TotalSeconds;$idleWatch=[Diagnostics.Stopwatch]::StartNew();Start-Sleep -Seconds 2;$process.Refresh();$cpuPercent=100*($process.TotalProcessorTime.TotalSeconds-$cpu)/$idleWatch.Elapsed.TotalSeconds/[Environment]::ProcessorCount
  $records+=@{Sample=$sample;ProcessReadyMs=$ready;Initial=$initialMetrics;WarmMs=$warm;WorkingSetMiB=$memory;PrivateMiB=$private;HiddenIdleCpuPercent=$cpuPercent}
  [LaunchpadMeasureNative]::ShowWindow($h,5)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;[LaunchpadMeasureNative]::PostMessage($h,0x8006,[IntPtr]1,[IntPtr]::Zero)|Out-Null;Start-Sleep -Milliseconds 120
  $window=[Windows.Automation.AutomationElement]::FromHandle($h)
  $exit=$window.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'종료')))
  if(!$exit){$manage=$window.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'관리')));if($manage){($manage.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();Start-Sleep -Milliseconds 100;foreach($candidate in Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id}){$exit=$candidate.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'종료')));if($exit){break}}}};if(!$exit){throw 'normal exit control not found'};($exit.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();if(!$process.WaitForExit(5000)){throw 'Launchpad normal exit timeout'};$process.Dispose();$process=$null
 }
}finally{Write-Json @{Label=$Label;CapturedAt=[DateTimeOffset]::Now.ToString('o');ExecutableSha256=(Get-FileHash $Executable).Hash;Records=$records;Conditions='별도 공개용 카탈로그. 프로세스 첫 UIA 준비와 WPF 내부 첫 프레임/Render 우선순위 따로 기록. OS 캐시 초기화 안 함. 각 7회 warm, 2초 hidden idle. CPU는 논리 프로세서 수로 정규화.'} (Join-Path $Root ('logs\'+$Label+'-performance.json'));if($process){$process.CloseMainWindow()|Out-Null;$process.Dispose()};Remove-Item Env:\GUNT_UI_METRICS -ErrorAction SilentlyContinue}
Write-Output ($Samples.ToString()+' process samples recorded')
