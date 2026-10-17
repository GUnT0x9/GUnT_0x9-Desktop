# 백업과 복구

v2.1 직전 GUNT 백업: `backups/v21-20261015-133116`.
최초 Windows 환경 백업: `backups/20261015-110531`.
백업 파일과 레지스트리 내보내기 경로는 `state/v21-backup.json`에 있습니다. 실제 복원은 실행하지 않았고 파일 존재·스크립트 구문을 검사했습니다.

## 업그레이드 직전 GUNT로 복구

`Rollback-GUNT.cmd`를 실행하거나 Windows PowerShell에서 다음을 실행하세요. 현재 상단 바·위젯·Flow·포터블 Windhawk가 잠시 종료되고 이전 구성이 시작됩니다. 열린 업무 앱이나 WSL 배포판은 제거하지 않습니다.

```powershell
& "$env:USERPROFILE\GUNT-Desktop\scripts\rollback.ps1"
```

현재 파일은 `backups/pre-v21-rollback-*`에 보존한 후 스냅샷의 구성·소스·위젯·모드와 GUNT 자동 실행 값, 이전 배경·표시 모드를 복원합니다. 관련 없는 자동 실행 항목을 덮어쓰지 않습니다. 생성된 프로그램과 새 배경 자산은 제거하지 않습니다. 결과는 `logs/v21-rollback-result.json`입니다.

## 최초 Windows 환경으로 복구

GUNT 커스터마이징 이전 Windows 상태까지 되돌리려면 별도 옵션을 직접 선택하세요.

```powershell
& "$env:USERPROFILE\GUNT-Desktop\scripts\rollback.ps1" -OriginalWindows
```

최초 파일·레지스트리 변경 기록을 사용하는 `rollback-original.ps1`이 실행됩니다. 이후 새 포터블 프로그램은 남아 있지만 자동 시작과 적용 설정은 복원 대상입니다.

## 현재 설정 추가 백업

```powershell
& "$env:USERPROFILE\GUNT-Desktop\scripts\backup-current.ps1"
```

이 명령은 현재 프로젝트 설정·소스 중심의 추가 백업입니다. v2.1 전 전체 스냅샷과 최초 Windows 백업을 대체하지 않습니다. Windows 시스템 복원 지점은 관리자 권한이 없어 생성하지 않았습니다.

자동 복원만 끄려면 config/startup.json에서 enabled=false로 바꾸고 Apply-GUNT.cmd를 실행하세요. 배경만 정적으로 유지하려면 config/wallpaper.json의 liveEnabled=false를 유지하세요.
