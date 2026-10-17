[CmdletBinding(SupportsShouldProcess=$true)]param([ValidatePattern('^[a-z0-9-]+$')][string]$ModId)
. "$PSScriptRoot\common.ps1"
$pointer=Get-Content (Join-Path $Root 'state\pre-windhawk-enhancement-checkpoint.json') -Raw -Encoding UTF8|ConvertFrom-Json
$backup=[IO.Path]::GetFullPath($pointer.BackupPath)
if(!$backup.StartsWith([IO.Path]::GetFullPath((Join-Path $Root 'backups'))+'\',[StringComparison]::OrdinalIgnoreCase)){throw '프로젝트 밖의 백업은 복원하지 않습니다.'}
$dir=Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods'
$files=@(Get-ChildItem $dir -Filter '*.ini'|Where-Object {!$ModId -or $_.BaseName -eq $ModId})
if(!$files.Count){throw '복구할 모드 설정을 찾지 못했습니다.'}
$actions=@();$revision=Join-Path $Root ('backups\before-windhawk-enhancement-rollback-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
# Validate every baseline file before changing any setting.
foreach($file in $files){
 $rel='apps\Windhawk\AppData\Engine\Mods\'+$file.Name;$from=Join-Path $backup ('files\'+$rel)
 if(Test-Path $from){$record=@($pointer.Hashes|Where-Object {$_.Relative -eq ('files\'+$rel)})|Select-Object -First 1;if(!$record -or (Get-FileHash $from).Hash -ne $record.SHA256){throw ('백업 해시 불일치: '+$file.Name)}}
 $actions+=@{Id=$file.BaseName;Path=$file.FullName;Baseline=$from;HasBaseline=(Test-Path $from)}
 $settingsRel='windhawk\'+$file.BaseName+'.settings.json';$settingsFrom=Join-Path $backup ('files\'+$settingsRel)
 if(Test-Path $settingsFrom){$record=@($pointer.Hashes|Where-Object {$_.Relative -eq ('files\'+$settingsRel)})|Select-Object -First 1;if(!$record -or (Get-FileHash $settingsFrom).Hash -ne $record.SHA256){throw ('백업 해시 불일치: '+$settingsRel)}}
}
if(!$ModId -or $ModId -eq 'windows-11-taskbar-styler'){
 $scriptRelative='scripts\install-dock.ps1';$scriptBaseline=Join-Path $backup ('files\'+$scriptRelative)
 $scriptRecord=@($pointer.Hashes|Where-Object {$_.Relative -eq ('files\'+$scriptRelative)})|Select-Object -First 1
 if(!$scriptRecord -or !(Test-Path $scriptBaseline) -or (Get-FileHash $scriptBaseline).Hash -ne $scriptRecord.SHA256){throw 'Dock 배포 스크립트 백업 해시가 맞지 않습니다.'}
}
if($WhatIfPreference){$actions|ForEach-Object {Write-Output ($_.Id+$(if($_.HasBaseline){' : 직전 INI 복원'}else{' : 새 모드 비활성화'}))};Write-Log 'windhawk-enhancement-rollback' 'dry-run' '모든 복구 대상의 백업 해시를 검사했습니다. 설정은 변경하지 않았습니다.';return}
foreach($action in $actions){
 if(!$PSCmdlet.ShouldProcess($action.Id,'Windhawk 확장 전 구성 복원')){continue}
 New-Item -ItemType Directory -Force $revision|Out-Null
 $old=[IO.File]::ReadAllText($action.Path)
 $text=if($action.HasBaseline){[IO.File]::ReadAllText($action.Baseline)}else{$old -replace '(?m)^Disabled=\d+','Disabled=1'}
 $text=$text -replace '(?m)^SettingsChangeTime=.*$',('SettingsChangeTime='+[DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
 $temp=$action.Path+'.'+[guid]::NewGuid().ToString('N')+'.tmp';[IO.File]::WriteAllText($temp,$text,[Text.Encoding]::Unicode);[IO.File]::Replace($temp,$action.Path,(Join-Path $revision ($action.Id+'.ini')))
 if([IO.File]::ReadAllText($action.Path) -ne $text){throw ('복원된 INI 확인 실패: '+$action.Id)}
 $rel='windhawk\'+$action.Id+'.settings.json';$from=Join-Path $backup ('files\'+$rel);$to=Join-Path $Root $rel
 if(Test-Path $from){if(Test-Path $to){Copy-Item $to (Join-Path $revision ($action.Id+'.settings.json'))};Copy-Item $from $to -Force}
}
if(!$ModId -or $ModId -eq 'windows-11-taskbar-styler'){
 $relative='scripts\install-dock.ps1';$from=Join-Path $backup ('files\'+$relative);$to=Join-Path $Root $relative
 $record=@($pointer.Hashes|Where-Object {$_.Relative -eq ('files\'+$relative)})|Select-Object -First 1
 if(!$record -or (Get-FileHash $from).Hash -ne $record.SHA256){throw 'Dock 배포 스크립트 백업 해시가 맞지 않습니다.'}
 Copy-Item $to (Join-Path $revision 'install-dock.ps1');Copy-Item $from $to -Force
}
& "$PSScriptRoot\export-windhawk-state.ps1"
Write-Json @{Time=(Get-Date).ToString('o');Baseline=$backup;PreviousSettings=$revision;Actions=$actions;ExplorerRestarted=$false;VisualVerification='복구 후 실제 UI는 별도 확인'} (Join-Path $Root 'logs\windhawk-enhancement-rollback.json')
Write-Log 'windhawk-enhancement-rollback' 'completed' 'Windhawk 구성만 복원했습니다. Rainmeter·배경·개발 앱·시작 등록은 변경하지 않았습니다.'
