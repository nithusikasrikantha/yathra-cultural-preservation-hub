import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService extends ChangeNotifier {
  BookmarkService._();

  static final BookmarkService instance = BookmarkService._();
  static const String _storageKey = 'youth_bookmarked_story_ids';

  final List<String> _storyIds = [];
  Future<void>? _loadFuture;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<String> get storyIds => UnmodifiableListView(_storyIds);

  Future<void> load() {
    if (_isLoaded) return Future.value();
    return _loadFuture ??= _loadPersistedIds();
  }

  bool isBookmarked(String storyId) => _storyIds.contains(storyId);

  Future<bool> toggle(String storyId) async {
    await load();
    if (isBookmarked(storyId)) {
      await remove(storyId);
      return false;
    }

    await add(storyId);
    return true;
  }

  Future<void> add(String storyId) async {
    await load();
    final normalizedId = storyId.trim();
    if (normalizedId.isEmpty) return;

    final previousIds = List<String>.of(_storyIds);
    _storyIds
      ..remove(normalizedId)
      ..insert(0, normalizedId);
    try {
      await _persist();
    } catch (_) {
      _storyIds
        ..clear()
        ..addAll(previousIds);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> remove(String storyId) async {
    await load();
    final previousIds = List<String>.of(_storyIds);
    if (!_storyIds.remove(storyId)) return;

    try {
      await _persist();
    } catch (_) {
      _storyIds
        ..clear()
        ..addAll(previousIds);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _loadPersistedIds() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final persistedIds = preferences.getStringList(_storageKey) ?? const [];
      final uniqueIds = <String>{};

      for (final id in persistedIds) {
        final normalizedId = id.trim();
        if (normalizedId.isNotEmpty) {
          uniqueIds.add(normalizedId);
        }
      }

      _storyIds
        ..clear()
        ..addAll(uniqueIds);

      if (!_sameIds(persistedIds, _storyIds)) {
        await preferences.setStringList(_storageKey, _storyIds);
      }

      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _loadFuture = null;
      rethrow;
    }
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_storageKey, _storyIds);
    if (!saved) {
      throw StateError('Bookmarks could not be saved on this device.');
    }
  }

  bool _sameIds(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}
