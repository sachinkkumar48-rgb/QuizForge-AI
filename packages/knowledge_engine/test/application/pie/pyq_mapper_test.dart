import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PYQMapper Tests', () {
    final mapper = PYQMapper();

    test(
        'mapToKnowledge transforms PreviousYearQuestion into canonical KnowledgeObject',
        () {
      final question = PreviousYearQuestion(
        id: 'pyq-300',
        question:
            'Which of the following bodies is/are established under Article 280 of the Constitution?',
        options: ['Finance Commission', 'NITI Aayog', 'GST Council', 'CAG'],
        answer: 'Finance Commission',
        explanation:
            'The Finance Commission is a constitutional body constituted under Article 280.',
        exam: 'UPSC CSE',
        year: 2021,
        paper: 'GS Paper I',
        subject: 'Polity',
        topics: ['Constitutional Bodies', 'Finance Commission'],
        difficulty: 'Easy',
        tags: ['Polity', 'PYQ 2021'],
      );

      final kObj = mapper.mapToKnowledge(question);

      expect(kObj.id, equals('pyq-300'));
      expect(kObj.type, equals(KnowledgeType.pyq));
      expect(kObj.title, contains('[UPSC CSE 2021 - GS Paper I]'));
      expect(kObj.summary,
          contains('Finance Commission is a constitutional body'));
      expect(kObj.source, equals('UPSC CSE 2021 GS Paper I'));
      expect(kObj.subjects, equals(['Polity']));
      expect(kObj.topics,
          containsAll(['Constitutional Bodies', 'Finance Commission']));
      expect(kObj.keywords,
          containsAll(['Polity', 'PYQ 2021', 'UPSC CSE', '2021', 'PYQ']));
      expect(kObj.metadata['itemId'], equals('pyq-300'));
      expect(kObj.metadata['contentType'], equals('pyq'));
    });
  });
}
