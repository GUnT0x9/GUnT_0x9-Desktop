. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))|Out-Null
$fixture=Join-Path $Root ('tests\work\transaction-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force (Join-Path $fixture 'config'),(Join-Path $fixture 'scripts')|Out-Null
Copy-Item (Join-Path $Root 'config\monitor.json') (Join-Path $fixture 'config\monitor.json')
[IO.File]::WriteAllText((Join-Path $fixture 'scripts\apply-v24-settings.ps1'),"throw '의도적 적용 실패 테스트'",[Text.UTF8Encoding]::new($true))
$service=New-Object Gunt.ControlCenter.Services.DesktopService($fixture)
$config=$service.Read('monitor');$json=$service.Json;$initial=$json.Serialize($config)
$field=New-Object Gunt.ControlCenter.Models.SettingField;$field.Config='monitor';$field.Key='showCpuGraph';$field.Label='CPU 그래프';$field.Kind='bool';$field.Original=$json.Serialize($config['showCpuGraph']);$field.Value=![bool]$config['showCpuGraph']
$fields=New-Object 'Collections.Generic.List[Gunt.ControlCenter.Models.SettingField]';$fields.Add($field)
$thrown=$false;try{$null=$service.Apply($fields)}catch{$thrown=$true}
if(!$thrown -or $json.Serialize($service.Read('monitor')) -ne $initial){throw '적용 실패 후 원본 복구 검증 실패'}
$config=$service.Read('monitor');$config['width']=10;$rejected=$false;try{[GuntConfiguration]::Save($fixture,'monitor',$config)|Out-Null}catch{$rejected=$true}
if(!$rejected -or $json.Serialize($service.Read('monitor')) -ne $initial){throw '잘못된 입력 사전 차단 검증 실패'}
$backups=@(Get-ChildItem (Join-Path $fixture 'backups\settings-v24') -File -Recurse)
if(!$backups.Count){throw '트랜잭션 백업이 생성되지 않았습니다.'}
Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Fixture=$fixture;LiveDesktopChanged=$false;FailureRollsBack=$true;InvalidInputRejectedBeforeWrite=$true;VersionedBackups=$backups.Count} (Join-Path $Root 'logs\v24-transaction-verification.json')
Write-Log 'transactions-v24-test' 'passed' '분리된 테스트 경로에서 적용 실패 복구·입력 사전 검증·버전 백업을 확인했습니다.'
