@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title AlgoKids - Cocuklar Icin Kodlama Oyunu Baslatici
cd /d "%~dp0"

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

:MENU
cls
echo ===============================================================
echo          🤖 ALGOKIDS: ÇOCUKLAR İÇİN KODLAMA MACERASI
echo ===============================================================
echo.
echo  [1] Google Chrome ile Başlat (TAVSİYE EDİLEN - Hızlı)
echo  [2] Web Tarayıcıda Başlat (Web Server Modu)
echo  [3] Microsoft Edge ile Başlat
echo  [4] Windows Masaüstü Uygulaması Olarak Başlat
echo  [5] Bağlı Telefona Yükle ve Çalıştır (flutter run)
echo  [6] Android APK Paketi Oluştur (flutter build apk)
echo  [7] Bağlı Cihazları Listele (flutter devices)
echo  [8] Paketleri Yenile (flutter pub get)
echo  [9] Projeyi Temizle (flutter clean - Yer Aç)
echo  [0] Çıkış
echo.
echo ===============================================================
set "SECIM=1"
set /p "SECIM=Lütfen bir seçim yapın [Varsayılan: 1]: "

if "%SECIM%"=="1" goto RUN_CHROME
if "%SECIM%"=="2" goto RUN_WEBSERVER
if "%SECIM%"=="3" goto RUN_EDGE
if "%SECIM%"=="4" goto RUN_WINDOWS
if "%SECIM%"=="5" goto RUN_DEVICE
if "%SECIM%"=="6" goto BUILD_APK
if "%SECIM%"=="7" goto LIST_DEVICES
if "%SECIM%"=="8" goto PUB_GET
if "%SECIM%"=="9" goto CLEAN_PROJECT
if "%SECIM%"=="0" goto CIKIS
goto GECERSIZ

:RUN_CHROME
echo.
echo [*] AlgoKids Google Chrome üzerinde başlatılıyor...
echo.
cmd /c "%FLUTTER_CMD% run -d chrome"
goto BITTI

:RUN_WEBSERVER
echo.
echo [*] AlgoKids Web Sunucusu başlatılıyor (http://localhost:8080)...
echo [*] Tarayıcınız otomatik açılacaktır.
echo.
start "" "http://localhost:8080"
cmd /c "%FLUTTER_CMD% run -d web-server --web-port=8080 --web-hostname=localhost"
goto BITTI

:RUN_EDGE
echo.
echo [*] AlgoKids Microsoft Edge üzerinde başlatılıyor...
echo.
cmd /c "%FLUTTER_CMD% run -d edge"
goto BITTI

:RUN_WINDOWS
echo.
echo [*] AlgoKids Windows Masaüstü uygulaması olarak başlatılıyor...
echo.
cmd /c "%FLUTTER_CMD% run -d windows"
goto BITTI

:RUN_DEVICE
echo.
echo [*] Bağlı telefon / cihaz tespit ediliyor ve oyun yükleniyor...
echo.
cmd /c "%FLUTTER_CMD% run"
goto BITTI

:BUILD_APK
echo.
echo [*] Android APK paketi oluşturuluyor (build/app/outputs/flutter-apk/)...
echo.
cmd /c "%FLUTTER_CMD% build apk --release"
echo.
echo [✓] APK başarıyla derlendi!
goto BITTI

:LIST_DEVICES
echo.
echo [*] Bağlı cihazlar sorgulanıyor:
echo.
cmd /c "%FLUTTER_CMD% devices"
goto BITTI

:PUB_GET
echo.
echo [*] Proje bağımlılıkları güncelleniyor (flutter pub get)...
echo.
cmd /c "%FLUTTER_CMD% pub get"
echo.
echo [✓] Paketler güncellendi!
goto BITTI

:CLEAN_PROJECT
echo.
echo [*] Geçici derleme dosyaları temizleniyor (flutter clean)...
echo.
cmd /c "%FLUTTER_CMD% clean"
cmd /c "%FLUTTER_CMD% pub get"
echo.
echo [✓] Proje temizlendi ve paketler yeniden çekildi!
goto BITTI

:GECERSIZ
echo.
echo [!] Geçersiz bir seçim yaptınız. Lütfen tekrar deneyin.
timeout /t 2 >nul
goto MENU

:BITTI
echo.
echo ===============================================================
echo İşlem tamamlandı. Menüye dönmek için herhangi bir tuşa basın...
echo ===============================================================
pause >nul
goto MENU

:CIKIS
echo.
echo AlgoKids Başlatıcıdan çıkılıyor...
timeout /t 1 >nul
exit /b 0
