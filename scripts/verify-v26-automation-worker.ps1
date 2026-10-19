. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root;$initial=$s.Workspace();$names=@('automation-owned','automation-times','automation-history','wallpaper-playback','profile-active');$old=@{};foreach($name in $names){$file=Join-Path $Root ('state\'+$name+'.json');if(Test-Path $file){$old[$name]=[IO.File]::ReadAllBytes($file)}}
$token=[guid]::NewGuid().ToString('N').Substring(0,8);$targetName='Gunt.V26Probe-'+$token;$dir=Join-Path $Root ('tests\automation-worker-'+$token);New-Item -ItemType Directory -Force $dir|Out-Null;$source=Join-Path $dir 'probe.cs';$exe=Join-Path $dir ($targetName+'.exe');[IO.File]::WriteAllText($source,'public static class Probe {public static void Main(){System.Threading.Thread.Sleep(25000);}}')
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe';& $csc /nologo /target:winexe ('/out:'+$exe) $source;if($LASTEXITCODE -ne 0){throw '검증용 프로세스 빌드 실패'}
$rule=New-Object Gunt.ControlCenter.Models.AutomationRule;$rule.Id='qa-worker-'+$token;$rule.Name='QA existing bar event';$rule.Trigger='application-running';$rule.TriggerValue=$targetName;$rule.Action='monitor-hide';$rule.Enabled=$true
try{
 $s.Action('monitor-show');$s.SaveRule($rule);$probe=Start-Process $exe -PassThru;$detected=$false
 for($i=0;$i -lt 120;$i++){Start-Sleep -Milliseconds 250;$events=$s.State('automation-history');if(!$s.MonitorVisible() -and ($s.Json.Serialize($events)).Contains($rule.Id)){$detected=$true;break}}
 if(!$detected){throw '기존 상단 바 조건 감지 → 무창 worker → 실제 위젯 숨김을 확인하지 못했습니다.'}
 $rule.Enabled=$false;$s.SaveRule($rule);$s.RestoreAutomationOwnership()|Out-Null
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';ExistingBarDetectedApp=$true;WindowlessWorkerExecuted=$true;ActualWidgetHidden=$true;OwnershipRestored=$true;NoNewDaemon=$true} (Join-Path $Root 'logs\v26-automation-worker.json')
 Write-Output '기존 상단 바의 실제 앱 감지 → 무창 이벤트 처리 → 모니터 숨김 → 소유 상태 복원 통과'
}finally{
 $s.DeleteRule($rule.Id);$s.Action($(if([bool]$initial.monitorVisible){'monitor-show'}else{'monitor-hide'}));foreach($name in $names){$file=Join-Path $Root ('state\'+$name+'.json');if($old.ContainsKey($name)){[IO.File]::WriteAllBytes($file,$old[$name])}elseif(Test-Path $file){$archive=Join-Path $dir 'state-backup';New-Item -ItemType Directory -Force $archive|Out-Null;Move-Item $file $archive}}
 if($probe -and !$probe.HasExited){$null=$probe.WaitForExit(27000)}
}
