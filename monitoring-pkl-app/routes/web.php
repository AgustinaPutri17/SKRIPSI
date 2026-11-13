<?php

use Illuminate\Support\Facades\Route;

// Endpoint unduh langsung file APK untuk HP Android
Route::get('/download-apk', function () {
    $path = public_path('pkl-monitoring.apk');
    if (file_exists($path)) {
        return response()->download($path, 'pkl-monitoring.apk', [
            'Content-Type' => 'application/vnd.android.package-archive',
        ]);
    }
    return response()->json(['error' => 'File APK belum tersedia di server.'], 404);
});

Route::get('/pkl-monitoring.apk', function () {
    $path = public_path('pkl-monitoring.apk');
    if (file_exists($path)) {
        return response()->download($path, 'pkl-monitoring.apk', [
            'Content-Type' => 'application/vnd.android.package-archive',
        ]);
    }
    return response()->json(['error' => 'File APK belum tersedia di server.'], 404);
});

Route::get('/', function () {
    return response()->file(public_path('index.html'));
});

Route::get('/{any}', function () {
    return response()->file(public_path('index.html'));
})->where('any', '^(?!api|download-apk|pkl-monitoring\.apk).*$');
