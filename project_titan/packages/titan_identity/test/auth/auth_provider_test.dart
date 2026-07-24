import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('Auth Providers Tests', () {
    test('GuestAuthProvider creates valid guest session', () async {
      const provider = GuestAuthProvider();
      expect(provider.providerType, AuthProviderType.guest);

      final session = await provider.signIn();
      expect(session.user.isGuest, isTrue);
      expect(session.user.providerType, AuthProviderType.guest);
      expect(session.isOffline, isTrue);
      expect(session.isActive, isTrue);
      expect(session.isExpired, isFalse);

      final refreshed = await provider.refreshSession(session);
      expect(refreshed.user.id, session.user.id);
    });

    test('GoogleAuthProvider signs in with credentials', () async {
      const provider = GoogleAuthProvider();
      expect(provider.providerType, AuthProviderType.google);

      final session = await provider.signIn(credentials: {
        'email': 'upsc.learner@gmail.com',
        'displayName': 'UPSC Aspirant',
      });

      expect(session.user.email, 'upsc.learner@gmail.com');
      expect(session.user.displayName, 'UPSC Aspirant');
      expect(session.user.isGuest, isFalse);
      expect(session.user.providerType, AuthProviderType.google);
      expect(session.accessToken, startsWith('google_token_'));

      final refreshed = await provider.refreshSession(session);
      expect(refreshed.accessToken, startsWith('google_token_refreshed_'));
    });

    test('EmailPasswordAuthProvider requires email & password', () async {
      const provider = EmailPasswordAuthProvider();
      expect(provider.providerType, AuthProviderType.emailPassword);

      expect(
        () => provider.signIn(credentials: {'email': ''}),
        throwsA(isA<ArgumentError>()),
      );

      final session = await provider.signIn(credentials: {
        'email': 'aspirant@titan.ai',
        'password': 'SecretPassword123',
      });

      expect(session.user.email, 'aspirant@titan.ai');
      expect(session.user.providerType, AuthProviderType.emailPassword);
      expect(session.accessToken, startsWith('email_token_'));

      final refreshed = await provider.refreshSession(session);
      expect(refreshed.accessToken, startsWith('email_token_refreshed_'));
    });
  });
}
