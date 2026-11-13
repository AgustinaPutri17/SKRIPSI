@echo off
title PKL Monitoring - Akses via Kabel USB Type-C
color 0b

echo ================================================================
echo   PANDUAN ^& SETUP AKSES APLIKASI VIA KABEL TYPE-C (USB DEBUGGING)
echo ================================================================
echo.

set ADB="C:\Users\UserZ\AppData\Local\Android\sdk\platform-tools\adb.exe"

:CHECK_DEVICE
echo [1/3] Memeriksa koneksi perangkat HP...
%ADB% devices > "%TEMP%\adb_devices.txt"
findstr /R /C:"[a-zA-Z0-9].*device$" "%TEMP%\adb_devices.txt" >nul
if %errorlevel% neq 0 (
    echo.
    echo [PERHATIAN] HP BELUM TERDETEKSI / BELUM DIIZINKAN!
    echo.
    echo Pastikan langkah-langkah berikut sudah dilakukan di HP Anda:
    echo  1. Hubungkan HP ke Laptop menggunakan kabel USB Tipe-C.
    echo  2. Buka Pengaturan HP ^> Tentang Ponsel.
    echo  3. Ketuk 'Nomor Versi / Build Number' sebanyak 7x hingga mode pengembang aktif.
    echo  4. Masuk ke Pengaturan Tambahan / Sistem ^> Opsi Pengembang (Developer Options).
    echo  5. Aktifkan 'Debugging USB' (USB Debugging).
    echo  6. Lihat layar HP Anda: Jika muncul pop-up 'Izinkan Debugging USB?',
    echo     centang 'Selalu izinkan dari komputer ini' lalu ketuk OK / Izinkan.
    echo.
    echo Hubungkan HP atau beri izin, lalu tekan tombol apa saja untuk mencoba lagi...
    pause >nul
    echo.
    goto CHECK_DEVICE
)
del "%TEMP%\adb_devices.txt" 2>nul

echo.
echo [V] HP Berhasil Terhubung!
%ADB% devices
echo.

echo [2/3] Mengaktifkan Port Reverse (ADB Reverse)...
%ADB% reverse tcp:8000 tcp:8000
echo   -> Port 8000 di HP berhasil diteruskan ke Laptop via kabel USB!
echo      (HP sekarang dapat mengakses http://127.0.0.1:8000 secara langsung)
echo.

echo [3/3] Menjalankan Backend Laravel di jendela baru...
start "Laravel Backend Server (USB Mode)" cmd /k "cd /d ""%~dp0monitoring-pkl-app"" && php artisan serve --host=0.0.0.0 --port=8000"
echo.

echo ================================================================
echo Pilihan Menjalankan Aplikasi:
echo  [1] Jalankan Flutter langsung ke HP (flutter run - live debug / hot reload)
echo  [2] Pasang/Update file APK (pkl-monitoring.apk) ke HP
echo  [3] Selesai (Hanya butuh koneksi server USB untuk buka app di HP)
echo ================================================================
set /p opt="Pilih menu (1/2/3): "

if "%opt%"=="1" (
    echo.
    echo Menjalankan Flutter Run ke HP...
    cd /d "%~dp0frontend"
    flutter run
) else if "%opt%"=="2" (
    echo.
    echo Memasang pkl-monitoring.apk ke HP...
    %ADB% install -r "%~dp0pkl-monitoring.apk"
    echo.
    echo [V] Selesai! Silakan buka aplikasi PKL Monitoring di HP Anda.
    pause
) else (
    echo.
    echo [V] Koneksi USB dan Backend aktif. Silakan gunakan aplikasi di HP Anda!
    pause
)

