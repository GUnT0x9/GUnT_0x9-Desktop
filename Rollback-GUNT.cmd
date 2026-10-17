@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\rollback.ps1"
if errorlevel 1 echo 복구에 실패했습니다. 프로젝트 logs 폴더를 확인하세요.
pause
