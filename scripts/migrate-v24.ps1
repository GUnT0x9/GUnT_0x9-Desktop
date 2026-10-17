. "$PSScriptRoot\common.ps1"
$m=Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json
$defaults=@{schemaVersion=2;showCpuGraph=$true;showNetworkGraph=$true;showGpuGraph=$false;graphHistorySeconds=60;graphStyle='lineWithGuides';networkScaleMode='dynamic';networkFixedMaxBytesPerSecond=10485760;gpuAdapterIndex=0;sensorProvider='auto';storageVolumes=@('C:','D:');showRemovable=$false;position=@{mode='auto';locked=$false;monitorId=$null;xDip=0;yDip=0}}
foreach($k in $defaults.Keys){if($m.PSObject.Properties.Name -notcontains $k){$m|Add-Member -NotePropertyName $k -NotePropertyValue $defaults[$k]}}
$m.width=360;$m.radius=6;Write-Json $m (Join-Path $Root 'config\monitor.json')
$t=Read-Theme;foreach($pair in @(@('ui','S-Core Dream 5 Medium'),@('heading','S-Core Dream 6 Bold'),@('secondary','S-Core Dream 4 Regular'),@('metrics','S-Core Dream 5 Medium'),@('latin','Manrope Medium'))){$t.fonts|Add-Member -NotePropertyName $pair[0] -NotePropertyValue $pair[1] -Force};$t.version='2.4';Write-Json $t (Join-Path $Root 'config\theme.json')
$b=Get-Content (Join-Path $Root 'config\topbar.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($pair in @(@('brandText','GUnT_0x9'),@('brandFont','Manrope Medium'),@('brandSize',20),@('iconSize',20))){$b|Add-Member -NotePropertyName $pair[0] -NotePropertyValue $pair[1] -Force};Write-Json $b (Join-Path $Root 'config\topbar.json')
if(!(Test-Path (Join-Path $Root 'config\sensors.json'))){Write-Json @{schemaVersion=1;provider='auto';staleSeconds=10;mappings=@();providerPath=$null} (Join-Path $Root 'config\sensors.json')}
Write-Log 'migrate-v24' 'passed' '현재 표시 선택·배경·Dock을 보존하고 새 설정 기본값을 추가했습니다.'
