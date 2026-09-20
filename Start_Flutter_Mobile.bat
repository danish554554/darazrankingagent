@echo off
title Daraz Ranking Mobile App
cd /d "%~dp0mobile_app"
echo ===================================================
echo   Starting Daraz Rank Radar Flutter App
echo ===================================================
echo Available devices:
flutter devices
echo.
echo Launching application...
flutter run
pause
