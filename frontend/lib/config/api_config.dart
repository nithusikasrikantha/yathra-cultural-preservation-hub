import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }
}
