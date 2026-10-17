. "$PSScriptRoot\common.ps1"
$rows=@();$fail=@();$metrics=@{CpuTemperatureC='CPU';GpuTemperatureC='GPU';SsdTemperatureC='SSD'}
for($i=0;$i -lt 20;$i++){
 $s=Get-Content (Join-Path $Root 'state\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $config=Get-Content (Join-Path $Root 'config\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json
 foreach($metric in $metrics.Keys){
  $mapping=$config.mappings|Where-Object metric -eq $metric|Select-Object -First 1
  $reading=$s.TemperatureReadings|Where-Object Fingerprint -eq $mapping.fingerprint|Select-Object -First 1
  $hive=if($reading.Hive -eq 'HKEY_CURRENT_USER'){[Microsoft.Win32.Registry]::CurrentUser}else{[Microsoft.Win32.Registry]::LocalMachine}
  $key=$hive.OpenSubKey('SOFTWARE\HWiNFO64\VSB')
  try{$raw=[double]::Parse([string]$key.GetValue('ValueRaw'+$reading.Index),[Globalization.CultureInfo]::InvariantCulture);$label=[string]$key.GetValue('Label'+$reading.Index);$sensor=[string]$key.GetValue('Sensor'+$reading.Index)}finally{if($key){$key.Dispose()}}
  $valid=$null -ne $s.$metric -and $reading.Quality -eq 'valid' -and $label -eq $mapping.label -and $sensor -eq $mapping.sensor -and $reading.Unit -eq '°C' -and [math]::Abs($raw-[double]$s.$metric) -le 12 -and $reading.AgeSeconds -lt 10
  if(!$valid){$fail+=($metric+' 대조 실패')}
  $rows+=[pscustomobject]@{Sample=$i;Time=(Get-Date).ToString('o');Metric=$metric;ProviderValue=$raw;AdapterValue=$s.$metric;Label=$label;Sensor=$sensor;RegistryIndex=$reading.Index;Fingerprint=$reading.Fingerprint;AgeSeconds=$reading.AgeSeconds;Status=$(if($valid){'passed'}else{'failed'});Note='공급자와 소비자의 샘플 시각 차이 최대 한 주기, 온도 변화 허용 12°C'}
 }
 Start-Sleep -Seconds 2
}
Write-Json @{Time=(Get-Date).ToString('o');Status=$(if($fail.Count){'failed'}else{'passed'});Rows=$rows;CpuMetric='DTS 코어 온도: 패키지 온도로 표기하지 않음';SsdPhysicalDevice='C:/D: 공유 Samsung NVMe, 한 번만 표시';Provider='HWiNFO 8.54 Gadget Registry';GuiValueComparison='별도 미시험';Failures=$fail} (Join-Path $Root 'logs\v24-sensor-verification.json')
if($fail.Count){throw ($fail -join ', ')}
Write-Log 'sensor-v24-test' 'passed' 'CPU·GPU·SSD 실제 센서와 20회 대조했습니다.'
