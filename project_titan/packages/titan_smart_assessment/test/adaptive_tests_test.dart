import 'package:flutter_test/flutter_test.dart';
import 'package:titan_smart_assessment/titan_smart_assessment.dart';

void main() {
  group('Adaptive CAT Assessment Logic Tests', () {
    late AssessmentEngine engine;

    setUp(() {
      engine = const AssessmentEngine();
    });

    test('Theta increases on successive correct responses', () {
      var state = const AdaptiveAssessmentState(
        sessionId: 's1',
        currentTheta: 0.0,
      );

      for (int i = 0; i < 3; i++) {
        state = engine.updateAdaptiveTheta(
          currentState: state,
          isCorrect: true,
          itemDifficulty: 0.0,
        );
      }

      expect(state.currentTheta, greaterThan(0.5));
      expect(state.itemsAdministered, equals(3));
      expect(state.consecutiveCorrect, equals(3));
    });

    test('Theta decreases on wrong response after streak', () {
      var state = const AdaptiveAssessmentState(
        sessionId: 's1',
        currentTheta: 1.0,
        consecutiveCorrect: 2,
      );

      state = engine.updateAdaptiveTheta(
        currentState: state,
        isCorrect: false,
        itemDifficulty: 0.5,
      );

      expect(state.currentTheta, lessThan(1.0));
      expect(state.consecutiveCorrect, equals(0));
    });
  });
}
