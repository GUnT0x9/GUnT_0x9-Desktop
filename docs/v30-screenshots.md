# 3.0 실제 화면 검증 기록

현재 검증은 아래 [dev.3 추가 기록](#dev3--2026-10-20)을 참조한다. dev.2의 날짜·개수·환경은 당시 기록으로 보존했다.

## 공개 README용 화면

[버전별 시각 기록](visual-history.md)에 개인정보를 포함하지 않는 **새 실제 앱 캡처**를 공개했다. dev.1 보존 빌드 2개와 dev.2 빌드 4개를 별도 문서용 예제 설정으로 다시 실행했다. 공개 export는 `docs/images/releases/v3.0/dev.1/`, `dev.2/`에 있고 [manifest](images/releases/manifest.json)에 출처·버전·해시·시각 검토를 기록한다.

이 이미지는 아래 개인 환경 검증 원본 19개를 그대로 Git에 넣은 것이 아니다. 예제 Git 저장소의 실제 파일을 조회하며 WSL 미지정·사용 기록 없음·기존 표시 제한을 유지한다. 별도 RGB 내보내기·메타데이터 제거·폭 제한 후 최종 이미지를 다시 열어 검토했다. 개인 정보가 처음부터 없어 픽셀 가림은 필요하지 않았다. 타사 배경 썸네일이 포함된 갤러리 원본은 공개하지 않았다.

공개 이미지는 제품 설명용이며 새 성능 측정이나 다른 DPI 검증을 뜻하지 않는다. [유지관리 절차](readme-maintenance.md)를 따른다.

## 이번 실행의 증거

dev.1과 dev.2를 **실제 Windows WPF 앱으로 빌드·실행·캡처**했다. 이전 dev.1 보고의 “실행 불가/캡처 0개” 상태는 현재 결과가 아니다. PE 자동 해석 대신 WSL `/init` 명시 호출로 Windows GUI를 실행했다.

실제 연결 화면은 1개, 2880×1800, 175%(DPI 168)다. 아래는 이번 작업 중 캡처한 화면을 직접 열어 확인한 결과다. 이미지 생성·가상 HTML·과거 v2.x 이미지로 대체하지 않았다.

| 순서 | 화면 | 상태와 검토 |
|---|---|---|
| 1 | 개요 | 실제 구성 요소 상태·정렬·한글·스크롤 확인 |
| 2 | 개발 세팅 | 이름·유형·Git·최근 사용·행 내부 즐겨찾기·선택 상세 확인 |
| 3 | 개발 세션 | 본문 단계 편집·사용/이동/제거·분리된 미리보기 확인 |
| 4 | WSL 환경 | 읽기 전용 환경 선택 흐름·설명·입력 크기 확인 |
| 5 | 명령 팔레트 | 검색·결과·문맥 미리보기·포커스 확인 |
| 6 | 빠른 패널 | 360 DIP 도구 창·현재 프로젝트·동작 그룹 확인 |
| 7 | 스마트 자동화 | 실제 빈 목록 안내·동작·접힌 이력 확인 |
| 8 | 배경 갤러리 | 실제 로컬 16개 패키지·비율·선택·화면 배치 확인 |
| 9 | 시스템 모니터 설정 | 단위·선택 입력·한글·긴 폼 스크롤 확인 |
| 10 | 진단 및 복구 | 실제 상태 행·복구 동작·스크롤 확인 |

개발 세팅·세션·갤러리는 780×560, 1180×800, 1500×900 DIP 요청 크기로 추가 캡처했다. 작은 창은 상세와 폼을 세로로 전환하고 스크롤로 접근한다. 실제 작업 영역보다 큰 요청은 작업 영역에 제한되며 로그에 실제 크기를 남긴다.

## 전후 비교

- dev.1: `screenshots/v30-dev1/`의 주요 화면 10개.
- dev.2: `screenshots/v30-dev2-final/`의 주요 화면 10개와 창 크기별 9개, 총 19개 캡처. 최종 빌드에서 다시 수집했다.
- 차이: 검은 접기 제목, 빈 검색 입력, 큰 빈 목록, 별도 단계 속성 편집, 긴 행 갤러리를 공통 글자색·검색 안내·축소 목록·본문 편집·적응형 타일로 변경.
- 배경 적용·영상 재생을 요청하지 않고 기존 메타데이터와 썸네일만 사용했다.

스크린샷과 UIA 원자료는 개인 경로·로컬 배경 썸네일을 포함할 수 있어 Git에서 제외한다. 위 경로는 검증한 로컬 산출물 위치이며 공개 저장소에 이미지가 포함돼 있다는 뜻이 아니다. 원본을 꾸미거나 개인정보를 가린 이미지로 바꿔 검증 증거라고 주장하지 않는다.

## 실행 명령

아래 `C:\src\GUNT-Desktop`은 설명용 경로이며 실제 체크아웃 경로로 바꾼다.

실제 Windows 대화형 세션:

```powershell
Set-Location 'C:\src\GUNT-Desktop'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-control-center.ps1
powershell.exe -MTA -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-v30-ui.ps1 -Label dev2-final -Samples 3 -IncludeSizes
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-v30-interactions.ps1
powershell.exe -MTA -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-v30-desktop-integration.ps1
```

WSL에서 Windows PE 자동 실행이 등록되지 않은 경우:

```bash
/init /mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe -MTA -NoProfile -ExecutionPolicy Bypass -File 'C:\src\GUNT-Desktop\scripts\verify-v30-ui.ps1' -Label dev2-final -Samples 3 -IncludeSizes
```

외부 UIA 클라이언트와 실제 WPF 컨트롤을 만드는 STA 검사를 분리한다. 수집 도구는 기존 제어 센터가 열려 있으면 중단하고 직접 연 창만 정상 종료한다. 창 위치 기록을 복원하며 실패한 캡처를 자동으로 시각 통과 처리하지 않는다.

## 입력·통합 검증

실제 WPF 컨트롤의 격리 데이터 검사 29개와 OS 키 입력·기존 WinForms 상단 바 목적지 검사 15개를 통과했다. Ctrl+K 검색 포커스, 방향키 이동, 별칭 결과, 빈 결과 Enter, Escape와 소유 창 포커스 복귀를 확인했다. 상단 바의 개발 메뉴에서 dev.2 개발 세팅으로 연결했다. 기존 전역 단축키를 재등록하거나 상단 바를 재시작하지 않았다.

키보드·통합 캡처는 `screenshots/enhancement-v30-dev2-palette-keyboard.png`, `screenshots/enhancement-v30-dev2-topbar.png`, `screenshots/enhancement-v30-dev2-topbar-destination.png`다. 결과는 `logs/v30-dev2-desktop-integration.json`에 남긴다. GDI/USER 핸들 3회 관찰은 장시간 누수 검증을 대체하지 않는다.

## 남은 범위

100/125/150/200% 실제 배율, 물리 다중 화면·재연결, 고대비·스크린리더, 모든 외부 CLI 인증·작업 준비 완료는 이번 검증 범위가 아니다. 최소 창에서 폼 전체가 첫 화면 안에 들어간다고 주장하지 않는다. 자동화의 실제 사용자 데이터는 빈 목록이었으며 모든 규칙 조합의 발동을 시각 검증한 것은 아니다.

## dev.3 — 2026-10-20

WSL2에서 `/init`으로 Windows 네이티브 빌드·GUI를 실행했다. 현재 OS 연결 화면은 **1개·2880×1800·DPI 168(175%)**다. 갤러리에 저장된 복수 화면 배치 기록을 실제 연결 모니터 수로 해석하지 않는다.

- 개인 환경 캡처: 개요·개발 세팅·세션·WSL·자동화·갤러리·모니터 설정·진단·팔레트·빠른 패널 10개. `screenshots/v30-dev3-final/`의 주요 10개와 개발/세션/갤러리 크기별 9개, 합계 19개.
- 추가 실제 확인: 센서·프로필·디스플레이·Windhawk·정보. `screenshots/v30-dev3-extra/` (5페이지와 중복 팝업 2개). 센서 결측/비활성 동작, 한글·공통 리소스·스크롤을 직접 검토.
- 780×560, 1180×800, 1500×900 DIP 요청. 큰 요청은 작업 영역에 제한되며 실제 픽셀 크기는 로컬 수집 JSON에 보존. 확대/축소로 다른 DPI를 검증했다고 하지 않는다.
- 보조창: 같은 작은 소유 창에서 dev.2/dev.3 프로젝트 개발 설정을 열어 저장·취소와 본문 스크롤 비교. 독립 공개용 상태이며 변경/저장하지 않음.
- 실제 Rainmeter 위젯 전후: `screenshots/v30-dev3-monitor-20261020-082315/`. 스타일 속성만 적용한 최종 검사에서 위치·크기 및 6개 보호 파일 해시 일치. 앞선 전체 Layout 교체 시 숨긴 좌표 보정이 풀린 시도는 원본 복구 후 제외했다.

개인 환경 19개/추가 페이지는 `284d783` 빌드의 기록이다. 이후 보조창 오류 영역을 수정한 `60af707` 최종 빌드에서 WPF 42개와 공개용 개발/세션/팔레트/편집창 4개를 다시 검증·캡처했다. 공개 manifest의 캡처 빌드 SHA-256은 `7755c7284c9dcc9c5034e81d71bcd5530337008a41d2e092628b647c7d304499`다. 이후 `78ddf11`은 센서 요청의 완료 오해를 막는 문구만 바꿨으며 공개 화면에 해당 문구가 나오지 않는다.

최종 공개 화면을 직접 열어 행/버튼/본문 정렬, 선택·포커스, 하단 키 안내, 한국어와 작은 창의 주요 동작을 확인했다. 작은 창의 모든 설정을 한 번에 보인다고 하지 않으며 전체 Tab 순서·스크린리더는 미검증이다. WPF 42개와 실제 키 입력/상단 바 15개 검사가 통과했다. 상단 바 핸들 3표본은 GDI 81/USER 49로 같았지만 장시간 누수 검증은 아니다.

공개한 새 dev.3 이미지 4개와 보존 dev.2 비교 2개는 `docs/images/releases/v3.0/`에 있다. 별도 예제 Git·개발 설정, 빈 실행 이력, WSL 미지정을 사용했다. RGB 재인코딩/메타데이터 제거 후 최종 6개를 다시 검토했다. 가릴 개인정보가 없어 픽셀 가림은 필요하지 않았다. 개인 갤러리·장치/경로를 담은 원본은 공개하지 않는다. [전후 비교](visual-history.md#v300-dev3--ui-polish--optimization) · [출처와 해시](images/releases/manifest.json).

재현 시 기존 명령에 `-Label dev3-final`, 상호작용/통합 명령에 `-ResultLabel dev3`을 지정하면 과거 결과 파일을 덮어쓰지 않는다. 공개 캡처는 [유지관리 옵션](readme-maintenance.md#dev3에서-확장한-캡처-옵션)을 따른다.

`78ddf11` 이후의 Dispatcher 수정 빌드에서 실제 센서 새로고침을 읽기 전용으로 요청하고 “센서 목록을 새로 요청했습니다.” 표시를 추가 확인했다. `logs/v30-dev3-sensor-request.json`, `screenshots/enhancement-v30-dev3-sensors-final-request.png`는 로컬 증거이며 공개하지 않는다. 요청과 완료를 혼동하지 않도록 하는 문구 보정이다.

센서 첫 화면 직접 실행에서 UI 컨텍스트 부재를 재현해 완료 처리를 명시적 Dispatcher로 보정했다. 이후 `scripts/verify-v30-sensor-startup.ps1 -Label dev3-final`에서 별도 이동 IPC 없이 직접 시작·WPF 컨트롤 준비·읽기 요청/피드백을 통과했다. 최신 증거는 `logs/v30-dev3-final-sensor-startup.json`과 `screenshots/enhancement-v30-dev3-final-sensors-direct-start.png`이며 공개 원본에 넣지 않는다. 마지막 WPF 42개 재검사도 같은 수정 바이너리에서 통과했다.
