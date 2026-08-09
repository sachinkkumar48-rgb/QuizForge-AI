import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P8 — HTML case rendering & injection safety (TITAN-KO-015.0 P8).
///
/// Covers: complete case structure, semantic HTML, HTML escaping of dynamic
/// content, evidence URL rendering, unsafe/script-like content, URL scheme
/// safety, absence of executable injection, and deterministic output.
void main() {
  final corpus = CaseSeedData.cases;
  final kesavananda = corpus.firstWhere((c) => c.caseId == 'KESAVANANDA');

  LegalGraph graph() => LegalGraphSeed.fromCorpora(
        cases: corpus,
        doctrines: DoctrineSeedData.doctrines,
      ).build();

  group('1. complete case & semantic structure', () {
    test('renders a semantic article with stable garuda class hooks', () {
      final html = HtmlCaseRenderer.render(kesavananda);
      expect(
        html,
        contains('<article class="garuda-case" data-case-id="KESAVANANDA">'),
      );
      expect(html, contains('<h1 class="case-title">'));
      expect(html, contains('<section class="case-identity"'));
      expect(html, contains('<section class="case-legal-content"'));
      expect(html, contains('<section class="case-judgment"'));
      expect(html, contains('<footer class="case-evidence"'));
    });

    test('citation line is emitted once when distinct', () {
      final html = HtmlCaseRenderer.render(kesavananda);
      expect(html, contains('(1973) 4 SCC 225 | AIR 1973 SC 1461'));
    });

    test('does not emit JavaScript or inline styles', () {
      final html = HtmlCaseRenderer.render(kesavananda);
      expect(html, isNot(contains('<script')));
      expect(html, isNot(contains('style=')));
      expect(html, isNot(contains('javascript:')));
    });
  });

  group('2. HTML escaping', () {
    test('script-like text content is escaped, never executable', () {
      final c = kesavananda.copyWith(facts: '<script>alert(1)</script>');
      final html = HtmlCaseRenderer.render(c);
      expect(html, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
      expect(html, isNot(contains('<script>alert(1)</script>')));
    });

    test('tags and ampersands in text are escaped', () {
      final c = kesavananda.copyWith(
        decision: '<b>bold</b> & "quoted" <i>italic</i>',
      );
      final html = HtmlCaseRenderer.render(c);
      // Element text escapes &, <, >; a double quote is inert inside an
      // element and passes through unchanged.
      expect(html, contains('&lt;b&gt;bold&lt;/b&gt; &amp; "quoted"'));
      expect(html, isNot(contains('<b>bold</b>')));
    });

    test('attribute values are escaped', () {
      final c = kesavananda.copyWith(caseId: 'X" onmouseover="alert(1)');
      final html = HtmlCaseRenderer.render(c);
      expect(
        html,
        contains('data-case-id="X&quot; onmouseover=&quot;alert(1)"'),
      );
      // The raw, unescaped attribute form (which would be executable) must
      // never appear.
      expect(
        html,
        isNot(contains('data-case-id="X" onmouseover="alert(1)"')),
      );
    });

    test('malformed markup in content cannot break out', () {
      final c = kesavananda.copyWith(oneLineSummary: '">><script>');
      final html = HtmlCaseRenderer.render(c);
      expect(html, contains('"&gt;&gt;&lt;script&gt;'));
      expect(html, isNot(contains('><script>')));
    });
  });

  group('3. evidence URLs', () {
    test('registered evidence renders the official URL as a safe link', () {
      final html = HtmlCaseRenderer.render(kesavananda);
      expect(
        html,
        contains(
          '<a rel="noreferrer noopener" '
          'href="https://main.sci.gov.in/judgments">'
          'https://main.sci.gov.in/judgments</a>',
        ),
      );
    });

    test('unresolved evidence renders without any link', () {
      final c = kesavananda.copyWith(evidenceIds: const ['bogus_evidence']);
      final html = HtmlCaseRenderer.render(c);
      expect(html, contains('<code>bogus_evidence</code>'));
      expect(html, contains('registered (unresolved)'));
      expect(html, isNot(contains('href=')));
    });
  });

  group('4. URL scheme safety', () {
    test('safeUrl accepts http(s) and rejects everything else', () {
      expect(HtmlSafety.safeUrl('https://example.com/a?b=1'),
          'https://example.com/a?b=1');
      expect(HtmlSafety.safeUrl('http://example.com'), 'http://example.com');
      expect(
          HtmlSafety.safeUrl('  https://example.com  '), 'https://example.com');
      expect(HtmlSafety.safeUrl('javascript:alert(1)'), '');
      expect(HtmlSafety.safeUrl('data:text/html,<script>'), '');
      expect(HtmlSafety.safeUrl('vbscript:msgbox(1)'), '');
      expect(HtmlSafety.safeUrl('ftp://example.com'), '');
      expect(HtmlSafety.safeUrl(''), '');
    });

    test('a javascript: official source never becomes a link', () {
      final c = kesavananda.copyWith(officialSource: 'javascript:alert(1)');
      final html = HtmlCaseRenderer.render(c);
      // No javascript: href is emitted anywhere.
      expect(html, isNot(contains('href="javascript:')));
      // The dangerous value is preserved as inert text, not a link.
      expect(html, contains('javascript:alert(1)'));
    });

    test('no javascript:/data: href is ever emitted for a full corpus', () {
      final g = graph();
      for (final c in corpus) {
        final html = HtmlCaseRenderer.render(c, graph: g);
        expect(html, isNot(contains('href="javascript:')));
        expect(html, isNot(contains('href="data:')));
      }
    });
  });

  group('5. no executable injection', () {
    test('a maximally hostile case renders inert HTML', () {
      final c = kesavananda.copyWith(
        caseId: 'X" onload="evil()',
        caseName: '<script>alert(document.cookie)</script>',
        facts: '<img src=x onerror=alert(1)>',
        officialSource: 'javascript:void(0)',
        decision: '"><svg onload=alert(1)>',
        bench: 'a" autofocus onfocus="alert(1)',
      );
      final html = HtmlCaseRenderer.render(c);
      // No executable tag may be emitted.
      expect(html, isNot(contains('<script')));
      expect(html, isNot(contains('<img')));
      expect(html, isNot(contains('<svg')));
      expect(html, isNot(contains('<iframe')));
      // No executable URL scheme may be emitted.
      expect(html, isNot(contains('href="javascript:')));
      // The dynamic attribute is fully escaped — attribute breakout is blocked.
      expect(html, contains('data-case-id="X&quot; onload=&quot;evil()"'));
      expect(html, isNot(contains('data-case-id="X" onload="evil()"')));
      // Hostile facts render as escaped text, not a real <img> element.
      expect(html, contains('&lt;img src=x onerror=alert(1)&gt;'));
    });
  });

  group('6. determinism', () {
    test('identical input renders identical HTML', () {
      final g = graph();
      final a = HtmlCaseRenderer.render(kesavananda, graph: g);
      final b = HtmlCaseRenderer.render(kesavananda, graph: g);
      expect(a, b);
    });

    test('full corpus HTML is byte-identical across renders', () {
      final g = graph();
      final a = corpus.map((c) => HtmlCaseRenderer.render(c, graph: g)).join();
      final b = corpus.map((c) => HtmlCaseRenderer.render(c, graph: g)).join();
      expect(a, b);
    });
  });

  group('7. Unicode / Devanagari in HTML', () {
    test('Devanagari passes through unescaped', () {
      final c = kesavananda.copyWith(
        facts: 'मूल संरचना सिद्धांत का प्रतिपादन।',
      );
      final html = HtmlCaseRenderer.render(c);
      expect(html, contains('मूल संरचना सिद्धांत'));
    });
  });
}
