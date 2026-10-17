# v2.1 구현 기록

2026-10-15, WSL에서 로컬 Windows PowerShell 5.1과 Win32 API를 호출하여 실제 적용했습니다. 한글 경로를 보호하도록 PowerShell 소스에는 UTF-8 BOM, 실제 Rainmeter 설정에는 UTF-16LE를 사용했습니다.

## 기존 환경 보존

기존 포터블 프로그램, 고정 앱, Windows 작업 표시줄, 트레이, Flow Launcher 설정과 별도 Rainmeter 스킨을 보존했습니다. Droptop 등 다른 상단 바를 추가하지 않고 기존 C# AppBar를 확장했습니다. Windows 시스템 파일 패치·보안 기능 변경·개발 앱 설정 초기화는 하지 않았습니다.

상단 바 빌드는 임시 EXE가 먼저 성공한 후 기존 바에 WM_CLOSE를 보내 정상 종료하고 교체합니다. 모드 출처의 고정 커밋과 SHA256을 확인한 뒤 Windhawk 자체 컴파일러로 빌드합니다. Explorer 재시작 없이 기존 엔진의 설정 감지를 이용했습니다.

## 화면과 위젯

상단 바가 주 화면 상단 작업 영역을 예약합니다. 주 화면 175%에서 46→80px입니다. 최대화 창이 이 영역을 침범하지 않는 것을 검사합니다. WM_DISPLAYCHANGE·DPI 변경·Explorer 작업 표시줄 재생성을 처리합니다.

위젯은 현재 주 화면 오른쪽 여백·DPI를 사용해 `(2257,115)`에 배치하며 기본 크기는 `581×941px`입니다. 시각·데이터·레이아웃·설정 파일을 분리했습니다. CPU·메모리·디스크·네트워크는 Rainmeter 기본 측정, 배터리·IP는 지원 플러그인에서 읽습니다. GPU 카운터 전체 열거가 지연되어 중지했고 센서를 추가하지 않았습니다. GPU 수치를 가장하지 않고 숨깁니다.

Dock은 공식 DockLike의 자연 폭·중앙 정렬을 유지합니다. 고정 MaxWidth는 Windows 내부 오버플로 계산과 충돌해 제거했습니다. 25H2의 동적 작은 아이콘 모드에도 아이콘 44와 버튼 폭 56을 적용합니다. 네이티브 작업 표시줄 전체 높이는 패널76+하단14=90, 주 화면에서는158px입니다. 트레이는 구조를 분리한 채 같은 배경·테두리·모서리·하단 여백으로 맞췄습니다.

## 배경 및 시작 순서

지정한 이미지의 실제 원본은 2912×1501입니다. Pillow로 원본에서 각각 85·80·75% PNG를 생성했습니다. Windows 레지스트리와 SystemParametersInfo로80%·Fill을 적용했습니다.

로그인 Run → VBS → 유한 PowerShell 복원 →2초 지연→ 현재 모니터 배치→ 정적 배경→ 빠진 Rainmeter/Flow/Windhawk/GUNT-Bar만 시작→ Rainmeter 구성 활성화→ 로그 저장→ 종료합니다. 동일 복원은 Mutex로 중복 방지합니다. 모니터 해상도·배율·주 화면 자체를 강제로 변경하지 않습니다. 연결 변경 시 실제 다른 모니터 조합으로 검증하지 않았습니다.

라이브 패키지는 CSS16초 미세 확대·이동과 숨김/배터리 API 대응을 준비했습니다. Lively2.2.1.0 공식 배포본과 소스를 평가했으나 별도 설치는 실행하지 않았습니다. 엔진의 실제 중지 정책은 미적용·미검증이며 정적 배경을 기본값으로 유지합니다.

## 검증 근거와 공식 자료

실측 로그는 logs/v21-*.json, 모드 출처는 windhawk/*.source.json, 스크립트·화면 검증은 screenshots에 보관합니다. 메뉴는 WinForms의 MSAA 접근성 인터페이스로 실제 드롭다운을 열어 검사합니다. 해당 메뉴 항목은 Windows UI Automation에 노출되지 않아 UIA 결과만으로 기능을 판정하지 않습니다.

- [DockLike 공식 설정](https://github.com/ramensoftware/windows-11-taskbar-styling-guide/blob/main/Themes/DockLike/README.md)
- [Windhawk 공식 모드 소스](https://github.com/ramensoftware/windhawk-mods)
- [Rainmeter 측정 문서](https://docs.rainmeter.net/manual/measures/)
- [Lively 성능 정책](https://github.com/lively-community/lively/wiki/Performance)
- [요청한 배경 원본 페이지](https://www.wallpaperalchemy.com/ko/wallpaper/gojo-satoru-jujutsu-kaisen-4k-wallpaper-1310)

관리자 권한이 아니어서 Windows 복원 지점은 생성하지 않았습니다. 실제 재로그인·전체 원상복구·종료·재시작·실제 게임 검사는 작업을 보존하기 위해 실행하지 않았습니다.
