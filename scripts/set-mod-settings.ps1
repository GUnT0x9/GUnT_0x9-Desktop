param([Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9-]+$')][string]$Id,[string]$SettingsPath)
. "$PSScriptRoot\common.ps1"
if(!$SettingsPath){$SettingsPath=Join-Path $Root ('windhawk\'+$Id+'.settings.json')}
$path=Join-Path $Root ('apps\Windhawk\AppData\Engine\Mods\'+$Id+'.ini')
if(!(Test-Path $path)){throw ('기존 모드 설정을 찾지 못했습니다: '+$Id)}
$settings=Get-Content $SettingsPath -Raw -Encoding UTF8|ConvertFrom-Json
$old=[IO.File]::ReadAllText($path,[Text.Encoding]::Unicode)
$parts=$old -split '\[Settings\]',2
if($parts.Count -ne 2){throw '모드 설정 형식을 확인할 수 없습니다.'}
$header=$parts[0] -replace '(?m)^SettingsChangeTime=.*$',('SettingsChangeTime='+[DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
$body=@($settings.PSObject.Properties|ForEach-Object {$_.Name+'='+[string]$_.Value}) -join "`r`n"
$backup=Join-Path $Root ('backups\mod-settings-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'\'+$Id+'.ini')
New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null;Copy-Item $path $backup
$temp=$path+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
[IO.File]::WriteAllText($temp,$header+"[Settings]`r`n"+$body+"`r`n",[Text.Encoding]::Unicode)
[IO.File]::Replace($temp,$path,$backup)
Write-Log 'mod-settings' 'applied' ($Id+' 설정을 백업 후 원자적으로 교체했습니다. 실제 UI 확인이 필요합니다.')
