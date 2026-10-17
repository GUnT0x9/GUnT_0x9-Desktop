# v2.4 구성 요소 복구

프로젝트 경로에서 일반 PowerShell을 사용한다. Explorer·Windows를 재시작하지 않는다. 실행 전 열려 있는 GUNT 제어 센터의 변경을 저장한다.

## 체크포인트

`state/pre-v24-checkpoint.json`은 업그레이드 이전 전체 상태와 SHA256을 가리킨다. `typography-v24`, `monitor-v24`, `windhawk-v24`, `control-center-v24`, `final-v24` 단계도 같은 방식이다. 신규 설정 변경은 `backups/settings-v24/`, PowerShell 명령 변경은 `backups/settings-*`, 소스는 `backups/source-revisions/`에 남는다.

선택한 구성 요소만 복원한다.

```powershell
.\scripts\rollback-v24.ps1 -Component monitor -Checkpoint pre-v24
.\scripts\rollback-v24.ps1 -Component windhawk -Checkpoint pre-v24
.\scripts\rollback-v24.ps1 -Component startup -Checkpoint pre-v24
.\scripts\rollback-v24.ps1 -Component topbar -Checkpoint pre-v24
.\scripts\rollback-v24.ps1 -Component control-center -Checkpoint pre-v24
```

- monitor: 해당 INI/Lua·설정과 내보내기 스크립트 복원 후 새로고침.
- windhawk: 신규 모드 비활성화 및 해당 단계의 모드 INI 복원. 기존 설치 프로그램은 삭제하지 않는다.
- startup: GUNT 복원 스크립트·설정과 `HKCU/.../Run`의 **GUNTDesktop 한 항목만** 복원한다.
- topbar: 프로젝트 소유 바·제어 센터만 닫고 백업 실행 파일과 의존 DLL·소스를 복원한다.
- control-center: 앱을 닫고 백업이 있으면 복원한다. pre-v24에는 앱이 없으므로 실행 파일을 복구 직전 백업 폴더로 이동해 비활성화한다.

복구 직전 파일도 `backups/before-component-rollback-*`에 남는다. 백업 파일 SHA256이 맞지 않으면 복원하지 않는다. 실제 사용자 전체 설정 복원은 자동 시험하지 않았다. 기존 `rollback.ps1`은 v2.1 전체 복원용이므로 v2.4 작업 복구에 사용하지 않는다.

## 글꼴 복구

```powershell
.\scripts\rollback-v24.ps1 -Component fonts
```

GUNT 앱을 닫고 GUNT 텍스트를 Segoe UI Variable로 전환한 뒤 `state/v24-fonts.json`에 기록한 **GUNT 이름의 현재 사용자 글꼴 등록만** 되돌린다. 기존 파일이 있었다면 보존한 파일을 복원한다. 사용 중인 새 파일은 강제 삭제하지 않으며 결과를 `logs/v24-font-rollback.json`에 기록한다. Windows 기본 글꼴과 아이콘 글꼴 등록은 건드리지 않는다. 다시 설치하려면 `install-fonts.ps1` 실행 후 GUNT 상단 바를 다시 연다.

## 설정 적용 실패

제어 센터는 입력 검사 → 설정별 버전 백업 → 원자적 저장 → Rainmeter 내보내기·대상 창 확인 → 저장 결과 비교를 수행한다. 실패하면 변경 전 설정을 원자적으로 복원하고 다시 적용한다. 복구까지 실패하면 오류를 표시한다. 오류는 `logs/control-center-errors.log`, 실제 복원 단계는 `logs/events.jsonl` 및 해당 단계 로그를 확인한다.

## 온도 연결

HWiNFO는 개인 비상업적 사용으로 준비했다. 센서 상태 창을 닫으면 측정이 중단될 수 있으므로 최소화한다. 센서 설정의 가젯 지원과 **실제 °C 행** 보고를 켠다. 제어 센터 → 하드웨어 센서에서 목록 갱신 후 장치·라벨·단위·시각을 확인하고 연결한다. 공급자가 없거나 레지스트리가 오래되면 온도를 숨긴다. 관리자 HWiNFO 자동 시작은 별도 승인을 받은 예약 작업만 사용한다. 등록 상태는 state/hwinfo-startup.json을 확인한다. 등록하지 않은 경우 수동 실행이 필요하다. UAC를 끄거나 보안 예외를 만들지 않는다.

## HWiNFO 로그인 작업 해제

별도 승인을 받아 등록된 경우 작업 스케줄러에서 `GUNT-HWiNFO-Sensors-v24` 한 작업만 사용 안 함으로 바꾸거나, 승인된 관리자 PowerShell에서 아래 명령을 실행한다.

```powershell
Unregister-ScheduledTask -TaskName 'GUNT-HWiNFO-Sensors-v24' -Confirm:$false
```

다른 HWiNFO 작업이나 기존 Windows 시작 항목을 지우지 않는다. 기존 동명 작업이 있었다면 backups/hwinfo-startup-*의 XML로 복구할 수 있다. UAC·보안 옵션은 바꾸지 않는다.

## 모니터 깜빡임 수정·모드 2개 추가 직전으로 복구

`pre-v24-flicker-mods` 체크포인트(2026-10-16 14:48, 351개 파일 해시) 사용. 새 모드만 해제할 때는 `set-v24-mod.ps1 -Id windows-11-settings-styler -Disable`, `-Id explorer-details-better-file-sizes -Disable`을 실행한다. `rollback-v24.ps1 -Component windhawk -Checkpoint pre-v24-flicker-mods`는 신규 2개를 해제하고 직전 INI를 복원한다. 모니터만 돌릴 경우 `-Component monitor`를 사용하되 콘솔 깜빡임 수정도 되돌아간다. 자동 전체 복구는 실행하지 않았다. [후속 적용 보고서](v24-flicker-mods-report.md) 참조.
