# 설정 안내

설정 변경 뒤 `Apply-GUNT.cmd`를 실행하세요. 기존 개발 앱 설정은 변경하지 않습니다. 크기는 별도 표시가 없으면 96DPI 기준 논리 픽셀입니다.

| 파일 | 실제 지원 항목 |
|---|---|
| config/theme.json | 패널·테두리·글자·보라색 강조, 수치 글꼴 선호도 |
| config/dock.json | 높이, 아이콘, 버튼 폭, 하단 여백, 가로 패딩, 모서리 |
| config/topbar.json | 높이, 메뉴·드롭다운·상태 글자 크기, 표시 메뉴, 상태 표시, 날짜·시간 형식 |
| config/monitor.json | 폭, 오른쪽 여백, 상단 간격, 모서리, 갱신 간격, 간단히 모드, CPU/RAM/디스크/네트워크/가동 시간/배터리/IP 표시 |
| config/wallpaper.json | brightness 75/80/85/100, 정적·선택형 라이브 사용 여부 |
| config/startup.json | 자동 실행 여부, 배경·배치 복원, 시작 지연·유한 재시도 |
| config/apps.json | 감지된 유효 앱 경로. Apply 때 다시 감지 |
| config/layout.json | 실행 시 생성한 실제 모니터 배치 기록 |

GPU·온도 센서는 연결되어 있지 않습니다. `showGpu`만 켜도 GPU 읽기가 추가되지 않으며 기본 숨김을 권장합니다. `hoverEnabled`와 `hoverDurationMs`는 향후 선택형 효과의 예약 항목으로 현재 적용하지 않습니다. 자동 숨김은 Windows 기본 작업 표시줄 설정을 사용하세요. 패널은 불투명하여 투명도 조절 항목을 제공하지 않습니다.

시각 색상은 위젯·메뉴 바·Dock에 반영됩니다. 알림 센터·시계 모드의 세부 색상은 `windhawk/*.settings.json`이며 해당 모드를 `scripts/install-optional-mod.ps1 모드ID -Enable`로 재적용해야 합니다. Flow Launcher 기존 테마는 별도 파일을 보존했습니다.

12시간은 `topbar.json`의 `timeFormat: "tt h:mm"`, 24시간은 `"HH:mm"`입니다. 작업 표시줄 시계는 `windhawk/taskbar-clock-customization.settings.json`의 `TimeFormat`을 별도로 조정합니다.

배경 표시 모드는 현재 Fill이며 mode를 Fit으로 바꾸는 것도 지원합니다. 중요한 얼굴은 보존되었으며 원본은 가로형이므로 주 화면 비율에 맞춰 좌우가 잘립니다. 스트레치는 사용하지 않습니다. 밝기 변경은 원본에서 만들어 둔 파일을 교체합니다.

라이브 배경의 pauseOn… 항목은 목표 정책을 기록한 값입니다. 현재 엔진은 설치하지 않았으며 이 값이 Lively 설정을 자동 변경하지 않습니다. 실제 엔진에서 전체 화면·다른 앱 포커스·배터리·절전 중지를 검증하고 `state/lively-validated.json`까지 준비하기 전에는 스크립트가 정적 배경을 유지합니다.

자동 실행 비활성화: startup.json의 enabled=false 후 Apply 실행. 다시 켤 때 true 후 Apply 실행. Start-GUNT.cmd는 사용자가 직접 요청한 수동 복원이므로 자동 실행 비활성화 상태에서도 동작합니다.

위젯의 ‘간단히’는 CPU·RAM 중심으로 줄이며 ‘자세히’로 복원합니다. 새로고침 화살표는 실제 Rainmeter 갱신입니다. 상단 바 알림·시계는 Windows의 실제 알림·달력을 열고 ‘소리’는 볼륨 믹서를 여는 버튼입니다. 소리 버튼에 실시간 음량 수치를 표시하지는 않습니다.
