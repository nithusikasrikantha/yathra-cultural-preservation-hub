import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/story.dart';

class StoryService {
  const StoryService();

  Future<StoryPage> fetchStories({
    required int page,
    int limit = 10,
    String? search,
    String? category,
    List<String> tags = const [],
  }) async {
    final queryParameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };

    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      queryParameters['search'] = trimmedSearch;
    }

    final trimmedCategory = category?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      queryParameters['category'] = trimmedCategory;
    }

    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
    if (normalizedTags.isNotEmpty) {
      queryParameters['tags'] = normalizedTags.join(',');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/stories',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid stories response.');
    }

    return StoryPage.fromJson(decoded);
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Use the fallback below when the server does not return JSON.
    }

    return 'Unable to load stories. Server returned ${response.statusCode}.';
  }
}
