. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\desktop-native.ps1"
$settings=Get-Content (Join-Path $Root 'wallpaper\wallpaper-settings.json') -Raw -Encoding UTF8|ConvertFrom-Json
$configPath=Join-Path $Root 'config\wallpaper.json'
$config=if(Test-Path $configPath){Get-Content $configPath -Raw -Encoding UTF8|ConvertFrom-Json}else{[pscustomobject]@{brightness=80;mode='Fill';liveEnabled=$false}}
$filename=if($config.brightness -eq 100){'gojo-original.jpg'}else{'gojo-'+$config.brightness+'.png'}
$path=Join-Path $Root ('wallpaper\'+$filename)
if(!(Test-Path $path)){throw '선택한 밝기의 배경화면 파일이 없습니다.'}
$variant=$settings.variants|Where-Object filename -eq $filename
if(!$variant -or (Get-FileHash $path).Hash -ne $variant.sha256){throw '배경화면 무결성 확인에 실패했습니다.'}
$style=if($config.mode -eq 'Fit'){'6'}else{'10'}
Set-GuntValue 'HKCU:\Control Panel\Desktop' 'WallpaperStyle' $style 'String'
Set-GuntValue 'HKCU:\Control Panel\Desktop' 'TileWallpaper' '0' 'String'
Set-GuntValue 'HKCU:\Control Panel\Desktop' 'Wallpaper' $path 'String'
if(![GuntDesktopNative]::SystemParametersInfo(20,0,$path,3)){throw 'Windows가 배경화면 적용을 거부했습니다.'}
$settings.selectedBrightness=$config.brightness
$settings.displayMode=$config.mode
$settings.selectedFile=$filename
$settings|Add-Member -NotePropertyName appliedPath -NotePropertyValue $path -Force
$settings|Add-Member -NotePropertyName appliedAt -NotePropertyValue (Get-Date).ToString('o') -Force
Write-Json $settings (Join-Path $Root 'wallpaper\wallpaper-settings.json')
Write-Log 'wallpaper-v21' 'applied' ('지정 원본의 밝기 '+$config.brightness+'%, 표시 모드 '+$config.mode+' 적용: '+$path)
