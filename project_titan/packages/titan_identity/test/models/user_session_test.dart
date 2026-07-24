import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('UserSession Model Tests', () {
    final now = DateTime.now();
    final futureTime = now.add(const Duration(hours: 24));
    final pastTime = now.subtract(const Duration(hours: 1));

    final user = User(
      id: 'usr_s1',
      email: 'session@example.com',
      displayName: 'Session Learner',
      providerType: AuthProviderType.google,
      createdAt: now,
    );

    test('creates UserSession with valid fields', () {
      final session = UserSession(
        sessionId: 'sess_1',
        user: user,
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        expiresAt: futureTime,
        isActive: true,
        isOffline: false,
      );

      expect(session.sessionId, 'sess_1');
      expect(session.user, user);
      expect(session.accessToken, 'access_123');
      expect(session.refreshToken, 'refresh_456');
      expect(session.expiresAt, futureTime);
      expect(session.isActive, isTrue);
      expect(session.isOffline, isFalse);
      expect(session.isExpired, isFalse);
    });

    test('isExpired detects expired sessions', () {
      final session = UserSession(
        sessionId: 'sess_expired',
        user: user,
        accessToken: 'expired_token',
        expiresAt: pastTime,
      );

      expect(session.isExpired, isTrue);
    });

    test('copyWith works correctly', () {
      final session = UserSession(
        sessionId: 'sess_1',
        user: user,
        accessToken: 'access_123',
        expiresAt: futureTime,
      );

      final updated = session.copyWith(
        accessToken: 'access_999',
        isOffline: true,
      );

      expect(updated.sessionId, 'sess_1');
      expect(updated.accessToken, 'access_999');
      expect(updated.isOffline, isTrue);
    });

    test('serialization toJson and fromJson', () {
      final session = UserSession(
        sessionId: 'sess_ser',
        user: user,
        accessToken: 'tok_abc',
        refreshToken: 'tok_ref',
        expiresAt: futureTime,
        isActive: true,
        isOffline: true,
      );

      final json = session.toJson();
      final deserialized = UserSession.fromJson(json);

      expect(deserialized.sessionId, session.sessionId);
      expect(deserialized.user, session.user);
      expect(deserialized.accessToken, session.accessToken);
      expect(deserialized.isOffline, isTrue);
    });
  });
}
