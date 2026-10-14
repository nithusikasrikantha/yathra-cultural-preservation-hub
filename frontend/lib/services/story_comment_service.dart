import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class StoryComment {
  const StoryComment({
    required this.id,
    required this.authorName,
    required this.text,
    this.authorAvatar,
    this.createdAt,
  });

  final String id;
  final String authorName;
  final String text;
  final String? authorAvatar;
  final DateTime? createdAt;

  factory StoryComment.fromJson(Map<String, dynamic> json) {
    final id = _stringValue(json['_id'] ?? json['id']);
    final authorName = _stringValue(json['authorName']);
    final text = _stringValue(json['text']);
    if (id.isEmpty || authorName.isEmpty || text.isEmpty) {
      throw const FormatException('Invalid story comment.');
    }

    return StoryComment(
      id: id,
      authorName: authorName,
      text: text,
      authorAvatar: _optionalString(json['authorAvatar'] ?? json['avatar']),
      createdAt: DateTime.tryParse(_stringValue(json['createdAt'])),
    );
  }

  static String _stringValue(dynamic value) =>
      value is String ? value.trim() : '';

  static String? _optionalString(dynamic value) {
    final result = _stringValue(value);
    return result.isEmpty ? null : result;
  }
}

class StoryCommentService {
  StoryCommentService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;

  Future<List<StoryComment>> fetchComments(String storyId) async {
    final response = await _apiService.get('/api/stories/$storyId/comments');
    if (response is! Map<String, dynamic> || response['comments'] is! List) {
      throw const FormatException('Invalid story comments response.');
    }
    return (response['comments'] as List)
        .whereType<Map<String, dynamic>>()
        .map(StoryComment.fromJson)
        .toList(growable: true);
  }

  Future<StoryComment> addComment({
    required String storyId,
    required String text,
  }) async {
    final response = await _apiService.post(
      '/api/stories/$storyId/comments',
      headers: await AuthService.authenticatedHeaders(),
      body: {'text': text.trim()},
      timeout: const Duration(seconds: 15),
    );
    if (response is! Map<String, dynamic> || response['comment'] is! Map) {
      throw const FormatException('Invalid story comment response.');
    }
    return StoryComment.fromJson(
      Map<String, dynamic>.from(response['comment'] as Map),
    );
  }
}
