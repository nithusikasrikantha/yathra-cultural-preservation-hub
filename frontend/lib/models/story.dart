class Story {
  const Story({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    required this.storyText,
    this.audioPath,
    this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String language;
  final String storyText;
  final String? audioPath;
  final DateTime? createdAt;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: _requiredString(json, '_id'),
      title: _requiredString(json, 'title'),
      category: _requiredString(json, 'category'),
      language: _requiredString(json, 'language'),
      storyText: _requiredString(json, 'storyText'),
      audioPath: _optionalString(json['audioPath']),
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
