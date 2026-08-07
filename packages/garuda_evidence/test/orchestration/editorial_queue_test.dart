import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('EditorialQueue Tests', () {
    late EditorialQueue queue;
    late EvidenceObject item1;
    late EvidenceObject item2;
    final now = DateTime.now();

    setUp(() {
      queue = InMemoryEditorialQueue();

      item1 = EvidenceObject(
        id: 'EV-ED-01',
        title: 'Draft Gazette Notification on Digital Data Protection',
        sourceName: 'Gazette Notifications',
        sourceType: EvidenceSourceType.gazette,
        authority: const EvidenceAuthority(
          id: 'meity',
          name: 'MeitY',
          type: EvidenceSourceType.ministry,
          jurisdiction: 'India',
        ),
        publicationDate: now,
        retrievedDate: now,
        category: 'Governance',
        subject: 'Polity',
        topic: 'Data Privacy',
        subtopic: 'DPDP Act Rules',
        keywords: const ['Privacy', 'Data'],
        language: 'en',
        summary: 'Draft rules notified for data protection.',
        originalUrl: 'https://egazette.gov.in/01',
        createdAt: now,
        updatedAt: now,
      );

      item2 = item1.copyWith(
        id: 'EV-ED-02',
        title: 'Draft Finance Bill Amendment',
      );
    });

    test('enqueue, pending, approve, reject, assignReviewer', () async {
      await queue.enqueue(item1, reason: 'Pending editorial review');
      await queue.enqueue(item2, reason: 'Pending editorial review');

      var pendingList = await queue.pending();
      expect(pendingList.length, equals(2));

      await queue.assignReviewer('EV-ED-01', 'SeniorEditor_Rajesh');
      final approved = await queue.approve('EV-ED-01',
          reviewer: 'SeniorEditor_Rajesh', notes: 'Factually verified');
      expect(approved, isNotNull);
      expect(approved!.status, equals(QueueStatus.approved));

      final rejected = await queue.reject('EV-ED-02',
          reviewer: 'SeniorEditor_Rajesh', reason: 'Outdated circular');
      expect(rejected, isNotNull);
      expect(rejected!.status, equals(QueueStatus.rejected));

      pendingList = await queue.pending();
      expect(pendingList, isEmpty);

      final approvedList = await queue.approved();
      expect(approvedList.length, equals(1));

      final rejectedList = await queue.rejected();
      expect(rejectedList.length, equals(1));
    });
  });
}
