. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
$s=Get-Content (Join-Path $Root 'state\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json
$topology=Get-Content (Join-Path $Root 'state\storage-topology.json') -Raw -Encoding UTF8|ConvertFrom-Json
$disk=$topology.Volumes|Where-Object DriveLetter -eq 'C:'|Select-Object -First 1
$selection=@(
 @{Metric='CpuTemperatureC';Label='코어 온도';Sensor='*Intel Core Ultra 5 226V*DTS*';Kind='core'},
 @{Metric='GpuTemperatureC';Label='GPU Core 온도';Sensor='*Intel Arc 130V*';Kind='gpu-core'},
 @{Metric='SsdTemperatureC';Label='디스크 온도';Sensor=('*'+$disk.DiskModel+'*');Kind='physical-disk'}
)
$config=[GuntConfiguration]::Read($Root,'sensors');$mappings=New-Object 'Collections.Generic.List[object]'
foreach($existing in $config['mappings']){if($existing['metric'] -notin @($selection.Metric)){$mappings.Add($existing)}}
foreach($spec in $selection){
 $matches=@($s.TemperatureReadings|Where-Object {$_.Label -eq $spec.Label -and $_.Sensor -like $spec.Sensor -and $_.Unit -eq '°C' -and $_.Quality -eq 'valid'})
 if($matches.Count -ne 1){throw ('실제 센서를 하나로 식별할 수 없습니다: '+$spec.Metric+'; 수='+$matches.Count)}
 $r=$matches[0];$m=@{metric=$spec.Metric;fingerprint=$r.Fingerprint;sensor=$r.Sensor;label=$r.Label;index=$r.Index;unit=$r.Unit;kind=$spec.Kind}
 if($spec.Kind -eq 'physical-disk'){$m['diskUniqueId']=$disk.DiskUniqueId;$m['diskNumber']=$disk.DiskNumber;$m['volumes']=@($topology.Volumes|Where-Object DiskUniqueId -eq $disk.DiskUniqueId|ForEach-Object DriveLetter)}
 $mappings.Add($m)
}
$config['mappings']=$mappings;$config['providerPath']=Join-Path $Root 'apps\HWiNFO\HWiNFO64.exe';$config['schemaVersion']=2
$backup=Join-Path $Root ('backups\sensor-mapping-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'\sensors.json');New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null;Copy-Item (Join-Path $Root 'config\sensors.json') $backup
Write-Json $config (Join-Path $Root 'config\sensors.json')
$monitor=[GuntConfiguration]::Read($Root,'monitor');$monitor['showGpu']=$true;[GuntConfiguration]::Save($Root,'monitor',$monitor)|Out-Null
Write-Log 'sensors-v24' 'connected' '실제 CPU DTS 코어·Arc GPU 코어·C/D 공유 NVMe 온도를 식별값과 단위로 연결했습니다.'
