import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/garuda_editor.dart';

void main() {
  group('EditorialStudioController Application Tests', () {
    late EditorialStudioController controller;

    setUp(() {
      controller = EditorialStudioController();
    });

    test('Initial tab index, role, and metrics loading', () {
      expect(controller.currentTabIndex, equals(0));
      expect(controller.currentRole, equals(EditorialRole.seniorEditor));
      expect(controller.isDarkMode, isTrue);
      expect(controller.evidenceInbox.isNotEmpty, isTrue);
      expect(controller.pendingLinks.isNotEmpty, isTrue);
    });

    test('selectTab and setRole update state', () {
      controller.selectTab(2);
      expect(controller.currentTabIndex, equals(2));

      controller.setRole(EditorialRole.administrator);
      expect(controller.currentRole, equals(EditorialRole.administrator));
    });

    test('approveEvidence removes item from inbox', () async {
      final initialCount = controller.evidenceInbox.length;
      final targetId = controller.evidenceInbox.first.id;

      await controller.approveEvidence(targetId, comment: 'Good evidence');
      expect(controller.evidenceInbox.length, equals(initialCount - 1));
    });

    test('approveLink removes item from pending links queue', () async {
      final initialCount = controller.pendingLinks.length;
      final targetId = controller.pendingLinks.first.id;

      await controller.approveLink(targetId);
      expect(controller.pendingLinks.length, equals(initialCount - 1));
    });
  });
}
