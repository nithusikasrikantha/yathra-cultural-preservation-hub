import 'dart:async';

import '../config/api_config.dart';
import '../utils/api_endpoints.dart';
import 'api_service.dart';
import 'auth_service.dart';

class StoryTranslation {
  const StoryTranslation({
    required this.storyId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.translatedText,
  });

  final String storyId;
  final String sourceLanguage;
  final String targetLanguage;
  final String translatedText;

  factory StoryTranslation.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Translation field "$key" is missing or invalid.',
        );
      }
      return value;
    }

    return StoryTranslation(
      storyId: requiredString('storyId'),
      sourceLanguage: requiredString('sourceLanguage'),
      targetLanguage: requiredString('targetLanguage'),
      translatedText: requiredString('translatedText'),
    );
  }
}

class TranslationService {
  TranslationService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;

  Future<StoryTranslation> translateStory({
    required String storyId,
    required String targetLanguage,
  }) async {
    return _translate({'storyId': storyId, 'targetLanguage': targetLanguage});
  }

  Future<StoryTranslation> translateDemoStory({
    required String storyId,
    required String storyText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    return _translate({
      'demo': true,
      'storyId': storyId,
      'storyText': storyText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
    });
  }

  Future<StoryTranslation> _translate(Map<String, dynamic> body) async {
    dynamic result;
    try {
      result = await _apiService.post(
        ApiEndpoints.storyTranslation,
        headers: await AuthService.authenticatedHeaders(),
        body: body,
        timeout: const Duration(seconds: 35),
      );
    } on TimeoutException {
      throw Exception('Translation is taking too long. Please try again.');
    } catch (error) {
      if (error.toString().contains('POST request failed:')) {
        throw Exception(
          'Could not reach the translation service. Check your connection and try again.',
        );
      }
      rethrow;
    }

    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        result['translation'] is! Map) {
      throw Exception(
        'The translation response could not be read. Please try again.',
      );
    }

    try {
      return StoryTranslation.fromJson(
        Map<String, dynamic>.from(result['translation'] as Map),
      );
    } on FormatException {
      throw Exception(
        'The translation response could not be read. Please try again.',
      );
    }
  }
}
