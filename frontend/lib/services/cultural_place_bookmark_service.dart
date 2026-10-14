import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CulturalPlaceBookmarkService extends ChangeNotifier {
  CulturalPlaceBookmarkService._();

  static final CulturalPlaceBookmarkService instance =
      CulturalPlaceBookmarkService._();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyPrefix = 'youth_saved_cultural_place_ids_';

  final Set<String> _placeIds = <String>{};
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  String? _storageKey;

  bool get isLoaded => _isLoaded;
  UnmodifiableSetView<String> get placeIds => UnmodifiableSetView(_placeIds);

  Future<void> load() async {
    final key = await _resolveStorageKey();
    if (_isLoaded && _storageKey == key) return;
    if (_loadFuture != null) return _loadFuture!;
    _storageKey = key;
    _loadFuture = _loadPersistedIds(key);
    try {
      await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  bool isSaved(String placeId) => _placeIds.contains(placeId);

  Future<bool> toggle(String placeId) async {
    await load();
    final normalizedId = placeId.trim();
    if (normalizedId.isEmpty) return false;
    if (isSaved(normalizedId)) {
      await remove(normalizedId);
      return false;
    }
    await add(normalizedId);
    return true;
  }

  Future<void> add(String placeId) async {
    await load();
    final normalizedId = placeId.trim();
    if (normalizedId.isEmpty) return;
    final previousIds = Set<String>.of(_placeIds);
    _placeIds.add(normalizedId);
    try {
      await _persist();
    } catch (_) {
      _placeIds
        ..clear()
        ..addAll(previousIds);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> remove(String placeId) async {
    await load();
    final normalizedId = placeId.trim();
    final previousIds = Set<String>.of(_placeIds);
    if (!_placeIds.remove(normalizedId)) return;
    try {
      await _persist();
    } catch (_) {
      _placeIds
        ..clear()
        ..addAll(previousIds);
      rethrow;
    }
    notifyListeners();
  }

  Future<String> _resolveStorageKey() async {
    final userId = (await _secureStorage.read(key: 'auth_user_id'))?.trim();
    final scope = userId == null || userId.isEmpty ? 'anonymous' : userId;
    return '$_keyPrefix$scope';
  }

  Future<void> _loadPersistedIds(String key) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final persistedIds = preferences.getStringList(key) ?? const [];
      _placeIds
        ..clear()
        ..addAll(
          persistedIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
        );
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final key = _storageKey ?? await _resolveStorageKey();
    final saved = await preferences.setStringList(
      key,
      _placeIds.toList(growable: false),
    );
    if (!saved) {
      throw StateError('Saved places could not be stored on this device.');
    }
  }
}
