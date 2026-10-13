import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5001';
    }

    if (Platform.isAndroid) {
      // 127.0.0.1 works over USB cable via adb reverse tcp:5001 tcp:5001
      return 'http://127.0.0.1:5001';
    }

    return 'http://127.0.0.1:5001';
  }
}
