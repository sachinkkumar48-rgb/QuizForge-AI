library;

import '../repositories/act_repository.dart';

/// Single search result wrapper.
class ActSearchResult {
  final String title;
  final String subtitle;
  final String actId;
  final String? sectionId;
  final String resultType; // 'Act', 'Section', 'Chapter', 'Schedule', 'Case', 'Article'
  final double score;

  const ActSearchResult({
    required this.title,
    required this.subtitle,
    required this.actId,
    this.sectionId,
    required this.resultType,
    this.score = 1.0,
  });
}

/// Multi-faceted search and autocomplete engine for Central Acts.
class ActSearchEngine {
  final ActRepository repository;

  ActSearchEngine(this.repository);

  /// Execute multi-faceted search across Acts, Sections, Chapters, Schedules, Cases, and Articles.
  List<ActSearchResult> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <ActSearchResult>[];
    final acts = repository.getAllActs();

    for (final act in acts) {
      // Act Title & Short Title Match
      if (act.metadata.shortTitle.toLowerCase().contains(q) ||
          act.metadata.officialName.toLowerCase().contains(q)) {
        results.add(ActSearchResult(
          title: act.metadata.shortTitle,
          subtitle: '${act.metadata.officialName} (${act.metadata.year})',
          actId: act.actId,
          resultType: 'Act',
          score: 1.0,
        ));
      }

      // Keyword Match
      for (final kw in act.searchKeywords) {
        if (kw.toLowerCase().contains(q)) {
          results.add(ActSearchResult(
            title: '${act.metadata.shortTitle} - Keyword: $kw',
            subtitle: act.metadata.officialName,
            actId: act.actId,
            resultType: 'Keyword',
            score: 0.8,
          ));
        }
      }

      // Section Match
      for (final sec in act.sections) {
        final secMatch = sec.sectionNumber.toLowerCase() == q ||
            'section ${sec.sectionNumber}'.toLowerCase() == q ||
            sec.title.toLowerCase().contains(q) ||
            sec.keywords.any((k) => k.toLowerCase().contains(q));

        if (secMatch) {
          results.add(ActSearchResult(
            title: '${act.metadata.shortTitle} Sec ${sec.sectionNumber}: ${sec.title}',
            subtitle: sec.content,
            actId: act.actId,
            sectionId: sec.sectionId,
            resultType: 'Section',
            score: 0.9,
          ));
        }

        // Case Law Link Match
        for (final c in sec.landmarkCases) {
          if (c.toLowerCase().contains(q)) {
            results.add(ActSearchResult(
              title: '$c (Linked to Sec ${sec.sectionNumber})',
              subtitle: act.metadata.shortTitle,
              actId: act.actId,
              sectionId: sec.sectionId,
              resultType: 'Case',
              score: 0.85,
            ));
          }
        }

        // Constitutional Article Match
        for (final art in sec.relatedArticles) {
          if (art.toLowerCase().contains(q)) {
            results.add(ActSearchResult(
              title: '$art (Cross-linked to Sec ${sec.sectionNumber})',
              subtitle: act.metadata.shortTitle,
              actId: act.actId,
              sectionId: sec.sectionId,
              resultType: 'Article',
              score: 0.85,
            ));
          }
        }
      }

      // Chapter Match
      for (final chap in act.chapters) {
        if (chap.chapterNumber.toLowerCase().contains(q) || chap.title.toLowerCase().contains(q)) {
          results.add(ActSearchResult(
            title: '${act.metadata.shortTitle} ${chap.chapterNumber}: ${chap.title}',
            subtitle: chap.description,
            actId: act.actId,
            resultType: 'Chapter',
            score: 0.75,
          ));
        }
      }

      // Schedule Match
      for (final sch in act.schedules) {
        if (sch.scheduleNumber.toLowerCase().contains(q) || sch.title.toLowerCase().contains(q)) {
          results.add(ActSearchResult(
            title: '${act.metadata.shortTitle} ${sch.scheduleNumber}: ${sch.title}',
            subtitle: sch.description,
            actId: act.actId,
            resultType: 'Schedule',
            score: 0.75,
          ));
        }
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Autocomplete suggestions for query prefix.
  List<String> getAutocompleteSuggestions(String prefix) {
    final p = prefix.trim().toLowerCase();
    if (p.isEmpty) return [];

    final suggestions = <String>{};
    final acts = repository.getAllActs();

    for (final act in acts) {
      if (act.metadata.shortTitle.toLowerCase().startsWith(p)) {
        suggestions.add(act.metadata.shortTitle);
      }
      for (final kw in act.searchKeywords) {
        if (kw.toLowerCase().startsWith(p)) {
          suggestions.add(kw);
        }
      }
      for (final sec in act.sections) {
        if (sec.title.toLowerCase().startsWith(p)) {
          suggestions.add(sec.title);
        }
        if ('section ${sec.sectionNumber}'.toLowerCase().startsWith(p)) {
          suggestions.add('Section ${sec.sectionNumber}');
        }
      }
    }

    return suggestions.take(10).toList();
  }
}
