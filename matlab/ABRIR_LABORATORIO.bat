@echo off
set "LAB_ROOT=%~dp0"
set "LAB_MATLAB=C:\Program Files\MATLAB\R2024a\bin\matlab.exe"
if not exist "%LAB_MATLAB%" (
    echo Abre MATLAB en esta carpeta y ejecuta lab_f16_app.
    pause
    exit /b 1
)
if not exist "%LAB_ROOT%resultados\lab_prefs" mkdir "%LAB_ROOT%resultados\lab_prefs"
if not exist "%LAB_ROOT%resultados\lab_tmp" mkdir "%LAB_ROOT%resultados\lab_tmp"
set "MATLAB_PREFDIR=%LAB_ROOT%resultados\lab_prefs"
set "TEMP=%LAB_ROOT%resultados\lab_tmp"
set "TMP=%TEMP%"
"%LAB_MATLAB%" -sd "%LAB_ROOT%." -r "lab_f16_app"
