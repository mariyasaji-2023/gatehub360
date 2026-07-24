import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for the backend API.
///
/// - A real physical device isn't the same machine as your backend, so it
///   needs your computer's LAN IP (both devices must be on the same Wi-Fi).
/// - The Android *emulator* would instead need the special alias
///   `10.0.2.2`, and iOS simulator / desktop / web can use `localhost` —
///   swap this value if you switch to testing on those instead of a phone.
/// - Once the backend is deployed, replace this with the deployed URL.
String get apiBaseUrl {
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://192.168.0.3:5000/api';
  }
  return 'http://localhost:5000/api';
}
