# QuizForge AI API & Contract Specification

This document provides formal technical specifications for public service interfaces, repository contracts, AI provider abstractions, dataset importers, search engines, and analytics APIs in **QuizForge AI**.

---

## 1. AI & LLM Provider Contracts

### A. `AIProvider` Interface (`lib/services/ai/ai_provider.dart`)

```dart
abstract class AIProvider {
  String get providerId;
  String get providerName;
  Future<bool> isConfigured();

  Future<String> explainAnswer({
    required String question,
    required String selectedAnswer,
    required String correctAnswer,
    String? context,
  });

  Future<String> generateMnemonic({
    required String topic,
    required String concept,
  });

  Future<String> suggestRevisionPlan({
    required List<String> weakTopics,
    required int totalDaysAvailable,
  });

  Future<List<String>> recommendPyqs({
    required List<String> weakConcepts,
    required List<String> availablePyqTitles,
  });

  Future<List<Map<String, dynamic>>> generateSimilarQuestions({
    required String questionText,
    required String subject,
    required String topic,
    int count = 3,
  });

  Future<List<String>> identifyWeakConcepts({
    required Map<String, dynamic> analyticsSummary,
  });

  Future<String> answerUserDoubt({
    required String doubtText,
    String? questionContext,
  });
}
```

### B. `LearningCoach` Interface (`lib/services/ai/coach/learning_coach.dart`)

```dart
abstract class LearningCoach {
  String get providerId;
  String get providerName;

  Future<PerformanceAnalysis> analyzePerformance({
    required LearningInsightsModel insights,
  });

  Future<RevisionRecommendation> recommendRevision({
    required List<String> weakTopics,
    required List<PyqQuestionModel> questions,
  });

  Future<WeaknessExplanation> explainWeakness({
    required String weaknessTopic,
    required double accuracyPercent,
  });

  Future<StudyPlan> generateStudyPlan({
    required List<String> weakTopics,
    required int totalDays,
    required double dailyHoursAvailable,
  });
}
```

---

## 2. Repository Contracts

### A. `PyqRepository` (`lib/repositories/pyq_repository.dart`)

```dart
abstract class PyqRepository {
  Future<void> init();
  Future<List<PyqQuestionModel>> getAllQuestions();
  Future<List<PyqQuestionModel>> getQuestionsByYear(int year);
  Future<List<PyqQuestionModel>> getQuestionsBySubject(String subject);
  Future<List<PyqQuestionModel>> getQuestionsByTopic(String topic);
  Future<List<PyqQuestionModel>> getBookmarkedQuestions();
  Future<List<PyqQuestionModel>> getIncorrectQuestions();

  Future<List<PyqQuestionModel>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    bool? onlyBookmarked,
    bool? onlyIncorrect,
    bool? unattempted,
  });

  Future<void> toggleBookmark(String questionId);
  Future<void> recordAttempt({
    required String questionId,
    required String selectedAnswer,
  });

  Future<DailyRevisionQueue> getDailyRevisionQueue();
  Future<void> recordSpacedRevisionResult({
    required String questionId,
    required bool isCorrect,
    required int confidenceRating,
  });
}
```

### B. `AnalyticsRepository` (`lib/repositories/analytics_repository.dart`)

```dart
abstract class AnalyticsRepository {
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot);
  Future<List<AnalyticsSnapshot>> getSnapshots();
  Future<AnalyticsSnapshot?> getLatestSnapshot();
  Future<void> deleteSnapshot(String snapshotId);
  Future<void> clear();
}
```

---

## 3. Spaced Repetition Strategy API (`lib/services/revision_strategy.dart`)

```dart
abstract class RevisionStrategy {
  RevisionSchedule computeNextSchedule({
    required String questionId,
    required RevisionSchedule? existingSchedule,
    required bool isCorrect,
    required int confidenceRating,
    required String difficulty,
    required bool isBookmarked,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  });

  double calculatePriorityScore({
    required DateTime nextReviewDue,
    required int mistakeCount,
    required bool isBookmarked,
    required String difficulty,
    required int confidenceRating,
    DateTime? lastAttempt,
    int timeTakenSeconds = 0,
  });

  String getPriorityTier(double priorityScore);

  DailyRevisionQueue buildDailyQueue({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  });

  Map<String, List<RevisionQueueItem>> buildRevisionCalendar({
    required List<PyqQuestionModel> questions,
    required Map<String, RevisionSchedule> scheduleMap,
  });

  List<String> buildSmartRecommendations({
    required List<RevisionQueueItem> items,
  });
}
```

---

## 4. Importer & Search Specifications

### A. `GenericDatasetImporter` (`lib/services/generic_dataset_importer.dart`)
- **`importJson(String rawJson, {bool strictMode = false})`**: Parses and validates raw JSON payload into structured question lists.
- **`ValidationReport validate(List<Map<String, dynamic>> rawList)`**: Checks all 7 validation rules (`VAL_001` through `VAL_007`) and returns error/warning summary.

### B. `PyqSearchEngine` (`lib/services/search/pyq_search_engine.dart`)
- Full-text search engine executing string tokenization, keyword matching, exact year/subject/topic filtering, and bookmark/incorrect bank filtering.

### C. `AnalyticsExporter` (`lib/services/analytics_exporter.dart`)
- **`exportToJson(LearningInsightsModel insights)`**: Returns formatted JSON string.
- **`exportToCsv(LearningInsightsModel insights)`**: Returns standard CSV table string.
- **`exportToPdfTextReport(LearningInsightsModel insights)`**: Returns formatted printable text summary.
