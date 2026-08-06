import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('GARUDA PYQ Domain Models', () {
    test('SupportedExam list contains all 24 required exams', () {
      expect(SupportedExam.initialExams.length, equals(24));
      
      final examIds = SupportedExam.initialExams.map((e) => e.id).toSet();
      expect(examIds.contains('upsc_cse'), isTrue);
      expect(examIds.contains('cds'), isTrue);
      expect(examIds.contains('nda'), isTrue);
      expect(examIds.contains('capf'), isTrue);
      expect(examIds.contains('epfo_eo_ao'), isTrue);
      expect(examIds.contains('epfo_apfc'), isTrue);
      expect(examIds.contains('ese_gs'), isTrue);
      expect(examIds.contains('rbi_grade_b'), isTrue);
      expect(examIds.contains('nabard_grade_a'), isTrue);
      expect(examIds.contains('sebi_grade_a'), isTrue);
      expect(examIds.contains('bpsc'), isTrue);
      expect(examIds.contains('uppsc'), isTrue);
      expect(examIds.contains('mppsc'), isTrue);
      expect(examIds.contains('rpsc'), isTrue);
      expect(examIds.contains('mpsc'), isTrue);
      expect(examIds.contains('jpsc'), isTrue);
      expect(examIds.contains('cgpsc'), isTrue);
      expect(examIds.contains('ukpsc'), isTrue);
      expect(examIds.contains('opsc'), isTrue);
      expect(examIds.contains('gpsc'), isTrue);
      expect(examIds.contains('ppsc'), isTrue);
      expect(examIds.contains('kpsc'), isTrue);
      expect(examIds.contains('tnpsc'), isTrue);
      expect(examIds.contains('wbpsc'), isTrue);
    });

    test('SupportedExam supports unlimited future exams via custom factory', () {
      final customExam = SupportedExam.custom(
        id: 'tspsc_group1',
        code: 'TSPSC_GRP1',
        fullName: 'Telangana State PSC Group 1',
        conductingBody: 'TSPSC',
      );

      expect(customExam.id, equals('tspsc_group1'));
      expect(customExam.category, equals(ExamCategory.custom));
    });

    test('Question model serialization and immutability', () {
      final source = QuestionSource(
        sourceType: SourceType.officialPdf,
        publisher: 'UPSC',
        retrievedDate: DateTime(2024, 1, 1),
        checksum: 'chk_123',
      );

      final q = Question(
        id: 'PYQ_UPSC_CSE_2024_GS1_Q001',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS Paper I',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        originalQuestion: 'Which Article protects right to life?',
        options: const [
          Option(key: 'A', text: 'Article 14'),
          Option(key: 'B', text: 'Article 19'),
          Option(key: 'C', text: 'Article 21', isCorrect: true),
          Option(key: 'D', text: 'Article 32'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['C']),
        garudaExplanation: 'Article 21 guarantees right to life and personal liberty.',
        source: source,
        articleLinks: const ['Article 21'],
        caseLinks: const ['Maneka Gandhi Case'],
      );

      final json = q.toJson();
      expect(json['id'], equals('PYQ_UPSC_CSE_2024_GS1_Q001'));
      expect(json['examId'], equals('upsc_cse'));

      final restored = Question.fromJson(json);
      expect(restored.id, equals(q.id));
      expect(restored.articleLinks, contains('Article 21'));
      expect(restored.officialAnswer.correctOptionKeys, contains('C'));
    });
  });
}
