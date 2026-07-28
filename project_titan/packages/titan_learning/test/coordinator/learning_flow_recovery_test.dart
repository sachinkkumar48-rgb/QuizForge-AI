import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('Learning Flow Recovery Tests', () {
    test('recoverSession returns null when no persisted session exists',
        () async {
      final coordinator = LearningFlowCoordinator();
      final recovered = await coordinator.recoverSession();
      expect(recovered, isNull);
      await coordinator.dispose();
    });
  });
}
