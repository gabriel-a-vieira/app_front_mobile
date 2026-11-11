import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Builds the file in memory (Blob) and clicks a temporary <a download>, which
/// makes the browser save it -- on a phone browser, opening the downloaded
/// .ics offers to add the event to the device calendar.
Future<bool> downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) async {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);

  return true;
}
