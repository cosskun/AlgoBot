@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title AlgoKids Oyunu Başlatılıyor (Windows Masaüstü)...
cd /d "%~dp0"

echo ========================================================
echo        [AlgoKids] Kodlama Oyunu Masaüstü Açılıyor...
echo ========================================================
echo.

REM Flutter komutunu otomatik tespit et
set "FLUTTER_CMD="
if exist "%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat" (
    set "FLUTTER_CMD=%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat"
) else (
    where flutter >nul 2>nul
    if %errorlevel% equ 0 (
        set "FLUTTER_CMD=flutter"
    ) else (
        where puro >nul 2>nul
        if %errorlevel% equ 0 (
            set "FLUTTER_CMD=puro flutter"
        ) else if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
            set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
        ) else if exist "C:\Users\Superuser\flutter\bin\flutter.bat" (
            set "FLUTTER_CMD=C:\Users\Superuser\flutter\bin\flutter.bat"
        ) else if exist "C:\flutter\bin\flutter.bat" (
            set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
        ) else (
            set "FLUTTER_CMD=flutter"
        )
    )
)

"%FLUTTER_CMD%" run -d windows

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [BILGI] Windows masaustu ile baslatilamadi, Chrome deneniyor...
    "%FLUTTER_CMD%" run -d chrome
)

echo.
echo Oyun kapatildi.
pause
