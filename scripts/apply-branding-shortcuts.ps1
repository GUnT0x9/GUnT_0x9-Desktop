. "$PSScriptRoot\common.ps1"
$wsh=New-Object -ComObject WScript.Shell
$target=Join-Path $Root 'bin\GUNT.ControlCenter.exe';$icon=Join-Path $Root 'assets\branding\icons\gunt-app.ico'
$start=Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\GUNT Desktop'
$matches=@();foreach($dir in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('StartMenu'))){foreach($file in Get-ChildItem -LiteralPath $dir -Filter '*.lnk' -Recurse -ErrorAction SilentlyContinue){$link=$wsh.CreateShortcut($file.FullName);if($link.TargetPath -eq $target){$matches+=@{Path=$file.FullName;Link=$link;Created=$false}}}}
if(!$matches.Count){New-Item -ItemType Directory -Force $start|Out-Null;$path=Join-Path $start 'GUnT_0x9 Desktop.lnk';if(Test-Path -LiteralPath $path){throw '같은 이름의 다른 바로가기가 있어 덮어쓰지 않았습니다.'};$link=$wsh.CreateShortcut($path);$link.TargetPath=$target;$link.Arguments='"'+$Root+'" overview';$link.WorkingDirectory=$Root;$matches+=@{Path=$path;Link=$link;Created=$true}}
$changes=@();$backup=Join-Path $Root ('backups\branding-shortcuts-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
foreach($item in $matches){
 $link=$item.Link;$before=@{Target=$link.TargetPath;Arguments=$link.Arguments;Icon=$link.IconLocation;WorkingDirectory=$link.WorkingDirectory;Description=$link.Description}
 if(!$item.Created){New-Item -ItemType Directory -Force $backup|Out-Null;Copy-Item -LiteralPath $item.Path -Destination (Join-Path $backup ([IO.Path]::GetFileName($item.Path)))}
 $link.IconLocation=$icon+',0';$link.Description='GUnT_0x9 Desktop 제어 센터';$link.Save()
 $read=$wsh.CreateShortcut($item.Path)
 if($read.TargetPath -ne $before.Target -or $read.Arguments -ne $before.Arguments -or $read.IconLocation -ne ($icon+',0')){throw '바로가기 대상·인수 또는 아이콘 검증 실패'}
 $changes+=@{Path=$item.Path;Created=$item.Created;Before=$before;AppliedSHA256=(Get-FileHash -LiteralPath $item.Path).Hash;Target=$read.TargetPath;Arguments=$read.Arguments;Icon=$read.IconLocation}
}
Write-Json @{Time=(Get-Date).ToString('o');Changes=$changes;DesktopShortcutCreated=$false;ThirdPartyShortcutsModified=$false} (Join-Path $Root 'state\branding-shortcuts.json')
Write-Log 'branding-shortcuts' 'passed' ($changes.Count.ToString()+'개 제어 센터 바로가기 검증. 타사 앱 대상과 고정 앱은 유지했습니다.')
