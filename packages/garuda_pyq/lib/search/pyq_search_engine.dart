library;

import '../models/question_model.dart';
import '../repository/pyq_repository_interface.dart';

/// Structured Search Query parameters for Master PYQ Corpus.
class PYQSearchQuery {
  final String? examId;
  final int? year;
  final int? questionNumber;
  final String? subject;
  final String? topic;
  final String? subtopic;
  final String? microConcept;
  final String? article;
  final String? caseName;
  final String? actName;
  final String? doctrine;
  final String? committee;
  final String? scheme;
  final String? currentAffairs;
  final String? keyword;
  final String? difficulty;
  final String? language;

  const PYQSearchQuery({
    this.examId,
    this.year,
    this.questionNumber,
    this.subject,
    this.topic,
    this.subtopic,
    this.microConcept,
    this.article,
    this.caseName,
    this.actName,
    this.doctrine,
    this.committee,
    this.scheme,
    this.currentAffairs,
    this.keyword,
    this.difficulty,
    this.language,
  });

  Map<String, dynamic> toCriteriaMap() => {
        'examId': examId,
        'year': year,
        'questionNumber': questionNumber,
        'subject': subject,
        'topic': topic,
        'subtopic': subtopic,
        'microConcept': microConcept,
        'article': article,
        'case': caseName,
        'act': actName,
        'doctrine': doctrine,
        'committee': committee,
        'scheme': scheme,
        'currentAffairs': currentAffairs,
        'keyword': keyword,
        'difficulty': difficulty,
        'language': language,
      };
}

/// Multi-faceted search, autocomplete, and suggestion engine for GARUDA PYQ.
class PYQSearchEngine {
  final IPYQRepository repository;

  PYQSearchEngine(this.repository);

  /// Execute structured search against repository.
  Future<List<Question>> search(PYQSearchQuery query) async {
    final all = await repository.getAllQuestions();

    return all.where((q) {
      if (query.examId != null && q.examId.toLowerCase() != query.examId!.toLowerCase()) return false;
      if (query.year != null && q.year != query.year) return false;
      if (query.questionNumber != null && q.questionNumber != query.questionNumber) return false;
      if (query.subject != null && q.subject.toLowerCase() != query.subject!.toLowerCase()) return false;
      if (query.topic != null && !q.topic.toLowerCase().contains(query.topic!.toLowerCase())) return false;
      if (query.subtopic != null && (q.subtopic == null || !q.subtopic!.toLowerCase().contains(query.subtopic!.toLowerCase()))) return false;
      if (query.microConcept != null && !q.microConcepts.any((m) => m.toLowerCase().contains(query.microConcept!.toLowerCase()))) return false;

      if (query.article != null) {
        final targetArt = query.article!.trim().toLowerCase();
        final artRegex = RegExp(r'\b' + RegExp.escape(targetArt) + r'\b', caseSensitive: false);
        final matchesArt = q.articleLinks.any((a) => a.toLowerCase() == targetArt || artRegex.hasMatch(a.toLowerCase()));
        if (!matchesArt) return false;
      }
      if (query.caseName != null && !q.caseLinks.any((c) => c.toLowerCase().contains(query.caseName!.toLowerCase()))) return false;
      if (query.actName != null && !q.actLinks.any((ac) => ac.toLowerCase().contains(query.actName!.toLowerCase()))) return false;
      if (query.committee != null && !q.committeeLinks.any((cm) => cm.toLowerCase().contains(query.committee!.toLowerCase()))) return false;
      if (query.doctrine != null) {
        final docKw = query.doctrine!.toLowerCase();
        final matchesDoc = (q.subtopic != null && q.subtopic!.toLowerCase().contains(docKw)) ||
            q.tags.any((t) => t.toLowerCase().contains(docKw)) ||
            q.garudaExplanation.toLowerCase().contains(docKw);
        if (!matchesDoc) return false;
      }
      if (query.scheme != null) {
        final schKw = query.scheme!.toLowerCase();
        final matchesScheme = q.topic.toLowerCase().contains(schKw) ||
            q.tags.any((t) => t.toLowerCase().contains(schKw)) ||
            q.originalQuestion.toLowerCase().contains(schKw);
        if (!matchesScheme) return false;
      }
      if (query.currentAffairs != null) {
        final caKw = query.currentAffairs!.toLowerCase();
        final matchesCA = q.currentAffairsLinks.any((ca) => ca.toLowerCase().contains(caKw)) ||
            q.tags.any((t) => t.toLowerCase().contains(caKw));
        if (!matchesCA) return false;
      }

      if (query.keyword != null && query.keyword!.trim().isNotEmpty) {
        final kw = query.keyword!.toLowerCase();
        final matches = q.originalQuestion.toLowerCase().contains(kw) ||
            q.garudaExplanation.toLowerCase().contains(kw) ||
            q.topic.toLowerCase().contains(kw) ||
            q.tags.any((t) => t.toLowerCase().contains(kw));
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  /// Search questions by legal and constitutional references.
  Future<List<Question>> searchByLegalReference({
    String? article,
    String? caseName,
    String? actName,
    String? doctrine,
  }) async {
    return search(PYQSearchQuery(
      article: article,
      caseName: caseName,
      actName: actName,
      doctrine: doctrine,
    ));
  }

  /// Get autocomplete suggestions for query prefix.
  Future<List<String>> getAutocompleteSuggestions(String prefix) async {
    final p = prefix.trim().toLowerCase();
    if (p.isEmpty) return [];

    final suggestions = <String>{};
    final questions = await repository.getAllQuestions();

    for (final q in questions) {
      if (q.topic.toLowerCase().startsWith(p)) suggestions.add(q.topic);
      if (q.subject.toLowerCase().startsWith(p)) suggestions.add(q.subject);
      for (final mc in q.microConcepts) {
        if (mc.toLowerCase().startsWith(p)) suggestions.add(mc);
      }
      for (final art in q.articleLinks) {
        if (art.toLowerCase().startsWith(p)) suggestions.add(art);
      }
      for (final act in q.actLinks) {
        if (act.toLowerCase().startsWith(p)) suggestions.add(act);
      }
      for (final c in q.caseLinks) {
        if (c.toLowerCase().startsWith(p)) suggestions.add(c);
      }
    }

    return suggestions.take(10).toList();
  }

  /// Get contextual search suggestions.
  Future<List<String>> getSearchSuggestions(String query) async {
    final q = query.trim().toLowerCase();
    final suggestions = <String>{};
    final questions = await repository.getAllQuestions();

    for (final item in questions) {
      if (item.topic.toLowerCase().contains(q)) suggestions.add(item.topic);
      for (final tag in item.tags) {
        if (tag.toLowerCase().contains(q)) suggestions.add(tag);
      }
    }

    return suggestions.take(5).toList();
  }
}
