import 'dart:async';

import '../config/api_config.dart';
import '../utils/api_endpoints.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CulturalTermExplanation {
  const CulturalTermExplanation({
    required this.term,
    required this.targetLanguage,
    required this.meaning,
    required this.culturalContext,
    required this.example,
  });

  final String term;
  final String targetLanguage;
  final String meaning;
  final String culturalContext;
  final String example;

  factory CulturalTermExplanation.fromJson(Map<String, dynamic> json) {
    String requiredString(String key, {bool allowEmpty = false}) {
      final value = json[key];
      if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
        throw FormatException('Explanation field "$key" is invalid.');
      }
      return value.trim();
    }

    return CulturalTermExplanation(
      term: requiredString('term'),
      targetLanguage: requiredString('targetLanguage'),
      meaning: requiredString('meaning'),
      culturalContext: requiredString('culturalContext'),
      example: requiredString('example', allowEmpty: true),
    );
  }
}

class TermExplanationService {
  TermExplanationService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;

  Future<CulturalTermExplanation> explainTerm({
    required String term,
    required String targetLanguage,
    required String storyId,
    required bool isDemo,
  }) async {
    dynamic result;
    try {
      result = await _apiService.post(
        ApiEndpoints.termExplanation,
        headers: await AuthService.authenticatedHeaders(),
        body: {
          'term': term.trim(),
          'targetLanguage': targetLanguage,
          'storyId': storyId,
          if (isDemo) 'demo': true,
        },
        timeout: const Duration(seconds: 35),
      );
    } on TimeoutException {
      throw Exception('The explanation is taking too long. Please try again.');
    } catch (error) {
      if (error.toString().contains('POST request failed:')) {
        throw Exception(
          'Could not reach the explanation service. Check your connection and try again.',
        );
      }
      rethrow;
    }

    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        result['explanation'] is! Map) {
      throw Exception(
        'The explanation response could not be read. Please try again.',
      );
    }

    try {
      return CulturalTermExplanation.fromJson(
        Map<String, dynamic>.from(result['explanation'] as Map),
      );
    } on FormatException {
      throw Exception(
        'The explanation response could not be read. Please try again.',
      );
    }
  }
}
