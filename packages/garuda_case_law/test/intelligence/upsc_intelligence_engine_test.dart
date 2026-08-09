import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.5 — UPSC Intelligence Engine: case-specific prelims/mains/interview/
/// essay profiles (TITAN-KO-015.0 P4).
void main() {
  const engine = UpscIntelligenceEngine();
  final cases = CaseSeedData.cases;

  CaseKnowledgeObject caseById(String id) =>
      cases.firstWhere((c) => c.caseId == id);

  group('Profile composition (case-specific)', () {
    test('Kesavananda profile carries its specific prelims facts', () {
      final p = engine.profileFor(caseById('KESAVANANDA'));
      expect(p.caseId, 'KESAVANANDA');
      expect(
          p.prelimsFacts.any((f) => f.contains('13-judge bench')), isTrue);
      expect(p.prelimsFacts.any((f) => f.contains('7:6 majority')), isTrue);
    });

    test('important Articles and Acts derive from the record', () {
      final p = engine.profileFor(caseById('KESAVANANDA'));
      expect(p.importantArticles, isNotEmpty);
      expect(p.importantArticles, contains('Article 368'));
    });

    test('important years include the decision year', () {
      final p = engine.profileFor(caseById('KESAVANANDA'));
      expect(p.importantYears, contains(1973));
    });

    test('judges and bench string are exposed', () {
      final p = engine.profileFor(caseById('KESAVANANDA'));
      expect(p.judgesOrBench, isNotEmpty);
    });

    test('landmark principle derives from the verified record ratio', () {
      final c = caseById('KESAVANANDA');
      final p = engine.profileFor(c);
      expect(p.landmarkPrinciple, isNotEmpty);
      expect(p.landmarkPrinciple, c.ratioDecidendi.first);
    });

    test('mains arguments include curated and record arguments', () {
      final p = engine.profileFor(caseById('KESAVANANDA'));
      expect(p.arguments, isNotEmpty);
      expect(p.counterarguments, isNotEmpty);
    });

    test('interview and essay content is present for curated cases', () {
      final p = engine.profileFor(caseById('KESAVANANDA'));
      expect(p.conceptualDiscussionPoints, isNotEmpty);
      expect(p.likelyInterviewQuestions, isNotEmpty);
      expect(p.essayThemes, isNotEmpty);
    });
  });

  group('Profile integrity (no fabricated filler)', () {
    test('every case yields a profile with a case name', () {
      for (final c in cases) {
        final p = engine.profileFor(c);
        expect(p.caseId, c.caseId);
        expect(p.caseName, isNotEmpty);
      }
    });

    test('environmental cases expose environment syllabus areas', () {
      final p = engine.profileFor(caseById('VELLORE_CITIZENS'));
      expect(
          p.toJson(),
          isA<Map<String, dynamic>>());
      final intel = caseById('VELLORE_CITIZENS').judgmentIntelligence!;
      expect(intel.upscIntelligence!.relatedSyllabusAreas,
          contains(UpscSyllabusArea.prelimsEnvironment));
    });

    test('profile serializes to JSON', () {
      final p = engine.profileFor(caseById('JOSEPH_SHINE'));
      final json = p.toJson();
      expect(json['caseId'], 'JOSEPH_SHINE');
      expect(json['caseName'], isNotEmpty);
    });
  });
}
