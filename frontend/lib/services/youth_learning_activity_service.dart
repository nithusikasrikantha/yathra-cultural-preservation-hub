import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/story.dart';

class YouthLearningActivityService extends ChangeNotifier {
  YouthLearningActivityService._();

  static final YouthLearningActivityService instance =
      YouthLearningActivityService._();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _viewedKeyPrefix = 'youth_viewed_story_ids_';
  static const String _categoryKeyPrefix = 'youth_explored_categories_';

  final Set<String> _viewedStoryIds = <String>{};
  final Set<String> _categories = <String>{};
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  String? _scope;

  bool get isLoaded => _isLoaded;
  UnmodifiableSetView<String> get viewedStoryIds =>
      UnmodifiableSetView(_viewedStoryIds);
  UnmodifiableSetView<String> get exploredCategories =>
      UnmodifiableSetView(_categories);

  Future<void> load() async {
    final scope = await _resolveScope();
    if (_isLoaded && _scope == scope) return;
    if (_loadFuture != null) return _loadFuture!;
    _scope = scope;
    _loadFuture = _loadPersistedActivity(scope);
    try {
      await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  Future<void> recordStoryView(Story story) async {
    if (story.id.trim().isEmpty || _isDummyId(story.id)) return;
    await load();
    final storyId = story.id.trim();
    final category = story.category.trim();
    final storyAdded = _viewedStoryIds.add(storyId);
    final categoryAdded = category.isNotEmpty && _categories.add(category);
    final changed = storyAdded || categoryAdded;
    if (!changed) return;

    try {
      await _persist();
    } catch (_) {
      // Restore the in-memory state if local persistence fails.
      if (storyAdded) _viewedStoryIds.remove(storyId);
      if (categoryAdded) _categories.remove(category);
      rethrow;
    }
    notifyListeners();
  }

  Future<String> _resolveScope() async {
    final userId = (await _secureStorage.read(key: 'auth_user_id'))?.trim();
    return userId == null || userId.isEmpty ? 'anonymous' : userId;
  }

  Future<void> _loadPersistedActivity(String scope) async {
    final preferences = await SharedPreferences.getInstance();
    final viewed =
        preferences.getStringList('$_viewedKeyPrefix$scope') ?? const [];
    final categories =
        preferences.getStringList('$_categoryKeyPrefix$scope') ?? const [];
    _viewedStoryIds
      ..clear()
      ..addAll(viewed.map((id) => id.trim()).where((id) => id.isNotEmpty));
    _categories
      ..clear()
      ..addAll(
        categories
            .map((category) => category.trim())
            .where((category) => category.isNotEmpty),
      );
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final scope = _scope ?? await _resolveScope();
    final viewedSaved = await preferences.setStringList(
      '$_viewedKeyPrefix$scope',
      _viewedStoryIds.toList(growable: false),
    );
    final categoriesSaved = await preferences.setStringList(
      '$_categoryKeyPrefix$scope',
      _categories.toList(growable: false),
    );
    if (!viewedSaved || !categoriesSaved) {
      throw StateError('Learning activity could not be stored on this device.');
    }
  }

  bool _isDummyId(String id) => id.startsWith('youth-dummy-');
}
