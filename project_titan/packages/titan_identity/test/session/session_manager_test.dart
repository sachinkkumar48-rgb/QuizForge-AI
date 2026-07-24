import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('SessionManager Tests', () {
    final now = DateTime.now();
    final user = User(
      id: 'usr_sm',
      email: 'sm@example.com',
      displayName: 'SM Aspirant',
      providerType: AuthProviderType.google,
      createdAt: now,
    );
    final session = UserSession(
      sessionId: 'sess_sm',
      user: user,
      accessToken: 'token_sm',
      expiresAt: now.add(const Duration(hours: 5)),
    );

    test('Initializes with initialSession', () {
      final manager = SessionManager(initialSession: session);
      expect(manager.currentSession, equals(session));
      expect(manager.currentUser, equals(user));
      expect(manager.isAuthenticated, isTrue);
    });

    test('Emits stream events on updateSession and clearSession', () async {
      final manager = SessionManager();
      final streamEvents = <UserSession?>[];

      final sub = manager.sessionStream.listen(streamEvents.add);

      expect(manager.isAuthenticated, isFalse);

      await manager.updateSession(session);
      expect(manager.currentSession, equals(session));
      expect(manager.isAuthenticated, isTrue);

      await manager.clearSession();
      expect(manager.currentSession, isNull);
      expect(manager.isAuthenticated, isFalse);

      await manager.dispose();
      await sub.cancel();

      expect(streamEvents, equals([session, null]));
    });
  });
}
