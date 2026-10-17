. "$PSScriptRoot\enhancement-ui-common.ps1"
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';$configPath=Join-Path $Root 'config\sensors.json';$before=Get-Content $configPath -Raw -Encoding UTF8|ConvertFrom-Json;$baseline=$before.mappings|ConvertTo-Json -Depth 12 -Compress
function Control($parent,[string]$name,$type){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.AndCondition((New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)),(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,$type)))))}
Start-Process $exe -ArgumentList ('"'+$Root+'" sensors');Start-Sleep -Milliseconds 1200;$p=Get-Process GUNT.ControlCenter|Select-Object -First 1;$win=[Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$button=$null;for($i=0;$i -lt 40 -and !$button;$i++){Start-Sleep -Milliseconds 100;$button=Control $win '선택한 센서 검증 · 연결' ([Windows.Automation.ControlType]::Button)}
if(!$button -or !$button.Current.IsEnabled){throw '현재 연결 가능한 실제 센서가 없습니다.'}
($button.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();$undo=$null;$done=$false
try{
 for($i=0;$i -lt 80;$i++){Start-Sleep -Milliseconds 150;$undo=Control $win '직전 적용 취소' ([Windows.Automation.ControlType]::Button);if($undo -and $undo.Current.IsEnabled){$done=$true;break}}
 if(!$done){throw '실제 센서 연결 저장 완료를 확인하지 못했습니다.'}
 ($undo.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();$restored=$false
 for($i=0;$i -lt 80;$i++){Start-Sleep -Milliseconds 150;$current=Get-Content $configPath -Raw -Encoding UTF8|ConvertFrom-Json;if(($current.mappings|ConvertTo-Json -Depth 12 -Compress) -eq $baseline -and !(Control $win '직전 적용 취소' ([Windows.Automation.ControlType]::Button)).Current.IsEnabled){$restored=$true;break}}
 if(!$restored){throw '센서 시험 후 기존 매핑 복원을 확인하지 못했습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Provider='existing HWiNFO';Verified='실제 값·장치·단위 재확인 후 연결 저장';PreviousMappingsRestored=$true} (Join-Path $Root 'logs\v25-sensor-ui.json');Write-Output '실제 센서 연결 검증·저장·기존 매핑 실행 취소 통과'
}finally{
 if(!$restored){$current=Get-Content $configPath -Raw -Encoding UTF8|ConvertFrom-Json;$current.mappings=$before.mappings;Write-Json $current $configPath}
}
