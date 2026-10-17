# 시스템 모니터 한글 표시 수정

수정 전 백업: `backups/monitor-korean-20261015-165535/`.

원인: 소스 INI 라벨은 정상이었지만 Lua 반환 문구는 UTF-8 파일을 ANSI로 처리해 깨졌다. 설치된 Rainmeter 4.5.28은 Lua의 UTF-16 LE BOM을 확인해 Unicode 모드를 선택한다. [해당 버전 공식 소스](https://github.com/rainmeter/rainmeter/blob/v4.5.28.3936/Library/lua/LuaScript.cpp).

변경: `scripts/update-monitor.ps1`이 배포하는 `.lua`도 `.ini`·`.inc`와 함께 UTF-16 LE로 저장한다. 프로젝트 원본은 UTF-8을 유지한다. 대소문자를 구분하지 않는 측정/표시 항목 이름 충돌 5개를 제거해 CPU 모델과 디스크 여유 공간 표시도 복구했다. 보기 전환의 PowerShell 인자 인용을 수정하고, 설명과 구분선이 겹치지 않도록 행 간격을 조정했다.

검증: 실제 175% 배율에서 간단히 보기·자세히 보기 화면을 확인했다. 버튼 여백과 글자를 각각 실제 마우스로 클릭해 전환했다. 창 높이는 각각 483px·920px였고 원래 자세히 보기 상태로 돌렸다. 새로고침 후 Lua BOM 유지 및 실행 중 Lua가 출력한 한국어 로그를 확인했다. 중복 측정/표시 섹션은 없다.

- 기능 결과: `logs/monitor-korean-verification.json`
- 화면: `screenshots/v23-monitor-korean-compact-fixed.png`
- 화면: `screenshots/v23-monitor-korean-detailed-verified.png`

재부팅 검증은 하지 않았다. Dock·Lively·Windows 전역 설정은 이 수정에서 변경하지 않았다.
