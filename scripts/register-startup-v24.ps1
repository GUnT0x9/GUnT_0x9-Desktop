. "$PSScriptRoot\common.ps1"
$c=Get-Content (Join-Path $Root 'config\startup.json') -Raw -Encoding UTF8|ConvertFrom-Json
$key='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run';$name='GUNTDesktop';$current=(Get-ItemProperty $key -ErrorAction SilentlyContinue).$name
$dir=Join-Path $Root ('backups\startup-register-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'));New-Item -ItemType Directory -Force $dir|Out-Null;Write-Json @{Previous=$current} (Join-Path $dir 'registration.json')
$expected='"'+(Join-Path $env:WINDIR 'System32\wscript.exe')+'" "'+(Join-Path $Root 'scripts\start-hidden.vbs')+'"'
if($c.enabled){New-ItemProperty $key -Name $name -Value $expected -PropertyType String -Force|Out-Null}else{Remove-ItemProperty $key $name -ErrorAction SilentlyContinue}
$actual=(Get-ItemProperty $key -ErrorAction SilentlyContinue).$name
if(($c.enabled -and $actual -ne $expected) -or (!$c.enabled -and $actual)){throw 'GUNT 시작 등록 검증 실패'}
Write-Log 'startup-registration' 'passed' ('현재 사용자 GUNT 자동 시작='+[bool]$c.enabled)
