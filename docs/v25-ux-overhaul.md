# GUnT_0x9 Desktop v2.5 — UX 개선 결과

2026-10-17. 기존 WinForms 상단 바, WPF/.NET Framework 4.8, Rainmeter, Windhawk, Lively 구조를 유지했습니다. v2.6의 프로젝트 런처·배경 갤러리 일부를 선행 통합했습니다. 선택한 배경을 이전 Gojo 이미지로 바꾸지 않습니다.

## 확인한 문제와 수정

| 문제 | 원인 | 실제 변경 |
|---|---|---|
| Dock 메뉴가 Windhawk로 이동 | `dock → windhawk` 별칭 | 독립 Dock 페이지, 지원되는 7개 값만 편집 |
| 프로젝트 관리 목적지 없음 | 모델·페이지 부재 | 빈 개인 목록으로 시작하는 CRUD·검색·고정·최근 목록 |
| 이동하면서 설정 유실 | 페이지 재생성 | 필드 dirty 추적, 적용/버리기/계속 편집, 창 닫기 보호 |
| 저장 결과가 불명확 | 일반 메시지·전체 덮어쓰기 복구 | 변경 요약, 외부 변경 충돌 감지, 변경 키만 복구, 1단계 실행 취소 |
| 상태가 긴 텍스트에 섞임 | 전체 보고서 방식 | 실제 프로세스·위젯·프로필·센서·시작 등록의 상태 행 |
| 프로필이 배경·위치를 건드릴 여지 | 전체 설정 캡처 | 모니터 표시·compact·수동 정지 정책 세 값으로 범위 축소 |
| 연속 프로필 전환 실패 | 갱신 중 layout.json 전체 캡처 경합 | 필요한 값만 읽기, 공유 읽기·제한된 재시도 |
| 입력한 숫자가 잘못되기 쉬움 | 자유 숫자 입력 | 그래프 30/60/120초, 수집 1/2/5초 선택 |
| 센서 연결 결과 불명확 | 공급자·단위·신선도 구분 부족 | 실제 값·장치·단위 재확인, 기존 Apply/Undo로 연결 |

## 일상 사용

- 상단 바의 **GUnT_0x9 → Dock 설정**은 Dock 페이지, **작업공간 → 프로젝트 바로가기 관리**는 프로젝트 페이지로 연결합니다.
- 수정하면 하단에 미저장 개수가 표시됩니다. Ctrl+S로 적용할 수 있습니다. 여러 설정·Dock·시작 설정은 실제 이전 값과 새 값을 확인한 뒤 적용합니다.
- 저장 후 **직전 적용 취소**는 가장 최근의 설정 트랜잭션 하나만 되돌립니다. 앱 재시작 뒤까지 유지되는 무제한 Undo가 아닙니다.
- **프로필**에서 현재 상태와 목표 세 값을 미리봅니다. 기본 프로필 삭제·이름 변경은 막고, 사용자 프로필은 저장·이름 변경·보관 삭제합니다. 이전 상태 복원은 한 번 소비하며 7일 지난 기록은 거부합니다.
- **진단 및 복구**는 구성 요소별 지원 동작, 설정 스냅샷 하나의 차이·복원, 진단 파일 내보내기를 제공합니다. 계정 홈·IP·대표 자격증명 패턴을 가리며 원본 로그 전체를 내보내지 않습니다.
- **명령 찾기**는 제어 센터 안에서 Ctrl+K입니다. 시작·자동화에서 Ctrl+Shift+P 또는 사용 안 함으로 바꿀 수 있습니다. Flow Launcher와 전역 단축키는 변경하지 않습니다.

## 디자인 검수

Midnight Purple 색·기존 S-Core Dream/Manrope·승인된 래스터 로고를 보존했습니다. 상태는 평면 행과 얇은 구분선으로 표현합니다. 선택·키보드 포커스에는 얇은 보라 테두리, 비활성 버튼에는 낮은 명도를 적용했습니다. 새 카드·그라데이션·가짜 센서 값은 넣지 않았습니다. 실제 창 단독 캡처로 한국어·겹침·표시를 확인했습니다.

| 이전 개요 | 새 개요 |
|---|---|
| ![v2.4 개요](images/v25-before-overview.png) | ![v2.5 개요](images/v25-overview.png) |

![Dock 설정](images/v25-dock.png)
![프로젝트 목록](images/v25-projects.png)
![프로필 미리보기](images/v25-profiles.png)

## 상태 구분

- **구현 및 검증**: Dock·Projects 목적지, dirty 보호, 실제 그래프 Apply/Undo, 프로젝트 GUI CRUD·폴더 실행, 네 기본 프로필 실제 전환·1회 복원, 센서 연결 저장/Undo, 명령 찾기·작은 창, 구성 요소 상태 읽기.
- **구현·추가 검증 필요**: 프로젝트 IDE·터미널·저장소 URL 및 직접 명령의 실제 앱 실행, 배경 종류 변경·전체 모니터 적용, 실패한 배경 적용의 실제 엔진 복구. 경로·명령 인수·거부 동작은 분리 모델 검사만 통과했습니다.
- **부분 구현**: 센서 안내는 기존 공급자의 감지→데이터→장치/단위→검증/연결을 한 화면에서 제공합니다. 관리자 HWiNFO 설정을 자동 조작하는 순차 마법사는 아닙니다. 모니터 설정은 저장된 실제 레이아웃 설명을 제공하며 축소된 실시간 위젯 미리보기는 없습니다.
- **미구현**: 조건 기반 자동 프로필 전환, 이름 있는 새 모니터 프로필 관리, 첫 실행 마법사, Flow 전역 명령 플러그인. 사용하지 않는 토글이나 작동하지 않는 페이지는 넣지 않았습니다.
- **환경 제한**: 조사 당시 3대였으나 마지막 검증에는 1대(2880×1800/175%)가 연결됐습니다. 3대 재연결·100%/150%·재로그인은 미검증입니다.

[탐색과 데이터 형식](v25-navigation.md) · [검사 기록](v25-testing.md) · [복구](v25-recovery.md) · [v2.6 기능 범위](v26-feature-expansion.md)

## 마지막 안전 조치 — Dock 자동 적용 보류

모서리 12→10→12 시험의 JSON·INI 값과 즉시 PID 검사에는 이상이 없었지만, 시험 종료 약 29초 뒤 Explorer 프로세스가 교체됐습니다(22:02:19). 자동 재시작 명령은 실행하지 않았으며 해당 시간 응용 프로그램 로그에서 1000/1001/1002 Explorer 이벤트는 발견하지 못했습니다. 사용자는 해당 현상을 확인하지 못했다고 응답했고, 원인은 확정하지 않았습니다. 최종 Dock INI는 시험 전과 비교해 SettingsChangeTime만 다르고 실제 스타일·크기·라이브러리는 같습니다.

이를 전체 안정성 통과로 처리하지 않았습니다. 로컬 `state/dock-live-apply-hold.json`이 있는 동안 Dock 페이지는 실제 값 조회와 Windhawk 열기만 제공하고, 설정 서비스도 Dock 쓰기를 거부합니다. 기존 Dock은 계속 동작합니다. 자동 적용의 UI·소스는 구현됐지만 이 PC에서는 원인 확인 전 **보류**입니다. 다른 설정 Apply/Undo에는 영향을 주지 않습니다. 이 보류 파일을 자동 삭제하는 복구 버튼은 제공하지 않습니다.

## 주요 변경 파일

- `control-center/src/GUNT.ControlCenter/Views/MainWindow.cs`, `UxShell.cs`, `UxPages.cs`, `UxStyles.cs`: 탐색·보호·페이지·키보드·flat 스타일.
- `control-center/src/GUNT.ControlCenter/Models/SettingField.cs`, `WorkspaceModels.cs`: dirty 필드와 실제 프로젝트/프로필/배경/상태 모델.
- `control-center/src/GUNT.ControlCenter/ViewModels/MainViewModel.cs`: 지원 설정·선택 입력.
- `control-center/src/GUNT.ControlCenter/Services/DesktopService.cs`, `WorkspaceService.cs`, `WallpaperService.cs`: 기존 트랜잭션 확장·복구·런처·배경·센서 재사용.
- `src/Configuration.cs`, `src/GuntBar.cs`: 공유 읽기·검증, 실제 목적지·프로필 미리보기·고정 프로젝트.
- `scripts/desktop-actions.ps1`, `restore-wallpaper.ps1`, `common.ps1`, `apply-v24-settings.ps1`: 최소 프로필 범위·한글 출력·기존 정책 복원·내보내기.
- `scripts/build-configuration.ps1`, `build-control-center.ps1`, WPF csproj: DLL 참조·사용 중 이전 DLL 빌드 백업 충돌 방지.
- `scripts/rollback-v25-ux.ps1`, `verify-v25-*.ps1`, `control-center/tests/UxTests.cs`: 선택 복구와 분리 모델·실제 UI 검사.
- `config/ux.json`, `config/theme.json`, `.gitignore`: 키 설정·2.5 버전·개인 데이터 공개 제외.
- `README.md`, `CHANGELOG.md`, `docs/v25-*.md`, `docs/v26-feature-expansion.md`, `docs/images/v25-*.png`, `windhawk/compatibility-matrix.md`: 실제 변경·근거·미완료·회복 기록.

`bin/GUNT.ControlCenter.exe`와 `bin/GUNT-Bar.exe`는 실제 Windows 빌드 결과이며 Git 제외 대상입니다. 소스·스크린샷·문서는 로컬 작업 트리에 작성했습니다. 이번 UX 작업의 변경을 원격 저장소에 새로 푸시하지는 않았습니다.
