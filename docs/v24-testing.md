# v2.4 검증 기록

실행 기록과 실제 화면을 기준으로 한다. 스크립트 실행 성공만으로 모든 시각·하드웨어 기능을 검증 완료로 표시하지 않는다.

| 항목 | 결과 | 증거 |
|---|---|---|
| 사용자 폰트 5종 등록·영문 family 확인 | 통과 | logs/v24-font-verification.json |
| 브랜드 원문·5개 MSAA 이름·실제 위젯 토글 | 통과 | logs/v24-topbar-verification.json |
| Alt+Shift+G → Space 실제 동작 | 통과 | logs/v24-keyboard-verification.json |
| CPU 7개 고정값 실제 Shape 픽셀 | 통과 | logs/v24-graph-verification.json, screenshots/v24-graph-controlled.png |
| 네트워크 동적 축 전체 재투영 | 통과 | 실제 공통 Graph.lua assert와 테스트 표시 픽셀 |
| 그래프 4조합·202 DIP 회수 | 통과 | logs/v24-monitor-verification.json |
| 간단히/자세히 버튼 여백 클릭 | 통과 | 같은 모니터 검증 로그 |
| 제목 드래그·저장·새로고침 | 통과 | 같은 로그 |
| 3화면·175/150/100%·음수 좌표 | 통과 | logs/v24-display-verification.json |
| 실제 WPF 체크박스 적용·되돌림 | 통과 | logs/v24-control-center-verification.json |
| 적용 실패 자동 복구·잘못된 입력 차단 | 통과 | logs/v24-transaction-verification.json; 분리된 fixture, 실제 설정 비변경 |
| 중앙 기준 Dock·16개 앱·시계 초·Chrome 전환 | 통과 | logs/v23-dock-verification.json의 이번 실행 시각 |
| 트레이 휠 실제 CoreAudio·볼륨 복원 | 통과 | logs/v24-volume-verification.json |
| 시작 메뉴 | 부분 검증 | 실제 열림·DLL·화면은 통과; 검색 결과 자동 검증은 포커스 제한으로 미확인 |
| 탐색기 Styler | 실패 후 복구 | Taskbar Styler 재시작 요구 → 탐색기 Styler 비활성; 기본 어두운 탐색기는 재열림 통과 |
| 복구 후 탐색기 재열림·안내 없음 | 통과 | logs/v24-explorer-reopen.json |
| 초기 GUNT DLL 로딩 오류 | 수정 후 재검증 | 공통 DLL 어셈블리명/파일명 일치. 최근 health에서 신규 충돌 0 |
| HWiNFO 서명·관리자 실행 | 통과 | state/hwinfo-start.json, diagnostics/hwinfo-signature.ps1 |
| 실제 CPU/GPU/SSD 온도 | 통과 | logs/v24-sensor-verification.json, 실제 공급자 레지스트리 20회 대조 |
| 오래된 온도·인덱스 변경·잘못된 센서 연결 | 통과 | logs/v24-sensor-failure-verification.json |
| 시작 복원 직접 실행·중복 방지 | 통과 | logs/startup-restore.json |
| 집중 모드·수집 중단·이전 상태 복원 | 통과 | logs/v24-focus-verification.json |
| 실제 재로그인·재부팅 | 미시험 | 사용자 승인 없이 수행하지 않음 |
| 배터리·잠금·전체 화면 절전 | 부분 검증 | Lively 정책 보존 확인. 실제 배터리/잠금/게임 비교 미측정 |
| Thumbnail 드래그·AltTab 화면별 대상 | 부분 검증 | DLL 로드만 확인, 실제 다중 창 순서 비교 미시험 |
| v2.4 전체 롤백 실사용 | 미시험 | 파괴적인 전체 복원을 자동 시험하지 않음. 설정 트랜잭션 복구는 통과 |

동시에 키보드 입력을 보내는 GUI 시험은 포커스를 경쟁하므로 순차 실행한다. 최초 다중 화면 경계 검사는 비동기 Rainmeter 재배치 완료 전에 읽어 실패했고, 완료 대기 후 실제 경계·배율·새로고침을 모두 통과했다. 초기 Lua fixture는 SKIN 초기화 전 호출·한글 리터럴 경로 때문에 실패했으며 Initialize 내부 경로 해석으로 고쳤다.

실제 사용자 화면의 센서·프로필 상태를 임의로 바꾸지 않도록 시험 전 설정을 저장하고 finally에서 복원했다. 제어 센터가 보이는 캡처는 해당 창만 일시적으로 상단 배치한 후 원래 Z 순위로 되돌렸다.

최종 시각 검사에서 RAM 총량의 초기 0으로 인해 잘못된 백분율이 나오는 문제를 발견해 Total 측정 주기를 1로 맞추고, 총량이 준비되기 전에는 수집 대기로 표시하도록 수정했다. CPU·GPU·공유 SSD 온도가 보이는 최종 실제 화면은 screenshots/v24-sensors-live.png다.

## 모드 전환 깜빡임 및 모드 확장 후속 검증

`verify-monitor-hidden.ps1`: 현재 175% 화면에서 글자·양쪽 여백 6회 클릭, 저장 완료 6건, 간단히 501px/자세히 1575px, 위치 보존. WinEvent 감시의 창 이벤트 16건 중 가시 콘솔 0건. 초기 숨긴 미터 창 크기 문제와 자동 입력 도구의 조기 커서 복구 문제를 고친 뒤 통과했다.

Settings Styler 1.1의 실제 화면 전후 캡처·정확한 색상 픽셀 및 DLL을 확인했다. `verify-filesizes-v24.ps1`은 실제 탐색기 크기 셀의 ValuePattern을 읽어 1.00MiB/20.0MiB를 파일 바이트와 대조했다. 파일명에 MiB가 포함됐다는 사실을 크기 검사 통과로 계산하지 않는다. 용량 셀의 단위 앞 공백이 없다는 실제 동작에 맞춰 검사식을 수정한 후 통과했다.

`logs/v24-flicker-mods-health.json`: 활성 11개, 기존 Explorer PID 응답 유지, 새 관련 충돌·Styler 안내 0건. Dock 추가 검사 통과. 이 추가분의 실제 배터리 사용시간·재로그인·비활성 대비 성능 차이는 미시험이다.
