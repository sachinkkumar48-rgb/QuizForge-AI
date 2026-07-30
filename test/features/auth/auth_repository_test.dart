import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/features/auth/data/auth_repository_impl.dart';
import 'package:quizforge_upsc/features/auth/domain/auth_repository.dart';

void main() {
  group('AuthRepository Placeholder Tests', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = AuthRepositoryImpl();
    });

    test('AuthRepository contract is implemented', () {
      expect(authRepository, isA<AuthRepository>());
    });

    test('register throws UnimplementedError', () {
      expect(
        () => authRepository.register('test@example.com', 'password123'),
        throwsUnimplementedError,
      );
    });

    test('login throws UnimplementedError', () {
      expect(
        () => authRepository.login('test@example.com', 'password123'),
        throwsUnimplementedError,
      );
    });

    test('refresh throws UnimplementedError', () {
      expect(
        () => authRepository.refresh(),
        throwsUnimplementedError,
      );
    });

    test('logout throws UnimplementedError', () {
      expect(
        () => authRepository.logout(),
        throwsUnimplementedError,
      );
    });

    test('getCurrentUser throws UnimplementedError', () {
      expect(
        () => authRepository.getCurrentUser(),
        throwsUnimplementedError,
      );
    });
  });
}
