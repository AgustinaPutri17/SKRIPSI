import 'dart:io';

void saveFileCrossPlatform(String content, String fileName, {String mimeType = 'text/csv'}) {
  try {
    Directory? targetDir;
    final downloadDir = Directory('/storage/emulated/0/Download');
    if (downloadDir.existsSync()) {
      targetDir = downloadDir;
    } else {
      final sdcardDir = Directory('/sdcard/Download');
      if (sdcardDir.existsSync()) {
        targetDir = sdcardDir;
      }
    }

    if (targetDir != null) {
      final file = File('${targetDir.path}/$fileName');
      file.writeAsStringSync(content);
    }
  } catch (_) {}
}

void printDocumentCrossPlatform() {}
