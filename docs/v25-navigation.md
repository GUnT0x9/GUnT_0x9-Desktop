# v2.5 탐색·설정 형식

## 호환 목적지

| 식별자 | 화면 | 주 기능 |
|---|---|---|
| overview | 개요 | 실제 상태, 모니터·배경·프로필·프로젝트 진입 |
| appearance | 외관 | 기존 범위의 한글/영문 글꼴·강조색 |
| dock | Dock | 높이, 아이콘, 버튼 폭, 패딩, 아래 여백, 컨트롤 간격, 모서리 |
| topbar | 상단 바 | 글꼴·빠른 동작 크기·가시성 |
| wallpaper | 배경화면 | 설치 갤러리·대상 화면·즐겨찾기·공식 CLI 요청 |
| projects | 프로젝트 | 추가·편집·보관 없는 목록 삭제·검색·실행 |
| profiles | 프로필 | 현재/이전·수동 변경·실제 차이·저장·적용·1회 복원 |
| displays | 디스플레이 | 기존 위젯 위치·잠금·자동/수동 배치·복원 |
| monitor | 시스템 모니터 | 독립 그래프·시간/간격·네트워크 축·실제 볼륨 |
| sensors | 하드웨어 센서 | 기존 HWiNFO 연결 안내·값·단위·시각·매핑 |
| windhawk | Windhawk | 실제 설치/활성/버전·호환성·공식 문서 |
| automation | 시작·자동화 | 로그인 복원·지연·명령 찾기 키 |
| diagnostics | 진단 및 복구 | 상태·지원 복구·내보내기·선택 설정 복원 |
| about | 프로그램 정보 | 공식 전체 로고·실제 설정 버전 |

`backup`은 `diagnostics`로 호환 연결합니다. 알 수 없는 목적지는 설명을 표시하며 개요로 조용히 우회하지 않습니다. 기존 `GUNT.ControlCenter.exe "<프로젝트 경로>" dock` 형식과 단일 인스턴스 요청을 유지합니다.

## 저장·충돌

`SettingField.Original`과 정규화한 `Value`를 비교합니다. 입력의 형식·범위 검사 후 현재 파일의 해당 키가 Original과 같은지 확인하고 기존 `GuntConfiguration.Save/Atomic`을 사용합니다. 구성 요소 내보내기와 저장 결과를 확인한 뒤에만 dirty를 지웁니다. 실패 복구는 자신이 바꾼 키만 대상으로 하며 외부 변경이 있는 키를 덮어쓰지 않습니다. 원래 JSON 설정 시스템을 유지합니다.

프로젝트 레코드와 즐겨찾기는 개인 데이터이며 `.gitignore`로 공개 저장소에서 제외합니다. 앱은 존재하지 않는 예제 프로젝트를 만들지 않습니다.

### `config/projects.json`

기본 직렬화는 PascalCase입니다. 상단 바는 PascalCase와 이전 camelCase를 모두 읽습니다.

```json
{"SchemaVersion":1,"Projects":[]}
```

레코드: `Id`, `Name`, `Directory`, `Ide`, `Terminal`, `RepositoryUrl`, `Pinned`, `Order`, `Commands`. 이름 1–80자, 기존 절대 경로만 저장하고 없는 폴더는 자동 생성하지 않습니다. 현재 UI는 VS Code/Windows Terminal을 사용하며 선택 명령 하나를 편집·직접 실행합니다. URL은 인증 정보 없는 GitHub HTTPS 저장소 주소입니다. 명령은 명시적 사용자 실행과 확인 뒤에만 실행됩니다. 비밀값 탐지 패턴은 모든 비밀을 보장하는 DLP가 아니므로 암호를 입력하지 않아야 합니다.

`state/project-recent.json`은 최근 실행 요청 시각입니다. 프로세스 실행 요청 뒤 기록하므로 편집기 내부 프로젝트 로딩 완료를 보증하지 않습니다.

### 사용자 프로필

`config/profiles/user-*.json`: schemaVersion 2, name, builtin=false, restoreScope=workspace, monitorVisible(bool), compact(bool), manualPaused(bool). 기존 기본 파일의 `settings.monitor.compact`도 읽습니다. 배경 패키지·화면 위치·Dock 전체를 사용자 프로필에 복사하지 않습니다. 직접 변경한 위 세 값이 다르면 ‘수동 변경 있음’입니다. Lively의 가림·배터리 자동 정책으로 실제 재생이 다를 수 있음을 표시합니다.

### UX·갤러리

- `config/ux.json`: schemaVersion=1, commandPaletteShortcut=`Ctrl+K`(기본)/`Ctrl+Shift+P`/`Disabled`.
- `config/wallpaper-gallery.json`: schemaVersion=1, favorites(설치 패키지 경로 배열). 개인 파일입니다.
- `config/monitor.json`: 기존 showCpuGraph(bool), showNetworkGraph(bool), graphHistorySeconds(30/60/120), updateMs(1000/2000/5000), networkScaleMode(dynamic/fixed)를 그대로 사용합니다.

## 지원하지 않는 Dock 조정

정렬은 자연 콘텐츠 중앙을 기준으로 오른쪽 컨트롤 Dock을 피하는 기존 구현입니다. 강제 최대 폭·임의 좌우 정렬·hover 확대는 안정적으로 적용할 수 없어 작동하는 슬라이더처럼 노출하지 않습니다. native 작업 표시줄의 실행 앱·고정·우클릭·미리보기·overflow는 Windows가 담당합니다.

## 키보드·창

Ctrl+S 적용, 설정한 키로 명령 찾기, 명령 찾기 Up/Down·Enter·Escape. 전역 키 등록 없음. 최소 780×560 DIP, 사이드바·내용 스크롤, 화면 밖 저장 좌표를 현재 작업 영역으로 제한합니다. 닫을 때 변경이 있으면 적용/버리기/계속 편집을 묻습니다. UI 작업은 백그라운드 Task로 실행하며 진행 중 닫기를 막습니다. 안전하게 중단할 수 없는 파일 적용의 임의 취소는 제공하지 않습니다.
