@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply.ps1" %*
if errorlevel 1 (
    echo.
    echo The folder paths were not updated.
    pause
    exit /b 1
)
echo.
pause
