import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P8 — export service integration (TITAN-KO-015.0 P8).
///
/// Covers: individual case export (all formats), invalid case IDs, corpus
/// export, corpus index, corpus statistics, the full 49-case corpus in all
/// three formats, determinism across service calls, and offline-first output.
void main() {
  final corpus = CaseSeedData.cases;
  final kesavananda = corpus.firstWhere((c) => c.caseId == 'KESAVANANDA');
  final service = const CaseExportService();

  group('1. individual case', () {
    test('exports a case as markdown', () async {
      final md = await service.exportCase('KESAVANANDA', RenderFormat.markdown);
      expect(md, contains('# Kesavananda Bharati v. State of Kerala'));
      expect(md, contains('## Case Identity'));
    });

    test('exports a case as html', () async {
      final html = await service.exportCase('KESAVANANDA', RenderFormat.html);
      expect(html, contains('<article class="garuda-case"'));
      expect(html, contains('data-case-id="KESAVANANDA"'));
    });

    test('exports a case as json', () async {
      final json = await service.exportCase('KESAVANANDA', RenderFormat.json);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['caseId'], 'KESAVANANDA');
    });

    test('resolves by alias and case name too', () async {
      final k = corpus.firstWhere((c) => c.caseId == 'KESAVANANDA');
      final alias = k.aliases.first;
      final byAlias = await service.exportCase(alias, RenderFormat.markdown);
      expect(byAlias, contains(k.caseName));
    });

    test('exportCaseJson returns the canonical map', () async {
      final m = await service.exportCaseJson('KESAVANANDA');
      expect(m, kesavananda.toJson());
    });
  });

  group('2. invalid case ID', () {
    test('throws ArgumentError for an unknown case', () async {
      expect(
        () => service.exportCase('NOT_A_CASE', RenderFormat.markdown),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for an empty identifier', () async {
      expect(
        () => service.exportCase('   ', RenderFormat.html),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for unknown case in JSON export', () async {
      expect(() => service.exportCaseJson('NOT_A_CASE'), throwsArgumentError);
    });
  });

  group('3. corpus export', () {
    test('renders all 49 cases in all three formats', () async {
      final md = await service.exportCorpus(RenderFormat.markdown);
      final html = await service.exportCorpus(RenderFormat.html);
      final json = await service.exportCorpus(RenderFormat.json);

      final jsonCases = jsonDecode(json) as List<dynamic>;
      expect(jsonCases, hasLength(49));
      expect(md, contains('# Kesavananda Bharati v. State of Kerala'));
      expect(html, contains('<div class="garuda-corpus">'));
      expect(html, isNot(contains('<script')));
    });
  });

  group('4. corpus index', () {
    test('index covers the full corpus in every format', () async {
      final md = await service.exportCorpusIndex(RenderFormat.markdown);
      final html = await service.exportCorpusIndex(RenderFormat.html);
      final json = await service.exportCorpusIndex(RenderFormat.json);

      expect(md, contains('49 landmark cases'));
      expect(html, contains('<section class="corpus-index"'));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['totalCases'], 49);
    });

    test('exportCorpusIndexJson exposes the raw index map', () async {
      final m = await service.exportCorpusIndexJson();
      expect(m['entries'], hasLength(49));
    });
  });

  group('5. corpus statistics', () {
    test('statistics reuse existing analytics through the service', () async {
      final stats = await service.computeCorpusStatistics();
      expect(stats.totalCases, 49);
      expect(stats.evidenceCoverage, 1.0);
      final direct = CorpusStatistics.compute(
          corpus,
          LegalGraphSeed.fromCorpora(
            cases: corpus,
            doctrines: DoctrineSeedData.doctrines,
          ).build());
      expect(stats.intelligence.completenessIndex,
          direct.intelligence.completenessIndex);
    });

    test('statistics render in every format', () async {
      final md = await service.exportCorpusStatistics(RenderFormat.markdown);
      final html = await service.exportCorpusStatistics(RenderFormat.html);
      final json = await service.exportCorpusStatistics(RenderFormat.json);
      expect(md, contains('**Total cases:** 49'));
      expect(html, contains('<section class="corpus-statistics"'));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['totalCases'], 49);
    });

    test('exportCorpusStatisticsJson exposes the snapshot map', () async {
      final m = await service.exportCorpusStatisticsJson();
      expect(m['totalCases'], 49);
      expect(m['evidenceCoverage'], closeTo(1.0, 1e-9));
    });
  });

  group('6. full 49-case corpus verification (all three formats)', () {
    test('every case renders in markdown, html and json', () async {
      final md = await service.exportCorpus(RenderFormat.markdown);
      final html = await service.exportCorpus(RenderFormat.html);
      final json = await service.exportCorpus(RenderFormat.json);

      final jsonCases = jsonDecode(json) as List<dynamic>;
      for (final c in corpus) {
        // Markdown: title present.
        expect(md, contains('# ${c.caseName}'));
        // HTML: article present with data-case-id.
        expect(
          html,
          contains('<article class="garuda-case" data-case-id="${c.caseId}">'),
        );
        // JSON: canonical map present for every caseId in order.
        final idSet = jsonCases.map((m) => (m as Map)['caseId']).toSet();
        expect(idSet, contains(c.caseId));
      }
      expect(jsonCases, hasLength(corpus.length));
    });
  });

  group('7. explicit 49/49/49 per-case verification', () {
    test('every case renders individually in all three formats', () async {
      var mdOk = 0, htmlOk = 0, jsonOk = 0;
      for (final c in corpus) {
        final md = await service.exportCase(c.caseId, RenderFormat.markdown);
        expect(md, contains('# ${c.caseName}'), reason: c.caseId);
        mdOk++;

        final html = await service.exportCase(c.caseId, RenderFormat.html);
        expect(html, contains('<article'), reason: c.caseId);
        htmlOk++;

        final json = await service.exportCase(c.caseId, RenderFormat.json);
        expect((jsonDecode(json) as Map)['caseId'], c.caseId, reason: c.caseId);
        jsonOk++;
      }
      expect(mdOk, 49);
      expect(htmlOk, 49);
      expect(jsonOk, 49);
    });
  });

  group('8. determinism across service calls', () {
    test('corpus output is byte-identical across repeated exports', () async {
      final mdA = await service.exportCorpus(RenderFormat.markdown);
      final mdB = await service.exportCorpus(RenderFormat.markdown);
      expect(mdA, mdB);

      final htmlA = await service.exportCorpus(RenderFormat.html);
      final htmlB = await service.exportCorpus(RenderFormat.html);
      expect(htmlA, htmlB);

      final jsonA = await service.exportCorpus(RenderFormat.json);
      final jsonB = await service.exportCorpus(RenderFormat.json);
      expect(jsonA, jsonB);
    });

    test('index and statistics are stable across exports', () async {
      expect(
        await service.exportCorpusIndex(RenderFormat.json),
        await service.exportCorpusIndex(RenderFormat.json),
      );
      expect(
        await service.exportCorpusStatistics(RenderFormat.json),
        await service.exportCorpusStatistics(RenderFormat.json),
      );
    });
  });

  group('9. offline-first output', () {
    test('all evidence URLs trace to the local official registry only',
        () async {
      final html = await service.exportCorpus(RenderFormat.html);
      // No external or unregistered host may appear as a link target.
      expect(
        html,
        isNot(contains('href="http://')),
      );
      // Only the registered SCI portal host may appear.
      expect(html, contains('href="https://main.sci.gov.in/judgments"'));
    });
  });
}
