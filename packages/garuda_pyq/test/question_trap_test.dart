import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('QuestionTrap & LearningObjectives Model Tests', () {
    test('QuestionTrap serialization and immutability', () {
      const trap = QuestionTrap(
        id: 'TRAP_01',
        questionId: 'Q1',
        trapType: 'Extreme Words Trap',
        commonMistake: 'Failing to spot "all", "only", "always"',
        expectedThinking: 'Notice absolute language',
        wrongEliminationStrategy: 'Assuming extreme statements are always true',
        correctEliminationStrategy: 'Eliminate options with unverified absolute claims',
      );

      final json = trap.toJson();
      expect(json['trapType'], equals('Extreme Words Trap'));

      final restored = QuestionTrap.fromJson(json);
      expect(restored.trapType, equals(trap.trapType));
      expect(restored.correctEliminationStrategy, equals(trap.correctEliminationStrategy));
    });

    test('LearningObjectives serialization', () {
      const lo = LearningObjectives(
        studentShouldBeAbleTo: ['Identify Article 21 scope'],
        define: ['Personal Liberty'],
        eliminateOptions: ['Eliminate Option A'],
      );

      final json = lo.toJson();
      expect(json['define'], contains('Personal Liberty'));

      final restored = LearningObjectives.fromJson(json);
      expect(restored.eliminateOptions, contains('Eliminate Option A'));
    });
  });
}
