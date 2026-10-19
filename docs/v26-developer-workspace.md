# GUnT_0x9 Desktop v2.6 — Developer Workspace

기존 v2.5를 `main`의 [582d3eb](https://github.com/GUnT0x9/GUnT_0x9-Desktop/commit/582d3eba57e09618c988b9465f2c23c78d6ffa1f)로 먼저 게시하고, `feat/v26-developer-workspace`에서 이어 개발했습니다. WinForms 상단 바·WPF/.NET Framework 4.8·기존 JSON·프로필·Rainmeter·Lively를 그대로 사용합니다. Dock 자동 적용 보류와 File Explorer Styler 비활성 상태는 해제하지 않았습니다.

## 기본 흐름

1. **개발 세팅 → 프로젝트 루트 추가**로 실제 폴더를 선택합니다. 등록 해제는 목록만 바꾸며 폴더를 삭제하지 않습니다.
2. 탐색 깊이·숨김 폴더를 선택하고 **다시 탐색**합니다. 기본 직접 하위 1단계, 최대 5단계·방문 폴더 5,000개이며 재분석 지점·junction·일부 의존성 폴더는 건너뜁니다. 전체 드라이브를 무제한 재귀 검색하지 않습니다.
3. 프로젝트를 선택합니다. 발견한 폴더의 선택 시 기존 프로젝트 목록에 등록하며, 기존 항목은 경로로 중복을 방지합니다.
4. **WSL 환경 → 배포판 새로고침 → 선택 환경 도구 확인**으로 실제 환경을 확인합니다. 배포판·패키지 설치는 하지 않습니다.
5. **전역 개발 기본값** 또는 **프로젝트 개발 설정**에서 배포판·일반 계정·터미널 호스트·기본 AI CLI·개발 세션·선택적 작업공간 프로필을 지정합니다.
6. **기본 AI CLI**, **WSL + Codex**, **WSL + OpenCode**, **VS Code** 등을 실행합니다. 선택한 폴더를 사용할 수 없으면 다른 폴더에서 시작하지 않고 오류로 중단합니다.

![개발 세팅 — 최초 빈 목록 상태](images/v26-developer-setup.png)

공개 캡처는 개인 프로젝트 경로를 노출하지 않는 실제 최초 빈 목록 상태입니다. 검증용 프로그램·폴더 실행은 별도로 실제 수행했으며 개인 실행 로그는 Git에서 제외했습니다.

## 탐색·프로젝트 정보

- 이름/전체 경로 검색, 이름순·최근 요청순, 즐겨찾기, 현재 프로젝트 저장.
- 파일 존재로 Node.js·pnpm·Python·Rust·Go·.NET·Docker·Git을 식별합니다. React 등 구체적 프레임워크를 추측하지 않습니다. 일반 폴더도 지원합니다.
- Git은 프로젝트 선택 또는 명시적 새로고침 때만 조회하며 15초 캐시를 사용합니다. 폴더 필터 입력으로 같은 프로젝트를 반복 조회하거나 설정을 반복 저장하지 않습니다.
- `git-bash.exe`가 등록된 PC에서도 실제 `git.exe`를 찾아 분기·변경/미추적 파일·저장소 루트를 읽습니다. `--no-optional-locks`, `core.fsmonitor=false`, `core.untrackedCache=false`를 사용하고 하위 모듈 내부 상태는 재귀 검사하지 않습니다. 실패 시 0개로 성공 표시하지 않습니다.
- Git commit/push/pull/reset/clean은 앱이 자동 실행하지 않습니다.

## WSL·터미널

- 공식 `wsl --list --quiet`, `wslpath -a -u`, `--distribution`, `--user`, `--cd`, `--exec`를 사용합니다. 목록의 UTF-16과 Linux 출력 UTF-8을 구분합니다.
- Windows 경로를 문자열 치환으로 만들지 않습니다. 배포판 안에서 변환하고 실제 폴더 접근과 계정을 확인합니다.
- root로 개발 도구를 실행하지 않습니다. 등록된 기본 UID에 해당하는 일반 계정을 우선 사용하고, 기본 계정이 일반 사용자가 아니면 유일한 일반 계정을 선택하거나 명시적 일반 계정 지정을 요구합니다. `/etc/passwd`의 일반 사용자 목록은 WSL 파일 인터페이스로 읽으며 기본 계정 설정을 변경하지 않습니다.
- 도구 조회는 Linux 홈에서 사용자 인터랙티브 셸의 PATH를 읽습니다. 실제 실행 파일이 있는지 확인하고 `--version`으로 확인합니다. Windows에 설치된 CLI를 WSL CLI로 간주하지 않습니다.
- Windows Terminal 또는 CMD의 **보이는 대화형 콘솔**을 사용합니다. WSL 프로세스의 stdin/stdout을 파이프로 돌리지 않습니다.
- 한글·공백·괄호·따옴표·`& $ ; %`가 셸 또는 Windows Terminal 구분자로 해석되지 않게 Windows 인수·POSIX 리터럴·UTF-16 실행 데이터 경계를 구분합니다. CLI 실행 데이터의 Base64는 인코딩이며 비밀 암호화 수단이 아닙니다.
- Codex/OpenCode의 승인·sandbox·인증 옵션을 우회하지 않습니다. 셸 초기화 파일·배포판·사용자 계정을 수정하지 않습니다.
- VS Code는 명시적으로 새 창에 정확한 폴더를 엽니다. Remote WSL 확장 자동 설치·지원 추정은 하지 않습니다.

## 설정과 데이터 형식

개인 파일은 모두 `.gitignore`에 있습니다.

| 파일 | 역할 |
|---|---|
| config/projects.json | 기존 목록 확장. 새 저장은 SchemaVersion 2, 버전 1도 읽기 지원. ProjectEntry.Developer에 선택적 지정값 |
| config/developer.json | 루트, ScanDepth, ShowHidden, Defaults, SelectedProjectId, 추가 도구 |
| config/development-sessions.json | 편집한 기본·사용자 세션 |
| config/commands.json | 사용자 별칭·즐겨찾기·최근 명령 |
| config/smart-automation.json | 명시적으로 사용한 규칙 |
| state/project-developer-recent.json | 프로젝트별 최근 CLI·배포판·프리셋·시각. 터미널 내용 없음 |
| state/development-*.json | 제한된 실행 이력·마지막 실행 구성·중복 시작 방지 |
| state/developer-hotkey.json | 실제 전역 키 등록 결과 |

기본값 상속은 비어 있는 프로젝트 지정값에 적용합니다. 프로젝트 경로 편집은 ID와 Developer 지정값을 유지합니다. 기본 AI CLI는 실제 기본 실행 버튼과 AI Coding 템플릿에서 사용합니다. 사용자 추가 도구는 검증한 `.exe`만 저장하며 설치하지 않습니다.

새 설정은 기존 `GuntConfiguration.Atomic`을 사용합니다. 입력 검증·버전 백업·저장 확인과 여러 화면 간 수정 충돌 감지를 추가했습니다. 외부 수정이 감지되면 덮어쓰지 않고 다시 읽도록 알립니다. 별도 DB·트랜잭션 엔진은 만들지 않았습니다. 암호·토큰·환경변수 비밀을 입력하지 마세요.

프로젝트 버전 2는 구형 v2.5 작성기가 새 Developer 필드를 조용히 없애지 못하도록 구형 프로젝트 편집을 거부하게 합니다. 전체 데스크톱 동작을 막는 변경은 아닙니다.

## 관련 문서

[개발 세션](v26-development-sessions.md) · [명령·빠른 패널](v26-command-palette.md) · [자동화](v26-automation.md) · [실제 시험·제한](v26-testing.md) · [복구](v26-recovery.md)

## 공식 근거

[Microsoft WSL 기본 명령](https://learn.microsoft.com/en-us/windows/wsl/basic-commands), [Windows Terminal 명령 인수](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments), [OpenAI Codex CLI](https://learn.chatgpt.com/docs/codex/cli), [OpenCode CLI](https://opencode.ai/docs/cli/). 실제 설치된 도구에 대해 조회·대화형 실행을 별도로 검증했으며 버전·계정·개인 경로는 공개 문서에 싣지 않았습니다.

## 주요 변경 소스

- `Models/DeveloperModels.cs`, 기존 `WorkspaceModels.cs`: 개발 기본값·프로젝트 확장·세션/명령/규칙 모델.
- `Services/DeveloperWorkspaceService.cs`, `DevelopmentSessions.cs`, `CommandRegistry.cs`, `SmartAutomation.cs`: 공유 실행·조건 처리.
- `Views/DeveloperPages.cs`, `DevelopmentSessionsPage.cs`, `CommandsPage.cs`, `DeveloperPopup.cs`, 기존 MainWindow/App: 실제 목적지·빠른 창·미저장 보호 유지.
- `src/GuntDeveloperIntegration.cs`, `GuntBar.cs`, `Configuration.cs`: 메뉴·전역 단축키·기존 타이머의 자동화 관측.
- `scripts/build.ps1`, `apply-v24-settings.ps1`, `rollback-v26-developer.ps1`, `verify-v26-*.ps1`: 빌드/설정 반영·복구·검사.

개발 UI 소스의 전체 위치는 `control-center/src/GUNT.ControlCenter/` 아래입니다.
