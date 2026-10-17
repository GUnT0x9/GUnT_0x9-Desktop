param([Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9-]+$')][string]$Name)
. "$PSScriptRoot\common.ps1"
$dest=Join-Path $Root ('backups\'+$Name+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $dest|Out-Null
$paths=@('assets','apps\HWiNFO','state\v24-fonts.json','state\hwinfo-startup.json','state\storage-topology.json','config','scripts','src','wallpaper','rainmeter','windhawk','control-center','docs','README.md','CHANGELOG.md','bin','apps\Rainmeter\Rainmeter.ini','apps\Rainmeter\Skins\GUNT-System-Monitor','apps\Rainmeter\Layouts','apps\Windhawk\AppData\Engine\Mods','apps\Windhawk\AppData\ModsSource','apps\Windhawk\AppData\settings.ini','apps\Windhawk\AppData\userprofile.json','state\bar-build.sha256')
$items=@()
foreach($rel in $paths){
 $path=Join-Path $Root $rel;$backup=Join-Path $dest ('files\'+$rel);$exists=Test-Path -LiteralPath $path
 if($exists){New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null;Copy-Item -LiteralPath $path -Destination $backup -Recurse -Force}
 $items+=@{Relative=$rel;Path=$path;Backup=$backup;Exists=$exists}
}
$lively=Join-Path $env:LOCALAPPDATA 'Lively Wallpaper'
foreach($file in 'Settings.json','WallpaperLayout.json','AppRules.json'){
 $path=Join-Path $lively $file;if(Test-Path $path){New-Item -ItemType Directory -Force (Join-Path $dest 'lively')|Out-Null;Copy-Item $path (Join-Path $dest ('lively\'+$file))}
}
$layoutPath=Join-Path $lively 'WallpaperLayout.json'
if(Test-Path $layoutPath){
 $liveLayout=Get-Content $layoutPath -Raw -Encoding UTF8|ConvertFrom-Json
 $n=0;foreach($assignment in $liveLayout){$path=$assignment.LivelyInfoPath;if($path -and (Test-Path -LiteralPath $path)){Copy-Item -LiteralPath $path -Destination (Join-Path $dest ('lively-project-'+$n)) -Recurse -Force;$n++}}
}
$wall=Get-ItemProperty 'HKCU:\Control Panel\Desktop'
$run=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').GUNTDesktop
$exports=@()
foreach($entry in @(@('HKCU\Control Panel\Desktop','desktop'),@('HKCU\Software\Microsoft\Windows\CurrentVersion\Run','startup'),@('HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','explorer'),@('HKCU\Software\Microsoft\Windows\CurrentVersion\Search','search'))){
 $file=Join-Path $dest ($entry[1]+'.reg');& reg.exe export $entry[0] $file /y|Out-Null
 if($LASTEXITCODE -ne 0){throw ('레지스트리 백업 실패: '+$entry[0])};$exports+=@{Key=$entry[0];File=$file}
}
if(Test-Path 'HKCU:\SOFTWARE\HWiNFO64'){
 $file=Join-Path $dest 'hwinfo64.reg';& reg.exe export 'HKCU\SOFTWARE\HWiNFO64' $file /y|Out-Null
 if($LASTEXITCODE -ne 0){throw 'HWiNFO 센서 설정 백업 실패'};$exports+=@{Key='HKCU\SOFTWARE\HWiNFO64';File=$file}
}
$hashes=@(Get-ChildItem $dest -File -Recurse|ForEach-Object {@{Relative=$_.FullName.Substring($dest.Length+1);SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash;Length=$_.Length}})
foreach($file in $items|Where-Object Exists){if(!(Test-Path -LiteralPath $file.Backup)){throw ('백업 대상 누락: '+$file.Relative)}}
$result=[ordered]@{Name=$Name;Time=(Get-Date).ToString('o');BackupPath=$dest;Files=$items;Hashes=$hashes;RegistryExports=$exports;Startup=$run;Wallpaper=@{Path=$wall.Wallpaper;Style=$wall.WallpaperStyle;Tile=$wall.TileWallpaper};Verified=$true;RestorePoint='권한 상승 없이 파일·설정·레지스트리 체크포인트를 생성했습니다.'}
Write-Json $result (Join-Path $dest 'snapshot.json')
Write-Json $result (Join-Path $Root ('state\'+$Name+'-checkpoint.json'))
Write-Log 'checkpoint' 'passed' ($Name+': '+$hashes.Count+'개 파일 SHA256 기록; '+$dest)
