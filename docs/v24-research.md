# v2.4 조사

실측: Windows 11 Home 25H2 26200.9711, Samsung 960XHA, Core Ultra 5 226V 8C/8T, Intel Arc 130V, 15.54GiB RAM. 화면 2880×1800/175%(0,0), 1920×1080/100%(442,-1080), 2160×1440/150%(2880,163). Rainmeter 4.5.28.3936, Windhawk 1.7.3, Flow Launcher 2.1.4, Lively 2.2.1.0.

상단 바는 WinForms AppBar, 위젯은 Rainmeter와 Gunt.Sensors.dll이다. Control Center는 아직 없다. 기존 문서는 v2.1/2.2 설명이 남아 있으므로 실제 설정과 로드 DLL을 우선한다. 기존 활성 모드 4개는 실제 로드까지 확인했다.

C/D는 동일 Samsung MZVL2512HCJQ-00B NVMe SSD의 파티션이다. E는 USB 이동식 볼륨이므로 기본 숨김이다. GPU 이름의 8GB는 전용 VRAM 용량으로 해석하지 않는다. DXGI의 전용/공유 메모리를 구분한다.

발견 결함: 시간 대신 그래프 폭에 종속된 CPU 이력, 네트워크 축 변경 시 과거 정규화 기준 불일치, 그래프 숨김 여백, 자동 오른쪽 위 배치, 잘못된 !Pause/!Unpause 명령, 미연결 온도 센서, v2.1을 대상으로 하는 전체 롤백. Lua 런타임 UTF-16 LE와 이름 충돌 수정은 유지한다.

실제 Lively 배경은 조사 도중 Medusae → Music TV로 사용자가 변경했다. Gojo로 기록된 config가 사용자의 현재 라이브 선택을 덮어쓰지 않게 한다. 시작·복구 시 엔진의 최신 정상 배정을 우선 보존한다.

공식 출처: https://windhawk.net/ · https://github.com/ramensoftware/windhawk-mods/tree/e3976aca5c5f511878e4beefdc2e9ef65cd5565b/mods · https://s-core.co.kr/company/font/ · https://docs.rainmeter.net/manual/meters/shape/ · https://docs.rainmeter.net/manual/skins/rainmeter-section/ · https://docs.rainmeter.net/tips/hwinfo/ · https://www.hwinfo.com/version-history/ · https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/tag/v0.9.6
