/// Saves a text file on the user's device. Web: triggers a browser download.
/// Native (Android/iOS): not implemented yet -- returns false so the caller
/// can tell the user. Same conditional-export pattern as google_auth_button.
export 'file_download_native.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
