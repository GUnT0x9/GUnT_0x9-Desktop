. "$PSScriptRoot\common.ps1"
$script=Join-Path $Root 'scripts\register-hwinfo-startup.ps1'
$p=Start-Process (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "'+$script+'"') -PassThru
if(!$p.WaitForExit(120000)){throw '관리자 승인 또는 시작 작업 등록이 아직 완료되지 않았습니다.'}
if($p.ExitCode -ne 0){throw ('센서 시작 작업 등록 실패: '+$p.ExitCode)}
$state=Join-Path $Root 'state\hwinfo-startup.json';if(!(Test-Path $state)){throw '시작 작업 등록 결과 파일을 찾지 못했습니다.'}
Write-Log 'hwinfo-startup' 'verified' '관리자 도우미의 등록 결과를 확인했습니다.'
