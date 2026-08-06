import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('KnowledgeObject Domain Entity Tests', () {
    final now = DateTime.now();

    final ko = KnowledgeObject(
      id: 'KO-TEST-001',
      title: 'Test Knowledge Object',
      subject: 'Polity',
      topic: 'Test Topic',
      summary: 'Test summary statement',
      content: 'Test content body',
      status: EditorialStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    test('KnowledgeObject instantiation, copyWith, and JSON serialization', () {
      expect(ko.id, equals('KO-TEST-001'));
      expect(ko.status, equals(EditorialStatus.draft));

      final updated = ko.copyWith(status: EditorialStatus.approved);
      expect(updated.status, equals(EditorialStatus.approved));

      final json = ko.toJson();
      final restored = KnowledgeObject.fromJson(json);

      expect(restored.id, equals(ko.id));
      expect(restored.title, equals(ko.title));
      expect(restored.status, equals(EditorialStatus.draft));
    });

    test('EditorialStatus display name extension', () {
      expect(EditorialStatus.draft.displayName, equals('Draft'));
      expect(EditorialStatus.reviewPending.displayName, equals('Pending Review'));
      expect(EditorialStatus.published.displayName, equals('Published'));
    });

    test('EditorialRole capabilities', () {
      expect(EditorialRole.editor.canApprovePublishing, isFalse);
      expect(EditorialRole.seniorEditor.canApprovePublishing, isTrue);
      expect(EditorialRole.administrator.canManageSettings, isTrue);
    });
  });
}
