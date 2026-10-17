. "$PSScriptRoot\common.ps1"
$baseline=Get-Content (Join-Path $Root 'state\windhawk-enhancement-baseline.json') -Raw -Encoding UTF8|ConvertFrom-Json
$start=Get-Date;$before=@(Get-Process explorer -ErrorAction Stop|Select-Object -ExpandProperty Id)
$pointer=Get-Content (Join-Path $Root 'state\pre-windhawk-enhancement-checkpoint.json') -Raw -Encoding UTF8|ConvertFrom-Json
$hashErrors=@(foreach($file in $pointer.Hashes){$path=Join-Path $pointer.BackupPath $file.Relative;if(!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path).Hash -ne $file.SHA256){$file.Relative}})
if($hashErrors.Count){throw '시작 전 백업의 해시 검증에 실패했습니다.'}
$preserved=@(foreach($file in $baseline.PreservedFiles){$current=if(Test-Path -LiteralPath $file.Path){(Get-FileHash -LiteralPath $file.Path).Hash}else{$null};@{Relative=$file.Relative;Unchanged=($current -eq $file.SHA256);CurrentHash=$current}})
$mods=@(foreach($file in Get-ChildItem (Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods') -Filter '*.ini'){$text=[IO.File]::ReadAllText($file.FullName);@{Id=$file.BaseName;Enabled=($text -notmatch '(?m)^Disabled=1\s*$');Version=([regex]::Match($text,'(?m)^Version=(.+)$').Groups[1].Value.Trim())}})
$ini=[IO.File]::ReadAllText((Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods\windows-11-taskbar-styler.ini'))
$adaptiveAbsent=$ini -notmatch 'guntAppWidth|ActualWidth=>gunt'
$modules=@(foreach($p in Get-Process explorer){try{$p.Modules|Where-Object {$_.FileName -match 'Engine\\Mods'}|Select-Object -ExpandProperty ModuleName}catch{}})
$counts=@{};foreach($name in 'GUNT-Bar','Rainmeter','windhawk'){$counts[$name]=@(Get-Process $name -ErrorAction SilentlyContinue).Count}
# Observe an interval without interacting with the shell.
$remaining=30-((Get-Date)-$start).TotalSeconds;if($remaining -gt 0){Start-Sleep -Milliseconds ([int]($remaining*1000))}
$after=@(Get-Process explorer -ErrorAction Stop|Select-Object -ExpandProperty Id)
$events=@();foreach($id in 1000,1001,1002,1026){try{$events+=@(Get-WinEvent -FilterHashtable @{LogName='Application';Id=$id;StartTime=$start} -ErrorAction Stop|Where-Object {$_.Message -match 'explorer.exe|Windhawk|ShellExperienceHost|StartMenuExperienceHost'}|Select-Object TimeCreated,Id,Message)}catch{if($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*'){throw}}}
$startup=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').GUNTDesktop
$result=@{Time=(Get-Date).ToString('o');BackupHashesVerified=$pointer.Hashes.Count;PreservedFiles=$preserved;StartupUnchanged=($startup -eq $baseline.Startup);Mods=$mods;LoadedExplorerModules=$modules;ProcessCounts=$counts;AdaptiveRuleRemoved=$adaptiveAbsent;ExplorerBefore=$before;ExplorerAfter=$after;StableObservationSeconds=[int]((Get-Date)-$start).TotalSeconds;StableDuringObservation=(($before -join ',') -eq ($after -join ','));OriginalExplorer=$baseline.Explorer;UnexpectedRestartOccurred=$true;RestartCause='미확정';RecentCrashEvents=$events;Limitations='재시작 원인 미확정·장시간 검증 미실시'}
# Korean text is used in the generated report.
$result.RestartCause='미확정: 사용자는 수동 재시작을 하지 않았다고 확인함'
$result.Limitations='작업 중 Explorer 교체 1회 발생. 최신 자동 폭 규칙을 되돌림. 장시간·재로그인 검증 미실시.'
Write-Json $result (Join-Path $Root 'logs\windhawk-enhancement-health.json')
if(!$adaptiveAbsent -or !$result.StableDuringObservation -or $events.Count){throw '최종 관찰에서 추가 불안정 신호가 발견됐습니다.'}
Write-Log 'windhawk-enhancement-health' 'partial' '백업·현재 셸 관찰 완료. 작업 중 발생한 Explorer 교체 원인은 미확정입니다.'
$result|ConvertTo-Json -Depth 7
