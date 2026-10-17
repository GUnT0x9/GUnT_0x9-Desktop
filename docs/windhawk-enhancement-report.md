# GUNT Desktop — Windhawk 확장 작업 결과

## 1. 기존 환경

2026-10-16 실제 확인: Windows 11 Home 25H2 빌드 26200.9711, Windhawk 1.7.3 portable, Rainmeter 4.5.28.3936, Flow Launcher 2.1.4, Lively 2.2.1.0. 주 화면 2880×1800/175%, 위 1920×1080/100%, 오른쪽 2160×1440/150%. 음수 좌표를 포함한다. 시작 당시 모드 12개 설치·11개 활성, 현재 14개 설치·13개 활성이다.

기존 한국어 상단 바·Rainmeter·Lively 선택·시작 등록·사용자 고정 앱을 유지했다. 현재 선택된 라이브 배경은 우주 영상이며 과거 Gojo 이미지로 덮어쓰지 않았다. 시스템 모니터는 현재 사용자가 저장한 위쪽 보조 화면 위치를 유지한다.

## 2. 추가 설치한 모드

| 모드 | 버전 | 대상 | 설정·실제 확인 |
|---|---|---|---|
| [Fix white flashes in explorer](https://windhawk.net/mods/fix-explorer-white-flash) | 1.4 | explorer.exe | 공식 소스 원본. 실제 복사·붙여넣기·해시·이름 변경·2개 탭·검색·500개 파일 통과. 번쩍임 감소량 정량 측정 미실시 |
| [Click on empty taskbar space](https://windhawk.net/mods/taskbar-empty-space-clicks) | 2.6 | explorer.exe | 왼쪽 Ctrl+주 화면 Dock 빈 영역 두 번 클릭으로 작업 관리자 실행 확인. 앱 버튼·일반 클릭에 추가 동작을 배정하지 않음 |

새 두 모드는 DLL 로드와 해당 기능을 확인했다. 작업 중 Explorer 교체가 있어 장시간 안정성이 검증됐다고 판단하지 않는다. 이전 작업에서 추가했던 Settings Styler 1.1·Better file sizes 1.6은 중복 설치하지 않았다.

## 3. 적용된 디자인

- 시작 메뉴: 기존 새 레이아웃과 고정 앱 16개 보존. 검색창 #15151C, 표면 #0E0E12, 테두리 #23232B/1DIP, 모서리 6DIP. 전원 메뉴도 같은 평면 스타일. 검색·전체 앱·계정·전원 기능 제거 없음.
- 알림/달력/빠른 설정: 16DIP 모서리를 6DIP로 정리. 얇은 테두리와 어두운 표면. 빠른 설정 선택 타일 #A78BFA, hover #C084FC, pressed #8B6BD6. 날짜 강조 보존. 네트워크·방해 금지·밝기 등 실제 설정 값 변경 없음.
- 설정 앱: 기존 Settings Styler 디자인 유지·실화면 확인. Windows 실제 설정 변경 없음.
- 탐색기: 기본 Windows 어두운 테마 유지. 전체 File Explorer Styler는 충돌 이력 때문에 비활성 유지. 따라서 전체 보라색 탐색기 테마 적용 완료로 분류하지 않는다.
- Dock: 60DIP 높이·38DIP 아이콘·12DIP 모서리·기존 중앙 기준 왼쪽 확장 보존. 마지막 검증에서 16개 앱, 앱 영역 x676/폭1431px, 트레이 x2143, 간격36px. 사용자 핀·그룹화 변경 없음.

추가했던 ActualWidth 기반 자동 여백 표현식은 Explorer 교체 확인 뒤 철회했다. 현재는 기존 설치 스크립트가 현재 앱/트레이 폭으로 계산하는 static margin이다. 앱 수가 크게 바뀌면 레이아웃 재적용이 필요할 수 있다.

## 4. 추가된 편의 기능

- Ctrl+Dock 빈 공간 두 번 클릭→작업 관리자.
- 기존 볼륨 모드의 트레이 휠 조절 실제 CoreAudio 값 확인 후 원래 볼륨 복원.
- 기존 Alt+Tab을 세 화면의 커서 위치에서 열어 각 화면 표시 확인. UIA에 목록 항목이 노출되지 않아 창 필터 내용까지 검증했다고 보지 않는다.
- GUNT 제어 센터의 Windhawk 페이지: 실제 INI에서 모드 14개·활성 13개·버전·대상 읽기, 선택 모드 설명·호환성, 공식 문서, 호환성표, 최근 오류, 복구 확인창. 가짜 활성 토글 없음. native Windhawk 설정으로 이동한다.
- 간단히/자세히 숨김 실행 수정은 이전 작업에서 적용된 상태를 유지한다. 이번 확장 때문에 콘솔 실행 방식을 다시 바꾸지 않았다.

## 5. 적용하지 않은 모드

Dock Animation Plus는 기존 변환/잘림/입력 영역 중첩 때문에 실험 분류. Shell Flyout Positions는 실제 겹침이 없어 미설치. Taskbar Labels는 폭과 그룹화 보존 때문에 제외. Dark menus처럼 기본 전체 프로세스 대상인 모드는 자동 설치하지 않았다. 자세한 버전·사유는 [호환성표](../windhawk/compatibility-matrix.md).

## 6. 충돌 및 호환성

**해결되지 않은 안정성 항목:** Explorer 셸 PID가 28960에서 28864로 16:00:46에 교체됐다. 사용자는 수동 재시작하지 않았다고 확인했다. Assistant는 Explorer 재시작을 지시하거나 실행하지 않았다. Taskbar Styler의 0x8000FFFF 재시작 안내가 작업 중 스크린샷에 있었고, 조사 당시에는 창이 사라져 있었다. Application 오류 이벤트가 없다는 사실만으로 충돌이 없었다고 판단할 수 없다.

가장 최근의 Dock 자동 폭 표현식을 원본 스크립트·기존 계산 방식으로 되돌렸으며 Dock 기능 검사를 다시 통과했다. 새 모드 두 개와의 인과관계는 확정되지 않았다. 현재 관찰 결과는 `logs/windhawk-enhancement-health.json`, 사건 조사는 `logs/enhancement-restart-audit.json`을 참조한다. 지속 관찰에서 재발하면 Ctrl 더블클릭 모드→white flash 모드 순으로 개별 해제한다. 전체 데스크톱 초기화는 하지 않는다.

File Explorer Styler의 이전 XAML diagnostics 충돌은 별도 미해결 항목이다. 기존 Dock 보존을 우선해 비활성 유지한다. 사용자의 모니터 위젯 위치 변경도 보존했다.

## 7. 성능

30초 표본, 8개 논리 프로세서 정규화. 전체 Explorer 부하를 Windhawk 단독 비용으로 해석하지 않는다.

| 프로세스 | 전 CPU | 후 CPU | 전 작업 집합 MiB | 후 작업 집합 MiB |
|---|---:|---:|---:|---:|
| Explorer | 1.551% | 1.036% | 159.6 | 254.0 |
| GUNT Bar | 0.180% | 0.103% | 44.8 | 52.1 |
| Rainmeter | 0.039% | 0.026% | 43.0 | 39.3 |
| Windhawk | 0.000% | 0.000% | 6.9 | 9.6 |
| HWiNFO | 0.528% | 0.463% | 29.3 | 46.8 |
| GUNT Control Center | 닫힘 | 0.000% | — | 188.2 |

**전후 사이 Explorer와 mpv PID, 열린 창, Control Center 상태가 바뀌어 직접적인 증감 원인 비교가 불가능하다.** CPU 수치가 낮아졌다는 이유로 최적화 성공을 주장하지 않는다. 시작 메뉴 열기 관찰431ms·500개 파일 폴더관찰392ms는 입력/폴링을 포함한 단일 기능 시험으로 속도 벤치마크가 아니다. 장시간 메모리 증가·전력·배터리·재로그인 지연은 미측정이다. 원시 표본은 `logs/v24-performance-enhancement-before.json`, `...-after.json`.

## 8. 테스트 결과

| 구분 | 결과 |
|---|---|
| 통과 | 시작 메뉴 실제 열기·16개 핀 유지·검색 후 메모장 실행 |
| 통과 | 탐색기 복사/붙여넣기 해시·이름 변경·2개 탭·500개 파일·검색 |
| 통과 | 알림 센터·달력 다음 달/원래 달 복원·빠른 설정 열기 |
| 통과 | 현재 Dock 16개 앱·간격·60DIP·Chrome 전환·한국어 초 시계 |
| 통과 | Ctrl+빈 Dock 두 번 클릭 작업 관리자·볼륨 휠 값/복구·IEC 파일 크기 |
| 통과 | Control Center 실제 14개 목록·설명·오류 버튼·복구 확인창/아니요 취소 |
| 부분 | 세 화면 Alt+Tab 표시 위치 확인. UIA 창 항목 열거 불가 |
| 부분 | 우클릭 메뉴 자동 검증은 관리자 HWiNFO 창의 UIA 접근 제한으로 불완전 |
| 실패 후 철회 | 자동 Dock 폭 규칙은 기능 시험 통과했으나 원인 미확정 Explorer 교체 후 안전상 철회 |
| 보류 | File Explorer Styler 전체 테마. 기존 충돌 때문에 비활성 |
| 미시험 | UNC 경로·썸네일 실제 드래그 재정렬·재로그인·배터리·장시간 안정성·전체 실제 롤백 |

개별 로그: `enhancement-start-verification.json`, `enhancement-explorer-verification.json`, `enhancement-flyout-verification.json`, `enhancement-alt-tab.json`, `enhancement-taskbar-shortcut.json`, `enhancement-control-center.json`, `v23-dock-verification.json`. 과거 `enhancement-dock-adaptive.json`은 철회된 실험 결과다.

## 9. 스크린샷

실제 캡처이며 관리자 창 가림·다른 앱 캡처는 성공 증거에서 제외했다.

- [시작 메뉴 이전](../screenshots/enhancement-start-before.png) / [이후](../screenshots/enhancement-start-after.png) / [전원 메뉴](../screenshots/enhancement-start-power.png)
- [알림 센터 이전](../screenshots/enhancement-notification-real-before.png) / [이후](../screenshots/enhancement-notification-after.png) / [빠른 설정](../screenshots/enhancement-quick-settings-after.png)
- [탐색기](../screenshots/enhancement-explorer-after.png) / [검색](../screenshots/enhancement-explorer-search.png) / [설정 앱](../screenshots/v24-settings-after.png)
- [제어 센터 실제 Windhawk 페이지](../screenshots/enhancement-control-center.png)
- [전체 가상 데스크톱](../screenshots/enhancement-desktop-final.png) / [주 화면](../screenshots/enhancement-desktop-final-primary.png)

전체·주 화면 캡처는 자동 폭 철회 뒤 다시 저장했다. 이전 개별 UI 캡처는 해당 기능 시험 시점 자료다. 현재 Dock 좌표는 최신 `v23-dock-verification.json`을 우선한다.

## 10. 변경된 파일

- `apps/Windhawk/AppData/Engine/Mods/`의 신규 INI/DLL 2개, 기존 시작/알림/taskbar styler INI 및 해당 project settings JSON.
- `apps/Windhawk/AppData/ModsSource/`, `windhawk/*.wh.cpp`, `.source.json`, 신규 `.settings.json`.
- `windhawk/mods.json`: 실제 INI 파생 목록. `windhawk/enhancement-status.json`: 검증 범위·설명. `windhawk/compatibility-matrix.md`.
- `control-center/src/GUNT.ControlCenter/Models/WindhawkEntry.cs`, `Services/DesktopService.cs`, `Views/MainWindow.cs`, `bin/GUNT.ControlCenter.exe`.
- `scripts/install-optional-mod.ps1`, `set-v24-mod.ps1`, `export-windhawk-state.ps1`, `checkpoint.ps1`, `rollback-windhawk-enhancement.ps1`.
- `scripts/enhancement-ui-common.ps1`, `inspect-windhawk-enhancement.ps1`, `verify-enhancement-*.ps1`, `verify-windhawk-enhancement-health.ps1`, `capture-enhancement-desktop.ps1`.
- 본 보고서·복구 문서·README·CHANGELOG. `install-dock.ps1`은 원본 복원됨.

## 11. 원상복구

`pre-windhawk-enhancement-20261016-152624`에 371개 파일 SHA256이 보관되어 재검증됐다. Windhawk GUI profile도 extra에 별도 보관했다. Windows 복원 지점을 생성했다고 주장하지 않는다. 이번 복구는 Windows 보안 설정을 변경하지 않는다.

복구는 [windhawk-recovery.md](windhawk-recovery.md)의 확인 명령과 개별 모드 절차를 따른다. 제어 센터에서도 확인 후 동일 복구 스크립트를 실행한다. 전체 설정 복구는 `-WhatIf`만 실행했으며 실제 전체 롤백 성공으로 표시하지 않는다. 신규 모드는 제거하지 않고 비활성화해 재현·복구 가능성을 보존한다.

## 12. 다음 개선 제안

새 모드를 더 추가하기 전에 현재 조합의 장시간 관찰과 셸 교체 재발 여부부터 확인한다. File Explorer Styler 재활성화와 애니메이션 확장은 XAML 소비자 충돌을 격리한 별도 단계로 진행한다. 썸네일 드래그·UNC 경로·실제 로그인 복원은 해당 사용 환경에서 검증할 필요가 있다.

## 종료 관찰 기록

`logs/windhawk-enhancement-health.json`: 시작 전 백업 371개 SHA256 재검증, Dock 자동 폭 규칙 제거 확인, 핵심 GUNT Bar/Rainmeter/Windhawk 엔진 각 1개. 시작 등록·상단 바·Dock JSON·Lively 배치 해시 유지. 모니터 위치 JSON만 작업 중 저장된 현재 사용자 배치를 보존했다. 철회 후 30초 관찰에서 Explorer 28864가 유지됐으며 새 관련 Application 오류는 발견하지 못했다. 이는 장시간 안정성이나 앞선 교체 원인 해명을 뜻하지 않는다. `verify-v24.ps1`의 전체 PS 구문·설정 범위·분리 트랜잭션 실패 복구·실제 센서 결측/정체성 시험 통과. 전체 Windhawk 복구는 `-WhatIf` 해시 검사만 실행했다.
