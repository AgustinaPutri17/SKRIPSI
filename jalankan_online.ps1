# PowerShell Script for PKL Monitoring Online Cloudflare Server & APK Builder
$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   PKL MONITORING - SERVER ONLINE CLOUDFLARE & APK BUILDER" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = $PSScriptRoot
$cfLog = Join-Path $env:TEMP "cf_pkl_tunnel.log"
if (Test-Path $cfLog) { Remove-Item $cfLog -Force -ErrorAction SilentlyContinue }

# Bersihkan proses lama jika masih menggantung
Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 1. Jalankan Laravel Backend
Write-Host "[1/3] Menjalankan Server Laravel Backend..." -ForegroundColor Yellow
$phpProc = Start-Process -FilePath "php" -ArgumentList "artisan", "serve", "--host=127.0.0.1", "--port=8000" -WorkingDirectory (Join-Path $rootPath "monitoring-pkl-app") -PassThru -WindowStyle Hidden

# 2. Jalankan Cloudflare Tunnel
Write-Host "[2/3] Membuka Cloudflare Quick Tunnel (Gratis)..." -ForegroundColor Yellow
$cfProc = Start-Process -FilePath (Join-Path $rootPath "cloudflared.exe") -ArgumentList "tunnel", "--url", "http://127.0.0.1:8000" -RedirectStandardError $cfLog -PassThru -WindowStyle Hidden

Write-Host "      Menunggu link HTTPS dari Cloudflare..." -ForegroundColor Gray
$tunnelUrl = $null
$rawUrl = $null

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $cfLog) {
        $content = Get-Content $cfLog -Raw -ErrorAction SilentlyContinue
        if ($content -match 'https://[a-zA-Z0-9-]+\.trycloudflare\.com') {
            $rawUrl = $matches[0]
            $tunnelUrl = "$rawUrl/api"
            break
        }
    }
}

if (-not $rawUrl) {
    Write-Host "[X] Gagal mendapatkan URL Cloudflare. Periksa koneksi internet Anda." -ForegroundColor Red
    Stop-Process -Id $cfProc.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $phpProc.Id -Force -ErrorAction SilentlyContinue
    pause
    exit 1
}

# 3. Update auth_service.dart otomatis
$authServicePath = Join-Path $rootPath "frontend\lib\core\services\auth_service.dart"
if (Test-Path $authServicePath) {
    $authContent = [System.IO.File]::ReadAllText($authServicePath)
    $authContent = [System.Text.RegularExpressions.Regex]::Replace(
        $authContent,
        "static const String cloudflareTunnelUrl = '.*?';",
        "static const String cloudflareTunnelUrl = '$tunnelUrl';"
    )
    [System.IO.File]::WriteAllText($authServicePath, $authContent)
    Write-Host "[3/3] URL berhasil disinkronkan ke kode Flutter!" -ForegroundColor Green
}

# Salin link ke clipboard
try {
    Set-Clipboard -Value $rawUrl
    $copiedText = "(Sudah otomatis disalin ke Clipboard)"
} catch {
    $copiedText = ""
}

Clear-Host
Write-Host "================================================================" -ForegroundColor Green
Write-Host "   SERVER BACKEND BERHASIL ONLINE DI CLOUDFLARE (100% GRATIS)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Link Cloudflare : " -NoNewline; Write-Host "$rawUrl " -ForegroundColor Cyan -NoNewline; Write-Host $copiedText -ForegroundColor Yellow
Write-Host " Endpoint API    : " -NoNewline; Write-Host "$tunnelUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host " Status: Backend aktif & siap diakses dari mana saja (HP/PC/Data Seluler)" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "PILIHAN TINDAKAN:" -ForegroundColor Yellow
Write-Host " [1] Buat File APK Siap Unduh (pkl-monitoring.apk) sekarang"
Write-Host " [2] Jaga Server Tetap Aktif (Gunakan APK yang sudah ada / buka app di HP)"
Write-Host ""
$choice = Read-Host "Masukkan pilihan (1/2) [Default 2]"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Sedang mem-build file APK Release Flutter..." -ForegroundColor Yellow
    Write-Host "(Proses ini membutuhkan waktu sekitar 1-2 menit)" -ForegroundColor Gray
    Write-Host ""
    
    Push-Location (Join-Path $rootPath "frontend")
    & flutter build apk --release
    Pop-Location

    $builtApk = Join-Path $rootPath "frontend\build\app\outputs\flutter-apk\app-release.apk"
    $targetApk = Join-Path $rootPath "pkl-monitoring.apk"

    if (Test-Path $builtApk) {
        Copy-Item -Path $builtApk -Destination $targetApk -Force
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host " [BERHASIL] File APK siap diunduh telah selesai dibuat!" -ForegroundColor Green
        Write-Host " Lokasi File : $targetApk" -ForegroundColor Cyan
        Write-Host " Ukuran File : $([math]::Round((Get-Item $targetApk).Length / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Petunjuk Penyebaran APK ke Siswa/Guru:" -ForegroundColor Yellow
        Write-Host " 1. Unggah file 'pkl-monitoring.apk' ini ke Google Drive / bagikan via WhatsApp."
        Write-Host " 2. Pengguna cukup mengunduh dan menginstal di HP Android mereka."
        Write-Host " 3. Saat dibuka, aplikasi langsung terhubung ke server online Cloudflare Anda!"
        Write-Host ""
    } else {
        Write-Host "[!] Gagal menemukan file APK hasil build." -ForegroundColor Red
    }
}

Write-Host "----------------------------------------------------------------" -ForegroundColor Gray
Write-Host "SERVER CLOUDFLARE SEDANG BERJALAN..." -ForegroundColor Green
Write-Host "JANGAN TUTUP jendela ini agar aplikasi di HP tetap dapat terhubung." -ForegroundColor Yellow
Write-Host "Tekan [Enter] atau [Ctrl+C] jika ingin mematikan server." -ForegroundColor Gray
Write-Host "----------------------------------------------------------------" -ForegroundColor Gray

# Loop monitor proses
try {
    while (-not $cfProc.HasExited -and -not $phpProc.HasExited) {
        Start-Sleep -Seconds 2
    }
} finally {
    Write-Host "`nMematikan server..." -ForegroundColor Yellow
    Stop-Process -Id $cfProc.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $phpProc.Id -Force -ErrorAction SilentlyContinue
    if (Test-Path $cfLog) { Remove-Item $cfLog -Force -ErrorAction SilentlyContinue }
    Write-Host "Server selesai dimatikan." -ForegroundColor Green
}
