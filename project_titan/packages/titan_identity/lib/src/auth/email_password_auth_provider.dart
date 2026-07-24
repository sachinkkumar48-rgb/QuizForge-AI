import '../models/user.dart';
import '../models/user_session.dart';
import 'auth_provider.dart';

/// Provider implementation for Email & Password authentication.
class EmailPasswordAuthProvider implements AuthProvider {
  const EmailPasswordAuthProvider();

  @override
  AuthProviderType get providerType => AuthProviderType.emailPassword;

  @override
  Future<UserSession> signIn({Map<String, dynamic>? credentials}) async {
    final email = credentials?['email'] as String?;
    final password = credentials?['password'] as String?;

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw ArgumentError('Email and password must be provided.');
    }

    final now = DateTime.now();
    final userId = 'user_${email.toLowerCase().hashCode.abs()}';
    final name = credentials?['displayName'] ?? email.split('@').first;

    final user = User(
      id: userId,
      email: email,
      displayName: name,
      providerType: AuthProviderType.emailPassword,
      isGuest: false,
      createdAt: now,
      lastLoginAt: now,
    );

    return UserSession(
      sessionId: 'session_$userId',
      user: user,
      accessToken: 'email_token_${now.millisecondsSinceEpoch}',
      refreshToken: 'email_refresh_${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(hours: 48)),
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
  Future<void> signOut(UserSession session) async {}

  @override
  Future<UserSession> refreshSession(UserSession session) async {
    final now = DateTime.now();
    return session.copyWith(
      accessToken: 'email_token_refreshed_${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(hours: 48)),
    );
  }
}
