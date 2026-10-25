@echo off
title Laravel Backend Server (PKL Monitoring)
echo ========================================================
echo   Menjalankan Server Laravel untuk Akses HP / Wi-Fi
echo ========================================================
echo.
cd /d "%~dp0\monitoring-pkl-app"

echo IP Laptop kamu saat ini:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address" /c:"Alamat IPv4"') do (
    echo   -> %%a
)
echo.
echo Pastikan HP dan Laptop terhubung ke Wi-Fi yang SAMA.
echo Menjalankan: php artisan serve --host=0.0.0.0 --port=8000
echo.
echo (Tekan Ctrl+C jika ingin mematikan server)
echo ========================================================
echo.

php artisan serve --host=0.0.0.0 --port=8000
pause
