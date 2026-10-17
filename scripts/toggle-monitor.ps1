param([switch]$DeferRefresh)
. "$PSScriptRoot\common.ps1"
[Console]::OutputEncoding=New-Object Text.UTF8Encoding($false)
$mutex=New-Object Threading.Mutex($false,'Local\GUNTMonitorMode')
$locked=$mutex.WaitOne(0)
if(!$locked){$mutex.Dispose();return}
$path=Join-Path $Root 'config\monitor.json'
$backup=Join-Path $Root ('backups\monitor-mode-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'\monitor.json')
try{
 New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null;Copy-Item $path $backup
 $config=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$config.compact=!$config.compact
 Write-Json $config $path
 & "$PSScriptRoot\update-monitor.ps1" -DeferRefresh:$DeferRefresh
 Write-Log 'monitor-mode' 'applied' ('모니터 모드 전환 완료; 간단히='+$config.compact)
}catch{
 if(Test-Path $backup){Copy-Item $backup $path -Force;try{& "$PSScriptRoot\update-monitor.ps1" -DeferRefresh:$DeferRefresh}catch{Write-Log 'monitor-mode-rollback' 'failed' $_.Exception.Message}}
 throw
}finally{$mutex.ReleaseMutex();$mutex.Dispose()}
