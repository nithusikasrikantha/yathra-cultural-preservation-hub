import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityPreferencesService extends ChangeNotifier {
  AccessibilityPreferencesService._();

  static final instance = AccessibilityPreferencesService._();
  static const _key = 'youth_high_contrast_enabled';

  bool _isLoaded = false;
  bool _highContrastEnabled = false;

  bool get isLoaded => _isLoaded;
  bool get highContrastEnabled => _highContrastEnabled;

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      _highContrastEnabled = preferences.getBool(_key) ?? false;
    } catch (_) {
      _highContrastEnabled = false;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setHighContrast(bool enabled) async {
    final previous = _highContrastEnabled;
    _highContrastEnabled = enabled;
    _isLoaded = true;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_key, enabled);
      if (!saved) throw StateError('Preference could not be saved');
    } catch (_) {
      _highContrastEnabled = previous;
      notifyListeners();
      rethrow;
    }
  }
}
