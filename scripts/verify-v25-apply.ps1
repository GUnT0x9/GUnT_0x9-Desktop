. "$PSScriptRoot\enhancement-ui-common.ps1"
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
Start-Process $exe -ArgumentList ('"'+$Root+'" monitor');Start-Sleep -Milliseconds 1000
$p=Get-Process GUNT.ControlCenter|Select-Object -First 1;$win=[Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
function Find-Typed([string]$name,$type){$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.AndCondition((New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)),(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,$type)))))}
$path=Join-Path $Root 'config\monitor.json';$before=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$expected=![bool]$before.showCpuGraph
$check=$null;for($probe=0;$probe -lt 40 -and !$check;$probe++){Start-Sleep -Milliseconds 100;$check=Find-Typed 'CPU 그래프 표시' ([Windows.Automation.ControlType]::CheckBox)};if(!$check){throw 'CPU 그래프 체크박스를 찾지 못했습니다.'}
($check.GetCurrentPattern([Windows.Automation.TogglePattern]::Pattern)).Toggle()
$apply=Find-Typed '변경 사항 적용' ([Windows.Automation.ControlType]::Button);if(!$apply.Current.IsEnabled){throw '실제 변경 후 적용이 활성화되지 않았습니다.'};($apply.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
$applied=$false;$restored=$false
try{
 for($i=0;$i -lt 100;$i++){Start-Sleep -Milliseconds 200;$m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$undo=Find-Typed '직전 적용 취소' ([Windows.Automation.ControlType]::Button);if([bool]$m.showCpuGraph -eq $expected -and $undo.Current.IsEnabled){$applied=$true;break}}
 if(!$applied){throw '실제 설정 반영과 실행 취소 활성화를 확인하지 못했습니다.'}
 $runtime=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json;$export=[IO.File]::ReadAllText($runtime.variables);$hidden=[int](!$expected -or [bool]$m.compact -or ![bool]$m.showCpu)
 if($export -notmatch ('(?m)^HideCPUGraph='+$hidden+'\r?$')){throw '실제 Rainmeter 내보내기 값 불일치'}
 ($undo.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke()
 for($i=0;$i -lt 100;$i++){Start-Sleep -Milliseconds 200;$m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;if([bool]$m.showCpuGraph -eq [bool]$before.showCpuGraph -and !(Find-Typed '변경 사항 적용' ([Windows.Automation.ControlType]::Button)).Current.IsEnabled -and !(Find-Typed '직전 적용 취소' ([Windows.Automation.ControlType]::Button)).Current.IsEnabled){$restored=$true;break}}
 if(!$restored){throw '실행 취소 후 이전 설정과 완료 상태를 확인하지 못했습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Before=$before.showCpuGraph;Applied=$expected;Restored=$m.showCpuGraph;RainmeterExportVerified=$true;PositionPreserved=([string]($before.position|ConvertTo-Json -Compress) -eq [string]($m.position|ConvertTo-Json -Compress))} (Join-Path $Root 'logs\v25-live-apply.json')
 Write-Output '실제 WPF 체크박스 → 적용 → Rainmeter 내보내기 → 한 단계 실행 취소 통과'
}finally{
 if(!$restored){$m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;if([bool]$m.showCpuGraph -ne [bool]$before.showCpuGraph){$m.showCpuGraph=$before.showCpuGraph;Write-Json $m $path;& (Join-Path $Root 'scripts\update-monitor.ps1')}}
}
