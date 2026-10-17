param([switch]$Interactive)
. "$PSScriptRoot\common.ps1"
$results=New-Object 'Collections.Generic.List[object]'
function Record($name,$status,$detail){$results.Add([pscustomobject]@{Name=$name;Status=$status;Detail=$detail})}
$files=@(Get-ChildItem (Join-Path $Root 'scripts') -Filter '*.ps1');$parseErrors=@()
foreach($file in $files){$tokens=$null;$errors=$null;[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)|Out-Null;foreach($error in $errors){$parseErrors+=($file.Name+': '+$error.Message)}}
if($parseErrors.Count){throw ($parseErrors -join "`n")};Record 'PowerShell 구문' 'passed' ($files.Count.ToString()+'개 스크립트')
$seen=@{};foreach($file in @('GUNT-System-Monitor.ini','@Resources\Measures.inc','@Resources\Styles.inc','@Resources\Layout.inc')){
 $path=Join-Path $Root ('rainmeter\GUNT-System-Monitor\'+$file)
 foreach($m in [regex]::Matches([IO.File]::ReadAllText($path),'(?m)^\[([^\]]+)\]')){$name=$m.Groups[1].Value;if($seen.ContainsKey($name)){throw ('Rainmeter 대소문자 무시 섹션 중복: '+$name)};$seen[$name]=$file}
}
Record 'Rainmeter 섹션 정체성' 'passed' ($seen.Count.ToString()+'개 중복 없음')
$manifest=Get-Content (Join-Path $Root 'assets\fonts\manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($font in $manifest){if((Get-FileHash (Join-Path $Root ('assets\fonts\'+$font.file))).Hash -ne $font.sha256){throw ('글꼴 자산 해시 불일치: '+$font.file)}};Record '글꼴 자산 해시' 'passed' '공식 manifest SHA256 일치'
$bar=Get-Content (Join-Path $Root 'config\topbar.json') -Raw -Encoding UTF8|ConvertFrom-Json
if($bar.brandText -cne 'GUnT_0x9' -or $bar.showClock){throw '브랜드 또는 상단 중복 시계 설정 오류'};Record '브랜드·시계' 'passed' '원문 일치·상단 시계 꺼짐'
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
foreach($name in 'monitor','topbar','theme','startup','sensors'){[GuntConfiguration]::Validate($name,[GuntConfiguration]::Read($Root,$name))};Record '실제 JSON 설정 검증' 'passed' '범위·스키마 검사'
foreach($name in 'GUNT-Bar','Rainmeter'){if(@(Get-Process $name -ErrorAction SilentlyContinue).Count -ne 1){throw ('실행 프로세스 수 오류: '+$name)}};Record '핵심 프로세스' 'passed' '상단 바·Rainmeter 각 1개'
& "$PSScriptRoot\verify-v24-transactions.ps1";Record '설정 실패 복구' 'passed' '분리된 실제 트랜잭션 시험'
$sensors=Get-Content (Join-Path $Root 'state\sensors.json') -Raw -Encoding UTF8|ConvertFrom-Json
if($sensors.TemperatureQuality -eq 'valid'){& "$PSScriptRoot\verify-v24-sensor-failures.ps1";Record '센서 정체성·결측' 'passed' '실제 제공자 읽기·시계 의존성 주입'}else{Record '센서 정체성·결측' 'pending' '현재 실제 센서 내보내기 없음'}
if($Interactive){foreach($test in 'verify-v24-graphs.ps1','verify-v24-monitor.ps1','verify-v24-keyboard.ps1','verify-dock-v3.ps1'){& (Join-Path $PSScriptRoot $test);Record $test 'passed' '순차 실제 UI 검사'}}
Write-Json @{Time=(Get-Date).ToString('o');Results=$results;Interactive=[bool]$Interactive;Limitations='배터리 지속시간·실제 재로그인·전체 환경 롤백을 실행하지 않음'} (Join-Path $Root 'logs\v24-verification.json')
Write-Log 'verify-v24' 'passed' 'v2.4 통합 검증을 완료했습니다. 개별 미시험 조건은 보고서에 구분했습니다.'
