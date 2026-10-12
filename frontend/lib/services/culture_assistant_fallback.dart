class CultureAssistantFallback {
  const CultureAssistantFallback._();

  static List<String> questions({required String topic, String answer = ''}) {
    final subject = topic.trim().isEmpty ? 'this tradition' : topic.trim();
    if (answer.trim().isEmpty) {
      return [
        'How did you first learn about $subject?',
        'Who helped preserve $subject in your family or community?',
        'How has $subject changed across generations?',
      ];
    }
    return const [
      'Could you tell me more about that memory?',
      'Who taught you this, and how was it passed on?',
      'What would you like younger generations to remember?',
    ];
  }

  static Map<String, dynamic> categoryTags({
    required String contentType,
    required String title,
    required String content,
  }) {
    final text = '$title $content'.toLowerCase();
    final category =
        text.contains('recipe') ||
            text.contains('food') ||
            text.contains('dish') ||
            contentType == 'Recipe'
        ? 'Food & Recipes'
        : text.contains('song') ||
              text.contains('music') ||
              contentType == 'Song'
        ? 'Music & Songs'
        : text.contains('festival') || contentType == 'Festival'
        ? 'Festivals'
        : text.contains('temple') || text.contains('history')
        ? 'History & Heritage'
        : 'Cultural Traditions';
    const stopWords = {
      'about',
      'after',
      'also',
      'been',
      'being',
      'from',
      'have',
      'into',
      'that',
      'their',
      'there',
      'these',
      'they',
      'this',
      'through',
      'with',
      'would',
      'were',
      'when',
      'where',
      'which',
      'while',
      'your',
      'traditional',
      'tradition',
      'culture',
      'cultural',
      'story',
      'content',
      'during',
      'people',
      'often',
      'made',
      'make',
      'used',
      'using',
      'very',
      'many',
      'some',
    };
    final words = RegExp(r'[a-z0-9]{3,}')
        .allMatches('$title $content')
        .map((match) => match.group(0)!)
        .where((word) => !stopWords.contains(word))
        .toSet()
        .take(6)
        .toList();
    if (words.isEmpty && title.trim().isNotEmpty) {
      words.addAll(title.toLowerCase().split(RegExp(r'\s+')).take(3));
    }
    return {
      'category': category,
      'tags': words
          .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
          .toList(),
    };
  }

  static Map<String, String> chatDraft({
    required String topic,
    required List<Map<String, dynamic>> messages,
    required String currentUserId,
  }) {
    final transcript = messages
        .map((message) {
          final speaker = message['sender']?.toString() == currentUserId
              ? 'Youth'
              : 'Elder';
          return '$speaker: ${message['text']?.toString() ?? ''}';
        })
        .join('\n\n');
    final subject = topic.trim().isEmpty
        ? 'Cultural Conversation'
        : topic.trim();
    return {
      'title': '$subject - Conversation Notes',
      'description': 'A conversation record prepared for the elder to review.',
      'content': transcript,
      'culturalSignificance': 'To be confirmed by the elder.',
    };
  }
}
