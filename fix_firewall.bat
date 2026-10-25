@echo off
:: Batch script untuk membuka blokir Windows Firewall terhadap PHP dan port 8000
echo ===================================================
echo Memperbaiki Firewall Windows untuk Koneksi Laravel
echo ===================================================
echo.
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [PERHATIAN] Script ini butuh izin Administrator!
    echo Sedang meminta hak akses Administrator...
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

echo [1/2] Mengubah aturan firewall PHP (CLI) menjadi ALLOW...
powershell -Command "Get-NetFirewallRule | Where-Object { $_.DisplayName -eq 'CLI' } | Set-NetFirewallRule -Action Allow"

echo [2/2] Membuka port 8000 TCP untuk koneksi HP...
powershell -Command "Remove-NetFirewallRule -DisplayName 'Laravel Port 8000' -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName 'Laravel Port 8000' -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow"

echo.
echo ===================================================
echo SUKSES! Firewall sekarang mengizinkan HP terhubung.
echo Silakan coba tekan tombol Masuk lagi di aplikasi HP!
echo ===================================================
echo.
pause
