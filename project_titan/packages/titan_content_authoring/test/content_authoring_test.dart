import 'package:flutter_test/flutter_test.dart';
import 'package:titan_content_authoring/titan_content_authoring.dart';

void main() {
  group('Content Authoring Unit Tests', () {
    late ContentAuthoringRepository repository;

    setUp(() {
      repository = ContentAuthoringRepositoryImpl();
    });

    test('getAllAuthoringItems returns seeded draft', () async {
      final items = await repository.getAllAuthoringItems();
      expect(items.isNotEmpty, isTrue);
      expect(items.first.title, contains('Article 21'));
    });

    test('saveDraft creates and updates authoring item', () async {
      final newItem = KmpAuthoringItem(
        id: 'auth_economy_budget',
        title: 'Union Budget 2026 Analysis',
        description:
            'Fiscal deficit targets and capital expenditure breakdown.',
        format: AuthoringFormat.pdf,
        bodyContent: 'PDF attachment reference',
        authorId: 'editor_eco',
        authorName: 'Economy Editor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveDraft(newItem);
      final fetched = await repository.getItemById('auth_economy_budget');
      expect(fetched, isNotNull);
      expect(fetched!.format, equals(AuthoringFormat.pdf));

      final updated = await repository.updateStatus(
        'auth_economy_budget',
        PublicationStatus.humanReview,
        reviewerId: 'rev_1',
      );
      expect(updated.status, equals(PublicationStatus.humanReview));
      expect(updated.reviewerId, equals('rev_1'));
    });
  });
}
