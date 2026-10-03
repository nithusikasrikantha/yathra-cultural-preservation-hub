class ElderStoryEngagement {
  const ElderStoryEngagement({
    required this.likes,
    required this.comments,
    required this.saves,
  });

  final int likes;
  final int comments;
  final int saves;
}

/// Temporary, read-only Elder metrics until story engagement counts are
/// available from the backend.
abstract final class ElderStoryEngagementDemoData {
  static const _byStoryId = <String, ElderStoryEngagement>{
    'youth-dummy-village-harvest-festival': ElderStoryEngagement(
      likes: 24,
      comments: 8,
      saves: 19,
    ),
    'youth-dummy-traditional-jaffna-recipe': ElderStoryEngagement(
      likes: 18,
      comments: 5,
      saves: 24,
    ),
  };

  static const fallback = ElderStoryEngagement(
    likes: 16,
    comments: 6,
    saves: 12,
  );

  static ElderStoryEngagement forStory(String storyId) =>
      _byStoryId[storyId] ?? fallback;
}
