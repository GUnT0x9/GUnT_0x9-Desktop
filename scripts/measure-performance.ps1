param([int]$Seconds=30)
. "$PSScriptRoot\common.ps1"
$names=@('GUNT-Bar','Rainmeter','Flow.Launcher','windhawk','explorer')
$before=@{}
foreach($p in Get-Process|Where-Object {$names -contains $_.ProcessName}){$before[$p.Id]=@{Name=$p.ProcessName;Cpu=$p.TotalProcessorTime.TotalSeconds}}
$watch=[Diagnostics.Stopwatch]::StartNew()
Start-Sleep -Seconds ([math]::Max(10,[math]::Min(60,$Seconds)))
$elapsed=$watch.Elapsed.TotalSeconds;$rows=@()
foreach($p in Get-Process|Where-Object {$names -contains $_.ProcessName}){
 if(!$before.ContainsKey($p.Id)){continue}
 $rows+=[pscustomobject]@{Name=$p.ProcessName;PID=$p.Id;CpuPercent=[math]::Round(100*($p.TotalProcessorTime.TotalSeconds-$before[$p.Id].Cpu)/$elapsed/[Environment]::ProcessorCount,3);WorkingSetMiB=[math]::Round($p.WorkingSet64/1MB,1);PrivateMiB=[math]::Round($p.PrivateMemorySize64/1MB,1);Responding=$p.Responding}
}
$owned=@($rows|Where-Object Name -ne 'explorer')
$result=[ordered]@{Time=(Get-Date).ToString('o');Seconds=[math]::Round($elapsed,2);LogicalProcessors=[Environment]::ProcessorCount;Processes=$rows;OwnCpuPercent=[math]::Round(($owned|Measure-Object CpuPercent -Sum).Sum,3);OwnWorkingSetMiB=[math]::Round(($owned|Measure-Object WorkingSetMiB -Sum).Sum,1);OwnPrivateMiB=[math]::Round(($owned|Measure-Object PrivateMiB -Sum).Sum,1);Notes='현재 작업 환경의 30초 표본입니다. 다른 앱의 부하를 제거한 실험실 유휴 측정이 아니며, Explorer에는 사용자 창과 Windhawk 모드가 함께 포함됩니다. 공유 메모리는 작업 집합 합계에 중복될 수 있습니다. GPU 전용 사용량·라이브 배경은 측정하지 않았습니다.'}
Write-Json $result (Join-Path $Root 'logs\v21-performance.json')
$result|ConvertTo-Json -Depth 5
