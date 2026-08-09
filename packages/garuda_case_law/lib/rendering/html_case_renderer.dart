/// HTML case renderer (TITAN-KO-015.0 P8).
///
/// Renders one `CaseKnowledgeObject` as semantic, safe, deterministic HTML.
/// Every dynamic value (case text, evidence metadata, titles, URLs, notes) is
/// HTML-escaped; only `http(s)` URLs are emitted as `href` targets; there is no
/// JavaScript and no inline styling. Stable `garuda-*` class hooks are provided
/// for CSS. Unicode / Devanagari pass through unescaped.
///
/// Only existing corpus fields are rendered — nothing is inferred, and absent
/// data is omitted. Precedent relationships come from the existing P5
/// [LegalGraph] when supplied, otherwise from the corpus-declared fields.
library;

import '../domain/entities/case_enums.dart';
import '../domain/entities/case_knowledge_object.dart';
import '../domain/entities/precedent_relationship.dart';
import '../graph/domain/legal_graph.dart';
import '../graph/domain/legal_graph_edge.dart';
import '../graph/domain/legal_graph_node_type.dart';
import '../intelligence/domain/judgment_intelligence.dart';
import 'evidence_entry.dart';
import 'html_safety.dart';

/// Renders a single case to HTML. Deterministic for identical input.
class HtmlCaseRenderer {
  static String render(CaseKnowledgeObject c, {LegalGraph? graph}) =>
      _HtmlDoc(c, graph: graph).build();

  static String renderWith(CaseKnowledgeObject c,
          {LegalGraph? graph, required Map<String, String> names}) =>
      _HtmlDoc(c, graph: graph, names: names).build();
}

class _HtmlDoc {
  final CaseKnowledgeObject c;
  final LegalGraph? graph;
  final Map<String, String> names;
  final StringBuffer _b = StringBuffer();

  _HtmlDoc(this.c, {this.graph, Map<String, String>? names})
      : names = names ?? const {};

  String _esc(String s) => HtmlSafety.escapeText(s);
  String _attr(String s) => HtmlSafety.escapeAttribute(s);

  String _caseName(String caseId) =>
      names[caseId] ??
      graph?.nodeFor(caseId, LegalGraphNodeType.caseLaw)?.name ??
      caseId;

  String _doctrineName(String doctrineId) =>
      graph?.nodeFor(doctrineId, LegalGraphNodeType.doctrine)?.name ??
      doctrineId;

  bool _nonEmpty(String? s) {
    final t = s?.trim();
    return t != null && t.isNotEmpty;
  }

  String build() {
    final safeId = _attr(c.caseId);
    _b.writeln('<article class="garuda-case" data-case-id="$safeId">');
    _b.writeln('  <header class="case-header">');
    _b.writeln('    <h1 class="case-title">${_esc(c.caseName)}</h1>');
    final citationLine = <String>[
      if (_nonEmpty(c.neutralCitation)) c.neutralCitation,
      if (_nonEmpty(c.citation) && c.citation != c.neutralCitation) c.citation,
    ].join(' | ');
    if (citationLine.isNotEmpty) {
      _b.writeln('    <p class="case-citation">${_esc(citationLine)}</p>');
    }
    _b.writeln('  </header>');

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

    _b.writeln('</article>');
    return _b.toString();
  }

  // -------------------------------------------------------------------------
  // Identity
  // -------------------------------------------------------------------------

  void _identity() {
    _b.writeln('  <section class="case-identity" aria-label="Case identity">');
    _b.writeln('    <h2>Case Identity</h2>');
    _dl([
      if (_nonEmpty(c.caseId))
        _row('Case ID', '<code>${_esc(c.caseId)}</code>'),
      if (_nonEmpty(c.objectId))
        _row('Object ID', '<code>${_esc(c.objectId)}</code>'),
      if (_nonEmpty(c.caseName)) _row('Short name', _esc(c.caseName)),
      if (_nonEmpty(c.citation)) _row('Full citation', _esc(c.citation)),
      if (_nonEmpty(c.neutralCitation))
        _row('Neutral citation', _esc(c.neutralCitation)),
      if (_nonEmpty(c.reporterCitation))
        _row('Reporter citation', _esc(c.reporterCitation)),
      if (_nonEmpty(c.judgmentTitle))
        _row('Judgment title', _esc(c.judgmentTitle)),
      if (_nonEmpty(c.court)) _row('Court', _esc(c.court)),
      if (_nonEmpty(c.jurisdiction)) _row('Jurisdiction', _esc(c.jurisdiction)),
      _row('Decision date', _esc(_date(c.judgmentDate))),
      if (c.filingDate != null) _row('Filing date', _esc(_date(c.filingDate!))),
      if (c.year > 0) _row('Year', _esc('${c.year}')),
      if (_nonEmpty(c.bench)) _row('Bench', _esc(c.bench)),
      if (c.benchStrength > 0)
        _row('Bench strength', _esc('${c.benchStrength}')),
      if (_nonEmpty(c.authoringJudge))
        _row('Authoring judge', _esc(c.authoringJudge)),
      if (c.judges.isNotEmpty) _row('Judges', _list(c.judges)),
      if (c.parties.isNotEmpty) _row('Parties', _list(c.parties)),
      if (_nonEmpty(c.petitioner)) _row('Petitioner', _esc(c.petitioner)),
      if (_nonEmpty(c.respondent)) _row('Respondent', _esc(c.respondent)),
      if (c.caseType != null) _row('Case type', _esc(c.caseType!.displayName)),
      _row('Status', _esc(c.status.name)),
      _row('Court level', _esc(c.courtLevel.name)),
      if (_nonEmpty(c.presentStatus))
        _row('Present status', _esc(c.presentStatus)),
      if (c.aliases.isNotEmpty) _row('Aliases', _list(c.aliases)),
      if (c.keywords.isNotEmpty) _row('Keywords', _list(c.keywords)),
    ]);
    _b.writeln('  </section>');
  }

  // -------------------------------------------------------------------------
  // Legal content
  // -------------------------------------------------------------------------

  void _legalContent() {
    _b.writeln(
        '  <section class="case-legal-content" aria-label="Legal content">');
    _b.writeln('    <h2>Legal Content</h2>');
    if (_nonEmpty(c.facts)) {
      _b.writeln('    <h3>Facts</h3>');
      _paragraph(c.facts);
    }
    if (_nonEmpty(c.historicalContext)) {
      _b.writeln('    <h3>Historical context</h3>');
      _paragraph(c.historicalContext);
    }
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
    if (c.relatedArticles.isNotEmpty) {
      _bullets('Constitutional articles', c.relatedArticles);
    }
    if (c.relatedParts.isNotEmpty) {
      _bullets('Constitutional parts', c.relatedParts);
    }
    if (c.relatedSchedules.isNotEmpty) {
      _bullets('Constitutional schedules', c.relatedSchedules);
    }
    if (c.relatedAmendments.isNotEmpty) {
      _bullets('Constitutional amendments', c.relatedAmendments);
    }
    if (c.relatedActs.isNotEmpty) _bullets('Statutes / Acts', c.relatedActs);
    if (c.sections.isNotEmpty) _bullets('Statutory sections', c.sections);
    if (c.relatedRules.isNotEmpty) _bullets('Rules', c.relatedRules);
    _b.writeln('  </section>');
  }

  // -------------------------------------------------------------------------
  // Judgment intelligence (P4)
  // -------------------------------------------------------------------------

  void _judgmentIntelligence() {
    final intel = c.judgmentIntelligence;
    _b.writeln('  <section class="case-judgment" aria-label="Judgment">');
    _b.writeln('    <h2>Judgment</h2>');

    if (_nonEmpty(c.decision)) {
      _b.writeln('    <h3>Decision</h3>');
      _paragraph(c.decision);
    }

    if (intel != null && intel.holdings.isNotEmpty) {
      _b.writeln('    <h3>Holding</h3>');
      for (final h in intel.holdings) {
        _blockquote(h.holding);
        final meta = <String>[
          if (_nonEmpty(h.legalPrinciple))
            'Legal principle: ${_esc(h.legalPrinciple)}',
          'Scope: ${h.scope.name}',
          'Confidence: ${h.confidence.name}',
          if (_nonEmpty(h.evidence.evidenceId))
            'Evidence: <code>${_esc(h.evidence.evidenceId)}</code>',
        ];
        if (meta.isNotEmpty) {
          _b.writeln('    <p class="hold-meta">${meta.join(' · ')}</p>');
        }
      }
    }

    if (c.ratioDecidendi.isNotEmpty) {
      _b.writeln('    <h3>Ratio Decidendi</h3>');
      for (final r in c.ratioDecidendi) {
        _blockquote(r);
      }
    } else if (intel != null && intel.ratios.isNotEmpty) {
      _b.writeln('    <h3>Ratio Decidendi</h3>');
      for (final r in intel.ratios) {
        _blockquote(r.ratio);
        final meta = <String>[
          'Type: ${r.type.name}',
          if (_nonEmpty(r.legalProposition))
            'Proposition: ${_esc(r.legalProposition)}',
          if (_nonEmpty(r.constitutionalBasis))
            'Constitutional basis: ${_esc(r.constitutionalBasis)}',
        ];
        if (meta.isNotEmpty) {
          _b.writeln('    <p class="ratio-meta">${meta.join(' · ')}</p>');
        }
      }
    }

    if (intel != null && intel.issues.isNotEmpty) {
      _b.writeln('    <h3>Issues Framed</h3>');
      for (final i in intel.issues) {
        _b.writeln('    <ul class="issues">');
        _b.writeln('      <li>${_esc(i.issue)}');
        final sub = <String>[
          'Category: ${i.category.name}',
          'Importance: ${i.importance.name}',
          if (i.relatedArticles.isNotEmpty)
            'Articles: ${i.relatedArticles.join(', ')}',
        ];
        if (sub.isNotEmpty) {
          _b.writeln(
              '        <span class="issue-meta">${_esc(sub.join(' · '))}</span>');
        }
        _b.writeln('      </li>');
        _b.writeln('    </ul>');
      }
    }

    if (intel?.reasoning != null) {
      final r = intel!.reasoning!;
      _b.writeln('    <h3>Reasoning</h3>');
      if (_nonEmpty(r.summary)) _paragraph(r.summary);
      _b.writeln('    <p class="approach">Interpretive approach: '
          '${_esc(r.approach.name)}</p>');
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
    _rowP('Constitutional significance', c.constitutionalSignificance);
    _rowP('Constitutional interpretation', c.constitutionalInterpretation);
    _rowP('Legal principle', c.legalPrinciple);
    _rowP('Majority opinion', c.majorityOpinion);
    _rowP('Minority opinion', c.minorityOpinion);
    _rowP('Dissent', c.dissent);

    if (intel?.outcome != null) {
      final o = intel!.outcome!;
      _b.writeln('    <h3>Outcome</h3>');
      _b.writeln('    <p class="outcome">Disposition: '
          '${_esc(o.disposition.name)}</p>');
      if (o.reliefGranted.isNotEmpty) {
        _bullets('Relief granted', o.reliefGranted);
      }
      if (o.reliefDenied.isNotEmpty) _bullets('Relief denied', o.reliefDenied);
      _rowP('Operative result', o.operativeResult);
      _rowP('Majority outcome', o.majorityOutcome);
      _rowP('Minority outcome', o.minorityOutcome);
    }
    _b.writeln('  </section>');
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

    _b.writeln(
        '  <section class="case-significance" aria-label="Judicial significance">');
    _b.writeln('    <h2>Judicial Significance</h2>');
    _rowP('Legal significance', sig?.legalSignificance);
    if (sig != null && _nonEmpty(sig.constitutionalSignificance)) {
      _rowP('Constitutional significance', sig.constitutionalSignificance);
    } else {
      _rowP('Constitutional significance', c.constitutionalSignificance);
    }
    _rowP('Historical context', sig?.historicalSignificance);
    if (sig != null && sig.significanceScore > 0) {
      _b.writeln('    <p class="significance-score">Significance score: '
          '${_esc('${sig.significanceScore}')}</p>');
    }
    if (upsc != null && upsc.contemporaryRelevance.isNotEmpty) {
      _bullets('Contemporary relevance', upsc.contemporaryRelevance);
    }
    _b.writeln('  </section>');
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

    _b.writeln('  <section class="case-doctrines" aria-label="Doctrines">');
    _b.writeln('    <h2>Doctrines</h2>');
    _b.writeln('    <ul class="doctrines">');
    if (hasEdges) {
      for (final e in doctrineEdges) {
        _b.writeln(
            '      <li><strong>${_esc(_doctrineName(e.targetId))}</strong> '
            '— ${_esc(e.type.name)} '
            '(<code>${_esc(e.targetId)}</code>)</li>');
      }
    } else {
      for (final d in c.doctrines) {
        _b.writeln('      <li><strong>${_esc(_doctrineName(d))}</strong> '
            '(<code>${_esc(d)}</code>)</li>');
      }
    }
    _b.writeln('    </ul>');
    _b.writeln('  </section>');
  }

  // -------------------------------------------------------------------------
  // Precedent relationships
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

    _b.writeln('  <section class="case-precedents" '
        'aria-label="Precedent relationships">');
    _b.writeln('    <h2>Precedent Relationships</h2>');
    if (outgoing.isNotEmpty) {
      _b.writeln('    <h3>Precedents (outgoing)</h3>');
      _b.writeln('    <ul class="precedent-edges">');
      for (final e in outgoing) {
        _edgeItem(e.type.name, _caseName(e.targetId), e.targetId, e.note);
      }
      _b.writeln('    </ul>');
    }
    if (incoming.isNotEmpty) {
      _b.writeln('    <h3>Cited by (incoming)</h3>');
      _b.writeln('    <ul class="precedent-edges">');
      for (final e in incoming) {
        _edgeItem(e.type.name, _caseName(e.sourceId), e.sourceId, e.note);
      }
      _b.writeln('    </ul>');
    }
    _b.writeln('  </section>');
  }

  void _edgeItem(String type, String name, String id, String? note) {
    _b.writeln('      <li><strong>${_esc(type)}</strong> — '
        '${_esc(name)} (<code>${_esc(id)}</code>)'
        '${note == null ? '' : ' — <em>${_esc(note)}</em>'}</li>');
  }

  void _corpusRelationships() {
    final hasAny = c.precedentsFollowed.isNotEmpty ||
        c.precedentsOverruled.isNotEmpty ||
        c.precedentsDistinguished.isNotEmpty ||
        c.relatedCases.isNotEmpty ||
        c.precedentRelationships.isNotEmpty;
    if (!hasAny) return;

    _b.writeln('  <section class="case-precedents" '
        'aria-label="Precedent relationships">');
    _b.writeln('    <h2>Precedent Relationships</h2>');

    void rel(String label, List<String> ids) {
      if (ids.isEmpty) return;
      _b.writeln('    <h3>$label</h3>');
      _b.writeln('    <ul class="precedent-edges">');
      for (final id in ids) {
        _b.writeln('      <li><strong>${_esc(id)}</strong> — '
            '${_esc(_caseName(id))}</li>');
      }
      _b.writeln('    </ul>');
    }

    rel('Followed', c.precedentsFollowed);
    rel('Overruled', c.precedentsOverruled);
    rel('Distinguished', c.precedentsDistinguished);
    rel('Related cases', c.relatedCases);
    if (c.precedentRelationships.isNotEmpty) {
      _b.writeln('    <h3>Structured relationships</h3>');
      _b.writeln('    <ul class="precedent-edges">');
      final rels = List<PrecedentRelationship>.of(c.precedentRelationships)
        ..sort((a, b) {
          final byType = a.type.name.compareTo(b.type.name);
          return byType != 0
              ? byType
              : a.targetCaseId.compareTo(b.targetCaseId);
        });
      for (final r in rels) {
        _edgeItem(
            r.type.name, _caseName(r.targetCaseId), r.targetCaseId, r.note);
      }
      _b.writeln('    </ul>');
    }
    _b.writeln('  </section>');
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

    _b.writeln('  <section class="case-upsc" aria-label="UPSC intelligence">');
    _b.writeln('    <h2>UPSC Intelligence</h2>');
    if (c.themes.isNotEmpty) _bullets('Themes', c.themes);
    if (c.subjects.isNotEmpty) _bullets('Subjects', c.subjects);
    _rowP('Prelims relevance', c.prelimsRelevance.name);
    _rowP('Mains relevance', c.mainsRelevance.name);
    _rowP('Essay relevance', c.essayRelevance.name);
    _rowP('Interview relevance', c.interviewRelevance.name);
    _rowP('Exam importance', c.examImportance);
    _rowP('Trend', c.trend);
    if (c.timesAsked > 0) {
      _rowP('Times asked', '${c.timesAsked} (last: ${c.lastAskedYear})');
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
    _b.writeln('  </section>');
  }

  // -------------------------------------------------------------------------
  // Knowledge & editorial
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

    _b.writeln('  <section class="case-knowledge" '
        'aria-label="Knowledge and editorial">');
    _b.writeln('    <h2>Knowledge &amp; Editorial</h2>');
    _paraP('One-line summary', c.oneLineSummary);
    _paraP('Detailed summary', c.detailedSummary);
    _paraP('GARUDA explanation', c.garudaExplanation);
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
    _b.writeln('  </section>');
  }

  // -------------------------------------------------------------------------
  // Timeline
  // -------------------------------------------------------------------------

  void _timeline() {
    final intel = c.judgmentIntelligence;
    final events = intel?.timeline ?? const <JudgmentTimelineEvent>[];

    if (c.timeline.isEmpty && events.isEmpty) return;

    _b.writeln('  <section class="case-timeline" aria-label="Timeline">');
    _b.writeln('    <h2>Timeline</h2>');
    if (c.timeline.isNotEmpty) _bullets('Key events', c.timeline);
    if (events.isNotEmpty) {
      _b.writeln('    <h3>Dated events</h3>');
      _b.writeln('    <ul class="timeline">');
      for (final t in events) {
        final when = t.date ?? (t.year != null ? '${t.year}' : '');
        final prefix = when.isEmpty ? '' : '<time>${_esc(when)}</time> — ';
        final significance =
            t.significance.isEmpty ? '' : ' <em>(${_esc(t.significance)})</em>';
        _b.writeln('      <li>$prefix${_esc(t.event)}$significance</li>');
      }
      _b.writeln('    </ul>');
    }
    _b.writeln('  </section>');
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

    _b.writeln('  <footer class="case-evidence" aria-label="Evidence">');
    _b.writeln('    <h2>Evidence</h2>');
    _rowP('Official source', c.officialSource);
    _rowP('Primary source', c.primarySource);
    _rowP('Last verified', c.lastVerifiedDate);
    if (c.citations.isNotEmpty) _bullets('Citations', c.citations);
    if (c.evidenceReferences.isNotEmpty) {
      _bullets('Evidence references', c.evidenceReferences);
    }
    if (entries.isNotEmpty) {
      _b.writeln('    <h3>Registered evidence</h3>');
      _b.writeln('    <ul class="evidence">');
      for (final e in entries) {
        _b.write('      <li><code>${_esc(e.evidenceId)}</code>');
        if (e.typeLabel.isNotEmpty) {
          _b.write(' — ${_esc(e.typeLabel)}');
        }
        _b.write(e.verified ? ' — verified' : ' — registered (unresolved)');
        final url = HtmlSafety.safeUrl(e.url);
        if (url.isNotEmpty) {
          _b.write(' — <a rel="noreferrer noopener" '
              'href="${_attr(url)}">${_esc(url)}</a>');
        }
        _b.writeln('</li>');
      }
      _b.writeln('    </ul>');
    }
    _b.writeln('  </footer>');
  }

  // -------------------------------------------------------------------------
  // HTML building helpers
  // -------------------------------------------------------------------------

  void _dl(List<String> rows) {
    _b.writeln('    <dl>');
    for (final r in rows) {
      _b.writeln('      $r');
    }
    _b.writeln('    </dl>');
  }

  String _row(String dt, String dd) =>
      '<div class="kv"><dt>${_esc(dt)}</dt><dd>$dd</dd></div>';

  String _list(List<String> items) =>
      '<ul>${items.map((i) => '<li>${_esc(i)}</li>').join()}</ul>';

  void _rowP(String label, String? value) {
    if (!_nonEmpty(value)) return;
    _b.writeln('    <p class="field"><strong>${_esc(label)}:</strong> '
        '${_esc(value!)}</p>');
  }

  void _paraP(String label, String? value) {
    if (!_nonEmpty(value)) return;
    _b.writeln('    <h3>${_esc(label)}</h3>');
    _paragraph(value!);
  }

  void _paragraph(String text) {
    _b.writeln('    <p class="prose">${_esc(text)}</p>');
  }

  void _bullets(String label, List<String> values) {
    if (values.isEmpty) return;
    _b.writeln('    <h3>${_esc(label)}</h3>');
    _b.writeln('    <ul>');
    for (final v in values) {
      _b.writeln('      <li>${_esc(v)}</li>');
    }
    _b.writeln('    </ul>');
  }

  void _blockquote(String text) {
    _b.writeln('    <blockquote class="quotation">${_esc(text)}</blockquote>');
  }

  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
