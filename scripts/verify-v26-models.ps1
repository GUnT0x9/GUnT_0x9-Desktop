. "$PSScriptRoot\common.ps1"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$exe=Join-Path $Root 'bin\Gunt.DeveloperTests.exe'
& $csc /nologo /target:exe ('/out:'+$exe) /reference:System.dll /reference:System.Core.dll /reference:System.Web.Extensions.dll ('/reference:'+(Join-Path $Root 'bin\GUNT.ControlCenter.exe')) ('/reference:'+(Join-Path $Root 'bin\Gunt.Configuration.dll')) ('/reference:'+(Join-Path $Root 'bin\Gunt.Sensors.dll')) (Join-Path $Root 'control-center\tests\DeveloperTests.cs')
if($LASTEXITCODE -ne 0){throw '개발 워크스페이스 모델 검사 컴파일 실패'}
$fixture=Join-Path $Root ('tests\v26-'+[guid]::NewGuid().ToString('N'));$savedErrorAction=$ErrorActionPreference;$ErrorActionPreference="Continue";try{$output=& $exe $fixture 2>&1;$code=$LASTEXITCODE}finally{$ErrorActionPreference=$savedErrorAction};$output|ForEach-Object {Write-Output $_}
Write-Json @{Time=(Get-Date).ToString('o');ExitCode=$code;Output=@($output|ForEach-Object {$_.ToString()});Fixture=$fixture} (Join-Path $Root 'logs\v26-model-tests.json')
if($code -ne 0){throw '분리된 개발 워크스페이스 검사 실패'}
