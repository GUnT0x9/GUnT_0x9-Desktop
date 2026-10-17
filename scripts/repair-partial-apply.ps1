# One-time recovery for the initial key recreation bug; retained as an audit trail.
. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\desktop-native.ps1"
$marker=Join-Path $Root 'state\partial-apply-repaired'
if(Test-Path $marker){Write-Log 'partial-apply-recovery' 'existing' 'Recovery was already completed.';return}
$s=Get-State
if(!$s){throw 'Original backup is required.'}
$keys=@('HKCU_Control Panel_Colors.reg','HKCU_Control Panel_Desktop.reg','HKCU_Software_Microsoft_Windows_CurrentVersion_Themes_Personalize.reg')
foreach($name in $keys){$file=Join-Path $s.BackupPath $name;if(!(Test-Path $file)){throw "Missing original registry export $name"}}
foreach($name in $keys){
    # reg.exe writes even its success message to stderr. Windows PowerShell 5.1
    # treats redirected native stderr as an error under ErrorActionPreference=Stop.
    $out=Join-Path $Root 'logs\registry-recovery.stdout.log'
    $err=Join-Path $Root 'logs\registry-recovery.stderr.log'
    $args='import "'+(Join-Path $s.BackupPath $name)+'"'
    $process=Start-Process "$env:WINDIR\System32\reg.exe" -ArgumentList $args -NoNewWindow -Wait -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    if($process.ExitCode -ne 0){throw "Registry recovery failed for $name : $(Get-Content $err -Raw)"}
    Write-Log 'registry-import' 'restored' $name
}
if(@((Get-Item 'HKCU:\Control Panel\Desktop').GetValueNames()).Count -lt 45){throw 'Desktop registry values did not recover.'}
if(@((Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize').GetValueNames()).Count -lt 4){throw 'Personalization registry values did not recover.'}
# Recapture the original values after restoring the complete exported keys.
foreach($entry in $s.Registry){
    $key=Get-Item $entry.Path -ErrorAction SilentlyContinue
    $entry.Exists=[bool]($key -and ($key.GetValueNames() -contains $entry.Name))
    if($entry.Exists){$entry.Kind=$key.GetValueKind($entry.Name).ToString();$entry.Value=$key.GetValue($entry.Name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}else{$entry.Value=$null}
    $entry.Touched=$false
}
Save-State $s
$wall=Get-Content (Join-Path $s.BackupPath 'wallpaper.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(![GuntDesktopNative]::SystemParametersInfo(20,0,[string]$wall.Wallpaper,3)){throw 'Restored wallpaper could not be activated.'}
$parts=$wall.Background -split ' ';$color=[int]$parts[0]+256*[int]$parts[1]+65536*[int]$parts[2]
[GuntDesktopNative]::SetSysColors(1,@(1),@($color))|Out-Null
[GuntDesktopNative]::Broadcast()
foreach($p in 'HKCU:\Control Panel\Colors','HKCU:\Control Panel\Desktop','HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'){
    $names=(Get-Item $p).GetValueNames()
    Write-Log 'registry-recovery-verification' 'restored' "$p : $($names.Count) original/Windows-updated values present"
}
[IO.File]::WriteAllText($marker,(Get-Date).ToString('o'),$Utf8)
Write-Log 'partial-apply-recovery' 'passed' 'Complete original registry exports restored; baseline value journal corrected. Existing-key recreation removed from apply and rollback.'
