import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/providers/learning_profile_controller.dart';
import 'package:quizforge_ai/src/presentation/states/learning_profile_state.dart';

void main() {
  group('LearningProfileController State Tests', () {
    test('initial state is LearningProfileState.initial()', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(learningProfileControllerProvider);

      expect(state.status, equals(LearningProfileStatus.initial));
      expect(state.profile, isNull);
    });

    test('loadProfile populates profile state successfully', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller =
          container.read(learningProfileControllerProvider.notifier);
      await controller.loadProfile();

      final state = container.read(learningProfileControllerProvider);

      expect(state.status, equals(LearningProfileStatus.success));
      expect(state.profile, isNotNull);
      expect(state.profile!.userId, equals('user_titan'));
      expect(state.profile!.topicMasteries, isNotEmpty);
    });
  });
}
