import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/providers/revision_controller.dart';
import 'package:quizforge_ai/src/presentation/states/revision_state.dart';

void main() {
  group('RevisionController Presentation State Tests', () {
    test('initial state is RevisionState.initial()', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(revisionControllerProvider);

      expect(state.status, equals(RevisionStateStatus.initial));
      expect(state.queue, isNull);
      expect(state.selectedCategory, equals('All'));
      expect(state.filterOption, equals('All'));
    });

    test('loadRevisionQueue populates queue and topicMastery state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(revisionControllerProvider.notifier);
      await controller.loadRevisionQueue();

      final state = container.read(revisionControllerProvider);

      expect(state.status, equals(RevisionStateStatus.success));
      expect(state.queue, isNotNull);
      expect(state.queue!.items, isNotEmpty);
      expect(state.topicMastery, isNotEmpty);
    });

    test('selectCategory updates selectedCategory and filters queue', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(revisionControllerProvider.notifier);
      await controller.selectCategory('Indian Polity');

      final state = container.read(revisionControllerProvider);

      expect(state.selectedCategory, equals('Indian Polity'));
      expect(state.queue, isNotNull);
      expect(
          state.queue!.items.every((i) => i.topic == 'Indian Polity'), isTrue);
    });

    test('selectFilterOption updates filterOption state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(revisionControllerProvider.notifier);
      await controller.selectFilterOption('Overdue');

      final state = container.read(revisionControllerProvider);

      expect(state.filterOption, equals('Overdue'));
    });

    test('recordRecallAttempt updates SM-2 schedule for target item', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(revisionControllerProvider.notifier);
      await controller.loadRevisionQueue();

      final firstItemId =
          container.read(revisionControllerProvider).queue!.items.first.id;
      await controller.recordRecallAttempt(firstItemId, 5);

      final stateAfter = container.read(revisionControllerProvider);
      expect(stateAfter.status, equals(RevisionStateStatus.success));
    });
  });
}
