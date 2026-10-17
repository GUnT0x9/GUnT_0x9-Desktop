. "$PSScriptRoot\common.ps1"
function Use-StaticFallback([string]$Reason) {
 & "$PSScriptRoot\apply-wallpaper.ps1"
 Write-Log 'live-wallpaper' 'static-fallback' $Reason
}
try {
 $config=Get-Content (Join-Path $Root 'config\wallpaper.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $engines=@("$env:LOCALAPPDATA\Programs\Lively Wallpaper\Lively.exe","$env:ProgramFiles\Lively Wallpaper\Lively.exe")
 $engine=$engines|Where-Object {Test-Path $_}|Select-Object -First 1
 if(!$config.liveEnabled -or !$engine){Use-StaticFallback '라이브 배경이 꺼져 있거나 Lively 엔진이 없어 검증한 정적 배경을 사용합니다.';return}
 # This marker records manual engine policy verification, never inferred support.
 $ready=Join-Path $Root 'state\lively-validated.json'
 if(!(Test-Path $ready)){Use-StaticFallback '엔진 가져오기·절전·전체 화면 중지 검증 기록이 없어 정적 배경을 유지합니다.';return}
 $validated=Get-Content $ready -Raw -Encoding UTF8|ConvertFrom-Json
 if(!$validated.pauseRulesVerified -or !$validated.primaryMonitorId){Use-StaticFallback '중지 규칙과 대상 모니터가 검증되지 않아 정적 배경을 유지합니다.';return}
 $project=Join-Path $Root 'wallpaper\gojo-live\lively'
 if(!(Test-Path (Join-Path $project 'LivelyInfo.json'))){Use-StaticFallback '라이브 배경 패키지가 없어 정적 배경을 유지합니다.';return}
 Start-Process $engine -ArgumentList ('setwp --file "'+$project+'" --monitor '+$validated.primaryMonitorId) -WorkingDirectory (Split-Path $engine -Parent)|Out-Null
 Write-Log 'live-wallpaper' 'requested' '검증 기록에 따라 Lively 복원을 요청했습니다. 실제 재생 여부를 자동 판정한 결과는 아닙니다.'
}catch{
 Use-StaticFallback ('라이브 배경 준비·실행 오류로 정적 배경을 사용합니다: '+$_.Exception.Message)
}
