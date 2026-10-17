param([Parameter(Mandatory=$true)][ValidateSet('monitor','topbar','windhawk','startup','fonts','control-center')][string]$Component,[string]$Checkpoint='pre-v24')
. "$PSScriptRoot\common.ps1"
if($Checkpoint -notmatch '^[a-zA-Z0-9-]+$'){throw '체크포인트 이름이 올바르지 않습니다.'}
$pointer=Join-Path $Root ('state\'+$Checkpoint+'-checkpoint.json')
$s=Get-Content $pointer -Raw -Encoding UTF8|ConvertFrom-Json
$backup=[IO.Path]::GetFullPath($s.BackupPath);$backupRoot=[IO.Path]::GetFullPath((Join-Path $Root 'backups'))+'\'
if(!$backup.StartsWith($backupRoot,[StringComparison]::OrdinalIgnoreCase)){throw '프로젝트 밖의 백업은 복원할 수 없습니다.'}
$before=Join-Path $Root ('backups\before-component-rollback-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
function Restore-File([string]$Relative){
 $from=Join-Path $backup ('files\'+$Relative);$to=Join-Path $Root $Relative
 if(!(Test-Path -LiteralPath $from -PathType Leaf)){return}
 $rel='files\'+$Relative;$record=@($s.Hashes|Where-Object {$_.Relative -eq $rel})|Select-Object -First 1
 if(!$record -or (Get-FileHash -LiteralPath $from).Hash -ne $record.SHA256){throw ('백업 해시 확인 실패: '+$Relative)}
 if(Test-Path $to){$save=Join-Path $before $Relative;New-Item -ItemType Directory -Force (Split-Path $save -Parent)|Out-Null;Copy-Item -LiteralPath $to -Destination $save -Force}
 New-Item -ItemType Directory -Force (Split-Path $to -Parent)|Out-Null;Copy-Item -LiteralPath $from -Destination $to -Force
}
function Restore-Tree([string]$Relative){$dir=Join-Path $backup ('files\'+$Relative);if(Test-Path $dir){foreach($f in Get-ChildItem $dir -File -Recurse){Restore-File ($Relative+'\'+$f.FullName.Substring($dir.Length+1))}}}
function Close-Owned([string]$Name){
 $processes=@(Get-Process $Name -ErrorAction SilentlyContinue|Where-Object {$_.Path -and $_.Path.StartsWith((Join-Path $Root 'bin\'),[StringComparison]::OrdinalIgnoreCase)})
 foreach($p in $processes){$null=$p.CloseMainWindow();if(!$p.WaitForExit(2000)){Stop-Process -Id $p.Id -Force;$null=$p.WaitForExit(3000)}}
}
switch($Component){
 'monitor' {Restore-File 'config\monitor.json';Restore-Tree 'rainmeter\GUNT-System-Monitor';Restore-File 'scripts\update-monitor.ps1';Restore-File 'scripts\toggle-monitor.ps1';& "$PSScriptRoot\update-monitor.ps1"}
 'windhawk' {
  $mods=Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods'
  foreach($id in 'taskbar-thumbnail-reorder','taskbar-notification-icon-spacing','taskbar-volume-control','alt-tab-per-monitor','windows-11-start-menu-styler','windows-11-file-explorer-styler','windows-11-settings-styler','explorer-details-better-file-sizes'){
   $path=Join-Path $mods ($id+'.ini');$baseline=Join-Path $backup ('files\apps\Windhawk\AppData\Engine\Mods\'+$id+'.ini')
   if((Test-Path $path) -and !(Test-Path $baseline)){& "$PSScriptRoot\set-v24-mod.ps1" -Id $id -Disable}
  }
  Restore-Tree 'apps\Windhawk\AppData\Engine\Mods';Restore-File 'config\dock.json';Restore-File 'config\dock-styles.json'
  & "$PSScriptRoot\export-windhawk-state.ps1"
 }
 'startup' {
  Restore-File 'config\startup.json';foreach($name in 'startup-restore.ps1','restore-wallpaper.ps1','start-hidden.vbs'){Restore-File ('scripts\'+$name)}
  $run='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
  if($s.Startup){Set-ItemProperty $run GUNTDesktop ([string]$s.Startup)}else{Remove-ItemProperty $run GUNTDesktop -ErrorAction SilentlyContinue}
 }
 'topbar' {
  Close-Owned 'GUNT.ControlCenter';Close-Owned 'GUNT-Bar'
  foreach($rel in 'config\topbar.json','src\GuntBar.cs','src\Sensors.cs','src\Configuration.cs','scripts\build.ps1','bin\GUNT-Bar.exe','bin\Gunt.Sensors.dll','bin\Gunt.Configuration.dll'){Restore-File $rel}
  Start-Process (Join-Path $Root 'bin\GUNT-Bar.exe') -ArgumentList ('"'+$Root+'"')
 }
 'control-center' {
  Close-Owned 'GUNT.ControlCenter'
  $baseline=Join-Path $backup 'files\bin\GUNT.ControlCenter.exe'
  if(Test-Path $baseline){Restore-File 'bin\GUNT.ControlCenter.exe';Restore-Tree 'control-center'}else{
   $exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';if(Test-Path $exe){New-Item -ItemType Directory -Force $before|Out-Null;Move-Item $exe (Join-Path $before 'GUNT.ControlCenter.exe')}
  }
 }
 'fonts' {
  Close-Owned 'GUNT.ControlCenter';Close-Owned 'GUNT-Bar'
  $theme=Get-Content (Join-Path $Root 'config\theme.json') -Raw -Encoding UTF8|ConvertFrom-Json
  foreach($key in 'ui','heading','secondary','metrics','latin'){$theme.fonts|Add-Member -NotePropertyName $key -NotePropertyValue 'Segoe UI Variable' -Force}
  Write-Json $theme (Join-Path $Root 'config\theme.json');& "$PSScriptRoot\update-monitor.ps1"
  Add-Type @'
using System;using System.Runtime.InteropServices;public static class FontRollback24{[DllImport("gdi32.dll",CharSet=CharSet.Unicode)]public static extern bool RemoveFontResourceEx(string p,uint f,IntPtr r);[DllImport("gdi32.dll",CharSet=CharSet.Unicode)]public static extern int AddFontResourceEx(string p,uint f,IntPtr r);[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,IntPtr l,uint f,uint t,out IntPtr r);public static void Notify(){IntPtr r;SendMessageTimeout(new IntPtr(0xffff),0x1D,IntPtr.Zero,IntPtr.Zero,2,1000,out r);}}
'@
  $journal=Get-Content (Join-Path $Root 'state\v24-fonts.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $fontRoot=[IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'))+'\'
  $key='HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts';$retained=@()
  foreach($entry in $journal.Entries){
   $path=[IO.Path]::GetFullPath($entry.Path)
   if(!$path.StartsWith($fontRoot,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($path) -notlike 'GUNT-*' -or $entry.Name -notlike 'GUNT *'){throw '프로젝트 글꼴 경로 확인 실패'}
   for($i=0;$i -lt 16;$i++){if(![FontRollback24]::RemoveFontResourceEx($path,0,[IntPtr]::Zero)){break}}
   if($entry.PreviousRegistered){Set-ItemProperty $key $entry.Name $entry.PreviousValue}else{Remove-ItemProperty $key $entry.Name -ErrorAction SilentlyContinue}
   if($entry.PreviousFile -and (Test-Path $entry.PreviousFile)){Copy-Item $entry.PreviousFile $path -Force;[FontRollback24]::AddFontResourceEx($path,0,[IntPtr]::Zero)|Out-Null}else{
    try{if(Test-Path $path){$to=Join-Path $before ('fonts\'+[IO.Path]::GetFileName($path));New-Item -ItemType Directory -Force (Split-Path $to -Parent)|Out-Null;Move-Item $path $to -Force}}catch{$retained+=$path}
   }
  }
  [FontRollback24]::Notify();Write-Json @{Time=(Get-Date).ToString('o');RegisteredEntriesRestored=$true;FilesStillInUse=$retained;Note='사용 중 파일은 강제 제거하지 않으며 다음 로그인 뒤 정리 가능'} (Join-Path $Root 'logs\v24-font-rollback.json')
  Start-Process (Join-Path $Root 'bin\GUNT-Bar.exe') -ArgumentList ('"'+$Root+'"')

 }
}
Write-Log 'component-rollback' 'completed' ($Component+' ← '+$backup+'; 복원 직전 백업: '+$before)
