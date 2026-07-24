import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('IdentityRepositoryImpl Tests', () {
    late IdentityRepository repository;
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      repository = IdentityRepositoryImpl(sessionManager: sessionManager);
    });

    tearDown(() async {
      await sessionManager.dispose();
    });

    test('signIn with guest provider initializes session', () async {
      final session = await repository.signIn(
        providerType: AuthProviderType.guest,
      );

      expect(session.user.isGuest, isTrue);
      expect(await repository.getCurrentUser(), equals(session.user));
      expect(await repository.getActiveSession(), equals(session));
    });

    test('register with email/password updates session state', () async {
      final session = await repository.register(
        providerType: AuthProviderType.emailPassword,
        userDetails: {
          'email': 'aspirant_reg@titan.ai',
          'password': 'PassWord123!',
          'displayName': 'New Aspirant',
        },
      );

      expect(session.user.email, 'aspirant_reg@titan.ai');
      expect(session.user.displayName, 'New Aspirant');
      expect(await repository.getCurrentUser(), equals(session.user));
    });

    test('refreshSession updates active session', () async {
      await repository.signIn(providerType: AuthProviderType.guest);
      final refreshed = await repository.refreshSession();
      expect(refreshed.isActive, isTrue);
    });

    test('signOut clears session', () async {
      await repository.signIn(providerType: AuthProviderType.guest);
      expect(await repository.getCurrentUser(), isNotNull);

      await repository.signOut();
      expect(await repository.getCurrentUser(), isNull);
      expect(await repository.getActiveSession(), isNull);
    });

    test('deleteAccount calls signOut and clears session', () async {
      await repository.signIn(
        providerType: AuthProviderType.google,
        credentials: {'email': 'del@google.com'},
      );

      await repository.deleteAccount();
      expect(await repository.getCurrentUser(), isNull);
    });
  });
}
