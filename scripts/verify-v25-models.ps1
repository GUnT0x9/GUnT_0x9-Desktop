. "$PSScriptRoot\common.ps1"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$exe=Join-Path $Root 'bin\Gunt.UxTests.exe'
& $csc /nologo /target:exe ('/out:'+$exe) /reference:System.dll /reference:System.Core.dll /reference:System.Web.Extensions.dll ('/reference:'+(Join-Path $Root 'bin\GUNT.ControlCenter.exe')) ('/reference:'+(Join-Path $Root 'bin\Gunt.Configuration.dll')) ('/reference:'+(Join-Path $Root 'bin\Gunt.Sensors.dll')) (Join-Path $Root 'control-center\tests\UxTests.cs')
if($LASTEXITCODE -ne 0){throw 'UX 모델 시험 컴파일 실패'}
$fixture=Join-Path $Root ('tests\v25-'+[guid]::NewGuid().ToString('N'))
$output=& $exe $fixture 2>&1;$code=$LASTEXITCODE;$output|ForEach-Object {Write-Output $_}
Write-Json @{Time=(Get-Date).ToString('o');ExitCode=$code;Fixture=$fixture;Output=@($output|ForEach-Object {$_.ToString()})} (Join-Path $Root 'logs\v25-model-tests.json')
if($code -ne 0){throw '분리된 UX 모델 시험 실패'}
Write-Log 'v25-models' 'passed' '분리 경로에서 실제 파일 저장·충돌·실패 복구·프로젝트 검증·로컬 갤러리 시험 통과. 라이브 설정·배경은 변경하지 않았습니다.'
