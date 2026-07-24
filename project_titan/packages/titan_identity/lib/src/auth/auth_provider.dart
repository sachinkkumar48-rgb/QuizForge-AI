import '../models/user_session.dart';

/// Supported authentication provider types in TITAN Identity.
enum AuthProviderType {
  guest,
  google,
  emailPassword,
}

/// Abstract provider-agnostic authentication contract.
abstract class AuthProvider {
  /// Unique identifier of the auth provider type.
  AuthProviderType get providerType;

  /// Authenticates user and returns an active [UserSession].
  Future<UserSession> signIn({Map<String, dynamic>? credentials});

  /// Registers a new user account if supported by provider.
  Future<UserSession> register({required Map<String, dynamic> userDetails});

  /// Terminate session and sign out.
  Future<void> signOut(UserSession session);

  /// Refresh session credentials.
  Future<UserSession> refreshSession(UserSession session);
}
