# v2.4 UI 사양

사용자 선택은 상세 개발 텔레메트리다. 대안인 간결한 계측 패널(332DIP, 32–40DIP 그래프) 대신 폭 360DIP, CPU 64DIP·네트워크 56DIP 그래프를 채택한다. 상세 높이는 콘텐츠로 계산하고 대략 520–680DIP를 목표로 한다. 간단히 모드는 필수 CPU/RAM/GPU/네트워크만 표시한다.

색: panel #0E0E12, surface #15151C, border #23232B, text #F4F4F5, muted #A1A1AA, accent #A78BFA, upload #67E8F9. 패널 반경6DIP, 버튼4DIP, 여백16DIP, 구역12DIP·행6DIP. 테두리1물리px. RAM은 숫자 우선, 저장공간은2DIP 보정선, 그래프는 채우기 없이 얇은 선. 글로우·중첩 카드·그라데이션 없음.

상단 바42DIP, Fluent 20 Regular(Pulse/Image/Weather Moon/Desktop/Settings), 아이콘20DIP·클릭36DIP·간격8DIP, 한국어 툴팁13DIP·500ms. AccessibleName·Tab·Enter/Space·포커스 표시. 기존 메뉴 동작 유지. 브랜드는 정확히 𝓖𝓤𝓷𝓣_𝟎𝔁𝟗, Cambria Math 20DIP, 대체 Segoe UI Symbol. 메뉴 ID GUNT와 표시 문구 분리.

모니터 상단 제목만 네이티브 DragMargins로 이동, 버튼 제외. 이동 종료 시 저장하고 화면 변경·새로고침이 위치를 덮어쓰지 않는다. 모니터 식별자와 작업영역 기준 DIP 좌표를 저장하며 음수 전역좌표와 서로 다른 DPI를 지원한다. 분리된 화면은 임시 대체하되 원래 위치를 보존한다.

showCpuGraph/showNetworkGraph bool=true, graphHistorySeconds int=60(30/60/120), updateMs int=2000(1000/2000/5000), graphStyle=lineWithGuides(line도 지원), networkScaleMode=dynamic(fixed도 지원), networkFixedMaxBytesPerSecond=10485760. graphUpdateInterval은 updateMs의 UI 이름이며 중복 저장하지 않는다. 토글 시 빈 공간 회수, 숫자 유지. 보이는 동안 원시 버퍼 수집 유지, 위젯 숨김 시 불필요한 작업 중단.

CPU는0–100% 고정축, 숫자와 마지막 점이 같은 표본. 네트워크는 raw bytes/s와 timestamp를 유지하고 현재 구간 최고값을 담는2의 거듭제곱 축으로 전체 점 재투영. 시각 기준 Shape Path 사용, 숨김 구간 연결 금지. 30/60/120초 지원.

## 실제 화면 높이 대응

GPU·배터리를 모두 표시해도 세 모니터에 맞도록 헤더 52 DIP·하단 패딩 8 DIP로 조정했다. 기본 CPU/네트워크 그래프는 64/56 DIP다. 해당 화면 작업영역이 부족할 때 CPU는 최소 48 DIP, 네트워크는 최소 40 DIP까지 높이만 줄인다. 사용자 그래프 표시 설정·시간창·DPI는 바꾸지 않으며 세로 축 값은 실제 그려지는 높이에 맞춰 계산한다. 기본 그래프를 둘 다 접을 때 회수하는 높이는 202 DIP이고, 높이 제한을 받은 화면에서는 축소한 만큼 회수량도 줄어든다. 글자 크기와 전역 디스플레이 설정은 강제로 축소하지 않는다.
