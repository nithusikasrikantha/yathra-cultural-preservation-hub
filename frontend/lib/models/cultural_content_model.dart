class CulturalContent {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final String authorId;
  final String language;
  final List<MediaItem> media;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CulturalContent({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    required this.authorId,
    this.language = 'English',
    this.media = const [],
    this.status = 'published',
    this.createdAt,
    this.updatedAt,
  });

  factory CulturalContent.fromJson(Map<String, dynamic> json) {
    return CulturalContent(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'other',
      tags: List<String>.from(json['tags'] ?? []),
      authorId: json['author'] ?? '',
      language: json['language'] ?? 'English',
      media: (json['media'] as List? ?? [])
          .map((item) => MediaItem.fromJson(item))
          .toList(),
      status: json['status'] ?? 'published',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'author': authorId,
      'language': language,
      'media': media.map((item) => item.toJson()).toList(),
      'status': status,
    };
  }
}

class MediaItem {
  final String type;
  final String url;

  MediaItem({required this.type, required this.url});

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
    };
  }
}
