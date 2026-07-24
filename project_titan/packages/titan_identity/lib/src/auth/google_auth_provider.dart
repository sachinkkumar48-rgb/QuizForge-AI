import '../models/user.dart';
import '../models/user_session.dart';
import 'auth_provider.dart';

/// Provider implementation for Google OAuth authentication.
class GoogleAuthProvider implements AuthProvider {
  const GoogleAuthProvider();

  @override
  AuthProviderType get providerType => AuthProviderType.google;

  @override
  Future<UserSession> signIn({Map<String, dynamic>? credentials}) async {
    final now = DateTime.now();
    final email = credentials?['email'] ?? 'learner@gmail.com';
    final name = credentials?['displayName'] ?? 'Google User';
    final userId = 'google_${email.hashCode.abs()}';

    final user = User(
      id: userId,
      email: email,
      displayName: name,
      photoUrl: credentials?['photoUrl'] ??
          'https://lh3.googleusercontent.com/a/default_avatar',
      providerType: AuthProviderType.google,
      isGuest: false,
      createdAt: now,
      lastLoginAt: now,
    );

    return UserSession(
      sessionId: 'session_$userId',
      user: user,
      accessToken: 'google_token_${now.millisecondsSinceEpoch}',
      refreshToken: 'google_refresh_${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(hours: 24)),
      isActive: true,
      isOffline: false,
    );
  }

  @override
  Future<UserSession> register(
      {required Map<String, dynamic> userDetails}) async {
    return signIn(credentials: userDetails);
  }

  @override
  Future<void> signOut(UserSession session) async {
    // Revoke token / sign out logic placeholder
  }

  @override
  Future<UserSession> refreshSession(UserSession session) async {
    final now = DateTime.now();
    return session.copyWith(
      accessToken: 'google_token_refreshed_${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }
}
