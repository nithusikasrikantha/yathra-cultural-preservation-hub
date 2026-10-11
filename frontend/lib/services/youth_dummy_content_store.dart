import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/story.dart';

class YouthDummyContentStore extends ChangeNotifier {
  YouthDummyContentStore._();

  static final YouthDummyContentStore instance = YouthDummyContentStore._();
  static const String _idPrefix = 'youth-dummy-';

  late final List<Story> _stories = List<Story>.unmodifiable([
    Story(
      id: '${_idPrefix}village-harvest-festival',
      title: 'Village Harvest Festival',
      category: 'Traditional Story',
      language: 'English',
      storyText:
          'The story of our village harvest, when the whole community came together to celebrate the season...',
      tags: ['harvest', 'village', 'tradition'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Story(
      id: '${_idPrefix}traditional-jaffna-recipe',
      title: 'Traditional Jaffna Recipe',
      category: 'Recipe',
      language: 'English',
      storyText:
          'A traditional recipe passed down through generations, prepared during family and community celebrations...',
      tags: ['food', 'recipe', 'jaffna'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ]);

  final Set<String> _bookmarkedIds = <String>{};
  final Set<String> _likedIds = <String>{};

  static const Map<String, _YouthDummySocialData> _socialData = {
    '${_idPrefix}village-harvest-festival': _YouthDummySocialData(
      sourceName: 'Thiruvarangan',
      relativeTime: '2h ago',
      initialLikeCount: 24,
      commentCount: 8,
      imageAssetPath: 'assets/images/youth_dummy/village_harvest_festival.png',
    ),
    '${_idPrefix}traditional-jaffna-recipe': _YouthDummySocialData(
      sourceName: 'Lakshmi Amma',
      relativeTime: 'Yesterday',
      initialLikeCount: 18,
      commentCount: 5,
      imageAssetPath: 'assets/images/youth_dummy/traditional_jaffna_recipe.png',
    ),
  };

  UnmodifiableListView<Story> get stories => UnmodifiableListView(_stories);

  Iterable<Story> get bookmarkedStories =>
      _stories.where((story) => _bookmarkedIds.contains(story.id));

  bool isDummyId(String storyId) => storyId.startsWith(_idPrefix);

  bool isBookmarked(String storyId) => _bookmarkedIds.contains(storyId);

  YouthDummyStoryMetadata? metadataFor(String storyId) {
    final data = _socialData[storyId];
    if (data == null) return null;
    final liked = _likedIds.contains(storyId);
    return YouthDummyStoryMetadata(
      sourceName: data.sourceName,
      relativeTime: data.relativeTime,
      likeCount: data.initialLikeCount + (liked ? 1 : 0),
      commentCount: data.commentCount,
      isLiked: liked,
      imageAssetPath: data.imageAssetPath,
    );
  }

  Story? storyById(String storyId) {
    for (final story in _stories) {
      if (story.id == storyId) return story;
    }
    return null;
  }

  void toggleBookmark(String storyId) {
    if (!isDummyId(storyId) || storyById(storyId) == null) return;
    if (!_bookmarkedIds.remove(storyId)) {
      _bookmarkedIds.add(storyId);
    }
    notifyListeners();
  }

  void removeBookmark(String storyId) {
    if (_bookmarkedIds.remove(storyId)) notifyListeners();
  }

  void toggleLike(String storyId) {
    if (!isDummyId(storyId) || !_socialData.containsKey(storyId)) return;
    if (!_likedIds.remove(storyId)) {
      _likedIds.add(storyId);
    }
    notifyListeners();
  }
}

class YouthDummyStoryMetadata {
  const YouthDummyStoryMetadata({
    required this.sourceName,
    required this.relativeTime,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.imageAssetPath,
  });

  final String sourceName;
  final String relativeTime;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final String imageAssetPath;
}

class _YouthDummySocialData {
  const _YouthDummySocialData({
    required this.sourceName,
    required this.relativeTime,
    required this.initialLikeCount,
    required this.commentCount,
    required this.imageAssetPath,
  });

  final String sourceName;
  final String relativeTime;
  final int initialLikeCount;
  final int commentCount;
  final String imageAssetPath;
}
