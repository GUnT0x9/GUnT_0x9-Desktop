# GitHub 공개 저장소 구성

대상: https://github.com/GUnT0x9/GUnT_0x9-Desktop

초기 공개는 main 브랜치에 소스·공통 설정·문서·브랜딩 자산을 기록했다. 현재 main은 v2.5 공개 소스 기준이고, v3.0 개발·문서는 `feat/v30-ui-foundation`에서 관리한다. 개발 브랜치의 일반 push와 main의 릴리스 갱신은 별도 작업이다. 실제 데스크톱에 필요한 내부 경로와 실행 파일 이름은 변경하지 않는다.

## 포함

- C#/WPF/WinForms 소스, PowerShell·Python·Rainmeter·Lua, 공개 Windhawk 공식 소스와 설정.
- 공식 로고 원본, 가공한 PNG·ICO와 자산 manifest, 라이선스 안내가 있는 글꼴.
- 구현·검증·복구 문서와 사용자 제공 적용 화면, 제어 센터 단독 캡처.
- 개인 경로를 제거한 config/examples 설정 예시.

## 제외

- apps·downloads·bin·backups·logs·state·diagnostics와 자동 생성 시험 파일.
- PC별 runtime/apps/layout/monitor/sensors/wallpaper JSON, installed mods 파생 스냅샷.
- 원본 배경 이미지·영상, 전체 screenshots 폴더, 인증 파일·환경 변수 파일.

이 제외는 로컬 파일 삭제가 아니다. 실제 데스크톱은 기존 파일을 계속 사용한다. 공개 저장소는 새 PC에서 검증된 일괄 설치 제품이 아니라 현재 개발 소스 스냅샷이다.

초기 대표 이미지는 사용자가 업로드를 요청한 실제 적용 화면이었다. 현재 쇼케이스에서는 아래 버전별 공개 검토 정책을 적용한다. 제어 센터는 다른 앱 창이 섞이지 않도록 PrintWindow로 해당 창만 캡처했다. 다른 작업 앱·채팅 창이 겹친 진단 캡처는 포함하지 않는다.

## 버전별 공개 화면

현재 README는 [공개 검토 목록](images/releases/manifest.json)의 실제 앱 캡처를 사용한다. 개인 설정을 건드리지 않는 문서용 예제 환경으로 새 화면을 수집하고, 기존 검토된 v2.x 이미지는 경로를 유지해 재사용한다. 사용자 제공 과거 데스크톱 이미지와 타사 배경 썸네일은 새 쇼케이스에 재사용하지 않는다. Git 이력을 지우거나 과거 이미지의 버전을 재표기하지 않는다.

원본·검토용 파일은 무시되는 `screenshots/`에 두고, 별도 RGB export·메타데이터 검사·최종 시각 검토를 거친 파일만 `docs/images/releases/`에 명시적으로 추가한다. [README 유지관리](readme-maintenance.md)의 체크리스트와 링크·PNG 검사를 따른다. 푸시 성공 여부는 실제 Git 응답으로 보고한다.
