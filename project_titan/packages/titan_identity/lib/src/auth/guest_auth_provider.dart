import '../models/user.dart';
import '../models/user_session.dart';
import 'auth_provider.dart';

/// Provider for guest authentication, enabling instant offline onboarding.
class GuestAuthProvider implements AuthProvider {
  const GuestAuthProvider();

  @override
  AuthProviderType get providerType => AuthProviderType.guest;

  @override
  Future<UserSession> signIn({Map<String, dynamic>? credentials}) async {
    final now = DateTime.now();
    final guestId =
        credentials?['guestId'] ?? 'guest_${now.millisecondsSinceEpoch}';
    final user = User(
      id: guestId,
      email: '$guestId@guest.quizforge.ai',
      displayName: 'Guest Aspirant',
      providerType: AuthProviderType.guest,
      isGuest: true,
      createdAt: now,
      lastLoginAt: now,
    );

    return UserSession(
      sessionId: 'session_$guestId',
      user: user,
      accessToken: 'guest_token_$guestId',
      expiresAt:
          now.add(const Duration(days: 365)), // Guest sessions are long-lived
      isActive: true,
      isOffline: true,
    );
  }

  @override
  Future<UserSession> register(
      {required Map<String, dynamic> userDetails}) async {
    return signIn(credentials: userDetails);
  }

  @override
  Future<void> signOut(UserSession session) async {
    // No-op for guest offline provider
  }

  @override
  Future<UserSession> refreshSession(UserSession session) async {
    final now = DateTime.now();
    return session.copyWith(
      expiresAt: now.add(const Duration(days: 365)),
      user: session.user.copyWith(lastLoginAt: now),
    );
  }
}
