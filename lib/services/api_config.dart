import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Base URL for the backend API.
///
/// - A real physical device isn't the same machine as your backend, so it
///   needs your computer's LAN IP (both devices must be on the same Wi-Fi).
/// - iOS simulator / desktop / web can use `localhost` directly.
String get apiBaseUrl {
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://192.168.0.3:5000/api';
  }
  return 'http://localhost:5000/api';
}
