@echo off
title PKL Monitoring - Server Online (Cloudflare Tunnel)
color 0b

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0jalankan_online.ps1"
if %errorlevel% neq 0 (
    pause
)
