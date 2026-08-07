import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_committees/garuda_committees.dart';

void main() {
  group('CommitteeValidator Tests', () {
    test('should validate valid Committee Knowledge Object', () {
      final committee = CommitteeSeedCorpus.phase1Committees.first;
      final report = CommitteeValidator.validate(committee);

      expect(report.isValid, isTrue);
      expect(report.issues, isEmpty);
    });

    test('should detect missing official name and constituting authority', () {
      final invalid = CommitteeKnowledgeObject(
        id: 'comm_invalid',
        officialName: '',
        shortName: 'Invalid',
        category: CommitteeCategory.executive,
        constitutingAuthority: '',
        chairperson: const CommitteeMember(name: '', role: 'Chairperson'),
        yearConstituted: 2025,
        termsOfReference: const TermsOfReference(id: 'tor_invalid', description: ''),
      );

      final report = CommitteeValidator.validate(invalid);

      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'officialName'), isTrue);
      expect(report.issues.any((i) => i.field == 'constitutingAuthority'), isTrue);
      expect(report.issues.any((i) => i.field == 'chairperson'), isTrue);
      expect(report.issues.any((i) => i.field == 'evidenceIds'), isTrue);
    });

    test('should detect duplicate committee with matching name and year', () {
      final committee1 = CommitteeSeedCorpus.phase1Committees.first;
      final committee2 = committee1.copyWith(id: 'comm_duplicate_id');

      final report =
          CommitteeValidator.validate(committee2, existingCommittees: [committee1]);

      expect(report.isValid, isFalse);
      expect(report.issues.any((i) => i.field == 'duplicate'), isTrue);
    });
  });
}
