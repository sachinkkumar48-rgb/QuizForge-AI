import 'dart:convert';
import '../models/analytics_engine_models.dart';

/// Multi-format Exporter (CSV, JSON, PDF/Text Report) for QuizForge AI Analytics.
class AnalyticsExporter {
  /// Export learning insights to formatted JSON string.
  static String exportToJson(LearningInsightsModel insights) {
    final Map<String, dynamic> data = {
      'generatedAt': DateTime.now().toIso8601String(),
      'overallAccuracy': insights.overallAccuracy,
      'averageTimePerQuestionSeconds': insights.averageTimePerQuestionSeconds,
      'dailyQuestionsSolved': insights.dailyQuestionsSolved,
      'weeklyQuestionsSolved': insights.weeklyQuestionsSolved,
      'monthlyQuestionsSolved': insights.monthlyQuestionsSolved,
      'currentStreak': insights.currentStreak,
      'longestStreak': insights.longestStreak,
      'bookmarkCount': insights.bookmarkCount,
      'incorrectQuestionCount': insights.incorrectQuestionCount,
      'weakSubjects': insights.weakSubjects,
      'strongSubjects': insights.strongSubjects,
      'weakAreaInsights':
          insights.weakAreaInsights.map((w) => w.toJson()).toList(),
      'subjectAccuracy':
          insights.subjectAccuracy.map((k, v) => MapEntry(k, v.toJson())),
      'topicAccuracy':
          insights.topicAccuracy.map((k, v) => MapEntry(k, v.toJson())),
      'difficultyAccuracy':
          insights.difficultyAccuracy.map((k, v) => MapEntry(k, v.toJson())),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export learning insights to standard CSV format.
  static String exportToCsv(LearningInsightsModel insights) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        'Dimension,Name,Total Questions,Attempted,Correct,Accuracy %,Confidence');

    // Subjects
    insights.subjectAccuracy.forEach((name, acc) {
      final conf =
          ConfidenceLevel.fromAttemptCount(acc.attemptedQuestions).name;
      buffer.writeln(
          'Subject,"$name",${acc.totalQuestions},${acc.attemptedQuestions},${acc.correctQuestions},${acc.accuracyPercent.toStringAsFixed(1)},$conf');
    });

    // Topics
    insights.topicAccuracy.forEach((name, acc) {
      final conf =
          ConfidenceLevel.fromAttemptCount(acc.attemptedQuestions).name;
      buffer.writeln(
          'Topic,"$name",${acc.totalQuestions},${acc.attemptedQuestions},${acc.correctQuestions},${acc.accuracyPercent.toStringAsFixed(1)},$conf');
    });

    // Difficulties
    insights.difficultyAccuracy.forEach((name, acc) {
      final conf =
          ConfidenceLevel.fromAttemptCount(acc.attemptedQuestions).name;
      buffer.writeln(
          'Difficulty,"$name",${acc.totalQuestions},${acc.attemptedQuestions},${acc.correctQuestions},${acc.accuracyPercent.toStringAsFixed(1)},$conf');
    });

    return buffer.toString();
  }

  /// Export learning insights to printable PDF / Plain Text Summary.
  static String exportToPdfTextReport(LearningInsightsModel insights) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('           QUIZFORGE AI LEARNING INSIGHTS           ');
    buffer.writeln('====================================================');
    buffer.writeln(
        'Generated: ${DateTime.now().toLocal().toString().split('.').first}');
    buffer.writeln('\n1. OVERALL METRICS:');
    buffer.writeln(
        ' - Overall Accuracy: ${insights.overallAccuracy.toStringAsFixed(1)}%');
    buffer.writeln(
        ' - Current Streak: ${insights.currentStreak} Days (Max: ${insights.longestStreak} Days)');
    buffer
        .writeln(' - Questions Solved Today: ${insights.dailyQuestionsSolved}');
    buffer.writeln(
        ' - Questions Solved This Week: ${insights.weeklyQuestionsSolved}');
    buffer.writeln(
        ' - Questions Solved This Month: ${insights.monthlyQuestionsSolved}');
    buffer.writeln(' - Bookmarked Questions: ${insights.bookmarkCount}');
    buffer.writeln(
        ' - Incorrect Question Bank: ${insights.incorrectQuestionCount}');
    buffer.writeln(
        ' - Avg Time / Question: ${insights.averageTimePerQuestionSeconds.toStringAsFixed(1)} seconds');

    buffer.writeln('\n2. WEAK AREA INSIGHTS & CONFIDENCE:');
    if (insights.weakAreaInsights.isEmpty) {
      buffer.writeln(' - No critical weak areas detected! Excellent progress.');
    } else {
      for (final w in insights.weakAreaInsights) {
        buffer.writeln(
            ' • [${w.dimension.toUpperCase()}] ${w.name}: ${w.accuracyPercent.toStringAsFixed(1)}% (${w.confidenceLevel.label})');
        buffer.writeln('   Recommendation: ${w.recommendation}');
      }
    }

    buffer.writeln('\n3. STRONG SUBJECTS:');
    if (insights.strongSubjects.isEmpty) {
      buffer.writeln(
          ' - Keep practicing to establish strong subjects (>=70% accuracy).');
    } else {
      for (final s in insights.strongSubjects) {
        buffer.writeln(' • $s');
      }
    }

    buffer.writeln('\n====================================================');
    return buffer.toString();
  }
}
