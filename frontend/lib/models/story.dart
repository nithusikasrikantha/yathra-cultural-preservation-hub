class Story {
  const Story({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    required this.storyText,
    this.tags = const [],
    this.audioPath,
    this.imageDataUri,
    this.createdAt,
    this.bannerImage,
    this.additionalImages = const [],
    this.location,
    this.timePeriod,
    this.community,
    this.communityId,
    this.aiSummary,
    this.summaryStatus,
    this.authorName,
    this.authorAvatar,
  });

  final String id;
  final String title;
  final String category;
  final String language;
  final String storyText;
  final List<String> tags;
  final String? audioPath;
  final String? imageDataUri;
  final DateTime? createdAt;
  final String? bannerImage;
  final List<String> additionalImages;
  final String? location;
  final String? timePeriod;
  final String? community;
  final String? communityId;
  final String? aiSummary;
  final String? summaryStatus;
  final String? authorName;
  final String? authorAvatar;
  String get preview =>
      summaryStatus == 'approved' && aiSummary?.isNotEmpty == true
      ? aiSummary!
      : storyText;
  int get readingMinutes =>
      (storyText.trim().split(RegExp(r'\s+')).length / 180).ceil().clamp(
        1,
        999,
      );

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: _requiredString(json, '_id'),
      title: _requiredString(json, 'title'),
      category: _requiredString(json, 'category'),
      language: _requiredString(json, 'language'),
      storyText: _requiredString(json, 'storyText'),
      tags: _stringList(json['tags']),
      audioPath: _optionalString(json['audioPath']),
      imageDataUri: _optionalString(json['imageDataUri']),
      bannerImage:
          _optionalString(json['bannerImage']) ??
          _optionalString(json['imageUrl']),
      additionalImages: _stringList(json['additionalImages']),
      location: _optionalString(json['location']),
      timePeriod: _optionalString(json['timePeriod']),
      community:
          _optionalString(json['communityName']) ??
          _optionalString(json['community']),
      communityId: _optionalString(json['communityId']),
      aiSummary: _optionalString(json['aiSummary']),
      summaryStatus: _optionalString(json['summaryStatus']),
      authorAvatar:
          json['publishedBy'] is Map &&
              json['publishedBy']['profileInfo'] is Map
          ? _optionalString(json['publishedBy']['profileInfo']['avatar'])
          : null,
      authorName: json['publishedBy'] is Map
          ? _optionalString(json['publishedBy']['name'])
          : null,
      createdAt: DateTime.tryParse(_optionalString(json['createdAt']) ?? ''),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Story field "$key" is missing or invalid.');
    }
    return value;
  }

  static String? _optionalString(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is! List) {
      throw const FormatException('Story field "tags" is invalid.');
    }

    return List<String>.unmodifiable(
      value.map((tag) {
        if (tag is! String || tag.trim().isEmpty) {
          throw const FormatException('Story field "tags" is invalid.');
        }
        return tag.trim();
      }),
    );
  }
}

class StoryPage {
  const StoryPage({required this.items, required this.pagination});

  final List<Story> items;
  final StoryPagination pagination;

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final paginationJson = json['pagination'];

    if (itemsJson is! List || paginationJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid paginated stories response.');
    }

    return StoryPage(
      items: itemsJson
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid story item.');
            }
            return Story.fromJson(item);
          })
          .toList(growable: false),
      pagination: StoryPagination.fromJson(paginationJson),
    );
  }
}

class StoryPagination {
  const StoryPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  factory StoryPagination.fromJson(Map<String, dynamic> json) {
    return StoryPagination(
      currentPage: _nonNegativeInteger(json, 'currentPage'),
      pageSize: _nonNegativeInteger(json, 'pageSize'),
      totalItems: _nonNegativeInteger(json, 'totalItems'),
      totalPages: _nonNegativeInteger(json, 'totalPages'),
    );
  }

  static int _nonNegativeInteger(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int || value < 0) {
      throw FormatException('Pagination field "$key" is missing or invalid.');
    }
    return value;
  }
}
