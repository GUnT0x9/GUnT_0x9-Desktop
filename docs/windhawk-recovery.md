# Windhawk 확장만 복구하기

이번 백업: `backups/pre-windhawk-enhancement-20261016-152624`, 포인터 `state/pre-windhawk-enhancement-checkpoint.json`. 371개 파일 SHA256 및 GUI profile extra 보관. 복구 전 현재 설정도 별도 버전 디렉터리에 보존한다. 사용자 파일·Rainmeter·Lively·개발 도구·시작 등록을 되돌리지 않는다.

## 먼저 확인

Windows PowerShell에서:

```powershell
Set-Location -LiteralPath "$env:USERPROFILE\GUNT-Desktop"
powershell.exe -NoProfile -File .\scripts\rollback-windhawk-enhancement.ps1 -WhatIf
```

해당 명령은 대상 백업의 해시를 읽고 복구 목록만 표시한다. 해시가 다르면 중단하며 다른 파일로 대체하지 않는다.

## 최신 모드만 해제

Explorer가 다시 저절로 교체되거나 입력 문제가 생기면 최근 모드 하나씩 해제하고 재발 여부를 비교한다.

```powershell
powershell.exe -NoProfile -File .\scripts\set-v24-mod.ps1 -Id taskbar-empty-space-clicks -Disable
# 첫 모드 해제 후에도 재발하는 경우에만 다음 모드를 해제한다.
powershell.exe -NoProfile -File .\scripts\set-v24-mod.ps1 -Id fix-explorer-white-flash -Disable
```

제어 센터의 Windhawk 열기로 공식 UI에서도 같은 모드를 비활성화할 수 있다. 현재 File Explorer Styler는 충돌 이력 때문에 비활성 상태로 유지한다. 문제를 해결하려고 무작정 Explorer 재시작 버튼을 누르지 않는다.

## 특정 모드 설정만 이전 상태로

```powershell
powershell.exe -NoProfile -File .\scripts\rollback-windhawk-enhancement.ps1 -ModId windows-11-start-menu-styler
```

기존 모드는 백업 INI·프로젝트 settings JSON을 복원하고, 백업에 없던 신규 모드는 Disabled=1로 만든다. 실제 DLL 언로드와 화면 반영은 별도로 확인해야 한다. 재시작이 필요한 경우 명령은 자동 재시작하지 않으며 사용자의 별도 승인 후 수행한다.

## 확장 전체 구성 복원

```powershell
powershell.exe -NoProfile -File .\scripts\rollback-windhawk-enhancement.ps1
```

제어 센터 Windhawk 페이지의 **이전 Windhawk 구성 복구**도 같은 작업이다. 확인창에서 아니요를 누르면 실행하지 않는다. 전체 복구는 이번 작업 중 실제로 수행하지 않았고, `-WhatIf`·해시·확인창 취소만 검증했다.

전체 복구는 원래 Dock 배포 스크립트도 복원한다. 이번 자동 폭 표현식은 이미 철회되어 현재 원본 방식이다. 프로필·상단 바·위젯 위치 등 unrelated 설정을 덮어쓰지 않는다. 새 DLL은 삭제하지 않는다.

## 복구 후 확인

- `scripts/export-windhawk-state.ps1` 결과와 공식 Windhawk 목록의 실제 활성 상태 확인.
- `scripts/verify-dock-v3.ps1`로 Dock 간격·현재 앱·시계 확인. 앱 수가 크게 바뀌면 기존 레이아웃 새로고침으로 폭 계산.
- 시작 메뉴/검색/탐색기/알림·달력 열기. 새 오류가 있으면 마지막 변경만 복원.
- `logs/windhawk-enhancement-rollback.json`, `logs/changes.jsonl` 및 `backups/before-windhawk-enhancement-rollback-*` 보관.

Explorer 교체 원인은 현재 미확정이다. 오류 이벤트가 없다고 충돌이 없었다고 해석하지 않는다. 관리자 권한·로그아웃·재부팅·Explorer 재시작은 이 스크립트의 자동 작업에 포함되지 않는다.
