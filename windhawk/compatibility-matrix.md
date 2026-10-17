# Windhawk 확장 호환성표

2026-10-16, Windows 11 Home 25H2 26200.9711, Windhawk 1.7.3 portable. 실제 엔진 INI 기준 설치 14개·활성 13개. 지원 판정은 이 PC에서 수행한 시험 범위이며 Windows 빌드 전체에 대한 인증이 아니다.

**안정성 유의:** 작업 도중 Explorer 셸 PID 28960→28864 교체가 16:00:46에 발생했다. 사용자는 직접 재시작하지 않았다고 확인했다. 관련 Application 오류 이벤트는 발견하지 못했으나 원인은 미확정이다. 최근 Dock ActualWidth 자동 폭 규칙은 철회하고 기존 계산 방식으로 복원했다. 장시간 안정성은 검증되지 않았다.

| 이름·공식 링크·ID | 설치 버전 | 상태 | 실제 대상 | 호환성·시험 범위 | 설정·위험 |
|---|---|---|---|---|---|
| [alt-tab-per-monitor](https://windhawk.net/mods/alt-tab-per-monitor) `alt-tab-per-monitor` | 1.2 | 활성 | explorer.exe | 세 화면 실제 전환 시험 결과 참조 | 기존 커서 화면 표시·전체 창 목록 유지. 화면별 결과는 logs/enhancement-alt-tab.json 참조. |
| [explorer-details-better-file-sizes](https://windhawk.net/mods/explorer-details-better-file-sizes) `explorer-details-better-file-sizes` | 1.6 | 활성 | explorer.exe | 현재 PC 실제 IEC 값 검증 | explorer.exe로 대상 제한. 재귀 폴더 크기 계산 꺼짐. 실제 1.00MiB/20.0MiB 값 검증. |
| [fix-explorer-white-flash](https://windhawk.net/mods/fix-explorer-white-flash) `fix-explorer-white-flash` | 1.4 | 활성 | explorer.exe | 현재 PC 기본 파일 작업 검증 | explorer.exe의 GDI 중간 프레임 처리. 복사·붙여넣기·이름 변경·탭·검색·500개 파일 확인. 번쩍임 감소량 정량 측정은 미실시. 작업 중 Explorer 교체 1회가 있어 원인 및 장시간 안정성은 미확정. |
| [taskbar-clock-customization](https://windhawk.net/mods/taskbar-clock-customization) `taskbar-clock-customization` | 1.8.1 | 활성 | explorer.exe | 현재 PC 실제 시계 검증 | 한국어 날짜·초 표시. 배터리·재로그인은 별도 시험 대상. |
| [taskbar-empty-space-clicks](https://windhawk.net/mods/taskbar-empty-space-clicks) `taskbar-empty-space-clicks` | 2.6 | 활성 | explorer.exe | 현재 PC 실제 단축 동작 검증 | 왼쪽 Ctrl+주 Dock 빈 영역 두 번 클릭 → 작업 관리자. 앱 버튼과 일반 클릭에 동작을 배정하지 않음. 작업 중 Explorer 교체 1회가 있어 원인 및 장시간 안정성은 미확정. |
| [taskbar-icon-size](https://windhawk.net/mods/taskbar-icon-size) `taskbar-icon-size` | 1.3.10 | 활성 | explorer.exe | 26200.9711에서 실제 Dock 검증 | 38DIP 아이콘과 60DIP 높이 유지. 글꼴·창 그룹화 변경 없음. |
| [taskbar-notification-icon-spacing](https://windhawk.net/mods/taskbar-notification-icon-spacing) `taskbar-notification-icon-spacing` | 1.4 | 활성 | explorer.exe | 현재 PC 실제 트레이 검증 | 한 줄 트레이 28, 숨김 아이콘 32/5열. 네이티브 네트워크·오디오·배터리·입력기 유지. |
| [taskbar-thumbnail-reorder](https://windhawk.net/mods/taskbar-thumbnail-reorder) `taskbar-thumbnail-reorder` | 1.1.5 | 활성 | explorer.exe | DLL 로드 확인·드래그 순서 별도 확인 | 기존 설정 유지. 여러 창 썸네일의 실제 재정렬은 별도 수동 확인 필요. |
| [taskbar-volume-control](https://windhawk.net/mods/taskbar-volume-control) `taskbar-volume-control` | 1.3.1 | 활성 | explorer.exe|ShellExperienceHost.exe|SndVol.exe | 현재 PC 실제 CoreAudio 검증 | 트레이 위 휠 2단계, 전체 화면에서는 휠 동작 꺼짐. 시험 후 원래 볼륨 복원. |
| [windows-11-file-explorer-styler](https://windhawk.net/mods/windows-11-file-explorer-styler) `windows-11-file-explorer-styler` | 1.7 | 비활성 | explorer.exe | 충돌로 비활성 | 앞선 Taskbar Styler 0x8000FFFF 충돌. 기존 Dock을 우선해 재활성화하지 않음. |
| [windows-11-notification-center-styler](https://windhawk.net/mods/windows-11-notification-center-styler) `windows-11-notification-center-styler` | 1.7 | 활성 | ShellExperienceHost.exe|ShellHost.exe | 현재 PC 실제 알림·달력 검증 | 표면 #0E0E12·테두리 #23232B·6DIP 모서리. 달력 다음 달/원래 달 복원, 빠른 설정 실제 열기 확인. |
| [windows-11-settings-styler](https://windhawk.net/mods/windows-11-settings-styler) `windows-11-settings-styler` | 1.1 | 활성 | SystemSettings.exe | 현재 PC 실제 설정 화면 검증 | 설정 앱만 대상으로 어두운 표면·검색창·강조색 적용. 실제 Windows 설정 값은 변경하지 않음. |
| [windows-11-start-menu-styler](https://windhawk.net/mods/windows-11-start-menu-styler) `windows-11-start-menu-styler` | 1.7 | 활성 | StartMenuExperienceHost.exe|SearchHost.exe|SearchApp.exe | 현재 PC 검색·앱 실행 검증 | 새 시작 레이아웃과 16개 고정 앱 유지. 검색창·전원 메뉴 스타일, 검색에서 실제 메모장 실행. 전원 동작 자체는 실행하지 않음. |
| [windows-11-taskbar-styler](https://windhawk.net/mods/windows-11-taskbar-styler) `windows-11-taskbar-styler` | 1.10 | 활성 | explorer.exe | 현재 Dock 검증 통과·작업 중 셸 재시작 원인 미확정 | 60DIP 높이와 중앙 기준 왼쪽 확장 유지. Explorer 교체 1회 뒤 최근 자동 폭 규칙을 되돌림. 현재 16개 앱·트레이 간격 검증. 장시간 안정성 미확정. |

## 후보 판단

이전 22개 후보의 고정 커밋 버전·변경일은 [v2.4 조사표](../docs/v24-windhawk-matrix.md)를 참조한다. 이번 적용 결과는 본 문서를 우선한다.

| 후보 | 확인 버전 | 분류 | 적용 여부·이유 |
|---|---|---|---|
| [Taskbar Dock Animation Plus](https://windhawk.net/mods/taskbar-dock-animation-plus) | 2.0.1 | 실험 | 미설치. 기존 Dock transform·clip·hit testing과 중첩. 셸 안정성 우선 |
| [Shell Flyout Positions](https://windhawk.net/mods/shell-flyout-positions) | 1.3 | 선택 | 미설치. 실제 달력·빠른 설정 위치에 Dock 겹침이 없어 추가 hook 불필요 |
| [Taskbar Labels for Windows 11](https://windhawk.net/mods/taskbar-labels) | 1.5.1 | 제외 | 미설치. 현재 아이콘 Dock 폭·창 그룹화 유지 |
| [Taskbar auto-hide when maximized](https://windhawk.net/mods/taskbar-auto-hide-when-maximized) | 1.2.6 | 선택 | 미설치. 현재 항상 보이는 Dock 동작 보존 |
| [Start Menu Size](https://windhawk.net/mods/start-menu-size) | 1.1 | 제외 | 미설치. 새 시작 메뉴의 기본 구조·스타일 규칙 중복 방지 |
| [Customize Windows notifications placement](https://windhawk.net/mods/notifications-placement) | 1.2.4 | 선택 | 미설치. 알림 겹침 미재현 |
| [Dark mode context menus](https://windhawk.net/mods/dark-menus) | 1.4.2 | 실험 | 미설치. 기본 대상 전체 프로세스이므로 자동 적용 제외 |
| [Explorer visual tweaks for dark mode](https://windhawk.net/mods/explorer-visual-tweaks-dark) | 1.0.1 | 실험 | 미설치. 재시작 요구·범위 확대를 피함 |
| Windows 11 File Explorer Styler | 1.7 | 보류 | 설치되어 있으나 비활성. 기존 XAML diagnostics 충돌 기록 때문에 재활성화하지 않음 |

## 이번 실제 순서와 검증

1. `pre-windhawk-enhancement` 백업 371개 파일 SHA256 검증, UI profile 추가 보관.
2. Fix white flashes in explorer 1.4 공식 소스 확인→컴파일→비활성 등록→활성→파일 작업 검증.
3. Click on empty taskbar space 2.6 동일 절차→왼쪽 Ctrl+빈 공간 두 번 클릭→작업 관리자 확인.
4. 기존 시작 메뉴·알림/달력/빠른 설정 스타일만 정제. 기본 레이아웃·고정 앱·실제 시스템 설정 보존.
5. 제어 센터 실제 목록·호환성·공식 문서·오류·복구 확인창 통합.
6. 예상치 못한 Explorer 교체 확인→가장 최근 자동 폭 표현식 철회→기존 static margin 재계산→Dock 재검증.

모든 스타일 모드는 Windows 업데이트 후 XAML 이름·private symbol·diagnostics 소비자 충돌을 재검사한다. DLL 로드만으로 기능 검증을 대체하지 않는다. 새 두 모드도 장시간 안정성은 미확정이다.

## 설치 방식과 출처

Windhawk가 공개한 [1.7.3 portable 설정 구현](https://github.com/ramensoftware/windhawk/blob/v1.7.3/src/vscode-windhawk/src/utils/modConfigUtils.ts)과 INI 형식을 확인해 기존 프로젝트의 컴파일·원자적 설정 배포를 재사용했다. 가상의 CLI/API는 만들지 않았다. 공식 소스는 [고정 커밋 e3976aca](https://github.com/ramensoftware/windhawk-mods/tree/e3976aca5c5f511878e4beefdc2e9ef65cd5565b/mods)에서 변경 없이 사용했고 `.source.json`에 URL·SHA256을 기록했다. 엔진 INI는 UTF-16 LE BOM을 유지한다. GUI 캐시는 공식 Windhawk 창만 다시 열어 갱신했으며 엔진을 재시작하지 않았다.

## 개별 복구

`powershell.exe -NoProfile -File scripts\set-v24-mod.ps1 -Id <ID> -Disable`로 신규 선택 모드를 해제한다. 직전 설정 복구는 `scripts/rollback-windhawk-enhancement.ps1 -ModId <ID>`, 전체 확장 구성 복구는 같은 스크립트에서 인자 생략. 자동 Explorer 재시작·소프트웨어 제거는 수행하지 않는다. [복구 절차](../docs/windhawk-recovery.md).
