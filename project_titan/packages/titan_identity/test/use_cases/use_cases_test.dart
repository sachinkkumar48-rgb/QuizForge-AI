import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('Identity Use Cases Tests', () {
    late IdentityRepository repository;
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      repository = IdentityRepositoryImpl(sessionManager: sessionManager);
    });

    tearDown(() async {
      await sessionManager.dispose();
    });

    test('RegisterUserUseCase executes registration', () async {
      final useCase = RegisterUserUseCase(repository);
      final session = await useCase.execute(
        providerType: AuthProviderType.emailPassword,
        userDetails: {
          'email': 'usecase@titan.ai',
          'password': 'Password123',
        },
      );

      expect(session.user.email, 'usecase@titan.ai');
    });

    test('SignInUseCase executes sign-in', () async {
      final useCase = SignInUseCase(repository);
      final session = await useCase.execute(
        providerType: AuthProviderType.guest,
      );

      expect(session.user.isGuest, isTrue);
    });

    test('GetCurrentUserUseCase retrieves user and session', () async {
      await repository.signIn(providerType: AuthProviderType.guest);

      final useCase = GetCurrentUserUseCase(repository);
      final user = await useCase.getUser();
      final session = await useCase.getSession();

      expect(user, isNotNull);
      expect(session, isNotNull);
    });

    test('RefreshSessionUseCase refreshes token', () async {
      await repository.signIn(providerType: AuthProviderType.guest);

      final useCase = RefreshSessionUseCase(repository);
      final session = await useCase.execute();

      expect(session.isActive, isTrue);
    });

    test('SignOutUseCase executes sign out', () async {
      await repository.signIn(providerType: AuthProviderType.guest);

      final useCase = SignOutUseCase(repository);
      await useCase.execute();

      expect(await repository.getCurrentUser(), isNull);
    });

    test('DeleteAccountUseCase executes account deletion', () async {
      await repository.signIn(providerType: AuthProviderType.guest);

      final useCase = DeleteAccountUseCase(repository);
      await useCase.execute();

      expect(await repository.getCurrentUser(), isNull);
    });
  });
}
