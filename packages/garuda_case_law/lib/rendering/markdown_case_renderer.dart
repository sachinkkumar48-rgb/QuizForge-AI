/// Markdown case renderer (TITAN-KO-015.0 P8).
///
/// Renders one `CaseKnowledgeObject` as deterministic, human-readable Markdown:
/// readable headings, consistent section ordering, lists for enumerations,
/// blockquotes for holding / ratio, and preserved legal text (Unicode /
/// Devanagari pass through unescaped). Only existing corpus fields are rendered
/// — nothing is inferred, and absent data is omitted rather than fabricated.
///
/// Precedent relationships come from the existing P5 [LegalGraph] when one is
/// supplied; otherwise the corpus-declared relationship fields are rendered.
/// Evidence is presented exactly as recorded on the case (ID, registry-derived
/// URL, verification date) — never guessed.
library;

import '../domain/entities/case_enums.dart';
import '../domain/entities/case_knowledge_object.dart';
import '../domain/entities/precedent_relationship.dart';
import '../graph/domain/legal_graph.dart';
import '../graph/domain/legal_graph_edge.dart';
import '../graph/domain/legal_graph_node_type.dart';
import '../intelligence/domain/judgment_intelligence.dart';
import 'evidence_entry.dart';

/// Renders a single case to Markdown. Deterministic for identical input.
class MarkdownCaseRenderer {
  /// Renders [c]. When [graph] is supplied, precedent/doctrine relationships
  /// are rendered from the existing P5 graph (never reconstructed); otherwise
  /// the corpus-declared relationship fields are used.
  static String render(CaseKnowledgeObject c, {LegalGraph? graph}) =>
      _MdDoc(c, graph: graph).build();

  // Convenience for callers that already hold an index of target case names.
  static String renderWith(CaseKnowledgeObject c,
          {LegalGraph? graph, required Map<String, String> names}) =>
      _MdDoc(c, graph: graph, names: names).build();
}

class _MdDoc {
  final CaseKnowledgeObject c;
  final LegalGraph? graph;
  final Map<String, String> names;
  final _MarkdownWriter _w = _MarkdownWriter();

  _MdDoc(this.c, {this.graph, Map<String, String>? names})
      : names = names ?? const {};

  /// Resolves a case ID to a display name (graph node name, supplied map, or
  /// the raw ID — never invented).
  String _caseName(String caseId) =>
      names[caseId] ??
      graph?.nodeFor(caseId, LegalGraphNodeType.caseLaw)?.name ??
      caseId;

  String _doctrineName(String doctrineId) =>
      graph?.nodeFor(doctrineId, LegalGraphNodeType.doctrine)?.name ??
      doctrineId;

  String build() {
    _w.h1(_nonEmpty(c.caseName) ?? 'Untitled Case');
    final citationLine = <String>[
      if (_nonEmpty(c.neutralCitation) != null) c.neutralCitation,
      if (_nonEmpty(c.citation) != null && c.citation != c.neutralCitation)
        c.citation,
    ].join(' | ');
    if (citationLine.isNotEmpty) {
      _w.line('*$citationLine*');
      _w.blank();
    }

    _identity();
    _legalContent();
    _judgmentIntelligence();
    _judicialSignificance();
    _doctrines();
    _precedentRelationships();
    _upscIntelligence();
    _crossLinks();
    _timeline();
    _evidence();

    return _w.toString();
  }

  // -------------------------------------------------------------------------
  // Case identity
  // -------------------------------------------------------------------------

  void _identity() {
    _w.h2('Case Identity');
    _kv('Case ID', '`${c.caseId}`');
    _kv('Object ID', '`${c.objectId}`');
    _kv('Short name', c.caseName);
    _kv('Full citation', c.citation);
    _kv('Neutral citation', c.neutralCitation);
    _kv('Reporter citation', c.reporterCitation);
    _kv('Judgment title', c.judgmentTitle);
    _kv('Court', c.court);
    _kv('Jurisdiction', c.jurisdiction);
    _kv('Decision date', _date(c.judgmentDate));
    _kv('Filing date', c.filingDate == null ? null : _date(c.filingDate!));
    _kv('Year', '${c.year}');
    _kv('Bench', c.bench);
    if (c.benchStrength > 0) _kv('Bench strength', '${c.benchStrength}');
    _kv('Authoring judge', c.authoringJudge);
    if (c.judges.isNotEmpty) _bullets('Judges', c.judges);
    if (c.parties.isNotEmpty) _bullets('Parties', c.parties);
    _kv('Petitioner', c.petitioner);
    _kv('Respondent', c.respondent);
    _kv('Case type', c.caseType?.displayName);
    _kv('Status', c.status.name);
    _kv('Court level', c.courtLevel.name);
    _kv('Present status', c.presentStatus);
    if (c.aliases.isNotEmpty) _bullets('Aliases', c.aliases);
    if (c.keywords.isNotEmpty) _bullets('Keywords', c.keywords);
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Legal content
  // -------------------------------------------------------------------------

  void _legalContent() {
    _w.h2('Legal Content');
    _paragraph('Facts', c.facts);
    _paragraph('Historical context', c.historicalContext);
    if (c.issues.isNotEmpty) _bullets('Issues', c.issues);
    if (c.constitutionalQuestions.isNotEmpty) {
      _bullets('Constitutional questions', c.constitutionalQuestions);
    }
    if (c.legalQuestions.isNotEmpty) {
      _bullets('Legal questions', c.legalQuestions);
    }
    if (c.petitionerArguments.isNotEmpty) {
      _bullets('Petitioner arguments', c.petitionerArguments);
    }
    if (c.respondentArguments.isNotEmpty) {
      _bullets('Respondent arguments', c.respondentArguments);
    }

    // Constitutional provisions.
    final articles = c.relatedArticles;
    final parts = c.relatedParts;
    final schedules = c.relatedSchedules;
    final amendments = c.relatedAmendments;
    if (articles.isNotEmpty) _bullets('Constitutional articles', articles);
    if (parts.isNotEmpty) _bullets('Constitutional parts', parts);
    if (schedules.isNotEmpty) _bullets('Constitutional schedules', schedules);
    if (amendments.isNotEmpty) {
      _bullets('Constitutional amendments', amendments);
    }

    // Statutory provisions.
    if (c.relatedActs.isNotEmpty) _bullets('Statutes / Acts', c.relatedActs);
    if (c.sections.isNotEmpty) _bullets('Statutory sections', c.sections);
    if (c.relatedRules.isNotEmpty) _bullets('Rules', c.relatedRules);
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Judgment intelligence (P4)
  // -------------------------------------------------------------------------

  void _judgmentIntelligence() {
    _w.h2('Judgment');
    final intel = c.judgmentIntelligence;

    if (c.decision.isNotEmpty) _paragraph('Decision', c.decision);

    if (intel != null && intel.holdings.isNotEmpty) {
      _w.h3('Holding');
      for (final h in intel.holdings) {
        _blockquote(h.holding);
        final sub = <String>[
          if (h.legalPrinciple.isNotEmpty)
            'Legal principle: ${h.legalPrinciple}',
          'Scope: ${h.scope.name}',
          'Confidence: ${h.confidence.name}',
          if (h.evidence.evidenceId.isNotEmpty)
            'Evidence: `${h.evidence.evidenceId}`',
        ];
        _w.line('*${sub.join(' · ')}*');
        _w.blank();
      }
    }

    if (c.ratioDecidendi.isNotEmpty) {
      _w.h3('Ratio Decidendi');
      for (final r in c.ratioDecidendi) {
        _blockquote(r);
      }
    } else if (intel != null && intel.ratios.isNotEmpty) {
      _w.h3('Ratio Decidendi');
      for (final r in intel.ratios) {
        _blockquote(r.ratio);
        final sub = <String>[
          'Type: ${r.type.name}',
          if (r.legalProposition.isNotEmpty)
            'Proposition: ${r.legalProposition}',
          if (r.constitutionalBasis.isNotEmpty)
            'Constitutional basis: ${r.constitutionalBasis}',
        ];
        _w.line('*${sub.join(' · ')}*');
        _w.blank();
      }
    }

    if (intel != null && intel.issues.isNotEmpty) {
      _w.h3('Issues Framed');
      for (final i in intel.issues) {
        _w.bullet(i.issue);
        final sub = <String>[
          'Category: ${i.category.name}',
          'Importance: ${i.importance.name}',
          if (i.relatedArticles.isNotEmpty)
            'Articles: ${i.relatedArticles.join(', ')}',
        ];
        _w.line('  *${sub.join(' · ')}*');
      }
      _w.blank();
    }

    if (intel?.reasoning != null) {
      final r = intel!.reasoning!;
      _w.h3('Reasoning');
      if (r.summary.isNotEmpty) _paragraph('Summary', r.summary);
      _kv('Interpretive approach', r.approach.name);
      if (r.constitutionalPhilosophy.isNotEmpty) {
        _bullets('Constitutional philosophy', r.constitutionalPhilosophy);
      }
      if (r.doctrinalReasoning.isNotEmpty) {
        _bullets('Doctrinal reasoning', r.doctrinalReasoning);
      }
      if (r.reasoningTools.isNotEmpty) {
        _bullets('Reasoning tools', r.reasoningTools);
      }
    }

    if (c.keyPrinciples.isNotEmpty) _bullets('Key principles', c.keyPrinciples);
    if (c.obiterDicta.isNotEmpty) _bullets('Obiter dicta', c.obiterDicta);
    _kv('Constitutional significance', c.constitutionalSignificance);
    _kv('Constitutional interpretation', c.constitutionalInterpretation);
    _kv('Legal principle', c.legalPrinciple);
    _kv('Majority opinion', c.majorityOpinion);
    _kv('Minority opinion', c.minorityOpinion);
    _kv('Dissent', c.dissent);

    if (intel?.outcome != null) {
      final o = intel!.outcome!;
      _w.h3('Outcome');
      _kv('Disposition', o.disposition.name);
      if (o.reliefGranted.isNotEmpty) {
        _bullets('Relief granted', o.reliefGranted);
      }
      if (o.reliefDenied.isNotEmpty) _bullets('Relief denied', o.reliefDenied);
      _kv('Operative result', o.operativeResult);
      _kv('Majority outcome', o.majorityOutcome);
      if (o.minorityOutcome != null && o.minorityOutcome!.isNotEmpty) {
        _kv('Minority outcome', o.minorityOutcome);
      }
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Judicial significance
  // -------------------------------------------------------------------------

  void _judicialSignificance() {
    final intel = c.judgmentIntelligence;
    final sig = intel?.judicialSignificance;
    final upsc = intel?.upscIntelligence;

    final hasSignificance = sig != null &&
        (sig.legalSignificance.isNotEmpty ||
            sig.historicalSignificance.isNotEmpty ||
            sig.constitutionalSignificance.isNotEmpty);
    final hasContemporary =
        upsc != null && upsc.contemporaryRelevance.isNotEmpty;
    if (!hasSignificance && !hasContemporary && c.historicalContext.isEmpty) {
      return;
    }

    _w.h2('Judicial Significance');
    _kv('Legal significance', sig?.legalSignificance);
    _kv(
        'Constitutional significance',
        sig?.constitutionalSignificance.isNotEmpty == true
            ? sig!.constitutionalSignificance
            : c.constitutionalSignificance);
    _kv('Historical context', sig?.historicalSignificance);
    if (sig != null && sig.significanceScore > 0) {
      _kv('Significance score', '${sig.significanceScore}');
    }
    if (upsc != null && upsc.contemporaryRelevance.isNotEmpty) {
      _bullets('Contemporary relevance', upsc.contemporaryRelevance);
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Doctrines
  // -------------------------------------------------------------------------

  void _doctrines() {
    List<DoctrineGraphEdge> doctrineEdges = const <DoctrineGraphEdge>[];
    if (graph != null) {
      doctrineEdges = graph!
          .edgesFrom(c.caseId, LegalGraphNodeType.caseLaw)
          .whereType<DoctrineGraphEdge>()
          .toList()
        ..sort((a, b) => a.targetId.compareTo(b.targetId));
    }

    final hasEdges = doctrineEdges.isNotEmpty;
    if (!hasEdges && c.doctrines.isEmpty) return;

    _w.h2('Doctrines');
    if (hasEdges) {
      for (final e in doctrineEdges) {
        _w.bullet(
            '**${_doctrineName(e.targetId)}** — ${e.type.name} (`${e.targetId}`)');
      }
    } else {
      for (final d in c.doctrines) {
        _w.bullet('**${_doctrineName(d)}** (`$d`)');
      }
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Precedent relationships (P5 graph / corpus fields)
  // -------------------------------------------------------------------------

  void _precedentRelationships() {
    if (graph != null) {
      _graphRelationships();
    } else {
      _corpusRelationships();
    }
  }

  void _graphRelationships() {
    final outgoing = graph!
        .edgesFrom(c.caseId, LegalGraphNodeType.caseLaw)
        .whereType<PrecedentGraphEdge>()
        .toList()
      ..sort((a, b) {
        final byType = a.type.name.compareTo(b.type.name);
        return byType != 0 ? byType : a.targetId.compareTo(b.targetId);
      });
    final incoming = graph!
        .edgesTo(c.caseId, LegalGraphNodeType.caseLaw)
        .whereType<PrecedentGraphEdge>()
        .toList()
      ..sort((a, b) {
        final byType = a.type.name.compareTo(b.type.name);
        return byType != 0 ? byType : a.sourceId.compareTo(b.sourceId);
      });

    if (outgoing.isEmpty && incoming.isEmpty) return;

    _w.h2('Precedent Relationships');
    if (outgoing.isNotEmpty) {
      _w.h3('Precedents (outgoing)');
      for (final e in outgoing) {
        final note = e.note == null ? '' : ' — *${e.note}*';
        _w.bullet(
            '**${e.type.name}** — ${_caseName(e.targetId)} (`${e.targetId}`)$note');
      }
    }
    if (incoming.isNotEmpty) {
      _w.h3('Cited by (incoming)');
      for (final e in incoming) {
        final note = e.note == null ? '' : ' — *${e.note}*';
        _w.bullet(
            '**${e.type.name}** — ${_caseName(e.sourceId)} (`${e.sourceId}`)$note');
      }
    }
    _w.blank();
  }

  void _corpusRelationships() {
    final hasAny = c.precedentsFollowed.isNotEmpty ||
        c.precedentsOverruled.isNotEmpty ||
        c.precedentsDistinguished.isNotEmpty ||
        c.relatedCases.isNotEmpty ||
        c.precedentRelationships.isNotEmpty;
    if (!hasAny) return;

    _w.h2('Precedent Relationships');
    void rel(String label, List<String> ids) {
      if (ids.isEmpty) return;
      _w.h3(label);
      for (final id in ids) {
        _w.bullet('**$id** — ${_caseName(id)}');
      }
    }

    rel('Followed', c.precedentsFollowed);
    rel('Overruled', c.precedentsOverruled);
    rel('Distinguished', c.precedentsDistinguished);
    rel('Related cases', c.relatedCases);
    if (c.precedentRelationships.isNotEmpty) {
      _w.h3('Structured relationships');
      final rels = List<PrecedentRelationship>.of(c.precedentRelationships)
        ..sort((a, b) {
          final byType = a.type.name.compareTo(b.type.name);
          return byType != 0
              ? byType
              : a.targetCaseId.compareTo(b.targetCaseId);
        });
      for (final r in rels) {
        final note = r.note == null ? '' : ' — *${r.note}*';
        _w.bullet('**${r.type.name}** — ${_caseName(r.targetCaseId)} '
            '(`${r.targetCaseId}`)$note');
      }
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // UPSC intelligence
  // -------------------------------------------------------------------------

  void _upscIntelligence() {
    final intel = c.judgmentIntelligence;
    final u = intel?.upscIntelligence;

    final hasCaseUpsc = c.themes.isNotEmpty ||
        c.subjects.isNotEmpty ||
        c.prelimsTraps.isNotEmpty ||
        c.mainsThemes.isNotEmpty ||
        c.interviewAngles.isNotEmpty ||
        c.examImportance.isNotEmpty;
    final hasIntelUpsc = u != null &&
        (u.prelimsFacts.isNotEmpty ||
            u.prelimsTraps.isNotEmpty ||
            u.mainsThemes.isNotEmpty ||
            u.mainsArguments.isNotEmpty ||
            u.mainsCounterarguments.isNotEmpty ||
            u.answerKeywords.isNotEmpty ||
            u.essayThemes.isNotEmpty ||
            u.interviewAreas.isNotEmpty ||
            u.answerEnrichmentPoints.isNotEmpty ||
            u.likelyInterviewQuestions.isNotEmpty ||
            u.conclusionIdeas.isNotEmpty ||
            u.relatedSyllabusAreas.isNotEmpty);

    if (!hasCaseUpsc && !hasIntelUpsc) return;

    _w.h2('UPSC Intelligence');
    if (c.themes.isNotEmpty) _bullets('Themes', c.themes);
    if (c.subjects.isNotEmpty) _bullets('Subjects', c.subjects);

    _kv('Prelims relevance', c.prelimsRelevance.name);
    _kv('Mains relevance', c.mainsRelevance.name);
    _kv('Essay relevance', c.essayRelevance.name);
    _kv('Interview relevance', c.interviewRelevance.name);
    _kv('Exam importance', c.examImportance);
    _kv('Trend', c.trend);
    if (c.timesAsked > 0) {
      _kv('Times asked', '${c.timesAsked} (last: ${c.lastAskedYear})');
    }

    if (c.prelimsTraps.isNotEmpty) _bullets('Prelims traps', c.prelimsTraps);
    if (c.mainsThemes.isNotEmpty) _bullets('Mains themes', c.mainsThemes);
    if (c.interviewAngles.isNotEmpty) {
      _bullets('Interview angles', c.interviewAngles);
    }
    if (c.frequentlyConfusedCases.isNotEmpty) {
      _bullets('Frequently confused cases', c.frequentlyConfusedCases);
    }

    if (u != null) {
      if (u.prelimsFacts.isNotEmpty) _bullets('Prelims facts', u.prelimsFacts);
      if (u.prelimsTraps.isNotEmpty) {
        _bullets('Prelims traps (intel)', u.prelimsTraps);
      }
      if (u.mainsThemes.isNotEmpty) {
        _bullets('Mains themes (intel)', u.mainsThemes);
      }
      if (u.mainsArguments.isNotEmpty) {
        _bullets('Mains arguments', u.mainsArguments);
      }
      if (u.mainsCounterarguments.isNotEmpty) {
        _bullets('Mains counterarguments', u.mainsCounterarguments);
      }
      if (u.answerKeywords.isNotEmpty) {
        _bullets('Answer keywords', u.answerKeywords);
      }
      if (u.essayThemes.isNotEmpty) _bullets('Essay themes', u.essayThemes);
      if (u.interviewAreas.isNotEmpty) {
        _bullets('Interview areas', u.interviewAreas);
      }
      if (u.answerEnrichmentPoints.isNotEmpty) {
        _bullets('Answer enrichment points', u.answerEnrichmentPoints);
      }
      if (u.likelyInterviewQuestions.isNotEmpty) {
        _bullets('Likely interview questions', u.likelyInterviewQuestions);
      }
      if (u.conclusionIdeas.isNotEmpty) {
        _bullets('Conclusion ideas', u.conclusionIdeas);
      }
      if (u.relatedSyllabusAreas.isNotEmpty) {
        _bullets('Syllabus areas',
            u.relatedSyllabusAreas.map((a) => a.name).toList());
      }
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Cross-links (knowledge-object links, analytics)
  // -------------------------------------------------------------------------

  void _crossLinks() {
    final hasAny = c.relatedCommittees.isNotEmpty ||
        c.relatedReports.isNotEmpty ||
        c.relatedBodies.isNotEmpty ||
        c.relatedSchemes.isNotEmpty ||
        c.relatedInternationalOrganisations.isNotEmpty ||
        c.sdgGoals.isNotEmpty ||
        c.relatedCurrentAffairs.isNotEmpty ||
        c.pyqIds.isNotEmpty ||
        c.relatedLessons.isNotEmpty ||
        c.crossReferences.isNotEmpty ||
        c.garudaExplanation.isNotEmpty ||
        c.commonMistakes.isNotEmpty ||
        c.memoryTricks.isNotEmpty ||
        c.oneLineSummary.isNotEmpty ||
        c.detailedSummary.isNotEmpty ||
        c.subsequentDevelopments.isNotEmpty;
    if (!hasAny) return;

    _w.h2('Knowledge & Editorial');
    _paragraph('One-line summary', c.oneLineSummary);
    _paragraph('Detailed summary', c.detailedSummary);
    _paragraph('GARUDA explanation', c.garudaExplanation);
    if (c.commonMistakes.isNotEmpty) {
      _bullets('Common mistakes', c.commonMistakes);
    }
    if (c.memoryTricks.isNotEmpty) _bullets('Memory tricks', c.memoryTricks);
    if (c.subsequentDevelopments.isNotEmpty) {
      _bullets('Subsequent developments', c.subsequentDevelopments);
    }
    if (c.relatedBodies.isNotEmpty) _bullets('Related bodies', c.relatedBodies);
    if (c.relatedCommittees.isNotEmpty) {
      _bullets('Related committees', c.relatedCommittees);
    }
    if (c.relatedReports.isNotEmpty) {
      _bullets('Related reports', c.relatedReports);
    }
    if (c.relatedSchemes.isNotEmpty) {
      _bullets('Related schemes', c.relatedSchemes);
    }
    if (c.relatedInternationalOrganisations.isNotEmpty) {
      _bullets('Related international organisations',
          c.relatedInternationalOrganisations);
    }
    if (c.sdgGoals.isNotEmpty) _bullets('SDG goals', c.sdgGoals);
    if (c.relatedCurrentAffairs.isNotEmpty) {
      _bullets('Related current affairs', c.relatedCurrentAffairs);
    }
    if (c.pyqIds.isNotEmpty) _bullets('Related PYQs', c.pyqIds);
    if (c.relatedLessons.isNotEmpty) {
      _bullets('Related lessons', c.relatedLessons);
    }
    if (c.crossReferences.isNotEmpty) {
      _bullets('Cross-references', c.crossReferences);
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Timeline
  // -------------------------------------------------------------------------

  void _timeline() {
    final intel = c.judgmentIntelligence;
    final events = intel?.timeline ?? const <JudgmentTimelineEvent>[];

    if (c.timeline.isEmpty && events.isEmpty) return;

    _w.h2('Timeline');
    if (c.timeline.isNotEmpty) _bullets('Key events', c.timeline);
    if (events.isNotEmpty) {
      _w.h3('Dated events');
      for (final t in events) {
        final when = t.date ?? (t.year != null ? '${t.year}' : '');
        final prefix = when.isEmpty ? '' : '**$when** — ';
        final significance =
            t.significance.isEmpty ? '' : ' (*${t.significance}*)';
        _w.bullet('$prefix${t.event}$significance');
      }
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Evidence
  // -------------------------------------------------------------------------

  void _evidence() {
    final entries = c.evidenceIds.map(EvidenceEntry.fromId).toList();

    final hasAny = entries.isNotEmpty ||
        c.officialSource.isNotEmpty ||
        c.primarySource.isNotEmpty ||
        c.citations.isNotEmpty ||
        c.evidenceReferences.isNotEmpty ||
        c.lastVerifiedDate.isNotEmpty;
    if (!hasAny) return;

    _w.h2('Evidence');
    _kv('Official source', c.officialSource);
    _kv('Primary source', c.primarySource);
    if (c.lastVerifiedDate.isNotEmpty) {
      _kv('Last verified', c.lastVerifiedDate);
    }
    if (c.citations.isNotEmpty) _bullets('Citations', c.citations);
    if (c.evidenceReferences.isNotEmpty) {
      _bullets('Evidence references', c.evidenceReferences);
    }
    if (entries.isNotEmpty) {
      _w.h3('Registered evidence');
      for (final e in entries) {
        final type = e.typeLabel.isEmpty ? '' : ' — ${e.typeLabel}';
        final status =
            e.verified ? ' — verified' : ' — registered (unresolved)';
        final url = e.url.isEmpty ? '' : ' — <${e.url}>';
        _w.bullet('`${e.evidenceId}`$type$status$url');
      }
    }
    _w.blank();
  }

  // -------------------------------------------------------------------------
  // Writer helpers
  // -------------------------------------------------------------------------

  void _kv(String label, String? value) {
    final v = _nonEmpty(value);
    if (v == null) return;
    _w.line('- **$label:** $v');
  }

  void _bullets(String label, List<String> values) {
    if (values.isEmpty) return;
    _w.h3(label);
    for (final v in values) {
      _w.bullet(v);
    }
  }

  void _paragraph(String label, String text) {
    final t = _nonEmpty(text);
    if (t == null) return;
    _w.h3(label);
    _w.paragraph(t);
  }

  void _blockquote(String text) => _w.blockquote(text);

  String? _nonEmpty(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : s;
  }

  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Minimal deterministic Markdown accumulator.
class _MarkdownWriter {
  final StringBuffer _buf = StringBuffer();

  @override
  String toString() => _buf.toString();

  void line(String s) => _buf.writeln(s);

  void blank() => _buf.writeln();

  void h1(String s) => _buf.writeln('# $s\n');

  void h2(String s) => _buf.writeln('## $s\n');

  void h3(String s) => _buf.writeln('### $s\n');

  void bullet(String s) {
    final lines = s.split('\n');
    _buf.writeln('- ${_mdEscapeLeading(lines.first)}');
    for (final l in lines.skip(1)) {
      if (l.trim().isEmpty) {
        _buf.writeln();
      } else {
        _buf.writeln('  ${_mdEscapeLeading(l)}');
      }
    }
  }

  void paragraph(String s) {
    // Split on blank lines into paragraphs; escape only a leading structural
    // token so legitimate legal text (Unicode, citations) is never damaged.
    for (final para in s.split(RegExp(r'\n\s*\n'))) {
      if (para.trim().isEmpty) continue;
      _buf.writeln();
      for (final l in para.split('\n')) {
        _buf.writeln(_mdEscapeLeading(l));
      }
      _buf.writeln();
    }
  }

  void blockquote(String s) {
    _buf.writeln();
    for (final l in s.split('\n')) {
      _buf.writeln(l.trim().isEmpty ? '>' : '> ${_mdEscapeLeading(l)}');
    }
    _buf.writeln();
  }

  /// Neutralises a single leading Markdown structural token so case content
  /// cannot hijack the document structure (heading / nested list / blockquote /
  /// ordered list / table). Everything else passes through untouched.
  static String _mdEscapeLeading(String line) {
    if (line.startsWith('#')) return '\\$line';
    if (line.startsWith('- ') ||
        line.startsWith('* ') ||
        line.startsWith('+ ') ||
        line.startsWith('> ')) {
      return '\\$line';
    }
    if (line.startsWith('|')) return '\\$line';
    if (RegExp(r'^(\d+)[.)]\s').hasMatch(line)) return '\\$line';
    return line;
  }
}
