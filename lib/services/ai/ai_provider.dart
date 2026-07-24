abstract class AIProvider {
  /// Unique identifier for the provider (e.g. 'gemini', 'openai', 'claude', 'local_llm')
  String get providerId;

  /// Display name for the provider
  String get providerName;

  /// Returns whether necessary credentials / connections are configured
  Future<bool> isConfigured();

  /// 1. Explain why the selected answer is correct or incorrect with conceptual breakdown
  Future<String> explainAnswer({
    required String question,
    required String selectedAnswer,
    required String correctAnswer,
    String? context,
  });

  /// 2. Generate memory tricks and mnemonics for complex topics/concepts
  Future<String> generateMnemonic({
    required String topic,
    required String concept,
  });

  /// 3. Suggest a structured revision plan based on weak topics and timeline
  Future<String> suggestRevisionPlan({
    required List<String> weakTopics,
    required int totalDaysAvailable,
  });

  /// 4. Recommend targeted PYQs based on student weak concept areas
  Future<List<String>> recommendPyqs({
    required List<String> weakConcepts,
    required List<String> availablePyqTitles,
  });

  /// 5. Generate similar practice questions matching UPSC Prelims standard
  Future<List<Map<String, dynamic>>> generateSimilarQuestions({
    required String questionText,
    required String subject,
    required String topic,
    int count = 3,
  });

  /// 6. Analyze performance metrics to identify weak conceptual pillars
  Future<List<String>> identifyWeakConcepts({
    required Map<String, dynamic> analyticsSummary,
  });

  /// 7. Interactive Q&A to resolve student doubts in real-time
  Future<String> answerUserDoubt({
    required String doubtText,
    String? questionContext,
  });
}
