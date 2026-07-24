import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';

void main() {
  group('User Model Tests', () {
    final now = DateTime(2026, 7, 24, 12, 0);

    test('creates User entity with correct fields', () {
      final user = User(
        id: 'usr_1',
        email: 'test@example.com',
        displayName: 'Test Aspirant',
        photoUrl: 'https://example.com/photo.png',
        providerType: AuthProviderType.emailPassword,
        isGuest: false,
        createdAt: now,
        lastLoginAt: now,
        metadata: const {'role': 'student'},
      );

      expect(user.id, 'usr_1');

      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test Aspirant');
      expect(user.photoUrl, 'https://example.com/photo.png');
      expect(user.providerType, AuthProviderType.emailPassword);
      expect(user.isGuest, false);
      expect(user.createdAt, now);
      expect(user.lastLoginAt, now);
      expect(user.metadata['role'], 'student');
    });

    test('copyWith updates fields correctly', () {
      final user = User(
        id: 'usr_1',
        email: 'test@example.com',
        displayName: 'Test Aspirant',
        providerType: AuthProviderType.guest,
        isGuest: true,
        createdAt: now,
      );

      final updated = user.copyWith(
        displayName: 'Updated Name',
        isGuest: false,
        providerType: AuthProviderType.google,
      );

      expect(updated.id, 'usr_1');
      expect(updated.displayName, 'Updated Name');
      expect(updated.isGuest, false);
      expect(updated.providerType, AuthProviderType.google);
    });

    test('equality and hashCode work as expected', () {
      final u1 = User(
        id: 'usr_1',
        email: 'test@example.com',
        displayName: 'Test User',
        providerType: AuthProviderType.guest,
        createdAt: now,
      );
      final u2 = User(
        id: 'usr_1',
        email: 'test@example.com',
        displayName: 'Test User',
        providerType: AuthProviderType.guest,
        createdAt: now,
      );
      final u3 = User(
        id: 'usr_2',
        email: 'other@example.com',
        displayName: 'Other User',
        providerType: AuthProviderType.google,
        createdAt: now,
      );

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
    });

    test('serialization toJson and fromJson', () {
      final user = User(
        id: 'usr_100',
        email: 'ser@example.com',
        displayName: 'Serializable User',
        providerType: AuthProviderType.google,
        isGuest: false,
        createdAt: now,
        lastLoginAt: now,
        metadata: const {'level': 5},
      );

      final json = user.toJson();
      final deserialized = User.fromJson(json);

      expect(deserialized, equals(user));
      expect(deserialized.metadata['level'], 5);
    });
  });
}
