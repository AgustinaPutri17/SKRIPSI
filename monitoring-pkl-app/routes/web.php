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

// Sajikan file media storage publik secara langsung dengan CORS & MIME type yang tepat
Route::get('/storage/{path}', function ($path) {
    $storagePublicPath = storage_path('app/public/' . $path);
    if (file_exists($storagePublicPath)) {
        return response()->file($storagePublicPath, [
            'Access-Control-Allow-Origin' => '*',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    $publicPath = public_path('storage/' . $path);
    if (file_exists($publicPath)) {
        return response()->file($publicPath, [
            'Access-Control-Allow-Origin' => '*',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    return response()->json(['error' => 'File tidak ditemukan di server.'], 404);
})->where('path', '.*');

Route::get('/', function () {
    return response()->file(public_path('index.html'));
});

Route::get('/{any}', function () {
    return response()->file(public_path('index.html'));
})->where('any', '^(?!api|storage|download-apk|pkl-monitoring\.apk).*$');
