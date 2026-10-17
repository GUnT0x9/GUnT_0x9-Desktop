. "$PSScriptRoot\common.ps1"
if(!(Test-Path (Join-Path $Root 'state\v21-backup.json'))){throw 'v2.1 업그레이드 전 백업이 필요합니다.'}
& "$PSScriptRoot\update-monitor.ps1"
& "$PSScriptRoot\apply-wallpaper.ps1"
& "$PSScriptRoot\build.ps1"
& "$PSScriptRoot\install-dock.ps1"
$apps=Get-AppPaths
$apps|Add-Member -NotePropertyName powershell -NotePropertyValue "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Force
foreach($entry in @(@('git',"$env:ProgramFiles\Git\git-bash.exe"),@('docker',"$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"))){if(Test-Path $entry[1]){$apps|Add-Member -NotePropertyName $entry[0] -NotePropertyValue $entry[1] -Force}}
Write-Json $apps (Join-Path $Root 'config\apps.json')
$startup=Get-Content (Join-Path $Root 'config\startup.json') -Raw -Encoding UTF8|ConvertFrom-Json
if($startup.enabled){
 $vbs=Join-Path $Root 'scripts\start-hidden.vbs'
 $cmd='powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+(Join-Path $Root 'scripts\startup-restore.ps1')+'"'
 [IO.File]::WriteAllText($vbs,'CreateObject("WScript.Shell").Run "'+$cmd.Replace('"','""')+'", 0, False',[Text.Encoding]::Unicode)
 Set-GuntValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'GUNTDesktop' ('wscript.exe "'+$vbs+'"') 'String'
}else{Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name GUNTDesktop -ErrorAction SilentlyContinue}
& "$PSScriptRoot\startup-restore.ps1" -Force
Write-Log 'apply-v21' 'passed' 'GUNT Desktop v2.1 설정 적용을 완료했습니다. 실제 화면과 검증 결과를 확인하세요.'
