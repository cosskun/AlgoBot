@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title AlgoKids Oyunu Telefona Yükleniyor...
cd /d "%~dp0"

echo ========================================================
echo        [AlgoKids] Oyunu Bağlı Telefona Yükleniyor...
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

echo [*] Bağlı cihazlar kontrol ediliyor...
"%FLUTTER_CMD%" devices

echo.
echo [*] Uygulama derleniyor ve cihaza kuruluyor...
"%FLUTTER_CMD%" run

echo.
echo Islem tamamlandi.
pause
