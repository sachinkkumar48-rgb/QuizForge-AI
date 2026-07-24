import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/providers/library_controller.dart';
import 'package:quizforge_ai/src/presentation/states/library_state.dart';

void main() {
  group('LibraryController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is LibraryState.initial()', () {
      final state = container.read(libraryControllerProvider);
      expect(state.status, equals(LibraryStateStatus.initial));
      expect(state.documents, isEmpty);
    });

    test(
        'loadLibrary populates documents, folders, continueReading, and favorites',
        () async {
      final controller = container.read(libraryControllerProvider.notifier);
      await controller.loadLibrary();

      final state = container.read(libraryControllerProvider);
      expect(state.status, equals(LibraryStateStatus.success));
      expect(state.documents, isNotEmpty);
      expect(state.folders, isNotEmpty);
      expect(state.favoriteDocuments, isNotEmpty);
    });

    test('searchDocuments updates query and filters documents', () async {
      final controller = container.read(libraryControllerProvider.notifier);
      await controller.loadLibrary();

      await controller.searchDocuments('Governance');
      final state = container.read(libraryControllerProvider);
      expect(state.searchQuery, equals('Governance'));
      expect(state.documents, isNotEmpty);
      expect(state.documents.first.title.contains('Governance'), isTrue);
    });

    test('selectCategory updates category and filters state', () async {
      final controller = container.read(libraryControllerProvider.notifier);
      await controller.loadLibrary();

      await controller.selectCategory('Economy');
      final state = container.read(libraryControllerProvider);
      expect(state.selectedCategory, equals('Economy'));
      expect(state.documents.every((d) => d.category == 'Economy'), isTrue);
    });
  });
}
