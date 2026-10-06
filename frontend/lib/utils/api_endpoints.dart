class ApiEndpoints {
  static const String healthCheck = '/api/health';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String updateRole = '/api/auth/role';
  static const String youthProfile = '/api/auth/youth-profile';
  static const String elderProfile = '/api/auth/elder-profile';

  // AI learning tools
  static const String storyTranslation = '/api/ai/story-translation';
  static const String termExplanation = '/api/ai/term-explanation';
  static const String vocabularyTranslation = '/api/ai/vocabulary-translation';

  // Content
  static const String culturalContent = '/api/content';

  // Connections
  static const String connections = '/api/connections';
}
