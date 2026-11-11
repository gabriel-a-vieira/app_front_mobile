/// Native builds (APK/iOS) don't save files yet: that needs path_provider +
/// a share/open-file plugin, postponed together with mobile distribution.
Future<bool> downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  return false;
}
