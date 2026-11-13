import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart';

class FileDownloadHelper {
  static void download(String content, String fileName, {String mimeType = 'text/csv'}) {
    saveFileCrossPlatform(content, fileName, mimeType: mimeType);
  }

  static void printDocument() {
    printDocumentCrossPlatform();
  }
}
