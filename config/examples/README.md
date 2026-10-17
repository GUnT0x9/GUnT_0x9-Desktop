# PC별 설정 예시

실제 `apps.json`, `runtime.json`, `monitor.json`, `sensors.json`, `wallpaper.json`은 사용자 경로·화면 ID·센서 매핑을 포함하므로 Git에서 제외한다. 이 폴더의 값은 참고용이며 자동 적용하지 않는다.

- `{projectRoot}`와 `{userProfile}`은 **설명용 자리표시자**다. 현재 프로그램이 자동 치환하지 않으므로 실제 PC 경로로 바꾸어야 한다.
- Rainmeter·Windhawk·Flow Launcher·Lively 설치 경로를 먼저 확인한다.
- 모니터는 주 화면 자동 배치 기본값, 센서는 비어 있는 매핑으로 제공한다. 센서 값을 다른 PC에 그대로 복사하지 않는다.
- 기존 백업 파일이 없는 새 PC에서 `rollback-*`나 예전 `apply.ps1`을 곧바로 실행하지 않는다.
- 이 저장소는 실제 사용 환경의 소스 스냅샷이다. 새 PC 일괄 설치 패키지의 검증은 아직 하지 않았다.
