class Explanation {
  final String explanationId;
  final String questionId;
  final String
      explanationType; // Official UPSC, AI Generated, Editorial, Community, Personal Note
  final String content;
  final String source;
  final String author;
  final String version;
  final String language;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  Explanation({
    required this.explanationId,
    required this.questionId,
    required this.explanationType,
    required this.content,
    required this.source,
    this.author = 'Unknown',
    this.version = '1.0.0',
    this.language = 'English',
    DateTime? lastUpdated,
    this.metadata = const {},
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  String get id => explanationId;

  factory Explanation.fromJson(Map<String, dynamic> json) {
    final String expType = json['explanationType'] as String? ?? 'Official';
    String defaultAuthor = 'Unknown';
    if (expType.toLowerCase().contains('official') ||
        expType.toLowerCase().contains('upsc')) {
      defaultAuthor = 'Official UPSC';
    } else if (expType.toLowerCase().contains('ai')) {
      defaultAuthor = 'Gemini AI';
    } else if (expType.toLowerCase().contains('editorial')) {
      defaultAuthor = 'QuizForge Editorial';
    } else if (expType.toLowerCase().contains('community')) {
      defaultAuthor = 'Community Contributor';
    } else if (expType.toLowerCase().contains('note')) {
      defaultAuthor = 'Aspirant (Personal)';
    }

    return Explanation(
      explanationId:
          json['explanationId'] as String? ?? json['id'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      explanationType: expType,
      content: json['content'] as String? ?? '',
      source: json['source'] as String? ?? '',
      author: json['author'] as String? ?? defaultAuthor,
      version: json['version'] as String? ?? '1.0.0',
      language: json['language'] as String? ?? 'English',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'explanationId': explanationId,
      'id': explanationId,
      'questionId': questionId,
      'explanationType': explanationType,
      'content': content,
      'source': source,
      'author': author,
      'version': version,
      'language': language,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata,
    };
  }
}
