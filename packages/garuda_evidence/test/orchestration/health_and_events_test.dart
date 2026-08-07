import 'package:test/test.dart';
import 'package:garuda_evidence/garuda_evidence.dart';

void main() {
  group('Health, Events, ChangeDetector & Scheduler Tests', () {
    final now = DateTime.now();

    test('SourceHealth serialization and copyWith', () {
      final health = SourceHealth(
        source: 'PIB Releases',
        enabled: true,
        status: SourceHealthStatus.healthy,
        lastSuccessfulSync: now,
        failureCount: 0,
        averageProcessingTimeMs: 142.5,
        healthScore: 0.99,
      );

      expect(health.status, equals(SourceHealthStatus.healthy));
      final json = health.toJson();
      final restored = SourceHealth.fromJson(json);
      expect(restored.source, equals('PIB Releases'));
      expect(restored.healthScore, equals(0.99));
    });

    test('StandardChangeDetector detects content differences', () {
      final detector = StandardChangeDetector();

      final obj1 = EvidenceObject(
        id: 'EV-100',
        title: 'Original Title',
        sourceName: 'PIB Releases',
        sourceType: EvidenceSourceType.government,
        authority: const EvidenceAuthority(
          id: 'pib',
          name: 'PIB',
          type: EvidenceSourceType.government,
          jurisdiction: 'India',
        ),
        publicationDate: now,
        retrievedDate: now,
        category: 'Polity',
        subject: 'Polity',
        topic: 'Elections',
        subtopic: 'ECI',
        keywords: const ['ECI'],
        language: 'en',
        summary: 'Original Summary',
        originalUrl: 'https://pib.gov.in/100',
        createdAt: now,
        updatedAt: now,
      );

      final obj2 = obj1.copyWith(title: 'Updated Title');
      final delta = detector.detectChange(obj1, obj2);

      expect(delta.hasChanged, isTrue);
      expect(delta.classification, equals(ChangeClassification.contentUpdate));
      expect(delta.modifiedFields, contains('title'));
    });

    test('ScheduleConfig serialization and enum support', () {
      final config = ScheduleConfig(
        scheduleType: ScheduleType.cron,
        cronExpression: '0 0 * * *',
        isEnabled: true,
        nextRunTime: now.add(const Duration(days: 1)),
      );

      expect(config.scheduleType, equals(ScheduleType.cron));
      final json = config.toJson();
      final restored = ScheduleConfig.fromJson(json);
      expect(restored.cronExpression, equals('0 0 * * *'));
    });

    test('EvidenceEvent subclasses produce valid event JSON', () {
      final events = <EvidenceEvent>[
        EvidenceCollected(
          eventId: 'evt-01',
          timestamp: now,
          sourceName: 'PIB Releases',
          evidenceId: 'EV-101',
        ),
        EvidenceParsed(
          eventId: 'evt-02',
          timestamp: now,
          evidence: EvidenceObject(
            id: 'EV-101',
            title: 'Title',
            sourceName: 'PIB',
            sourceType: EvidenceSourceType.government,
            authority: const EvidenceAuthority(
                id: 'pib',
                name: 'PIB',
                type: EvidenceSourceType.government,
                jurisdiction: 'India'),
            publicationDate: now,
            retrievedDate: now,
            category: 'Polity',
            subject: 'Polity',
            topic: 'Topic',
            subtopic: 'Subtopic',
            keywords: const [],
            language: 'en',
            summary: 'Summary',
            originalUrl: 'https://pib.gov.in/101',
            createdAt: now,
            updatedAt: now,
          ),
        ),
        EvidenceValidated(
          eventId: 'evt-03',
          timestamp: now,
          evidenceId: 'EV-101',
          isValid: true,
        ),
        EvidenceApproved(
          eventId: 'evt-04',
          timestamp: now,
          evidenceId: 'EV-101',
          reviewer: 'Editor_A',
        ),
        EvidenceRejected(
          eventId: 'evt-05',
          timestamp: now,
          evidenceId: 'EV-102',
          reviewer: 'Editor_B',
          reason: 'Incomplete content',
        ),
        EvidenceUpdated(
          eventId: 'evt-06',
          timestamp: now,
          evidenceId: 'EV-101',
          newVersion: 2,
        ),
        KnowledgeLinked(
          eventId: 'evt-07',
          timestamp: now,
          evidenceId: 'EV-101',
          knowledgeObjectType: 'constitutionArticles',
          targetLinkId: 'Art-21',
        ),
        SourceUnavailable(
          eventId: 'evt-08',
          timestamp: now,
          sourceName: 'PIB',
          errorDetails: 'HTTP 503',
        ),
        CollectorFailed(
          eventId: 'evt-09',
          timestamp: now,
          collectorName: 'PIBCollector',
          errorMessage: 'Timeout',
        ),
      ];

      expect(events.length, equals(9));
      for (final evt in events) {
        final json = evt.toJson();
        expect(json['eventId'], isNotEmpty);
        expect(json['eventType'], isNotEmpty);
      }
    });
  });
}
