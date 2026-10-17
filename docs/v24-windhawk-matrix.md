# Windhawk v2.4 호환성·배포 행렬

현재 활성 11개 / 설치 12개. [후속 실제 적용 보고서](v24-flicker-mods-report.md)에 Settings Styler·Better file sizes 검증을 추가했다.

조사 기준 2026-10-16. 공식 저장소 커밋 e3976aca5c5f511878e4beefdc2e9ef65cd5565b. 날짜는2026년 마지막 파일 변경일이다. 기존4개는 DLL로드 확인, 신규는 실제 적용 검증 전 호환 확정이 아니다.

| ID·공식 링크 | 버전 | 변경일 | 프로세스 | 판단 |
|---|---|---|---|---|
| [windows-11-taskbar-styler](https://windhawk.net/mods/windows-11-taskbar-styler) | 1.10 | 09-13 | explorer | 기존 유지 |
| [taskbar-icon-size](https://windhawk.net/mods/taskbar-icon-size) | 1.3.10 | 09-07 | explorer | 기존 유지 |
| [taskbar-clock-customization](https://windhawk.net/mods/taskbar-clock-customization) | 1.8.1 | 09-30 | explorer | 기존 유지 |
| [windows-11-notification-center-styler](https://windhawk.net/mods/windows-11-notification-center-styler) | 1.7 | 09-12 | ShellExperienceHost/ShellHost | 기존 유지 |
| [taskbar-thumbnail-reorder](https://windhawk.net/mods/taskbar-thumbnail-reorder) | 1.1.5 | 06-24 | explorer | 추천 1 |
| [taskbar-notification-icon-spacing](https://windhawk.net/mods/taskbar-notification-icon-spacing) | 1.4 | 09-29 | explorer | 추천 2 |
| [taskbar-volume-control](https://windhawk.net/mods/taskbar-volume-control) | 1.3.1 | 06-06 | explorer/ShellExperienceHost/SndVol | 추천 3 |
| [alt-tab-per-monitor](https://windhawk.net/mods/alt-tab-per-monitor) | 1.2 | 03-22 | explorer | 추천 4 |
| [windows-11-start-menu-styler](https://windhawk.net/mods/windows-11-start-menu-styler) | 1.7 | 08-15 | StartMenuExperienceHost/SearchHost/SearchApp | 추천 5·적용 검증 |
| [windows-11-file-explorer-styler](https://windhawk.net/mods/windows-11-file-explorer-styler) | 1.7 | 09-27 | explorer | 추천 6·XAML 충돌 검사 |
| [shell-flyout-positions](https://windhawk.net/mods/shell-flyout-positions) | 1.3 | 06-27 | explorer/ShellExperienceHost/ShellHost/StartMenuExperienceHost | 위치 문제 재현 시 선택 |
| [fix-explorer-white-flash](https://windhawk.net/mods/fix-explorer-white-flash) | 1.4 | 04-21 | explorer | 번쩍임 재현 시 선택 |
| [explorer-details-better-file-sizes](https://windhawk.net/mods/explorer-details-better-file-sizes) | 1.6 | 10-06 | 기본 * | 적용·탐색기 한정·폴더 계산 꺼짐 |
| [windows-11-settings-styler](https://windhawk.net/mods/windows-11-settings-styler) | 1.1 | 08-15 | SystemSettings | 적용·Midnight Purple 화면 확인 |
| [start-menu-size](https://windhawk.net/mods/start-menu-size) | 1.1 | 03-21 | StartMenuExperienceHost/explorer | 선택·중복 크기 규칙 금지 |
| [notifications-placement](https://windhawk.net/mods/notifications-placement) | 1.2.4 | 07-20 | explorer/ShellExperienceHost | 토스트 겹침 시 선택 |
| [taskbar-empty-space-clicks](https://windhawk.net/mods/taskbar-empty-space-clicks) | 2.6 | 02-09 | explorer | 선택 |
| [taskbar-auto-hide-when-maximized](https://windhawk.net/mods/taskbar-auto-hide-when-maximized) | 1.2.6 | 03-30 | explorer | 선택·기본 꺼짐 |
| [dark-menus](https://windhawk.net/mods/dark-menus) | 1.4.2 | 01-24 | 기본 * | 실험·대상 제한 |
| [taskbar-dock-animation-plus](https://windhawk.net/mods/taskbar-dock-animation-plus) | 2.0.1 | 07-13 | explorer | 실험·잘림 위험·기본 꺼짐 |
| [taskbar-labels](https://windhawk.net/mods/taskbar-labels) | 1.5.1 | 09-27 | explorer | 기본 제외·Dock 폭 충돌 |
| [explorer-visual-tweaks-dark](https://windhawk.net/mods/explorer-visual-tweaks-dark) | 1.0.1 | 09-21 | explorer/prevhost | 실험·재시작 요구·기본 제외 |

주요 위험: Styler XAML diagnostics 소비자 충돌, 트레이 폭 변경, private symbol 변경. 한 번에1개 활성화하고 실제 기능·모듈·오류로그 확인, 마지막 변경만 되돌린다. 설치된 엔진1.7.3 및 기존4개 버전을 유지한다. 시작 메뉴 구형 레이아웃 강제 금지, tray glyph 글꼴 변경 금지.

트레이 폭28·1행/숨김32·5열, 볼륨 트레이휠2단계·Win11표시·전체화면휠 꺼짐, AltTab커서위치·전체창 목록. 낮은 지속 부하를 예상하지만 실제 성능은 개별 검사한다. 소스SHA256·커밋을 기록하고 INI를 원자적으로 적용한다. 복구는 직전INI복원 또는 신규모드Disabled=1이다. Explorer재시작이 필요하면 승인을 받는다.

## 초기 실제 적용 결과 (14:40 시점)

추천 6개를 공식 소스 해시 확인 → 개별 컴파일 → 비활성 등록 → 한 개씩 활성화했다. 기존 4개와 함께 처음 총 10개로 시험했으나 최종 활성은 9개다. Explorer 셸 PID 28960이 유지됐고, 폴더 창 전용 Explorer 27488이 추가 실행됐다. 이를 셸 재시작이나 충돌로 계산하지 않는다.

| 신규 모드 | 실제 확인 | 추가 수동 확인 |
|---|---|---|
| Taskbar Thumbnail Reorder 1.1.5 | 셸 DLL 로드 | 동일 앱의 여러 창 미리보기 드래그 순서 |
| Taskbar tray icon spacing and grid 1.4 | DLL·트레이·Dock 간격·숨김 아이콘 영역 유지 | 장치별 아이콘 증감·최대 오버플로 |
| Taskbar Volume Control 1.3.1 | 네이티브 트레이 휠 후 CoreAudio 값 변화·원래 볼륨 복구 | 다른 출력 장치 전환 |
| Alt+Tab per monitor 1.2 | 셸 DLL 로드 | 세 화면 간 실제 Alt+Tab 대상 비교 |
| Windows 11 Start Menu Styler 1.7 | 대상 프로세스 DLL·실제 시작 메뉴·검색 검사 | 로그인 직후 초기 화면 |
| Windows 11 File Explorer Styler 1.7 | 초기 화면은 통과했으나 Taskbar Styler 재시작 안내 0x8000FFFF 발생 → 비활성 복구 | XAML 소비자 충돌 해결 전 재활성화 금지 |

설치 순서는 Thumbnail → Volume → AltTab → Tray → Start → Explorer였다. 각 단계 INI는 `backups/mod-toggle-*`로 보존했다. 신규 6개 이외 후보는 설치하지 않았다. `scripts/set-v24-mod.ps1 -Id <ID> -Disable`로 개별 해제할 수 있다. 재부팅·로그오프·Explorer 재시작은 수행하지 않았다.

### 실제 충돌과 최종 선택

추가 UI 검사에서 `Windows 11 Taskbar Styler`의 재시작 안내 `0x8000FFFF`를 발견했다. 공식 소스는 XAML diagnostics 소비자가 동시에 하나만 가능하며 allow가 다른 모듈을 허용하는 대신 자신의 동작을 깨뜨릴 수 있다고 명시한다. 파일 탐색기 Styler를 비활성화한 뒤 작업 표시줄 설정을 다시 적용하고 Dock 검사를 재통과했다. 안내에는 No를 선택했으며 Explorer를 재시작하지 않았다. 파일 탐색기는 Windows 기본 어두운 테마를 유지한다. 최종 신규 활성은 Thumbnail·Tray spacing·Volume·AltTab·Start 5개다.

## 후속 적용 및 최종 상태

Settings Styler 1.1 → 실제 설정 앱 화면·DLL 확인 → Better file sizes 1.6 → 1.00MiB/20.0MiB 실제 셀 확인 순으로 추가했다. 기존 Explorer 셸 PID 유지, 새 관련 충돌 0건, Dock 60DIP/15개 앱 겹침 없음. 설치 12개 중 활성 11개이며 File Explorer Styler만 비활성이다. Settings Styler는 SystemSettings.exe, 용량 표시는 explorer.exe로 한정했다. 폴더 재귀 계산은 껐다. `set-v24-mod.ps1 -Id <ID> -Disable`로 각각 해제하고 `pre-v24-flicker-mods` 체크포인트로 직전 상태 복구가 가능하다. DLL을 로드한 사실과 실제 기능·화면 검증은 로그에 구분했다.
