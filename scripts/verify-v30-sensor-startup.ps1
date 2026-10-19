param([ValidatePattern('^[a-z0-9.-]+$')][string]$Label='dev3',[string]$Executable)
. "$PSScriptRoot\enhancement-ui-common.ps1"
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '기존 제어 센터를 먼저 정상 종료하세요.'}
$exe=if($Executable){$Executable}else{Join-Path $Root 'bin\GUNT.ControlCenter.exe'}
$windowFile=Join-Path $Root 'state\control-center-window.json';$original=if(Test-Path $windowFile){[IO.File]::ReadAllBytes($windowFile)}else{$null};$process=$null
function Find-Name($window,$name){$window.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
try{
 # App.Main constructs MainWindow before Application.Run installs its UI context.
 $process=Start-Process $exe -ArgumentList ('"'+$Root+'" sensors') -PassThru
 $button=$null;$window=$null
 for($i=0;$i -lt 160 -and !$button;$i++){
  if($process.HasExited){throw ('센서 시작 화면이 종료됐습니다. 종료 코드: '+$process.ExitCode)}
  Start-Sleep -Milliseconds 80
  $window=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id -and $_.Current.Name -eq 'GUnT_0x9 Desktop'}|Select-Object -First 1
  if($window){$title=$window.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'PageTitle')));if($title -and $title.Current.Name -eq '하드웨어 센서'){$button=Find-Name $window '실제 센서 다시 읽기'}}
 }
 if(!$button){throw '센서 직접 시작의 WPF 컨트롤 준비 시간 초과'}
 Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$h=[IntPtr]$window.Current.NativeWindowHandle;$screen=[Windows.Forms.Screen]::FromHandle($h);$scale=[GuntLayout]::Scale($screen)
 [GuntEnhanceUi]::SetWindowPos($h,[IntPtr]::Zero,$screen.WorkingArea.Left+8,$screen.WorkingArea.Top+8,[int][math]::Min(1180*$scale,$screen.WorkingArea.Width-16),[int][math]::Min(800*$scale,$screen.WorkingArea.Height-16),0x14)|Out-Null
 ($button.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
 $matched=$false
 for($i=0;$i -lt 80 -and !$matched;$i++){Start-Sleep -Milliseconds 80;$window=Get-EnhancementWindows|Where-Object {$_.Current.ProcessId -eq $process.Id -and $_.Current.Name -eq 'GUnT_0x9 Desktop'}|Select-Object -First 1;if($window){$matched=$null -ne (Find-Name $window '센서 목록을 새로 요청했습니다.')}}
 if(!$matched){throw '실제 센서 요청 피드백을 확인하지 못했습니다.'}
 Save-EnhancementShot ('v30-'+$Label+'-sensors-direct-start') $window.Current.BoundingRectangle
 Write-Json @{Status='passed';DirectSensorStartup=$true;SensorRequestFeedback=$true;ExecutableSha256=(Get-FileHash $exe).Hash;Scope='실제 Windows에서 sensors를 첫 화면으로 직접 실행. 읽기 전용 새로고침과 실제 피드백 확인. 별도 이동 IPC·공급자 실행·연결 저장 없음.'} (Join-Path $Root ('logs\v30-'+$Label+'-sensor-startup.json'))
 Write-Output '센서 직접 시작·요청 피드백 검사 통과'
}finally{
 if($process){try{if(!$process.HasExited){$process.CloseMainWindow()|Out-Null;if(!$process.WaitForExit(10000)){throw '검사 창 정상 종료 실패. 강제 종료하지 않았습니다.'}}}finally{$process.Dispose()}}
 if(!@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count){if($null -ne $original){[IO.File]::WriteAllBytes($windowFile,$original)}elseif(Test-Path $windowFile){Remove-Item -LiteralPath $windowFile}}
}
