# GUNT Launchpad — dev.4–dev.6 결과

`feat/v30-launchpad` / **3.0.0-dev.6 개발 프리뷰**. v3.0 안정판이 아니다. dev.3 `048be04`에서 시작했고 v2.x·기존 UI 브랜치 이력을 보존한다.

## 체크포인트

| 버전 | 구현 | 근거 |
|---|---|---|
| dev.4 | 네이티브 앱 발견·그리드·검색·키보드·카테고리·즐겨찾기·폴더·정렬·바로가기·단축키 | `82b7c5e`, Windows 38개 기반 검사, 실제 초기 화면 |
| dev.5 | 기존 승인 코딩 포즈 + 신규 참조 생성 9종, 선택형 테마·앱/카테고리 지정·짧은 전환·fallback | `f7b47ce`, Windows 50개 검사, 실제 마스코트 테마 캡처 |
| dev.6 | Settings/Workspace 탐색 분리·기존 경로 호환·명령 통합·실제 입력 수정·재열기 작업 절감 | 아래 최종 검증과 성능 기록 |

[구현 상세](v30-launchpad.md) · [포즈·출처·제작 프롬프트](../assets/branding/mascot/README.md).

## 실행과 데이터

Windows PowerShell에서 기존 빌드 순서를 사용한다. 추가 앱 프로세스는 키보드 데몬이 아니라 첫 요청 때 여는 WPF UI 호스트이며 숨김 10분 후 해제한다. 키 등록은 기존 상단 바만 수행한다.

```powershell
.\scripts\build-configuration.ps1
.\scripts\build.ps1
.\scripts\build-control-center.ps1
& .\bin\GUNT-Bar.exe (Get-Location).Path
& .\bin\GUNT.ControlCenter.exe (Get-Location).Path launchpad
& .\bin\GUNT.ControlCenter.exe (Get-Location).Path settings
& .\bin\GUNT.ControlCenter.exe (Get-Location).Path workspace
```

기존 상단 바가 이미 실행 중이면 중복 실행하지 않는다. `build.ps1`은 프로젝트 상단 바를 교체하기 위해 정상 종료할 수 있으며 빌드 후 실행이 필요하다. Explorer는 재시작하지 않는다. 열려 있는 미저장 제어 센터를 강제 종료하지 않는다. `-Candidate`는 현재 앱을 교체하지 않는 검토용 빌드다.

`config/launchpad.json`은 버전 1의 사용자 설정·바로가기·포즈·정렬이며 Git에서 제외한다. `state/launchpad-catalog.json`은 비공개 발견 결과다. 공개 예제만 `config/examples/launchpad.example.json`에 둔다. 저장은 기존 원자 저장·백업·동시 편집 보호를 이용하며 알 수 없는 스키마를 덮어쓰지 않는다. 제거·카테고리 삭제는 앱/실행 파일을 삭제하지 않는다.

## 실제 검증

Windows 네이티브 Framework C# 5 빌드와 실제 GUI 실행을 완료했다. 최종 파일의 제품 버전은 `3.0.0-dev.6`, SHA-256은 `962364d555505414be3f55de755ff22f398fa16ae151581eab5f9f6976520d58`다. 소스는 `ce77dcc`이며 이후 캡처 경계·문서만 변경했다.

| 구분 | 결과 | 근거 |
|---|---|---|
| Launchpad WPF | 63개 통과 | `verify-launchpad.ps1`, `logs/launchpad-dev6-final-tests.json` |
| 실제 데스크톱 입력 | 26개 통과 | `verify-launchpad-desktop.ps1`, `logs/launchpad-dev6-final-desktop-tests.json` |
| 실제 상단 바 키 갱신/충돌 | 3개 통과·원본 복원 | `verify-launchpad-hotkey-reload.ps1`, 로컬 동일 이름 로그 |
| 기존 WPF 회귀 | 42개 통과 | `logs/v30-launchpad-regression-interactions.json` |
| 기존 검색·경로 | 검색10개, 기존19개 보존+새3개 | `check-v30-search.py`, `check-v30-source.py` |
| C#5/.NET4.8 교차 컴파일 | 구성·센서·WPF·상단 바4개 통과 | `compile-v30-linux.py`; native 빌드를 대체하지 않음 |
| 실제 캡처와 검토 | 최종10개 원본·export 검토 | [시각 기록](visual-history.md#v300-dev4--dev6--gunt-launchpad) |

WPF 검사는 실제 키 등록 충돌·원자 저장/동시 편집 거부·1,000개 항목의 페이지 생성·별칭·폴더/즐겨찾기/순서·동작 줄이기·10종 포즈/없는 자산/미지정 앱 원래 아이콘·Settings/Workspace/과거 deep link를 포함한다. 검증 fixture와 실행 가로채기를 사용한 부분은 실제 외부 앱 실행과 구분한다.

실제 입력 검사는 운영 상단 바의 `Ctrl+Alt+L`, 같은 창 토글, 초기 검색 포커스와 Escape, 실제 마우스 순서/폴더/카테고리 드래그·실행 오발 없음, 없는 대상 오류, 화살표/Enter와 통제된 Windows exe 실행을 확인했다. 해당 exe는 받은 argv를 로컬 검증 파일로 남겨 **공백·한글·따옴표·끝 역슬래시·`$(...)`·`&`**가 셸 명령으로 실행되지 않고 정확히 전달된 것을 확인했다. 프로세스 시작은 앱 초기화 완료를 뜻하지 않는다. 기존 팔레트 전역 키·빠른 패널도 실제 창으로 확인했다.

연결 화면은 주 `(0,0,2880,1800)`의 175%, 보조 `(-2160,194,2160,1440)`의 150%였다. 작업 영역 포함·음수 좌표·마우스와 다른 전경 창 화면 선호를 확인했다. 다른 배율이나 물리 재연결까지 통과로 확장하지 않는다.

초기 입력 시험의 창 검색 오류(작업 표시줄에 표시되지 않는 창을 Process.MainWindowTitle로 찾음)와 스크립트 핸들 범위 오류는 수정 후 다시 실행했다. 실제 DND에서 클릭 상태를 다음 Dispatcher 작업까지 보존해 실행 오발을 막았고, 운영 루트와 문서 루트의 같은 제목 창은 Win32 루트 속성으로 구분한다. 해당 과정의 실패 로그를 통과 자료에 섞지 않았다.

## 화면과 성능

[10개 실제 화면·dev.4 비교](visual-history.md#v300-dev4--dev6--gunt-launchpad). 개인 프로젝트·앱 인벤토리·장치 ID·배경 미디어를 제외한 공개용 루트를 사용했다. 초기 식별자 노출·창 바깥 픽셀 캡처는 폐기하고 최종 원본·메타데이터 없는 RGB export를 각각 검토했다.

같은 공개 카탈로그에서 3개 프로세스/21회 warm 비교: 내부 재표시 **90.257→17.450ms**, 작업 집합 **212.645→188.711MiB**. 첫 UIA 표시 **730.571→597.007ms**는 범위가 겹치고 변동이 크다. 예비 빌드의 +21.2% 첫 표시 퇴행도 [전체 측정](v30-performance.md#launchpad-dev4--dev6--2026-10-20)에 보존했다. OS 콜드 시작·키부터 합성까지·캐시 없는 전체 발견·장시간 CPU는 미측정이다.

## 주요 변경 파일

- `control-center/src/GUNT.ControlCenter/Models/LaunchpadModels.cs`
- `control-center/src/GUNT.ControlCenter/Services/ApplicationRegistry.cs`, `LaunchpadIcons.cs`, `CommandRegistry.cs`, `DeveloperWorkspaceService.cs`, `WorkspaceService.cs`
- `control-center/src/GUNT.ControlCenter/Views/LaunchpadWindow.cs`, `LaunchpadEditors.cs`, `LaunchpadMotion.cs`, `ApplicationAreas.cs`, `MainWindow.cs`, `UxPages.cs`, `DeveloperPopup.cs`
- `control-center/src/GUNT.ControlCenter/App.cs`, `ViewModels/MainViewModel.cs`, `GUNT.ControlCenter.csproj`
- `src/LaunchpadHotkey.cs`, `GuntDeveloperIntegration.cs`, `GuntBar.cs`
- `assets/branding/mascot/`, `config/examples/launchpad.example.json`, `config/theme.json`, `.gitignore`
- `scripts/build.ps1`, `build-control-center.ps1`, `verify-launchpad*.ps1`, `capture-launchpad.ps1`, `measure-launchpad.ps1`, `prepare-mascot-icons.py`, 소스·교차 빌드 검사 도구

## Git 체크포인트

- `82b7c5e` — dev.4 기반.
- `f7b47ce` — dev.5 실제 포즈와 테마.
- `957ea16` — dev.6 탐색 분리·명령 연결·재열기·실제 입력 검사.
- `ce77dcc` — 미지정 앱 아이콘 유지·되돌리기·공개 캡처 경계 보정.

사용자 `config/dock.json`은 스테이징하지 않았고 처음 기록한 파일 해시와 같음을 재확인한다. 원격 게시 결과는 작업 최종 보고에서 실제 push·원격 HEAD 확인 후 기록한다. main은 변경하지 않는다.

## 검증하지 않은 부분과 남은 시각 문제

긴 앱/프로젝트 이름과 문맥은 일부 말줄임이다. 툴팁·접근성 이름에서 전체 문맥을 제공하지만 큰 글꼴·키보드 사용자에게 충분한지는 추가 확인이 필요하다. 같은 이름의 다른 등록을 안전하게 구별하지 못하면 합치지 않으므로 브라우저가 중복으로 보일 수 있다. 선택형 투명도는 소스·저장 경로를 구현했지만 실제 투명 상태의 별도 시각 검토는 하지 않았다. 전체 카테고리 편집/키 기록/사용자 정의 항목의 모든 조합을 수동으로 완주한 것은 아니다.

## 남은 제한

- 모든 설치 앱을 실행한 것이 아니다. 실제 발견, 잘못된 경로/프로토콜 차단, 통제된 네이티브 검증 앱의 argv·실행 요청을 검증한다. 패키지 앱은 등록/파싱 지원과 개별 실행 검증을 구분한다.
- 새 포즈는 개발 프리뷰 파생 자산이다. 기존 승인 원본은 보존하며 신규 그림의 별도 사용자 승인까지 받은 것으로 표시하지 않는다.
- 100/125/200% 화면·재연결·전체 접근성·장시간 안정성은 미검증이다. 150/175%를 다른 배율 검증의 대체 근거로 쓰지 않는다.
- 첫 실행의 런타임·글꼴·아이콘 공급자 비용이 남아 있다. 따뜻한 UI 재열기 수치가 프로세스 콜드 시작이나 OS 합성 완료를 의미하지 않는다.
- 설치 패키지·main 병합·정식 3.0 출시는 이번 작업에 포함하지 않는다.
