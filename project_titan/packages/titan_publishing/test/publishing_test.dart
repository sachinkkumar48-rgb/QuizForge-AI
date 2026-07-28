import 'package:flutter_test/flutter_test.dart';
import 'package:titan_content_authoring/titan_content_authoring.dart';
import 'package:titan_publishing/titan_publishing.dart';

void main() {
  group('Publishing & Versioning Unit Tests', () {
    late PublishingRepository repository;

    setUp(() {
      repository = PublishingRepositoryImpl();
    });

    test('transitionState advances status and records audit snapshot',
        () async {
      final initialItem = KmpAuthoringItem(
        id: 'item_101',
        title: 'Initial Draft Title',
        description: 'Description',
        format: AuthoringFormat.markdown,
        bodyContent: 'Initial Body Content',
        authorId: 'author_1',
        authorName: 'Author 1',
        status: PublicationStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final reviewed = await repository.transitionState(
        item: initialItem,
        targetStatus: PublicationStatus.humanReview,
        actorId: 'reviewer_1',
        actorRole: 'Reviewer',
        comments: 'Ready for editorial review',
      );

      expect(reviewed.status, equals(PublicationStatus.humanReview));

      final audit = await repository.getWorkflowAuditLog('item_101');
      expect(audit.length, equals(1));
      expect(audit.first.fromStatus, equals(PublicationStatus.draft));
      expect(audit.first.toStatus, equals(PublicationStatus.humanReview));

      final history = await repository.getVersionHistory('item_101');
      expect(history.length, equals(1));
      expect(history.first.snapshotTitle, equals('Initial Draft Title'));
    });

    test('rollbackToVersion reverts content to prior snapshot', () async {
      final initialItem = KmpAuthoringItem(
        id: 'item_102',
        title: 'Original Title v1',
        description: 'Desc',
        format: AuthoringFormat.markdown,
        bodyContent: 'Original Body v1',
        authorId: 'author_1',
        authorName: 'Author 1',
        status: PublicationStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final step1 = await repository.transitionState(
        item: initialItem,
        targetStatus: PublicationStatus.approved,
        actorId: 'admin_1',
        actorRole: 'Publisher',
      );

      final history = await repository.getVersionHistory('item_102');
      final snapshotId = history.first.versionId;

      final modifiedItem = step1.copyWith(
        title: 'Corrupted Modified Title v2',
        bodyContent: 'Bad edit',
      );

      final rolledBack = await repository.rollbackToVersion(
        currentItem: modifiedItem,
        targetVersionId: snapshotId,
        actorId: 'editor_1',
      );

      expect(rolledBack.title, equals('Original Title v1'));
      expect(rolledBack.bodyContent, equals('Original Body v1'));
      expect(rolledBack.status, equals(PublicationStatus.draft));
    });
  });
}
