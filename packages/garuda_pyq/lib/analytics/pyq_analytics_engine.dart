library;

import '../repository/pyq_repository_interface.dart';

/// Master Analytics Summary Report for GARUDA PYQ Engine.
class AnalyticsSummary {
  final Map<String, int> topicFrequency;
  final Map<String, int> conceptRecurrence;
  final Map<String, int> examDistribution;
  final Map<int, int> yearTrend;
  final Map<String, int> difficultyDistribution;
  final Map<String, List<String>> crossExamMapping;
  final Map<String, int> articleFrequency;
  final Map<String, int> actFrequency;
  final Map<String, int> caseFrequency;
  final Map<String, int> doctrineFrequency;
  final Map<String, int> subjectDistribution;
  final Map<String, int> questionNatureDistribution;
  final Map<String, int> repeatConceptAnalysis;

  const AnalyticsSummary({
    required this.topicFrequency,
    required this.conceptRecurrence,
    required this.examDistribution,
    required this.yearTrend,
    required this.difficultyDistribution,
    required this.crossExamMapping,
    required this.articleFrequency,
    required this.actFrequency,
    required this.caseFrequency,
    required this.doctrineFrequency,
    required this.subjectDistribution,
    required this.questionNatureDistribution,
    required this.repeatConceptAnalysis,
  });
}

/// Comprehensive Analytics Engine for Master PYQ Corpus.
class PYQAnalyticsEngine {
  final IPYQRepository repository;

  PYQAnalyticsEngine(this.repository);

  /// Generate analytics metrics across all questions or filtered by exam.
  Future<AnalyticsSummary> generateAnalytics({String? examId}) async {
    final questions = examId != null
        ? await repository.getQuestionsByExam(examId)
        : await repository.getAllQuestions();

    final topicFreq = <String, int>{};
    final conceptRec = <String, int>{};
    final examDist = <String, int>{};
    final yearTr = <int, int>{};
    final diffDist = <String, int>{};
    final crossMapping = <String, Set<String>>{};
    final artFreq = <String, int>{};
    final actFreq = <String, int>{};
    final caseFreq = <String, int>{};
    final docFreq = <String, int>{};
    final subjDist = <String, int>{};
    final natureDist = <String, int>{};
    final repeatConcepts = <String, int>{};

    for (final q in questions) {
      // Subject & Topic Frequency
      subjDist[q.subject] = (subjDist[q.subject] ?? 0) + 1;
      topicFreq[q.topic] = (topicFreq[q.topic] ?? 0) + 1;

      // Exam & Year distribution
      examDist[q.examId] = (examDist[q.examId] ?? 0) + 1;
      yearTr[q.year] = (yearTr[q.year] ?? 0) + 1;

      // Difficulty & Nature distribution
      diffDist[q.difficulty] = (diffDist[q.difficulty] ?? 0) + 1;
      final natureName = q.questionNature.name;
      natureDist[natureName] = (natureDist[natureName] ?? 0) + 1;

      // Concept recurrence
      for (final tag in q.tags) {
        conceptRec[tag] = (conceptRec[tag] ?? 0) + 1;
      }
      for (final mc in q.microConcepts) {
        repeatConcepts[mc] = (repeatConcepts[mc] ?? 0) + 1;
      }

      // Legal & Knowledge Links Frequencies
      for (final art in q.articleLinks) {
        artFreq[art] = (artFreq[art] ?? 0) + 1;
      }
      for (final act in q.actLinks) {
        actFreq[act] = (actFreq[act] ?? 0) + 1;
      }
      for (final c in q.caseLinks) {
        caseFreq[c] = (caseFreq[c] ?? 0) + 1;
      }
      if (q.subtopic != null) {
        docFreq[q.subtopic!] = (docFreq[q.subtopic!] ?? 0) + 1;
      }

      // Cross exam mapping
      crossMapping.putIfAbsent(q.topic, () => <String>{}).add(q.examId);
    }

    return AnalyticsSummary(
      topicFrequency: topicFreq,
      conceptRecurrence: conceptRec,
      examDistribution: examDist,
      yearTrend: yearTr,
      difficultyDistribution: diffDist,
      crossExamMapping: crossMapping.map((k, v) => MapEntry(k, v.toList())),
      articleFrequency: artFreq,
      actFrequency: actFreq,
      caseFrequency: caseFreq,
      doctrineFrequency: docFreq,
      subjectDistribution: subjDist,
      questionNatureDistribution: natureDist,
      repeatConceptAnalysis: repeatConcepts,
    );
  }
}
