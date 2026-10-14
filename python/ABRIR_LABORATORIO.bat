@echo off
cd /d "%~dp0"
set "LAB_PYTHON=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if exist "%LAB_PYTHON%" (
    "%LAB_PYTHON%" laboratorio_f16.py
) else (
    python laboratorio_f16.py
)
if errorlevel 1 pause
