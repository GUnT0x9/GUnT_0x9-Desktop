# 시스템 모니터 깜빡임 수정 및 Windhawk 추가 적용

2026-10-16. 기존 Windows 11 25H2 빌드 26200.9711 / Rainmeter 4.5.28.3936 / Windhawk 1.7.3 환경을 유지했다.

## 모니터 모드 전환

원인은 Rainmeter 버튼이 PowerShell을 직접 실행하는 구조였다. `-WindowStyle Hidden`만으로는 콘솔이 처음 생성되는 순간까지 숨기지 못할 수 있다. [Rainmeter 공식 RunCommand](https://docs.rainmeter.net/manual/plugins/runcommand/)의 `State=Hide`를 사용해 처음부터 숨겨 실행하도록 변경했다. 추가 상주 프로세스나 별도 실행 프로그램은 만들지 않았다.

`Layout.inc`의 `Mode`는 `!CommandMeasure ToggleMode Run`을 호출한다. `ToggleMode`는 `powershell.exe -NoProfile -NonInteractive ... -File "#ToggleScript#" -DeferRefresh`를 실행한다. 기존 백업·뮤텍스·설정 저장·실패 복구를 유지한다. RunCommand는 숨겨 실행 중인 프로세스를 스킨 새로고침 때 종료할 수 있으므로, 스크립트 자체에서 먼저 새로고침하지 않고 완료 후 `FinishAction=[!Refresh]`로 갱신한다. `OnRefreshAction`이 새 좌표·크기를 적용한다. 직접 실행 경로의 기존 동작은 기본값으로 유지한다.

숨긴 그래프 등의 Y 좌표가 Rainmeter 창 크기에 남아 간단한 모드에 투명 영역을 만드는 문제도 수정했다. 내보내기 시 현재 숨긴 미터만 Y=0으로 옮긴다. 원본 디자인과 활성 미터 좌표는 그대로 유지한다. 현재 사용자가 저장한 주 화면의 위치와 배율 175%를 보존했다.

`verify-monitor-hidden.ps1`은 버튼 왼쪽 여백·오른쪽 여백·글자를 실제 마우스 입력으로 6회 전환하고 설정·위젯 실제 높이·완료 로그를 대조했다. 전환 6회 모두 통과, 간단한 모드 높이 501px / 자세한 모드 1575px, 저장 위치 일치. 전용 메시지 루프의 WinEvent SHOW/FOREGROUND 감시로 창 이벤트 16건을 수신했고 그중 보이는 콘솔 창 이벤트는 0건이었다. 모든 사용자 PC 상황에서의 절대 보장을 의미하지 않으며 해당 실제 시험의 결과다.

초기 시험은 숨겨진 미터의 창 크기 영향과 자동 입력 후 커서를 너무 빨리 복구하는 시험 도구 문제를 발견했다. 두 문제를 고친 후 동일한 글자·여백 검사가 통과했다. 과거 실패 기록은 삭제하지 않았다.

## Windhawk 적용 현황

작업 전 실제 활성은 9개였다. 이번에 2개를 추가하여 설치 12개 / 활성 11개 / 충돌로 비활성 1개다. 단순 조사 목록을 적용된 모드 수로 계산하지 않았다. `windhawk/mods.json`에 오래된 초기 조사 상태가 남아 있어 실제 INI를 읽는 파생 스냅샷으로 갱신했다. 실행 설정의 원본은 Windhawk의 실제 INI이며, Control Center도 이를 직접 읽는다.

| 이번 추가 모드 | 버전·대상 | 실제 적용과 검증 |
|---|---|---|
| [Windows 11 Settings Styler](https://windhawk.net/mods/windows-11-settings-styler) | 1.1 / SystemSettings.exe | 배경 #0E0E12, 행·검색창 #15151C, 검색창 반경 6, 테두리 #23232B, 강조 #A78BFA. 실제 DLL 로드·설정 앱 응답·디스플레이 화면 캡처 비교 |
| [Better file sizes in Explorer details](https://windhawk.net/mods/explorer-details-better-file-sizes) | 1.6 / explorer.exe만 | 실제 크기 셀에서 1MiB 시험 파일 → 1.00MiB, 20MiB → 20.0MiB 확인. 폴더 재귀 계산 disabled, 기존 폴더/파일 정렬 그룹 보존 |

공식 저장소 커밋 `e3976aca5c5f511878e4beefdc2e9ef65cd5565b`에서 받은 변경하지 않은 소스·URL·SHA256을 기록했다. 개별 컴파일 → 비활성 등록 → 한 개씩 활성화했다. 설정 앱 Styler는 Dock과 다른 프로세스 대상이라 Explorer XAML 소비자 충돌을 추가하지 않는다. 이 시험은 해당 빌드에서의 검증이며 향후 Windows 업데이트 호환 보장이 아니다. 글꼴과 시스템 아이콘 glyph는 건드리지 않았다.

기존 활성 9개는 Taskbar Styler 1.10, Taskbar height and icon size 1.3.10, Clock Customization 1.8.1, Notification Center Styler 1.7, Thumbnail Reorder 1.1.5, tray spacing 1.4, Volume Control 1.3.1, Alt+Tab per monitor 1.2, Start Menu Styler 1.7이다.

File Explorer Styler 1.7은 앞선 실제 Taskbar Styler 0x8000FFFF 충돌 때문에 비활성 상태를 유지한다. 이를 ‘설치 안 함’이나 ‘정상 적용’으로 표시하지 않는다. Dock Animation Plus와 Labels는 Dock 잘림·폭 충돌 위험 때문에 켜지 않았다. Shell Flyout Positions 등은 현재 문제 재현 없이 임의 설치하지 않았다.

## 실제 화면

- 설정 앱 [적용 전](../screenshots/v24-settings-before.png) / [적용 후](../screenshots/v24-settings-after.png)
- 탐색기 [적용 전](../screenshots/v24-file-sizes-before.png) / [적용 후](../screenshots/v24-file-sizes-after.png)
- 현재 [시스템 모니터](../screenshots/v24-system-monitor-thermal.png)

실제 설정 앱 캡처에서 #0E0E12 픽셀은 53,666→2,385,385, #15151C는 1→1,130,817, #A78BFA는 0→67,402개였다. 한글·아이콘·배치가 유지된 것을 화면으로 확인했다. 캡처에 사용자 계정 정보가 포함될 수 있으므로 공유 전 확인한다.

## 검증 및 제한

- 통과: 모드 버튼 6회, 보이는 콘솔 이벤트 0건, 저장 위치 유지, 두 모드의 실제 기능/화면, 통합 스크립트 구문·설정·복구 시험.
- 통과: Dock 중앙 기준 왼쪽 확장, 높이 60DIP, 앱 15개 겹침 없음, 한국어 초 단위 시계, Chrome 창 전환.
- 통과: 작업 전 Explorer PID 유지 및 응답, 추가 작업 이후 관련 새 충돌 이벤트와 Styler 재시작 안내 없음.
- 미시험: 재로그인, 실제 배터리 지속시간, 추가 모드만의 활성/비활성 비교 성능. Explorer·Windows 재시작은 실행하지 않았다.

추가 후 30초 실제 작업 표본(논리 프로세서 8개 기준): 상단 바 CPU 0.232% / 작업집합 59.4MiB, Rainmeter 0.084% / 44.6MiB, HWiNFO 0.457% / 29.7MiB. Explorer CPU 1.643%는 사용자 앱·셸 전체가 섞인 값이므로 모드 두 개의 부하로 계산하지 않는다. 추가 전후의 동일 조건 비교나 전력 절감 증명은 아니다. `logs/v24-performance-post-flicker-mods.json`에 다른 프로세스와 private memory도 기록했다.

실제 로그: `logs/monitor-hidden-verification.json`, `logs/settings-mod-verification.json`, `logs/v24-file-sizes-after.json`, `logs/v24-flicker-mods-health.json`, `logs/v24-verification.json`, `logs/v23-dock-verification.json`.

## 변경 파일

- `rainmeter/GUNT-System-Monitor/@Resources/Layout.inc`
- `scripts/toggle-monitor.ps1`, `scripts/update-monitor.ps1`, `scripts/verify-monitor-hidden.ps1`
- `scripts/install-optional-mod.ps1`, `scripts/set-v24-mod.ps1`, `scripts/export-windhawk-state.ps1`, `scripts/verify-filesizes-v24.ps1`, `scripts/rollback-v24.ps1`
- `windhawk/windows-11-settings-styler.*`, `windhawk/explorer-details-better-file-sizes.*`, `windhawk/mods.json`
- 실제 배포된 Rainmeter 스킨 및 Windhawk 모드 INI/DLL, 관련 문서·캡처·진단 로그

## 원상복구

적용 전 체크포인트 `backups/pre-v24-flicker-mods-20261016-144831`의 351개 파일 해시를 기록했다. 개별 수정 전 파일은 `backups/source-revisions`와 `backups/mod-toggle-*`에도 보존했다.

새 모드만 해제:

```powershell
.\scripts\set-v24-mod.ps1 -Id windows-11-settings-styler -Disable
.\scripts\set-v24-mod.ps1 -Id explorer-details-better-file-sizes -Disable
```

이번 변경 직전 모니터 또는 Windhawk 구성만 복구:

```powershell
.\scripts\rollback-v24.ps1 -Component monitor -Checkpoint pre-v24-flicker-mods
.\scripts\rollback-v24.ps1 -Component windhawk -Checkpoint pre-v24-flicker-mods
```

모니터 복구는 깜빡임 수정 전 구현으로 돌아간다. 복구를 자동 실행하지 않았다. HWiNFO 관리자 시작 작업 등록은 별도 미승인 상태로 유지하며 이번 작업에서 실행하지 않았다.
