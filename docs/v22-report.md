# GUNT Desktop v2.2 작업 기록

2026-10-15, v2.1 적용 상태에서 시각 결함 수정과 미완성 기능 마무리를 진행했다. 동작 중인 구성은 보존하고 결함 부분만 수정했다.

## 1. Dock 재설계

원인:
- Search(SearchboxTaskbarMode=3)와 작업 보기(ShowTaskViewButton=1)가 켜져 있어 Dock에 시스템 버튼이 노출되고 있었다.
- `config/dock-styles.json`의 TaskView collapse 규칙이 없었다.

변경:
- `HKCU\...\Search\SearchboxTaskbarMode=0`, `HKCU\...\Explorer\Advanced\ShowTaskViewButton=0` (Set-GuntValue 저널 등록, 롤백 가능).
- `config/dock-styles.json`에 `Taskbar.TaskViewButton` Visibility=Collapsed 추가.
- `scripts/install-dock.ps1` 재실행으로 Windhawk ini 재생성 (DLL 재컴파일 없음).
- 사용자 고정 핀은 건드리지 않았다.

검증: `screenshots/v22-dock-fix.png`에서 Search·작업 보기 제거, 아이콘 겹침 해소 확인.

## 2. 시스템 트레이 수정

원인: `dock-styles.json`의 InnerTextBlock 글꼴 강제 지정(`Segoe UI Variable Text`, 13px)이 트레이 아이콘 글리프용 폰트를 덮어써 빈 사각형 tofu가 발생했다.

변경: FontFamily·FontSize 지정 제거, 전경색(#F4F4F5)만 유지. `screenshots/v22-dock-fix.png`에서 정상 글리프 확인.

## 3. 배경화면

- 원본 기준으로 70·65·60% 변형 추가 (Pillow 밝기 조정만, 해시는 `wallpaper/wallpaper-settings.json`에 등록).
- 70·65·60% 실화면 비교 결과 65%를 최종 기본값으로 적용 (`config/wallpaper.json`, Fill 유지). 70%는 양호, 60%는 그림자 뭉개짐 시작. 캐릭터 디테일·푸른 눈 보존 확인.
- 라이브 패키지 이미지와 설명문을 65%로 동기화. 애니메이션 타이밍을 `steps(96,end)`에서 `ease-in-out`으로 보정 (16초·진폭 유지).
- 다크모드 레지스트리는 이미 정상(AppsUseLightTheme=0, SystemUsesLightTheme=0)이어서 변경하지 않았다. 높은 RAM 사용량(84~95%)의 원인은 WSL·Discord·Chrome 등 사용자 작업 부하이며 커스터마이징 도구가 아니다.

## 4. 라이브 배경화면 (사용자 승인 대기 — 검증 게이트 우회하지 않음)

- 설치 파일 해시 검증 완료: `downloads/lively_setup_x86_full_v2210.exe` SHA256이 공식 릴리스 값과 일치 (Inno Setup 방식 확인).
- 무인 설치(`/VERYSILENT`)를 시도했으나 사용자 중단으로 취소하고 설치 프로세스 잔재 4건을 정리했다. 엔진 미설치 상태 유지.
- `state/lively-validated.json`은 생성하지 않았다. 재생·가림 일시정지·전체화면·배터리·정적 대체 검증 후에만 실측 기록한다.

## 5. 시작 복원

- `scripts/startup-restore.ps1`: health 판정 전 3초 안정화, 경로 기준 중복 인스턴스는 강제 종료 없이 경고 기록 후 최저 PID만 평가.
- 14:08 로그의 Rainmeter 2중 기록은 종료 과도기 현상으로 판명, 현재 단일 인스턴스 정상.
- `logs/startup-restore.json` Status=passed (2026-10-15T15:01). 실제 재부팅·재로그인은 미실시.

## 6. GPU 모니터링 (선택 사항으로 보류)

- Windows GPU Engine 카운터는 프로세스별 인스턴스라 내장 수단만으로 안정적인 전체 사용률을 얻을 수 없다. 가짜 수치를 표시하지 않고 숨김 유지.
- HWiNFO는 trick 우선순위에서 제외 (Dock·배경·성능·시작 복원 우선). 필요 시 공식 포터블 v8.54 + 관리자 권한 실행 승인 후 진행. 직접 다운로드는 Cloudflare 챌린지로 차단되어 브라우저 수동 다운로드 또는 winget 필요.

## 7. 검증 결과

- `scripts/verify.ps1`: 15 passed / 1 not-tested (게임·재로그인 미실시).
- 성능 30초 표본 (15:04): 4개 도구 합계 CPU 0.085%, 작업 집합 146.7 MiB. Explorer 1.224% 별도. v2.1 대비 회귀 없음.
- 백업: `backups/manual-20261015-145559` (설정 5종 + Search·ExplorerAdvanced 레지스트리).

## 8. 남은 작업

1. Lively 엔진 설치 (사용자 명시적 승인 필요 — 무인 설치는 중단됨) → 정책 설정·재생 검증 (에이전트).
2. HWiNFO 관리자 권한 실행 승인 (선택 사항).
3. 실제 재부팅 후 로그인 복원 확인 (사용자, 편할 때). 재부팅·Explorer 재시작·파괴적 변경은 승인 없이 수행하지 않는다.
