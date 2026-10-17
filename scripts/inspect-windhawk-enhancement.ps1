. "$PSScriptRoot\enhancement-ui-common.ps1"
$checkpoint=Get-Content (Join-Path $Root 'state\pre-windhawk-enhancement-checkpoint.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($entry in $checkpoint.Hashes){$file=Join-Path $checkpoint.BackupPath $entry.Relative;if((Get-FileHash $file -Algorithm SHA256).Hash -ne $entry.SHA256){throw ('백업 해시 불일치: '+$entry.Relative)}}
$preserve=@('config\dock.json','config\dock-styles.json','config\topbar.json','config\monitor.json','config\wallpaper.json','config\startup.json','scripts\startup-restore.ps1','scripts\start-hidden.vbs','bin\GUNT-Bar.exe')
$manifest=@(foreach($rel in $preserve){$p=Join-Path $Root $rel;if(Test-Path $p){@{Path=$p;Relative=$rel;SHA256=(Get-FileHash $p).Hash}}})
$lively=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\WallpaperLayout.json'
if(Test-Path $lively){$manifest+=@{Path=$lively;Relative='Lively WallpaperLayout';SHA256=(Get-FileHash $lively).Hash}}
$state=@{Time=(Get-Date).ToString('o');Explorer=@(Get-Process explorer|Select-Object Id,StartTime);Windows=@(Get-EnhancementWindows|ForEach-Object {@{Name=$_.Current.Name;Pid=$_.Current.ProcessId;Handle=$_.Current.NativeWindowHandle}});Startup=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').GUNTDesktop;PreservedFiles=$manifest;BackupHashCount=$checkpoint.Hashes.Count;WindhawkVersion=(Get-Item (Join-Path $Root 'apps\Windhawk\windhawk.exe')).VersionInfo.FileVersion}
Write-Json $state (Join-Path $Root 'state\windhawk-enhancement-baseline.json')
$start=Open-EnhancementStart;Start-Sleep -Milliseconds 750;Save-EnhancementShot 'start-before';Write-Json @{Time=(Get-Date).ToString('o');OpenMs=$StartOpenMs;Root=$start.Current.Name;Bounds=$start.Current.BoundingRectangle.ToString();Elements=(Get-EnhancementTree $start)} (Join-Path $Root 'logs\enhancement-start-before.json');[GuntEnhanceUi]::Tap(0x1b)
[GuntEnhanceUi]::Chord(0x5b,0x4e);Start-Sleep -Milliseconds 900;Save-EnhancementShot 'notification-before'
$wins=Get-EnhancementWindows;$ids=@((Get-Process ShellExperienceHost,ShellHost -ErrorAction SilentlyContinue).Id)
Write-Json @($wins|Where-Object {$ids -contains $_.Current.ProcessId}|ForEach-Object {@{Name=$_.Current.Name;Bounds=$_.Current.BoundingRectangle.ToString();Elements=(Get-EnhancementTree $_)}}) (Join-Path $Root 'logs\enhancement-notification-before.json');[GuntEnhanceUi]::Tap(0x1b)
[GuntEnhanceUi]::Chord(0x5b,0x41);Start-Sleep -Milliseconds 800;Save-EnhancementShot 'quick-settings-before';[GuntEnhanceUi]::Tap(0x1b)
Write-Log 'enhancement-inspection' 'passed' ('백업 '+$checkpoint.Hashes.Count+'개 해시 재검사, 시작 메뉴·알림·빠른 설정 적용 전 캡처 완료.')
