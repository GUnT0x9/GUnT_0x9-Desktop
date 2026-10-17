. "$PSScriptRoot\common.ps1"
if(Get-State){Write-Log 'backup' 'preserved' 'Existing immutable baseline retained.';return}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$dest=Join-Path $Root "backups\$stamp"
New-Item -ItemType Directory -Force $dest|Out-Null
$state=[pscustomobject]@{Version=1;Created=(Get-Date).ToString('o');BackupPath=$dest;Files=@();Registry=@();Installed=@();Components=@();Restore='Not attempted: standard user; elevation required';RolledBack=$false}
Save-State $state
$keys=@('HKCU\Control Panel\Desktop','HKCU\Control Panel\Colors','HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3','HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband','HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize','HKCU\Software\Microsoft\Windows\DWM','HKCU\Software\Microsoft\Windows\CurrentVersion\Run','HKLM\SOFTWARE\Windhawk','HKCU\SOFTWARE\Windhawk')
foreach($key in $keys) {
    if(Test-Path ($key -replace '^HKCU\\','HKCU:\' -replace '^HKLM\\','HKLM:\')) {
        $file=Join-Path $dest (($key -replace '[\\:]','_')+'.reg')
        & reg.exe export $key $file /y *> $null
        if($LASTEXITCODE -ne 0){throw "Registry backup failed: $key"}
    }
}
$targets=@("$env:APPDATA\Rainmeter",(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter'),"$env:APPDATA\FlowLauncher","$env:LOCALAPPDATA\FlowLauncher\Settings","$env:ProgramFiles\Windhawk\windhawk.ini","$env:ProgramFiles\Windhawk\Engine\Mods","$env:ProgramData\Windhawk",(Join-Path $Root 'config\apps.json'),(Join-Path $Root 'config\runtime.json'))
$targets+=@("$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json","$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json")
foreach($target in $targets){Backup-Target $target}
$wall=Get-ItemProperty 'HKCU:\Control Panel\Desktop'
Write-Json ([ordered]@{Wallpaper=$wall.Wallpaper;WallpaperStyle=$wall.WallpaperStyle;TileWallpaper=$wall.TileWallpaper;Background=(Get-ItemProperty 'HKCU:\Control Panel\Colors').Background}) (Join-Path $dest 'wallpaper.json')
if($wall.Wallpaper -and (Test-Path -LiteralPath $wall.Wallpaper)){Copy-Item -LiteralPath $wall.Wallpaper (Join-Path $dest ('original-wallpaper'+[IO.Path]::GetExtension($wall.Wallpaper)))}
Write-Log 'restore-point' 'unavailable' 'Session is not elevated; no UAC elevation or system protection changes were attempted. File and registry backups completed.'
Write-Log 'backup' 'passed' $dest
