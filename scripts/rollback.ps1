param([switch]$OriginalWindows)
. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\desktop-native.ps1"
if($OriginalWindows){& "$PSScriptRoot\rollback-original.ps1";return}
$pointer=Join-Path $Root 'state\v21-backup.json'
if(!(Test-Path $pointer)){throw '업그레이드 전 GUNT 백업을 찾을 수 없습니다.'}
$snapshot=Get-Content $pointer -Raw -Encoding UTF8|ConvertFrom-Json
$safety=Join-Path $Root ('backups\pre-v21-rollback-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $safety|Out-Null
foreach($file in $snapshot.Files|Where-Object Exists){if(!(Test-Path -LiteralPath $file.Backup)){throw ('원본 백업 누락: '+$file.Relative)}}
$runtime=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($p in Get-Process 'GUNT-Bar','Flow.Launcher' -ErrorAction SilentlyContinue|Where-Object {$_.Path -and $_.Path.StartsWith($Root,[StringComparison]::OrdinalIgnoreCase)}){Stop-Process -Id $p.Id -Force}
if(Get-Process Rainmeter -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $runtime.rainmeter}){Start-Process $runtime.rainmeter -ArgumentList '!Quit' -Wait|Out-Null}
if(Get-Process windhawk -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $runtime.windhawk}){Start-Process $runtime.windhawk -ArgumentList '-exit -wait -timeout 10000' -Wait|Out-Null}
Start-Sleep -Seconds 1
foreach($file in $snapshot.Files){
 $target=Join-Path $Root $file.Relative
 if(Test-Path -LiteralPath $target){$safe=Join-Path $safety $file.Relative;New-Item -ItemType Directory -Force (Split-Path $safe -Parent)|Out-Null;Move-Item -LiteralPath $target -Destination $safe -Force}
 if($file.Exists){New-Item -ItemType Directory -Force (Split-Path $target -Parent)|Out-Null;Copy-Item -LiteralPath $file.Backup -Destination $target -Recurse -Force}
}
$wall=$snapshot.Wallpaper
$desktop='HKCU:\Control Panel\Desktop'
foreach($value in @(@('Wallpaper',[string]$wall.Path),@('WallpaperStyle',[string]$wall.Style),@('TileWallpaper',[string]$wall.Tile))){New-ItemProperty $desktop -Name $value[0] -Value $value[1] -PropertyType String -Force|Out-Null}
$parts=$wall.Background -split ' ';$color=[int]$parts[0]+256*[int]$parts[1]+65536*[int]$parts[2]
[GuntDesktopNative]::SetSysColors(1,@(1),@($color))|Out-Null
if(![GuntDesktopNative]::SystemParametersInfo(20,0,[string]$wall.Path,3)){throw '이전 배경화면 적용에 실패했습니다.'}
# Restore this project's one startup value only; preserve unrelated new entries.
$runExport=$snapshot.RegistryExports|Where-Object Key -eq 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run'
$runText=Get-Content $runExport.File -Raw -Encoding Unicode
$line=@($runText -split "`r?`n"|Where-Object {$_ -like '"GUNTDesktop"=*'})|Select-Object -First 1
if($line){$value=($line.Substring($line.IndexOf('=')+1)).Trim('"').Replace('\\','\').Replace('\"','"');New-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name GUNTDesktop -Value $value -PropertyType String -Force|Out-Null}else{Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name GUNTDesktop -ErrorAction SilentlyContinue}
Write-Json @{Time=(Get-Date).ToString('o');Success=$true;SafetyBackup=$safety;Restored=$snapshot.BackupPath;ProgramsUninstalled=$false} (Join-Path $Root 'logs\v21-rollback-result.json')
& (Join-Path $Root 'scripts\start.ps1')
Write-Output '업그레이드 전 GUNT Desktop으로 복원했습니다. 새 자산과 백업은 보존했습니다.'
