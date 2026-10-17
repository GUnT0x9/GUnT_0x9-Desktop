[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
param([ValidateSet('ControlCenter','TopBar','All')][string]$Component='ControlCenter')
. "$PSScriptRoot\common.ps1"
$pointer=Join-Path $Root 'state\pre-v25-ux-overhaul-checkpoint.json'
$appliedPath=Join-Path $Root 'state\v25-applied-files.json'
if(!(Test-Path $pointer) -or !(Test-Path $appliedPath)){throw '원본 체크포인트 또는 적용 파일 목록이 없습니다. 임의 복구하지 않았습니다.'}
$baseline=Get-Content $pointer -Raw -Encoding UTF8|ConvertFrom-Json
$applied=Get-Content $appliedPath -Raw -Encoding UTF8|ConvertFrom-Json
$backup=[IO.Path]::GetFullPath($baseline.BackupPath)
if(!$backup.StartsWith([IO.Path]::GetFullPath((Join-Path $Root 'backups'))+'\',[StringComparison]::OrdinalIgnoreCase)){throw '프로젝트 안의 체크포인트만 복원합니다.'}
$plan=@($applied.Files|Where-Object {$Component -eq 'All' -or $_.Component -eq $Component})
if(!$plan.Count){throw '복구할 파일 목록이 비어 있습니다.'}
foreach($entry in $plan){
 $rel=[string]$entry.Relative
 $to=[IO.Path]::GetFullPath((Join-Path $Root $rel))
 if(!$to.StartsWith([IO.Path]::GetFullPath($Root)+'\',[StringComparison]::OrdinalIgnoreCase)){throw '복구 파일 경로를 확인하세요.'}
 if(!(Test-Path -LiteralPath $to) -or (Get-FileHash -LiteralPath $to).Hash -ne $entry.SHA256){throw ('적용 뒤 수정되었거나 없는 파일입니다. 덮어쓰지 않았습니다: '+$rel)}
 $from=Join-Path $backup ('files\'+$rel)
 $record=@($baseline.Hashes|Where-Object {$_.Relative -eq ('files\'+$rel)})|Select-Object -First 1
 if($record -and (!(Test-Path -LiteralPath $from) -or (Get-FileHash -LiteralPath $from).Hash -ne $record.SHA256)){throw ('원본 백업 해시가 다릅니다: '+$rel)}
 if(!$record -and (Test-Path -LiteralPath $from)){throw ('원본 백업의 해시 기록이 없습니다: '+$rel)}
}
$plan|ForEach-Object {[pscustomobject]@{Component=$_.Component;File=$_.Relative;Action=$(if(Test-Path (Join-Path $backup ('files\'+$_.Relative))){'원본 복원'}else{'이번 추가 파일을 백업으로 이동'})}}|Format-Table -AutoSize
if($WhatIfPreference){$null=$PSCmdlet.ShouldProcess($Component,'선택 구성 요소 코드 복구');return}
# Do not close a window that may contain unsaved edits.
if(@(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue).Count){throw '제어 센터에서 변경을 저장하거나 버린 뒤 창을 닫고 다시 실행하세요. 강제 종료하지 않았습니다.'}
if(!$PSCmdlet.ShouldProcess($Component,'선택 구성 요소 코드 복구')){return}
$before=Join-Path $Root ('backups\before-v25-ux-rollback-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $before|Out-Null
# Preserve every current file before stopping any owned component.
foreach($entry in $plan){$save=Join-Path $before $entry.Relative;New-Item -ItemType Directory -Force (Split-Path $save -Parent)|Out-Null;Copy-Item -LiteralPath (Join-Path $Root $entry.Relative) $save}
$bars=@();if($Component -in 'TopBar','All'){$bars=@(Get-Process GUNT-Bar -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq (Join-Path $Root 'bin\GUNT-Bar.exe')});foreach($p in $bars){$null=$p.CloseMainWindow();if(!$p.WaitForExit(5000)){throw '상단 바가 정상 종료되지 않았습니다. 강제 종료하지 않았습니다.'}}}
$done=New-Object Collections.Generic.List[object]
try{
 foreach($entry in $plan){
  $to=Join-Path $Root $entry.Relative;$from=Join-Path $backup ('files\'+$entry.Relative)
  $done.Add($entry)
  if(Test-Path -LiteralPath $from){Copy-Item -LiteralPath $from $to -Force;if((Get-FileHash $to).Hash -ne (Get-FileHash $from).Hash){throw ('복구 확인 실패: '+$entry.Relative)}}
  else{Move-Item -LiteralPath $to -Destination (Join-Path $before ('added-'+[IO.Path]::GetFileName($to)))}
 }
 if($bars.Count){Start-Process (Join-Path $Root 'bin\GUNT-Bar.exe') -ArgumentList ('"'+$Root+'"')|Out-Null}
 Write-Log 'rollback-v25-ux' 'completed' ($Component+'; 설정·프로젝트·배경·Windhawk·Rainmeter 보존; 직전 코드 백업: '+$before)
 Write-Output '선택 코드와 실행 파일을 복구했습니다. 실행 후 기능·화면은 다시 확인하세요. 사용자 설정과 배경은 변경하지 않았습니다.'
}catch{
 $failure=$_;foreach($entry in $done){$save=Join-Path $before $entry.Relative;if(Test-Path $save){Copy-Item -LiteralPath $save (Join-Path $Root $entry.Relative) -Force}}
 Write-Log 'rollback-v25-ux' 'failed' ('복구 중 실패·직전 파일 재복원 요청. 실제 상태 확인 필요: '+$failure.Exception.Message)
 throw $failure
}
