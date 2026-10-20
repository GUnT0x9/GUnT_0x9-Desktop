param([string]$Label='dev6')
# Exercise the real top-bar registration host, then restore the exact original private config.
. "$PSScriptRoot\enhancement-ui-common.ps1"
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';$null=[Reflection.Assembly]::LoadFrom($exe)
$service=New-Object Gunt.ControlCenter.Services.DesktopService($Root)
$path=Join-Path $Root 'config\launchpad.json';$original=if(Test-Path $path){[IO.File]::ReadAllBytes($path)}else{$null};$backup=Join-Path $Root ('tests\launchpad-hotkey-original-'+[guid]::NewGuid().ToString('N')+'.json');if($original){[IO.File]::WriteAllBytes($backup,$original)}
$ownedHash=$null;$checks=@();$failure=$null;$reserved=$false
function Wait-State([string]$Shortcut,[bool]$Available){for($i=0;$i -lt 80;$i++){Start-Sleep -Milliseconds 50;$state=Get-Content -Raw -LiteralPath (Join-Path $Root 'state\launchpad-hotkey.json') -Encoding UTF8|ConvertFrom-Json;if($state.Shortcut -eq $Shortcut -and $state.Available -eq $Available){return $state}};throw '상단 바 단축키 재등록 결과 시간 초과'}
function Save-Test($Config){$service.SaveLaunchpad($Config);$script:ownedHash=(Get-FileHash $path).Hash}
try{
 if(Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUNT Launchpad'}){throw '검사 전에 Launchpad를 정상 종료하세요.'}
 $config=$service.Launchpad();$config.HotkeyEnabled=$false;Save-Test $config;$null=Wait-State $config.Shortcut $false;$checks+='실제 상단 바에서 사용 안 함 반영'
 $testKey=$null;foreach($candidate in @('Ctrl+Alt+F11','Ctrl+Alt+F10','Ctrl+Alt+F9')){if([GuntLaunchpadHotkey]::Probe($candidate)){$testKey=$candidate;break}};if(!$testKey){throw '충돌 검증용 빈 단축키가 없습니다.'}
 [uint32]$modifiers=0;[uint32]$code=0;$null=[GuntLaunchpadHotkey]::TryParse($testKey,[ref]$modifiers,[ref]$code);$reserved=[GuntLaunchpadHotkey]::RegisterHotKey([IntPtr]::Zero,197,$modifiers,$code);if(!$reserved){throw '검증 키 예약 실패'}
 $config=$service.Launchpad();$config.HotkeyEnabled=$true;$config.Shortcut=$testKey;Save-Test $config;$state=Wait-State $testKey $false;if($state.Status -notlike '*등록 불가*'){throw '충돌 설명 누락'};$checks+='다른 창이 예약한 키를 빼앗지 않고 충돌 설명 표시'
 [GuntLaunchpadHotkey]::UnregisterHotKey([IntPtr]::Zero,197)|Out-Null;$reserved=$false
 $config=$service.Launchpad();$config.HotkeyEnabled=$false;Save-Test $config;$null=Wait-State $testKey $false
 $config=$service.Launchpad();$config.HotkeyEnabled=$true;Save-Test $config;$null=Wait-State $testKey $true;$checks+='키 변경과 다시 사용의 실제 등록 반영'
}catch{$failure=$_.Exception.Message;throw}finally{
 if($reserved){[GuntLaunchpadHotkey]::UnregisterHotKey([IntPtr]::Zero,197)|Out-Null}
 if($ownedHash){if((Get-FileHash $path).Hash -ne $ownedHash){$failure='다른 화면이 변경한 설정은 덮어쓰지 않았습니다. 로컬 원본 백업을 확인하세요.'}elseif($null -ne $original){[GuntConfiguration]::Atomic($Root,$path,[Text.Encoding]::UTF8.GetString($original),$false);if((Get-FileHash $path).Hash -ne [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($original)).Replace('-','')){$failure='설정 원본 바이트 복원 확인 실패'}}else{Remove-Item -LiteralPath $path}}
 Start-Sleep -Milliseconds 2300
 Write-Json @{Label=$Label;Failure=$failure;Checks=$checks;Passed=$checks.Count;OriginalConfigExisted=($null -ne $original);Note='실제 상단 바에서 잠시 검증한 뒤 원본 복원. 다른 화면의 동시 변경은 덮어쓰지 않음.'} (Join-Path $Root ('logs\launchpad-'+$Label+'-hotkey-reload.json'))
}
if($failure){throw $failure};Write-Output ($checks.Count.ToString()+' registration reload checks passed; original config restored')
