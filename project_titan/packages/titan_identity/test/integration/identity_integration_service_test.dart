import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('IdentityIntegrationService Tests', () {
    late SessionManager sessionManager;
    late IdentityIntegrationService integrationService;

    setUp(() {
      sessionManager = SessionManager();
      integrationService = IdentityIntegrationService(
        sessionManager: sessionManager,
      );
      integrationService.initialize();
    });

    tearDown(() async {
      integrationService.dispose();
      await sessionManager.dispose();
    });

    test('Reacts to session state changes in SessionManager', () async {
      final now = DateTime.now();
      final session = UserSession(
        sessionId: 'sess_integ',
        user: User(
          id: 'usr_integ',
          email: 'integ@titan.ai',
          displayName: 'Integ Aspirant',
          providerType: AuthProviderType.guest,
          createdAt: now,
        ),
        accessToken: 'tok_integ',
        expiresAt: now.add(const Duration(hours: 1)),
      );

      await sessionManager.updateSession(session);
      await Future<void>.delayed(Duration.zero);

      expect(integrationService.lastProcessedSession, equals(session));

      await sessionManager.clearSession();
      await Future<void>.delayed(Duration.zero);

      expect(integrationService.lastProcessedSession, isNull);
    });
  });
}
