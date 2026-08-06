import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('InMemoryEditorialRepository Integration Tests', () {
    late InMemoryEditorialRepository repo;
    final now = DateTime.now();

    setUp(() {
      repo = InMemoryEditorialRepository();
    });

    test('getKnowledgeObjects should return seeded initial items', () async {
      final items = await repo.getKnowledgeObjects();
      expect(items.length, greaterThanOrEqualTo(3));
    });

    test('saveKnowledgeObject should persist new object and create version v1', () async {
      final ko = KnowledgeObject(
        id: 'KO-PERSIST-99',
        title: 'New Persisted Object',
        subject: 'Governance',
        topic: 'E-Governance',
        summary: 'Summary text',
        content: 'Content text',
        createdAt: now,
        updatedAt: now,
      );

      final saved = await repo.saveKnowledgeObject(ko, editor: 'TestEditor', changeSummary: 'Initial save');
      expect(saved.id, equals('KO-PERSIST-99'));
      expect(saved.currentVersion, equals(1));
      expect(saved.versions.length, equals(1));

      final retrieved = await repo.getKnowledgeObjectById('KO-PERSIST-99');
      expect(retrieved, isNotNull);
      expect(retrieved?.title, equals('New Persisted Object'));
    });

    test('updateKnowledgeObject should increment version number', () async {
      final items = await repo.getKnowledgeObjects();
      final target = items.first;

      final updated = target.copyWith(title: '${target.title} Updated');
      final res = await repo.updateKnowledgeObject(updated, editor: 'TestEditor', changeSummary: 'Title update');

      expect(res.currentVersion, equals(target.currentVersion + 1));
      expect(res.versions.length, equals(target.versions.length + 1));
    });

    test('changeStatus should record audit log entry', () async {
      final items = await repo.getKnowledgeObjects();
      final target = items.first;

      await repo.changeStatus(target.id, EditorialStatus.published, editor: 'SeniorEditor', comment: 'Approved for launch');
      final updated = await repo.getKnowledgeObjectById(target.id);
      expect(updated?.status, equals(EditorialStatus.published));

      final logs = await repo.getAuditLogs(objectId: target.id);
      expect(logs.any((l) => l.action == 'STATUS_CHANGE'), isTrue);
    });
  });
}
