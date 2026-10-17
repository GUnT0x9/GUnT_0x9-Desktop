param([switch]$RemoveNewPrograms)
. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\desktop-native.ps1"
$s=Get-State
if(!$s){throw 'No GUNT baseline exists; no changes were made.'}
if($s.RolledBack){Write-Log 'rollback' 'existing' 'Rollback already completed.';return}
$errors=New-Object Collections.Generic.List[string]
function Attempt([string]$Name,[scriptblock]$Action){try{& $Action;Write-Log $Name 'restored' 'Operation completed.'}catch{$errors.Add("$Name : $_");Write-Log $Name 'failed' $_.Exception.Message}}
$safety=Join-Path $Root ('backups\pre-rollback-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $safety|Out-Null
Attempt 'stop-bar' {Get-Process 'GUNT-Bar' -ErrorAction SilentlyContinue|ForEach-Object{[void]$_.CloseMainWindow()};Start-Sleep -Milliseconds 600}
$runtimePath=Join-Path $Root 'config\runtime.json'
$r=if(Test-Path $runtimePath){Get-Content $runtimePath -Raw -Encoding UTF8|ConvertFrom-Json}else{$null}
if($r){
    Attempt 'unload-rainmeter' {if(Test-Path $r.rainmeter){Start-Process $r.rainmeter -ArgumentList '!DeactivateConfig "GUNT-System-Monitor"' -Wait|Out-Null}}
    Attempt 'close-owned-rainmeter' {if($r.rainmeter.StartsWith($Root,[StringComparison]::OrdinalIgnoreCase)){Start-Process $r.rainmeter -ArgumentList '!Quit' -Wait|Out-Null;Start-Sleep -Milliseconds 500}}
    Attempt 'stop-flow' {Get-Process 'Flow.Launcher' -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $r.flow}|Stop-Process -Force}
}
# Only the portable engine created by this project can be stopped here.
Attempt 'stop-windhawk' {Get-Process windhawk -ErrorAction SilentlyContinue|Where-Object {$_.Path -and $_.Path.StartsWith((Join-Path $Root 'apps\Windhawk'),[StringComparison]::OrdinalIgnoreCase)}|ForEach-Object{Start-Process $_.Path -ArgumentList '-exit -wait -timeout 10000' -Wait|Out-Null}}
$touched=@($s.Files|Where-Object Touched)
[array]::Reverse($touched)
foreach($entry in $touched){
    $e=$entry
    Attempt ('file '+$e.Path) {
        if(Test-Path -LiteralPath $e.Path){$safe=Join-Path $safety ([guid]::NewGuid().ToString('N'));Move-Item -LiteralPath $e.Path -Destination $safe -Force}
        if($e.Exists){New-Item -ItemType Directory -Force (Split-Path $e.Path -Parent)|Out-Null;Copy-Item -LiteralPath $e.Backup -Destination $e.Path -Recurse -Force}
    }
}
foreach($entry in @($s.Registry|Where-Object Touched)){
    $e=$entry
    Attempt ('registry '+$e.Name) {
        if($e.Exists){if(!(Test-Path $e.Path)){New-Item -Path $e.Path|Out-Null};New-ItemProperty -Path $e.Path -Name $e.Name -Value $e.Value -PropertyType $e.Kind -Force|Out-Null}
        elseif(Test-Path $e.Path){Remove-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction Stop}
    }
}
Attempt 'wallpaper' {
    $wall=Get-Content (Join-Path $s.BackupPath 'wallpaper.json') -Raw -Encoding UTF8|ConvertFrom-Json
    $path=[string]$wall.Wallpaper
    if($path -and !(Test-Path -LiteralPath $path)){$copy=Get-ChildItem $s.BackupPath -Filter 'original-wallpaper*'|Select-Object -First 1;if($copy){$path=$copy.FullName}else{throw 'Original wallpaper is missing.'}}
    if(![GuntDesktopNative]::SystemParametersInfo(20,0,$path,3)){throw 'Windows rejected wallpaper restoration.'}
    $parts=$wall.Background -split ' ';$color=[int]$parts[0]+256*[int]$parts[1]+65536*[int]$parts[2]
    [GuntDesktopNative]::SetSysColors(1,@(1),@($color))|Out-Null
    $hide=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -ErrorAction SilentlyContinue).HideIcons
    [GuntDesktopNative]::Icons($hide -ne 1);[GuntDesktopNative]::Broadcast()
}
# Existing applications are retained. User explicitly opts in to moving new portable installs out of service.
if($RemoveNewPrograms){foreach($i in $s.Installed){$app=$i;Attempt ('remove-new '+$app.Name) {if($app.Portable -and $app.Path.StartsWith((Join-Path $Root 'apps'),[StringComparison]::OrdinalIgnoreCase)){Get-Process|Where-Object {$_.Path -and $_.Path.StartsWith($app.Path,[StringComparison]::OrdinalIgnoreCase)}|Stop-Process -Force;if(Test-Path $app.Path){Move-Item $app.Path (Join-Path $safety ('removed-'+($app.Name -replace ' ','-')))}}}}}
$s=Get-State
$s.RolledBack=($errors.Count -eq 0)
Save-State $s
Write-Json ([ordered]@{Time=(Get-Date).ToString('o');Success=$s.RolledBack;Errors=@($errors);SafetyBackup=$safety;ProgramsRetained=(!$RemoveNewPrograms)}) (Join-Path $Root 'logs\rollback-result.json')
if($errors.Count){throw "Rollback incomplete: $($errors -join '; ')"}
Write-Log 'rollback' 'passed' 'Recorded settings restored. Project sources, backups and logs retained.'
