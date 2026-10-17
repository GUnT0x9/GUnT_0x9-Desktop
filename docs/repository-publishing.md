# GitHub 공개 저장소 구성

대상: https://github.com/GUnT0x9/GUnT_0x9-Desktop

프로젝트 원본 폴더에서 Git을 시작하고 main 브랜치로 소스·공통 설정·문서·브랜딩 자산을 기록한다. 실제 데스크톱에 필요한 내부 경로와 실행 파일 이름은 변경하지 않는다.

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

대표 이미지는 사용자가 업로드를 요청한 실제 적용 화면이다. 제어 센터는 다른 앱 창이 섞이지 않도록 PrintWindow로 해당 창만 캡처했다. 다른 작업 앱·채팅 창이 겹친 진단 캡처는 포함하지 않는다.
