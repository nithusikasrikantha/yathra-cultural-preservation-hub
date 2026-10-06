import 'dart:async';

import '../config/api_config.dart';
import '../utils/api_endpoints.dart';
import 'api_service.dart';
import 'auth_service.dart';

class VocabularyTranslation {
  const VocabularyTranslation({
    required this.original,
    required this.targetLanguage,
    required this.translatedText,
    required this.contextualMeaning,
    required this.example,
  });

  final String original;
  final String targetLanguage;
  final String translatedText;
  final String contextualMeaning;
  final String example;

  factory VocabularyTranslation.fromJson(Map<String, dynamic> json) {
    String requiredString(String key, {bool allowEmpty = false}) {
      final value = json[key];
      if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
        throw FormatException('Vocabulary field "$key" is invalid.');
      }
      return value.trim();
    }

    return VocabularyTranslation(
      original: requiredString('original'),
      targetLanguage: requiredString('targetLanguage'),
      translatedText: requiredString('translatedText'),
      contextualMeaning: requiredString('contextualMeaning'),
      example: requiredString('example', allowEmpty: true),
    );
  }
}

class VocabularyTranslationService {
  VocabularyTranslationService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;

  Future<VocabularyTranslation> translate({
    required String text,
    required String targetLanguage,
    required String storyId,
    required bool isDemo,
  }) async {
    dynamic result;
    try {
      result = await _apiService.post(
        ApiEndpoints.vocabularyTranslation,
        headers: await AuthService.authenticatedHeaders(),
        body: {
          'text': text.trim(),
          'targetLanguage': targetLanguage,
          'storyId': storyId,
          if (isDemo) 'demo': true,
        },
        timeout: const Duration(seconds: 35),
      );
    } on TimeoutException {
      throw Exception('The translation is taking too long. Please try again.');
    } catch (error) {
      if (error.toString().contains('POST request failed:')) {
        throw Exception(
          'Could not reach the vocabulary service. Check your connection and try again.',
        );
      }
      rethrow;
    }

    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        result['translation'] is! Map) {
      throw Exception(
        'The vocabulary response could not be read. Please try again.',
      );
    }

    try {
      return VocabularyTranslation.fromJson(
        Map<String, dynamic>.from(result['translation'] as Map),
      );
    } on FormatException {
      throw Exception(
        'The vocabulary response could not be read. Please try again.',
      );
    }
  }
}
