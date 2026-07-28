import 'package:test/test.dart';
import 'package:titan_ai/titan_ai.dart';

void main() {
  group('PromptTemplateEngine Tests', () {
    late PromptTemplateEngine engine;

    setUp(() {
      engine = PromptTemplateEngine();
    });

    test('default templates are registered on initialization', () {
      expect(engine.registeredTemplates.isNotEmpty, isTrue);
      expect(engine.getTemplate('tutor_explain'), isNotNull);
      expect(engine.getTemplate('mentor_guide'), isNotNull);
      expect(engine.getTemplate('quiz_generate'), isNotNull);
      expect(engine.getTemplate('summary_lesson'), isNotNull);
      expect(engine.getTemplate('revision_suggest'), isNotNull);
      expect(engine.getTemplate('planner_generate'), isNotNull);
      expect(engine.getTemplate('mindmap_generate'), isNotNull);
      expect(engine.getTemplate('notes_generate'), isNotNull);
      expect(engine.getTemplate('evaluate_answer'), isNotNull);
      expect(engine.getTemplate('daily_targets'), isNotNull);
      expect(engine.getTemplate('motivation_generate'), isNotNull);
    });

    test('renders template variables correctly', () {
      final rendered = engine.render('tutor_explain', {
        'concept': 'Preamble',
        'subject': 'Polity',
        'targetExam': 'UPSC CSE',
        'masteryLevel': 'Advanced',
        'context': 'Basic Structure Doctrine',
        'query': 'Explain sovereignty',
      });

      expect(rendered, contains('Preamble'));
      expect(rendered, contains('Polity'));
      expect(rendered, contains('Explain sovereignty'));
    });

    test('throws ArgumentError for unregistered template id', () {
      expect(
        () => engine.render('unknown_template', {}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows registering custom template', () {
      const custom = PromptTemplate(
        id: 'custom_test',
        name: 'Custom Test',
        template: 'Hello {{name}}',
        version: '1.0.0',
      );
      engine.register(custom);
      expect(engine.getTemplate('custom_test'), equals(custom));
      expect(engine.render('custom_test', {'name': 'World'}),
          equals('Hello World'));
    });
  });
}
