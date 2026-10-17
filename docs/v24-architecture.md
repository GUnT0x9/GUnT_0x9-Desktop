# v2.4 구조와 유지보수

## 실행 구성

- `GUNT-Bar.exe`: 기존 WinForms AppBar를 확장했다. Fluent 아이콘·MSAA 버튼·키보드 포커스·한국어 툴팁·정확한 브랜드를 렌더링한다. Rainmeter 이동 종료 이벤트를 받아 위치를 저장한다.
- `Gunt.Sensors.dll`: 상단 바 내부 타이머에서 Windows PDH/DXGI, NetworkInterface, DriveInfo와 선택적 HWiNFO Registry를 수집한다. PowerShell을 주기적으로 실행하지 않는다. 위젯이 보이거나 제어 센터가 열려 있을 때 수집한다.
- `Gunt.Configuration.dll`: JSON 입력 검증, 버전 백업·원자적 저장, 모니터 식별·DPI·작업영역 배치를 공유한다. DLL 파일명과 어셈블리 이름을 동일하게 유지한다.
- Rainmeter: CPU/메모리 기본 측정과 텍스트·Shape 그래프를 담당한다. 원시 시각 표본은 Lua 메모리 안에만 보관한다. `Graph.lua`는 실제 스킨과 고정값 테스트가 공유한다.
- `GUNT.ControlCenter.exe`: .NET Framework 4.8 WPF. Models/Views/ViewModels/Services/Infrastructure 구조이며 JSON을 직접 수동 편집하지 않아도 v2.4 설정을 바꿀 수 있다. 서버·상주 서비스는 없다.

## 설정 원본

`config/theme.json`, `topbar.json`, `monitor.json`, `sensors.json`, `startup.json`이 각 설정 원본이다. Rainmeter Variables.inc는 update-monitor.ps1이 생성한다. Windhawk는 검증된 기존 포터블 INI 형식을 사용하며 제어 센터는 상태 읽기와 공식 관리 창 열기만 제공한다.

`Local\GUNTSettingsV24` 잠금과 임시 파일/Replace를 사용한다. 제어 센터는 열린 이후 다른 도구가 바꾼 필드를 감지하면 적용을 중단해 다시 읽도록 안내한다. 변경하지 않은 필드는 현재 값을 보존한다. 설정 검증과 적용 실패 복구는 실제 분리된 테스트 경로에서 검증했다.

## 그래프

- CPU: Rainmeter CPU 측정값 한 번을 캐시해 숫자와 최신 점을 함께 사용한다. 0–100% 고정. 평균은 현재 시간창 안의 **표본 평균**이다.
- 네트워크: 라우팅 테이블의 실제 인터페이스를 우선 선택하고 누적 바이트 차이를 Stopwatch 경과 시간으로 나눈다. 첫 표본·어댑터 전환·장기 일시정지 후 첫 값은 결측으로 처리한다.
- 30/60/120초 창, 1000/2000/5000ms 간격. `history.time`으로 x를 계산한다. 동적 네트워크 축은 원시 이력 전체에 적용한다. 최대 122표본이며 파일 누적 로깅은 하지 않는다.
- 그래프를 접어도 보이는 위젯의 숫자 표본은 유지한다. 위젯 전체 숨김에서는 Monitoring measure group과 내부 수집을 멈춘다. 제어 센터가 열려 있으면 진단을 위해 네이티브 수집은 유지한다. 긴 숨김 후 그래프를 새로 시작해 비측정 구간을 연결하지 않는다.

## 센서

HWiNFO VSB를 읽는다. 공급자 프로세스, Registry 키의 실제 LastWrite, Sensor/Label/Unit fingerprint와 유효 범위를 검사한다. 소비자가 읽은 시각을 공급자의 갱신 시각으로 쓰지 않는다. 유일하게 식별되는 CPU Package/GPU Temperature만 자동 연결하며, 나머지는 제어 센터에서 수동 연결한다. 결측은 null이다. 실제 VSB의 CPU DTS 코어·Arc GPU 코어·Samsung NVMe 온도를 연결했고 20회 대조 및 결측 처리 시험을 통과했다. HWiNFO 관리자 자동 시작을 새로 등록하지 않았다.

## 빌드

새 SDK 설치 없이 기존 Framework csc.exe로 빌드한다.

```powershell
.\scripts\build-configuration.ps1
.\scripts\build.ps1
.\scripts\build-control-center.ps1
```

빌드 실패 시 기존 실행 파일을 보존한다. 제어 센터는 빌드 전에 닫는다. Visual Studio용 `.sln`과 고전 `.csproj`도 포함했다. 이 환경에서 검증한 배포 경로는 위 csc 스크립트이며 SDK 방식 빌드는 별도 검증 대상이다.

## 모니터와 자동 복원

실제 모니터 DeviceID를 저장하고 작업영역 상대 DIP 좌표를 사용한다. 선택 화면이 없어지면 주 모니터에 임시 배치하되 사용자의 저장 프로필은 덮어쓰지 않는다. 전체 화면 연결 설정은 바꾸지 않는다.

시작 시 실제 C:/D: 물리 장치 매핑을 다시 읽고 현재 Lively 배경 선택을 채택한 다음 기존 구성 요소를 중복 없이 복원한다. HWiNFO는 별도 관리자 동의가 필요한 프로그램이므로 일반 자동 시작에 끼워 넣지 않는다.

HWiNFO의 LastWrite는 공급자 Registry 키 단위 갱신 시각이다. 키는 갱신되지만 특정 장치 값만 정지한 경우까지 개별 센서 정지를 보증하지 않는다. 정체성·단위·프로세스·키 갱신 검증과 구분한다.
