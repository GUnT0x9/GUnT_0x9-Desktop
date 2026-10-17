## GUNT Desktop v2.1 작업 결과

2026년10월15일, 기존 프로젝트를 이어서 실제 Windows에 적용했습니다. 현재 기본값은 **밝기80% 정적 배경**입니다. 라이브 배경 재생이 완료되었다고 표시하지 않습니다.

![최종 적용 화면](../screenshots/v21-final-primary.png)

### 1. 시스템 환경

Windows11 Home25H2 빌드26200.9711, Core Ultra5 226V(논리 프로세서8개), RAM16GB, Intel Arc130V(드라이버32.0.101.8626)입니다. Windows 레지스트리의 ProductName은 호환용 Windows10 표기를 유지하지만 실제 빌드는 Windows11입니다.

주 화면2880×1800·175%·(0,0), 보조2160×1440·150%·(2880,163), 보조1920×1080·100%·(472,-1080)를 확인했습니다. WSL에서 로컬 Windows PowerShell·Win32 API를 통해 적용했습니다. 런타임은 Windows에서 독립 실행됩니다.

### 2. 현재 상태 요약

기존 포터블 Rainmeter·Flow Launcher·Windhawk와 C# AppBar가 동작하고 있었습니다. 원래 검정 배경, 34px 영어 상단 바, 높이52·아이콘32 Dock, 작은 SYSTEM 위젯을 사용했습니다. 기존 개발 도구·작업·고정 앱을 보존해 확장했습니다.

인계 재점검 때 시작 복원에서 실행 파일이 누락되어도 최종 오류 목록이 비어 있을 수 있는 문제를 찾았습니다. 종료 상태와 프로젝트 소유 경로를 함께 검사하도록 수정했습니다. 별도 임시 환경에서4개 누락을 실제 재현해 오류 기록을 검증했습니다.

### 3. 적용된 변경 사항

정확한 배경 이미지와 밝기 변형4종, 큰 Dock·아이콘, 동일한 트레이 표면, 한국어 시스템 모니터,46px 한국어 기능 메뉴, 한국어 네이티브 시계, 실제 알림·달력 테마를 적용했습니다. 시작 복원·정적 대안·백업·원상복구·검증·한국어 안내를 추가했습니다. 상단 바는 기존 구현을 확장해 하나만 실행합니다.

### 4. 배경화면

[요청한 원본 페이지](https://www.wallpaperalchemy.com/ko/wallpaper/gojo-satoru-jujutsu-kaisen-4k-wallpaper-1310)의 [공식 다운로드 이미지](https://server.wallpaperalchemy.com/storage/wallpapers/1310/gojo-satoru-jujutsu-kaisen-4k-wallpaper.jpg)를 사용했습니다. 실제 해상도는2912×1501입니다. 자동 페이지 요청은 차단되었으나 해당 원본 이미지 다운로드는 성공했습니다.

`wallpaper/gojo-original.jpg`와 `gojo-85.png`, `gojo-80.png`, `gojo-75.png`를 보존했습니다. 원본을 기준으로 각각 Pillow 밝기만 조정했고 블러·추가 오버레이·재색칠·재생성은 하지 않았습니다. 현재80%·Fill 적용을 Windows 레지스트리와 실제 화면에서 확인했습니다. 얼굴과 주요 색을 보존하며 상단 바·위젯·Dock 가독성을 확인했습니다. [밝기 비교](../wallpaper/brightness-comparison.jpg), 출처·해시·이전 배경과 모드는 [메타데이터](../wallpaper/wallpaper-settings.json)에 있습니다.

### 5. 애니메이션 배경화면 설정

**현재 라이브 배경은 비활성화, 엔진은 미설치입니다.** Lively Wallpaper2.2.1.0 공식 배포본과 성능 정책을 평가했고 설치 파일을 보관했습니다. 별도 엔진·런타임 설치와 추가 메모리 사용을 도입하지 않고 정적 배경을 기본값으로 선택했습니다.

선택형 `wallpaper/gojo-live/lively` 패키지는16초 루프·0.6% 크기 변화·최대0.12% 미세 이동, 무음, 외부 요청 없음으로 준비했습니다. 웹 페이지 숨김과 지원되는 배터리 API에 따른 정지를 포함합니다. 실제 전체 화면·화면 가림·세션 잠금·절전 판정은 엔진에서 검증해야 합니다. config의 pauseOn… 값은 목표 정책 기록이며 엔진에 적용된 설정이 아닙니다.

준비·검증 기록이 없거나 실행 준비 오류가 발생하면 정적 배경으로 복귀하도록 스크립트를 보강했습니다. 현재 비활성·엔진 없음 경로의 정적 대안 실행은 통과했습니다. 엔진 실행 실패 주입·재생·루프 부드러움·배터리 절약·일시 정지·GPU 비용은 미검증입니다.

### 6. Dock 및 시스템 트레이

Dock76·아이콘44·버튼 폭56·패딩18·모서리22·하단 여백14 논리 픽셀을 적용했습니다. 주 화면에서 아이콘 실제77×77px, 중앙 Dock 영역은 `(966,1642,948,133)`으로 확인했습니다. 네이티브 작업 표시줄 전체 높이는 하단 여백을 포함해158px입니다.

Windows25H2가 작은 아이콘 모드로 바꿀 때도 같은44 크기를 사용합니다. 강제 MaxWidth는 Windows 오버플로 계산과 충돌하여 제거하고 공식 DockLike의 자연 폭을 사용했습니다. Dock 오른쪽1914px와 트레이 왼쪽1996px 사이 간격을 확인했습니다. 기존 고정 앱·실행 표시·오버플로·기본 트레이를 유지했습니다. 고정된 작업 관리자 버튼을 실제 클릭해 실행 후 닫는 검사가 통과했습니다. 호버 확대는 비활성입니다.

### 7. 시스템 모니터

한국어 제목, CPU 수치·그래프, 메모리 사용량·비율·막대, C: 사용·전체·여유 공간, 자동 단위 송수신·그래프·어댑터, 가동 시간을 표시합니다. 실제 Rainmeter 측정을 사용하며 기본 갱신은2000ms입니다.

폭332 논리 픽셀, 주 화면 실제581×941px, 위치(2257,115)입니다. 원본·측정·스타일·레이아웃·변수를 분리했습니다. 새로고침과 간단히/자세히가 실제 동작하며 축소→복원 검사를 통과했습니다. JetBrains Mono 미설치로 Consolas를 사용합니다. GPU·온도 센서는 연결하지 않아 기본 숨김이며 임의 값을 표시하지 않습니다. 선택형 배터리·IP는 제공하나 기본 비표시입니다.

### 8. 상단 바 및 한국어 메뉴

46 논리 픽셀·실제80px 높이의 기존 C# AppBar를 사용합니다.5개 메뉴와 실제 드롭다운을 MSAA로 열어 확인했고 시스템 모니터 숨김·표시 명령도 호출했습니다. 최대화 검증 창의 상단80px가 메뉴 바와 겹치지 않았습니다.

- GUNT: 배경·테마·Rainmeter·Dock 설정, 레이아웃, 백업/복구 안내, 프로그램 정보.
- 작업공간: 유효한 홈·프로젝트·다운로드·문서·기존 프로젝트와 폴더 선택.
- 개발: 감지된 Windows Terminal·PowerShell·WSL·VS Code·Git·Docker. GitHub Desktop은 미감지로 제외.
- 도구: 작업 관리자·설정·장치 관리자·네트워크·볼륨 믹서·캡처·시스템 정보·업데이트.
- 시스템: 모니터 표시/숨김/갱신·화면·시작 앱·잠금·절전·재시작·종료. 절전과 종료·재시작에는 확인 창을 사용합니다.

오른쪽 연결 상태·전원/배터리·한국어 날짜·시간과 실제 알림 접근을 제공합니다. ‘소리’는 볼륨 믹서 단축 버튼이며 실시간 음량 수치는 아닙니다. 모든 앱·전원 명령을 자동 실행해 검사하지는 않았습니다.

### 9. Windows UI 연동

한국어 작업 표시줄 시계를 적용했습니다. 실제 Windows 알림 센터와 달력의 어두운 배경·절제한 테두리·보라색 오늘 선택을 화면에서 확인했습니다. 가짜 달력이나 트레이는 만들지 않았습니다.

시작 메뉴·파일 탐색기 스타일 모드와 Dock Animation Plus는 공식 소스·설정 구조를 평가했으나 활성화하지 않았습니다. 기존 Windows 다크 모드와 탐색기 기능을 유지했습니다. 별도 볼륨 제어·플라이아웃 위치 모드를 추가하지 않았습니다. [호환성 기록](../windhawk/compatibility-report.md)에 결정을 기록했습니다.

### 10. 시작 시 자동 복원

HKCU Run의 `GUNTDesktop` → `scripts/start-hidden.vbs` → `startup-restore.ps1`입니다.2초 지연 후 현재 주 화면·DPI·배치를 읽고 정적 배경, 빠진 Rainmeter·Flow·Windhawk·상단 바, 위젯 구성을 복원한 뒤 종료합니다. Mutex와 경로 확인으로 중복 실행을 피하고 유한 재시도·최종 상태·누락 로그를 남깁니다.

실제 VBS를 직접 실행해 종료한 상단 바가 다시 실행되고 구성 요소가 각각 하나씩 응답함을 확인했습니다. 별도 임시 환경의 누락 검사도 통과했습니다. 모니터 해상도·배율·주 화면 지정은 강제 변경하지 않습니다. 현재 배치에서 위치를 검증했고 실제 케이블 변경·재부팅·재로그인은 미검증입니다.

자동 실행을 끄려면 `config/startup.json`의 enabled=false 후 Apply-GUNT.cmd를 실행하세요. 수동 Start-GUNT.cmd는 계속 사용할 수 있습니다.

### 11. 설치 및 수정된 프로그램 / 모드

| 구성 | 버전 | 변경 |
|---|---|---|
| Rainmeter |4.5.28.3936| 기존 포터블, GUNT 스킨 수정 |
| Flow Launcher |2.1.4| 기존 포터블·설정 보존, 실제 VS Code 검색 통과 |
| Windhawk |1.7.3| 기존 포터블,4개 모드 활성 |
| Windows11 Taskbar Styler |1.10| 기존 모드, Dock 표면 변경 |
| Taskbar height and icon size |1.3.10| 기존 모드, 크기 변경 |
| Taskbar Clock Customization |1.8.1| 새 모드 추가·한국어 설정 |
| Windows11 Notification Center Styler |1.7| 새 모드 추가·패널 설정 |
| GUNT-Bar |2.1 프로젝트 소스| 기존 AppBar 확장·로컬 빌드 |

모드는 공식 소스의 고정 커밋·SHA256을 확인해 Windhawk 컴파일러로 빌드했습니다. 출처·실제 활성 DLL은 [mods.json](../windhawk/mods.json)과 개별 source.json에 있습니다. Lively는 다운로드만 했으며 설치하지 않았습니다.

### 12. 변경된 파일

주요 파일은 config의 theme·dock·topbar·monitor·wallpaper·startup·layout JSON, `src/GuntBar.cs`, `rainmeter/GUNT-System-Monitor`, `wallpaper` 자산과 라이브 패키지, `windhawk/*.settings.json`·mods.json·호환성 기록입니다.

실행 도구: inspect·backup·install·apply·apply-wallpaper·install-dock·install-optional-mod·update-monitor·startup-restore·live-wallpaper·verify·verify-native-ui·verify-dock·verify-launcher·verify-startup·verify-recovery·measure-performance·rollback.ps1 및3개 CMD입니다. [설정 안내](customization.md), [구현](implementation.md), [복구](recovery.md), [인계](handoff.md), README·CHANGELOG를 정리했습니다. 변경 전 소스는 backups/source-revisions에 보존합니다.

### 13. 검증 결과

- **통과:** PowerShell 전체 구문, 배경80%·Fill·자산 해시, Dock 중앙·아이콘77px·트레이 간격·고정 앱 실행, 위젯 실제 표시·위치·간단히 전환, 한국어5개 드롭다운·모니터 메뉴 명령, 최대화 겹침 방지,4개 Windhawk 모드 로드, 실제 알림·달력 화면, Flow 실제 VS Code 검색·테마·단축키, VBS 복구·중복 방지·누락 오류 기록, 정적 배경 대안, 백업19개 대상·레지스트리7개 내보내기.
- **실패:** 최종 수행한 정상 동작 검사에서 남은 실패 없음. 누락 주입 검사의 오류는 의도한 실패 경로이며 감지 검사는 통과.
- **부분 검증:** 자동 시작은 동일 VBS 직접 실행까지, 모니터 대응은 현재3화면 배치까지. 새 Windows 업데이트와 다른 모니터 구성은 보장하지 않음.
- **미검사:** 실제 재로그인·재부팅·게임·화면 잠금·종료/재시작, 모든 창 그룹·우클릭 조합, 전체 원상복구. 라이브 엔진 재생·실제 중지·배터리·GPU 비용.
- **권한상 제약:** Windows 복원 지점은 일반 사용자 권한으로 생성하지 않았음. 권한 상승은 수행하지 않음.

증거는 logs/v21-verification.json, v21-dock-verification.json, v21-startup-verification.json, v21-startup-missing-verification.json, v21-notification-verification.json, v21-monitor-fallback-verification.json, v21-recovery-verification.json, launcher-verification.json과 화면 파일입니다.

### 14. 성능 분석

14:06:22에 기록한30.01초 표본에서 구성 요소4개의 CPU 합계는 전체8개 논리 프로세서 기준0.085%, 작업 집합 합계174.2MiB, 전용 메모리252.6MiB였습니다.

| 프로세스 | CPU % | 작업 집합 MiB | 전용 MiB |
|---|---:|---:|---:|
| Flow Launcher |0.000|101.9|208.9|
| GUNT-Bar |0.020|46.4|27.8|
| Rainmeter |0.065|22.1|13.0|
| Windhawk |0.000|3.8|2.9|

Explorer는 별도로2.701%·작업 집합227MiB였습니다. 이 수치는 사용자 셸 작업과 모드를 포함하므로 모드의 추가 비용으로 단정할 수 없습니다. 다른 앱을 종료하지 않은 실제 작업 환경 표본이며 공유 메모리 합산 중복과 페이징이 있을 수 있습니다. GPU 전용 비용·라이브 배경 사용량은 측정하지 않았습니다. [측정 원본](../logs/v21-performance.json)을 보존합니다.

### 15. 남은 제한 사항

라이브 엔진과 실제 절전·전체 화면·배터리 중지 정책은 미적용입니다. GPU·CPU/GPU 온도·WSL 상태 센서는 추가하지 않았습니다. 호버 확대·시작 메뉴/탐색기 추가 스타일은 비활성입니다. 음량은 기본 트레이에서 확인합니다. 글꼴은 설치된 대체 글꼴입니다. 실제 재부팅과 새 모니터 조합은 검증하지 않았습니다.

### 16. 원상복구 방법

`Rollback-GUNT.cmd` 또는 `scripts/rollback.ps1`은 v2.1 직전 GUNT 백업 `backups/v21-20261015-133116`을 복원합니다. 현재 파일은 복구 직전 별도 보존하고 이전 배경·모드·위젯·상단 바·GUNT 자동 실행 값을 되돌립니다. 관련 없는 사용자 파일·개발 앱·WSL 배포판은 제거하지 않습니다.

최초 Windows 환경까지는 `rollback.ps1 -OriginalWindows`를 사용합니다. 최초 백업은 `backups/20261015-110531`입니다. 백업 경로와 파일을 검사했으며 원하는 새 환경을 유지하기 위해 전체 복구는 실행하지 않았습니다. 자세한 절차는 [복구 안내](recovery.md)에 있습니다.

### 17. 다음 추천 작업

다음 실제 로그인 후 자동 배치와 앱 복원 상태를 확인하는 것이 우선입니다. 라이브 효과를 사용하려면 별도 Lively 설치 후 전체 화면·다른 앱 포커스·배터리·절전 중지를 실제 검증하고 정적 배경보다 이점이 있는지 판단하세요. 현재 정적 기본값으로 일상 사용이 가능합니다.
