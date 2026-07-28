import 'package:flutter_test/flutter_test.dart';
import 'package:titan_dashboard/titan_dashboard.dart';
import 'package:titan_storage/titan_storage.dart';

void main() {
  group('Dashboard Use Cases Unit Tests', () {
    late DashboardEngine engine;
    late GetDashboardSnapshotUseCase getSnapshotUC;
    late RefreshDashboardUseCase refreshUC;
    late GenerateInsightsUseCase insightsUC;

    setUp(() {
      final repo =
          DashboardRepositoryImpl(storageService: InMemoryStorageService());
      engine = DashboardEngine(repo);
      getSnapshotUC = GetDashboardSnapshotUseCase(engine);
      refreshUC = RefreshDashboardUseCase(engine);
      insightsUC = GenerateInsightsUseCase(engine);
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('GetDashboardSnapshotUseCase returns snapshot', () async {
      final snapshot = await getSnapshotUC.execute(
        userId: 'u_101',
        userName: 'Alice',
      );

      expect(snapshot.userId, equals('u_101'));
      expect(snapshot.userName, equals('Alice'));
    });

    test('RefreshDashboardUseCase forces snapshot refresh', () async {
      final snapshot = await refreshUC.execute(
        userId: 'u_101',
        userName: 'Alice',
      );

      expect(snapshot.userId, equals('u_101'));
    });

    test('GenerateInsightsUseCase extracts insights', () async {
      final insights = await insightsUC.execute(
        userId: 'u_101',
        userName: 'Alice',
      );

      expect(insights.topRecommendation, isNotEmpty);
    });
  });
}
