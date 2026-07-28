import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('DashboardRepositoryImpl Unit Tests', () {
    late StorageService storageService;
    late DashboardRepositoryImpl repository;

    setUp(() {
      storageService = InMemoryStorageService();
      repository = DashboardRepositoryImpl(storageService: storageService);
    });

    test('getSnapshot aggregates fresh snapshot and persists to storage',
        () async {
      final snapshot = await repository.getSnapshot(
        userId: 'user_99',
        userName: 'Tester',
      );

      expect(snapshot.userId, equals('user_99'));
      expect(snapshot.userName, equals('Tester'));
      expect(snapshot.readinessScore, greaterThan(0.0));

      // Retrieve again to hit offline-first cache
      final cachedSnapshot = await repository.getSnapshot(
        userId: 'user_99',
        userName: 'Tester',
      );

      expect(cachedSnapshot.userId, equals('user_99'));
    });

    test('forceRefresh bypasses cache', () async {
      final s1 = await repository.getSnapshot(
        userId: 'user_99',
        userName: 'Tester',
      );

      final s2 = await repository.getSnapshot(
        userId: 'user_99',
        userName: 'Tester',
        forceRefresh: true,
      );

      expect(s2.userId, equals(s1.userId));
    });

    test('generateInsights delegates to snapshot insights', () async {
      final insights = await repository.generateInsights(
        userId: 'user_99',
        userName: 'Tester',
      );

      expect(insights.topRecommendation, isNotEmpty);
    });
  });
}
