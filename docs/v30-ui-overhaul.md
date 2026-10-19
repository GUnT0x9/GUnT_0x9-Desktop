# 3.0 UI 기반 구현 결과

개발 식별자: **3.0.0-dev.1**. 전체 UI 리뉴얼 또는 안정판 3.0 수용 기준을 모두 충족한 상태가 아니다. 실제 Windows 빌드·실행·화면 검토·175% DPI·성능 비교가 남아 있다.

## 보존

v2.6 `3ae33e2`와 v2.5 `main` 이력을 보존하고 `feat/v30-ui-foundation`에서 작업한다. 프로젝트·세션·명령·자동화의 실행 서비스와 저장 형식을 유지한다. Rainmeter·Lively·Dock 자동 적용 보류·Explorer Styler 비활성 정책은 변경하지 않는다. 사용자 Dock 미커밋 변경은 커밋하지 않는다. 설정 초기화·현재 배경 변경·Explorer 재시작·원격 게시를 수행하지 않았다.

## 구현 범위

- 셸: 기존 19개 목적지를 작업공간/데스크톱/시스템/도구/정보로 그룹화. 작은 워드마크·기존 마스코트 창 아이콘 보존. 고정 제목, 재활용 탐색 목록, 변경이 있을 때 Apply/Discard 표시. Undo와 실제 상태 영역은 유지.
- 개발 세팅: 넓은 본문 1040 DIP 이상에서 루트/목록/상세 3열. 중간 폭은 루트 설정을 접이식으로 제공하고 목록/상세 2열. 본문 620 DIP 미만은 상세를 목록 아래로 이동. 검색·정렬·재탐색·즐겨찾기·기존 실행 버튼·외부 도구 등록을 보존. Enter/더블클릭은 기존 기본 AI CLI를 요청한다. 프로젝트별 기본값 편집은 기존 창을 사용한다.
- 세션: 프리셋과 실행 미리보기 분할. 작은 폭은 수직 배치. 실행 단계 목록, 선택 단계의 동작/사용/등록 도구 편집, 기존 순서 조정·추가·삭제 유지. 단계별 실제 요청 결과를 목록으로 표시하고 상세 이력은 접는다.
- 팔레트: 폭 680 DIP, 검색부터 시작, 결과 목록·대상 프로젝트와 WSL·키 힌트. 기존 검색 규칙을 유지하며 열린 창의 데이터를 재사용한다. 실행 시 대상 프로젝트 변경을 확인한다.
- 빠른 패널: 폭 360 DIP, 현재 프로젝트·개발 동작·데스크톱 구분. 공통 리소스, Escape·외부 클릭·진행 중 닫기 보호 유지. 화면 작업 영역 제한.
- 자동화: 현재 enabled 상태에 맞는 문구와 조건/추가 조건/동작/고급 섹션. 실행 이력 접기. 새 조건·엔진 추가 없음.
- 설정·센서·진단: 기존 입력 종류를 유지하며 공통 스타일 적용. 상태/센서 조회를 비동기로 수행하고 사용 불가를 실제 값으로 표현.
- 배경: 데이터 기반 가상화 목록, 검색·즐겨찾기 필터, 선택 유지, 축소 썸네일 비동기 로딩과 제한 캐시. 다열 썸네일 그리드의 가상화는 이번 구현에 포함하지 않는다.
- Rainmeter: 측정·그래프·레이아웃·샘플 간격을 변경하지 않았다. 자체 스킨의 추가 시각 보정은 실기 화면 검토 후 진행한다.

## 변경 파일

| 파일 | 목적 |
|---|---|
| `config/theme.json` | 개발 버전 식별 |
| `control-center/src/GUNT.ControlCenter/Views/UxStyles.cs` | 공유 UxTheme, 입력/버튼/목록/문맥 메뉴 스타일 |
| `control-center/src/GUNT.ControlCenter/Views/MainWindow.cs` | 셸·그룹 탐색·고정 제목·계측·프로세스 정리 |
| `control-center/src/GUNT.ControlCenter/Views/UxShell.cs` | 변경 시 적용/버리기 노출 |
| `control-center/src/GUNT.ControlCenter/Views/DeveloperPages.cs` | 프로젝트 브라우저·문맥 메뉴·응답형 배치·선택 보호 |
| `control-center/src/GUNT.ControlCenter/Views/DevelopmentSessionsPage.cs` | 단계 편집·실행 결과·규칙 구조 |
| `control-center/src/GUNT.ControlCenter/Views/DeveloperPopup.cs` | 팔레트·빠른 패널·대상 표시·공통 스타일 |
| `control-center/src/GUNT.ControlCenter/Views/UxPages.cs` | 비동기 상태 조회·가상화 갤러리·캐시 |
| `control-center/src/GUNT.ControlCenter/Models/DeveloperModels.cs` | 저장에서 제외한 세션 표시 요약 |
| `control-center/src/GUNT.ControlCenter/Services/CommandRegistry.cs` | 기존 검색의 스냅샷 오버로드 |
| `control-center/src/GUNT.ControlCenter/Services/WorkspaceService.cs` | 예외 시에도 Process 해제 |
| `control-center/src/GUNT.ControlCenter/Infrastructure/UiPerformance.cs` | 선택적 로컬 계측 |
| `src/GuntBar.cs` | 툴팁·아이콘·레이아웃·메뉴·타이머 수명 |
| `scripts/check-v30-source.py` | 페이지 보존·XML/문자 검사 |
| `scripts/check-v30-search.py` | 실제 메서드 검색 회귀 10개 |
| `scripts/compile-v30-linux.py` | 임시 교차 컴파일 |
| `scripts/verify-v30-ui.ps1` | Windows 캡처·반복 표본 수집 준비 |
| `README.md`, `CHANGELOG.md`, `docs/v30-*.md` | 구현과 검증 한계 기록 |

## 확인 결과와 미완료

| 항목 | 상태 |
|---|---|
| 기준 브랜치·과거 이력 보존 | 확인 |
| 기존 페이지 19개 보존 | 소스 검사 통과 |
| 공통 스타일·셸·주요 개발 화면 변경 | 소스 구현 |
| 검색 동작 10개 | 독립 알고리즘 실행 검사 통과 |
| .NET Framework 4.8/C# 5 호환 | 네 구성 요소 교차 컴파일 통과 |
| Windows 수집 스크립트 PowerShell 구문 | Linux PowerShell 7.4.6 파서 통과 (실행 아님) |
| WPF 템플릿 실제 로딩·Windows 배포 빌드 | 미검증 |
| 실제 실행 동작·설정 보존 회귀 | 미검증, 기존 서비스 경로 보존만 확인 |
| 화면 캡처·175% DPI·실제 키보드 UX | 차단: Windows 실행 연결 불가 |
| 시작/탐색/CPU/메모리 전후 중앙값 | 미측정 |
| 기존 모든 페이지의 완전한 시각 통일 | 미완료: 공유 스타일 외 개별 보정 필요 |

## 남은 보정

Windows 접근이 가능해지면 실제 화면부터 캡처하고 WPF 템플릿 로딩 오류 여부를 확인한다. 프로젝트 행의 기술 종류/Git/최근 사용을 모두 목록 열로 보여주는 것, 루트 트리 확장, 행 내부 즐겨찾기, 세션 주 편집 영역에 단계 속성 완전 통합, Rainmeter 자체 스킨 보정, 가상화 가능한 갤러리 다열 배치를 추가 검토한다. 현재는 해당 정보 중 일부를 선택 상세·기존 설정창에서 제공한다. 전체 화면이 완성됐다고 표시하지 않는다.

[디자인 시스템](v30-ui-design-system.md) · [소스 점검](v30-ui-audit.md) · [성능](v30-performance.md) · [실제 화면 검증](v30-screenshots.md) · [로드맵](v30-roadmap.md)
