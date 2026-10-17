param([Parameter(Mandatory=$true)][ValidateSet('taskbar-thumbnail-reorder','taskbar-notification-icon-spacing','taskbar-volume-control','alt-tab-per-monitor','windows-11-start-menu-styler','windows-11-file-explorer-styler','windows-11-settings-styler','explorer-details-better-file-sizes','fix-explorer-white-flash','taskbar-empty-space-clicks')][string]$Id,[switch]$Disable)
. "$PSScriptRoot\common.ps1"
$path=Join-Path $Root ('apps\Windhawk\AppData\Engine\Mods\'+$Id+'.ini')
$before=[IO.File]::ReadAllText($path);$text=$before -replace '(?m)^Disabled=\d+',('Disabled='+[int][bool]$Disable)
$text=$text -replace '(?m)^SettingsChangeTime=.*',('SettingsChangeTime='+[DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
$backup=Join-Path $Root ('backups\mod-toggle-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'\'+$Id+'.ini');New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null
$initial=Get-Process explorer -ErrorAction Stop|Select-Object -ExpandProperty Id
$temp=$path+'.tmp';[IO.File]::WriteAllText($temp,$text,[Text.Encoding]::Unicode);[IO.File]::Replace($temp,$path,$backup)
Start-Sleep -Milliseconds 2500
$now=@(Get-Process explorer -ErrorAction SilentlyContinue)
if(@($now|Where-Object {$initial -contains $_.Id -and $_.Responding}).Count -eq 0){Copy-Item $backup $path -Force;throw 'Explorer 상태가 달라져 직전 모드 설정을 복원했습니다.'}
$iniText=[IO.File]::ReadAllText($path)
$include=[regex]::Match($iniText,'(?m)^IncludeCustom=(.*)').Groups[1].Value.Trim()
$targetNames=@($include -split '\|'|Where-Object {$_ -match '\.exe$'}|ForEach-Object {[IO.Path]::GetFileNameWithoutExtension($_)})
$targetProcesses=@();if($targetNames.Count){$targetProcesses=@(Get-Process -Name $targetNames -ErrorAction SilentlyContinue)}
$modules=@();foreach($p in $targetProcesses){try{$modules+=@($p.Modules|Where-Object {$_.ModuleName -like ($Id+'_*')}|Select-Object -ExpandProperty ModuleName)}catch{}}
Write-Json @{Time=(Get-Date).ToString('o');Id=$Id;Enabled=(!$Disable);ExplorerPid=$initial;ExplorerResponding=$true;TargetProcesses=@($targetProcesses|Select-Object ProcessName,Id,Responding);LoadedModules=$modules;Backup=$backup;FunctionalVerification='각 UI와 입력 동작은 별도 검증 필요'} (Join-Path $Root ('logs\v24-mod-'+$Id+'.json'))
Write-Log 'mod-toggle' 'applied' ($Id+' 활성화='+(!$Disable)+'; 로드 확인='+$modules.Count)

& "$PSScriptRoot\export-windhawk-state.ps1"
