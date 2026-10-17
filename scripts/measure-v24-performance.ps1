param([ValidatePattern('^[a-z0-9-]+$')][string]$Scenario='detailed-visible',[ValidateRange(10,120)][int]$Seconds=60)
. "$PSScriptRoot\common.ps1"
$names=@('GUNT-Bar','Rainmeter','GUNT.ControlCenter','Flow.Launcher','windhawk','explorer','Lively','Lively.PlayerWebView2','Lively.Player.Mpv','mpv','HWiNFO64')
$before=@{};Get-Process|Where-Object {$names -contains $_.ProcessName}|ForEach-Object {$before[$_.Id]=@{Name=$_.ProcessName;Cpu=$_.TotalProcessorTime.TotalSeconds}}
$timer=[Diagnostics.Stopwatch]::StartNew();$samples=@()
while($timer.Elapsed.TotalSeconds -lt $Seconds){Start-Sleep -Seconds 2;$samples+=@(Get-Process|Where-Object {$before.ContainsKey($_.Id)}|ForEach-Object {[pscustomobject]@{Pid=$_.Id;Name=$_.ProcessName;WorkingSetMiB=$_.WorkingSet64/1MB;PrivateMiB=$_.PrivateMemorySize64/1MB}})}
$elapsed=$timer.Elapsed.TotalSeconds
$rows=@(Get-Process|Where-Object {$before.ContainsKey($_.Id)}|ForEach-Object {$subset=@($samples|Where-Object Pid -eq $_.Id);[pscustomobject]@{Name=$_.ProcessName;Pid=$_.Id;CpuPercent=[math]::Round(100*($_.TotalProcessorTime.TotalSeconds-$before[$_.Id].Cpu)/$elapsed/[Environment]::ProcessorCount,3);WorkingSetMiB=[math]::Round(($subset|Measure-Object WorkingSetMiB -Average).Average,1);PrivateMiB=[math]::Round(($subset|Measure-Object PrivateMiB -Average).Average,1);Responding=$_.Responding}})
$s=Get-Content (Join-Path $Root 'state\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json
Write-Json @{Time=(Get-Date).ToString('o');Scenario=$Scenario;Seconds=$elapsed;LogicalProcessors=[Environment]::ProcessorCount;Processes=$rows;ACConnected=$s.ACConnected;BatterySaver=$s.BatterySaver;Monitor=(Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json);Notes='현재 실제 작업 중 표본. Explorer·Lively는 별도 표시하며 다른 앱 부하를 GUNT에 합산하지 않음. 숨김 상태 센서 파일은 마지막 샘플일 수 있음. 배터리 지속시간·GPU 전력 절감은 미측정.'} (Join-Path $Root ('logs\v24-performance-'+$Scenario+'.json'))
Write-Log 'performance-v24' 'measured' ($Scenario+' '+[math]::Round($elapsed)+'초');$rows|ConvertTo-Json
