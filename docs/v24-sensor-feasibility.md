# 센서 실행 가능성

CPU Core Ultra5 226V(Lunar Lake), Intel Arc130V iGPU, Samsung MZVL2512HCJQ-00B NVMe SSD(C/D 공유). 일반 사용자 ACPI·Get-StorageReliabilityCounter 접근은 거부됐다. 미지원 여부와 권한 부족을 구분한다. 현재 HWiNFO/LibreHardwareMonitor 설치·VSB 매핑은 없다.

주 제공자 HWiNFO8.54(개인 비상업적 사용), 대체 LibreHardwareMonitor0.9.6. 공식 LHM소스에 LunarLake0xBD 및 iGPU IGCL 코드가 있으나 실제 노트북 센서는 별도 검증한다. HWiNFO의 Sensors-only/Gadget Registry 방식,2000ms를 우선 사용한다. Shared Memory불필요. 두 엔진 상시 동시 실행 금지.

순서: CPU Package·코어 요약→GPU 실제 온도→SSD→CPU package power→노출되는 GPU전력·팬. 각 SensorN/LabelN/ValueRawN과 단위·장치 매핑을 기록하고 인덱스만 믿지 않는다. SSD온도는 물리장치당1회, CPU온도로 GPU온도를 대신하지 않는다.

값은 nullable, unit/provider/device/source/observedAt/quality(valid/missing/stale/unknown)를 갖는다. Registry변경과 제공자 상태를 확인한다. 소비자 읽은 시각을 센서 시각으로 만들지 않는다.10초 이상 갱신 확인 불가 시 현재값에서 제외. 안정된 값에서도 Registry변경이 발생하는지 시험한다. 제공자 화면과30표본 대조, 종료·정지·매핑 변경 검사. 미측정 온도0°C 금지.

권한 상승·드라이버 설치는 별도 승인 후 수행한다. Defender/UAC/메모리 무결성/취약 드라이버 차단을 끄지 않는다. 승인/지원이 없으면 온도 미연결을 명확히 남기고 다른 구현을 계속한다. 제공자 부하는 실제로 따로 측정한다.

출처: https://www.hwinfo.com/download/ · https://www.hwinfo.com/version-history/ · https://docs.rainmeter.net/tips/hwinfo/ · https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/tag/v0.9.6

## 실제 연결 결과 (2026-10-16)

HWiNFO 8.54-6090의 관리자 실행과 사용자의 가젯 설정 후 실제 값을 확인했다. HKCU/HKLM에 같은 센서가 복제되므로 Sensor/Label/Unit 식별값을 기준으로 합쳐 최신 사용자 사본을 우선한다.

| 화면 값 | 실제 장치·라벨 | 가젯 인덱스 | 검증 표본 범위 |
|---|---|---|---|
| CPU 온도 | CPU [#0]: Intel Core Ultra 5 226V: DTS / 코어 온도 | 0 | 53–65°C |
| GPU 온도 | iGPU [#0]: Intel Arc 130V / GPU Core 온도 | 6 | 50–52°C |
| 물리 SSD 온도 | S.M.A.R.T.: SAMSUNG MZVL2512HCJQ-00B [...] [C:, D:] / 디스크 온도 | 5 | 49–50°C |

이는 해당 검증 시점의 20회 표본 범위이며 정상 범위 보장이나 고정값이 아니다. CPU는 **코어 온도**이며 패키지 온도로 이름을 바꾸지 않는다. CPU package power, GPU power, fan speed는 실제 보고가 없어 표시하지 않는다. PCH 온도는 다른 장치이므로 CPU 온도로 자동 연결하지 않는다. `아니요`로 보고되는 열 경보와 `%`인 NPU 사용량도 °C 센서로 취급하지 않는다.

매핑은 config/sensors.json에 전체 장치 이름·라벨·단위·fingerprint와 SSD의 DiskUniqueId를 보존한다. 레지스트리 인덱스는 진단 정보이며 값 연결의 유일한 근거가 아니다. C:와 D:는 eui.002538B841B143C4 장치 하나에 속하므로 SSD 온도를 한 번 표시한다.

`verify-v24-sensors.ps1`은 실제 공급자 레지스트리와 20회 대조했다. 샘플 시각 차이에 따른 온도 변화는 허용하되 장치·라벨·단위는 정확히 일치해야 한다. `verify-v24-sensor-failures.ps1`은 분리된 설정 경로에서 시계 의존성만 120초 앞으로 주입해 오래된 값이 null이 되는지, 인덱스 999가 돼도 식별값으로 연결되는지, 틀린 식별값을 다른 온도로 대체하지 않는지 확인했다. Windows 시계·실제 HWiNFO 값은 바꾸지 않았다.

공급자 GUI 셀과 동시 프레임 비교, 배터리 장시간 센서 부하, 실제 로그온의 관리자 센서 시작은 별도 검증 대상이다.
