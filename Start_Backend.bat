@echo off
title Daraz Ranking Engine - Backend
cd /d "%~dp0backend"
echo ===================================================
echo   Starting Daraz Rank Radar Backend Server
echo   API running on http://127.0.0.1:8000
echo   Swagger Documentation: http://127.0.0.1:8000/docs
echo ===================================================
call .\venv\Scripts\activate.bat
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
