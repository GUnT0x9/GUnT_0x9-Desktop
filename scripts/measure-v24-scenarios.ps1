. "$PSScriptRoot\common.ps1"
$path=Join-Path $Root 'config\monitor.json';$original=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json
try{
 foreach($scenario in 'compact-closed','graphs-hidden-closed','monitor-hidden-closed'){
  $m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$m.visible=$true;$m.compact=($scenario -eq 'compact-closed');$m.showCpuGraph=$scenario -eq 'compact-closed';$m.showNetworkGraph=$scenario -eq 'compact-closed'
  if($scenario -eq 'monitor-hidden-closed'){$m.visible=$false}
  Write-Json $m $path;& "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Seconds 2
  & "$PSScriptRoot\measure-v24-performance.ps1" -Scenario $scenario -Seconds 30
 }
}finally{Write-Json $original $path;& "$PSScriptRoot\update-monitor.ps1"}
