# Windhawk 호환성 기록

검사 대상은 Windows11 Home25H2 빌드26200.9711, Explorer 네이티브 작업 표시줄입니다. 고정한 공식 소스·해시를 사용하며 개별 출처는 *.source.json, 실제 활성 목록은 mods.json에 기록합니다. 향후 Windows 업데이트까지 보장하는 호환성 판정은 아닙니다.

| 모드 | 버전 | 결정 및 확인 |
|---|---|---|
| Windows11 Taskbar Styler |1.10| 기존 사용, DockLike 자연 폭·중앙 정렬 유지, 실제 DLL 로드·화면 확인 |
| Taskbar height and icon size |1.3.10| 기존 사용, 높이90·아이콘44·버튼56, 25H2 작은 아이콘 경로도 동일 크기, 실제77px 아이콘 확인 |
| Taskbar Clock Customization |1.8.1| 추가 활성화, 한국어 날짜·12시간 시계, Explorer DLL 로드·표시 확인. 웹 콘텐츠 사용 안 함 |
| Windows11 Notification Center Styler |1.7| 추가 활성화, 실제 Windows 알림·달력 어두운 패널·보라색 오늘 선택, 호스트 DLL·화면 확인 |
| Windows11 Start Menu Styler |1.7| 공식 소스 평가·보관, 비활성. 시작 메뉴 구조 변경을 추가하지 않음 |
| Windows11 File Explorer Styler |1.7| 공식 소스 평가·보관, 비활성. 탐색기 기존 다크 모드 보존 |
| Taskbar Dock Animation Plus |2.0.1| 공식 소스 평가·보관, 비활성. 확대를 위한 추가 훅·효과는 생략 |

Taskbar Styler와 아이콘 크기 모드는 역할을 나눠 기존 조합을 유지했습니다. 시계·알림 모드는 각각 추가해 로딩을 확인했습니다. Explorer 재시작 없이 적용했습니다. 다른 트레이 교체·가짜 달력·중복 상단 바는 추가하지 않았습니다.

현재 구조에서 Dock에 MaxWidth를 강제하면 Windows의 앱 영역 계산이 좁아져 시작 버튼과 오버플로만 남는 문제가 있었습니다. 강제 폭 제한을 제거하여 복구했고 최종 중앙 배치·트레이 간격·아이콘 크기를 다시 확인했습니다. 앱이 많은 경우 기존 Windows 오버플로는 유지합니다.

GPU 센서·라이브 엔진·게임·특수 전체 화면 앱·새 Windows 빌드·안티치트 조합은 검증하지 않았습니다. 종료·재시작·로그아웃은 실행하지 않았습니다.

공식 자료: [모드 저장소](https://github.com/ramensoftware/windhawk-mods), [DockLike 설정](https://github.com/ramensoftware/windows-11-taskbar-styling-guide/blob/main/Themes/DockLike/README.md).
