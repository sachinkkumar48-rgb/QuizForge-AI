import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizforge_upsc/core/network/api_client.dart';
import 'package:quizforge_upsc/repositories/impl/http_remote_learning_state_repository.dart';

void main() {
  group('HttpRemoteLearningStateRepository Tests (P56 Foundation)', () {
    test('isReachable returns true when /health reports healthy status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/health');
        expect(request.method, 'GET');
        return http.Response(jsonEncode({'status': 'healthy', 'version': '1.5.0'}), 200);
      });

      final repo = HttpRemoteLearningStateRepository(apiClient: ApiClient(client: mockClient));
      final reachable = await repo.isReachable();
      expect(reachable, isTrue);
    });

    test('isReachable returns false when /health is unavailable', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final repo = HttpRemoteLearningStateRepository(apiClient: ApiClient(client: mockClient));
      final reachable = await repo.isReachable();
      expect(reachable, isFalse);
    });

    test('pushState successfully delivers envelope and parses remote revision', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/sync/state');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['learnerId'], equals('learner_101'));
        expect(body['examId'], equals('upsc_prelims'));

        return http.Response(
          jsonEncode({
            'success': true,
            'remoteRevision': 5,
            'syncedAt': DateTime.now().toUtc().toIso8601String(),
          }),
          200,
        );
      });

      final repo = HttpRemoteLearningStateRepository(apiClient: ApiClient(client: mockClient));
      final envelope = SyncEnvelope(
        syncId: 'sync_001',
        learnerId: 'learner_101',
        examId: 'upsc_prelims',
        revision: 5,
        deviceId: 'dev_phone_1',
        checksum: 'dummy_hash',
        payload: {'learnerId': 'learner_101', 'examId': 'upsc_prelims', 'revision': 5},
      );

      final result = await repo.pushState(envelope);
      expect(result.success, isTrue);
      expect(result.remoteRevision, equals(5));
      expect(result.isConflict, isFalse);
    });

    test('fetchState returns RemoteFetchResult.empty when state does not exist', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/sync/state');
        expect(request.url.queryParameters['learnerId'], equals('learner_none'));
        return http.Response(jsonEncode({'success': true, 'exists': false, 'revision': 0}), 200);
      });

      final repo = HttpRemoteLearningStateRepository(apiClient: ApiClient(client: mockClient));
      final result = await repo.fetchState(learnerId: 'learner_none', examId: 'upsc');
      expect(result.success, isTrue);
      expect(result.exists, isFalse);
      expect(result.state, isNull);
    });

    test('pushCheckpoint posts session checkpoint and parses remote revision', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/sync/checkpoint');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['sessionId'], equals('sess_99'));
        expect(body['deviceId'], equals('dev_01'));

        return http.Response(jsonEncode({'success': true, 'remoteRevision': 3}), 200);
      });

      final repo = HttpRemoteLearningStateRepository(apiClient: ApiClient(client: mockClient));
      final checkpoint = SessionCheckpoint(
        sessionId: 'sess_99',
        learnerId: 'learner_101',
        examId: 'upsc_prelims',
        checkpointRevision: 3,
        authoritativeStateRevision: 5,
        questionIndex: 0,
        completedQuestionIds: const [],
        activeObjectiveId: 'obj_1',
        timestamp: DateTime.now().toUtc(),
      );

      final result = await repo.pushCheckpoint(checkpoint, deviceId: 'dev_01');
      expect(result.success, isTrue);
      expect(result.remoteRevision, equals(3));
    });
  });
}
