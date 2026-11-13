@echo off
title PKL Monitoring - Build APK Siap Unduh
color 0a

echo ================================================================
echo   MEMBUAT FILE APK RELEASE PKL MONITORING (SIAP DIUNDUH)
echo ================================================================
echo.
cd /d "%~dp0frontend"

echo Menjalankan 'flutter build apk --release'...
echo Harap tunggu sebentar (biasanya 1-2 menit)...
echo.
call flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo Menyalin APK ke folder utama proyek...
    copy /y "build\app\outputs\flutter-apk\app-release.apk" "%~dp0pkl-monitoring.apk"
    echo.
    echo ================================================================
    echo [SUKSES] APK berhasil dibuat:
    echo   %~dp0pkl-monitoring.apk
    echo.
    echo Silakan bagikan / upload file 'pkl-monitoring.apk' ini ke
    echo Google Drive atau WhatsApp agar bisa diunduh oleh Siswa ^& Guru!
    echo ================================================================
) else (
    echo.
    echo [ERROR] Gagal mem-build APK. Periksa pesan error di atas.
)

pause

