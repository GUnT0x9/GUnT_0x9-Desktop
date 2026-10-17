. "$PSScriptRoot\common.ps1"
$identity=[Security.Principal.WindowsIdentity]::GetCurrent();$principal=New-Object Security.Principal.WindowsPrincipal($identity)
if(!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw '승인된 관리자 PowerShell에서 실행해야 합니다.'}
$interactiveUser=(Get-CimInstance Win32_ComputerSystem).UserName
if(!$interactiveUser -or ![string]::Equals($interactiveUser,$identity.Name,[StringComparison]::OrdinalIgnoreCase)){throw '관리자 승인 계정과 현재 데스크톱 사용자가 달라 작업 등록을 중단했습니다.'}
$exe=Join-Path $Root 'apps\HWiNFO\HWiNFO64.exe';$sig=Get-AuthenticodeSignature $exe
if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'REALiX'){throw 'HWiNFO 서명 검증 실패. 시작 작업을 등록하지 않았습니다.'}
$name='GUNT-HWiNFO-Sensors-v24';$backup=Join-Path $Root ('backups\hwinfo-startup-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'));New-Item -ItemType Directory -Force $backup|Out-Null
$old=Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
if($old){Export-ScheduledTask -TaskName $name|Set-Content (Join-Path $backup 'previous-task.xml') -Encoding Unicode}
$ini=Join-Path (Split-Path $exe -Parent) 'HWiNFO64.INI';$text=if(Test-Path $ini){[IO.File]::ReadAllText($ini)}else{"[Settings]`r`n"}
if(Test-Path $ini){Copy-Item $ini (Join-Path $backup 'HWiNFO64.INI')}
if($text -match '(?m)^SensorsOnly='){$text=$text -replace '(?m)^SensorsOnly=.*$','SensorsOnly=1'}else{$text=$text -replace '(?m)^\[Settings\]',('[Settings]'+"`r`nSensorsOnly=1")}
[IO.File]::WriteAllText($ini,$text,[Text.Encoding]::Default)
$action=New-ScheduledTaskAction -Execute $exe -WorkingDirectory (Split-Path $exe -Parent)
$trigger=New-ScheduledTaskTrigger -AtLogOn -User $identity.Name;$trigger.Delay='PT15S'
$settings=New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$taskPrincipal=New-ScheduledTaskPrincipal -UserId $identity.Name -LogonType Interactive -RunLevel Highest
$task=New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $taskPrincipal -Description 'GUNT Desktop 온도 센서: 서명 검증한 HWiNFO만 현재 사용자 로그인 후 실행. 암호 저장 없음.'
Register-ScheduledTask -TaskName $name -InputObject $task -Force|Out-Null
$actual=Get-ScheduledTask -TaskName $name
if($actual.Actions.Execute -ne $exe -or $actual.Principal.RunLevel -ne 'Highest'){throw '센서 시작 작업 등록 검증 실패'}
Write-Json @{Time=(Get-Date).ToString('o');TaskName=$name;Executable=$exe;User=$identity.Name;RunLevel=$actual.Principal.RunLevel.ToString();Backup=$backup;TaskRegistered=$true;ActualLogonTested=$false;Note='현재 HWiNFO는 재실행하지 않았습니다. 센서 상태 창을 닫지 않고 최소화하세요.'} (Join-Path $Root 'state\hwinfo-startup.json')
Write-Log 'hwinfo-startup' 'registered' '승인된 HWiNFO 전용 로그인 작업을 등록했습니다. 실제 재로그인은 미시험입니다.'
