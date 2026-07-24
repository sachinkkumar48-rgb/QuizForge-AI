import 'package:meta/meta.dart';

import 'user.dart';

/// Immutable domain model representing an active user authentication session.
@immutable
class UserSession {
  final String sessionId;
  final User user;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final bool isActive;
  final bool isOffline;

  const UserSession({
    required this.sessionId,
    required this.user,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    this.isActive = true,
    this.isOffline = false,
  });

  /// Checks if the session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  UserSession copyWith({
    String? sessionId,
    User? user,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool? isActive,
    bool? isOffline,
  }) {
    return UserSession(
      sessionId: sessionId ?? this.sessionId,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          user == other.user &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          expiresAt == other.expiresAt &&
          isActive == other.isActive &&
          isOffline == other.isOffline;

  @override
  int get hashCode => Object.hash(
        sessionId,
        user,
        accessToken,
        refreshToken,
        expiresAt,
        isActive,
        isOffline,
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
        'isOffline': isOffline,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        sessionId: json['sessionId'] as String,
        user: User.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
        isOffline: json['isOffline'] as bool? ?? false,
      );
}
