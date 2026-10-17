. "$PSScriptRoot\common.ps1"
$p=Join-Path $Root 'apps\HWiNFO\HWiNFO64.exe'
$signature=Get-AuthenticodeSignature $p
if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'REALiX'){throw 'HWiNFO 공식 서명이 유효하지 않습니다.'}
if(Get-Process HWiNFO64 -ErrorAction SilentlyContinue){Write-Log 'hwinfo-start' 'already-running' 'HWiNFO가 이미 실행 중입니다. 기존 센서 상태 창을 사용하세요.';return}
# HWiNFO preserves SensorsOnly in its INI; do not invent unsupported CLI switches.
$ini=Join-Path (Split-Path $p -Parent) 'HWiNFO64.INI'
$text=if(Test-Path $ini){[IO.File]::ReadAllText($ini)}else{"[Settings]`r`n"}
if(Test-Path $ini){Copy-Item $ini ($ini+'.before-gunt') -Force}
if($text -match '(?m)^SensorsOnly='){$text=$text -replace '(?m)^SensorsOnly=.*$','SensorsOnly=1'}else{$text=$text -replace '(?m)^\[Settings\]',('[Settings]'+"`r`nSensorsOnly=1")}
[IO.File]::WriteAllText($ini,$text,[Text.Encoding]::Default)
$process=Start-Process $p -Verb RunAs -PassThru
Write-Json @{Time=(Get-Date).ToString('o');Path=$p;Id=$process.Id;Signature='Valid';Scope='사용자가 명시적으로 허용한 HWiNFO 센서 실행'} (Join-Path $Root 'state\hwinfo-start.json')
Write-Log 'hwinfo-start' 'started' '승인된 HWiNFO 센서 프로그램을 실행했습니다.'
