import 'package:meta/meta.dart';

import '../auth/auth_provider.dart';

/// Immutable domain entity representing a user in Project TITAN.
@immutable
class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AuthProviderType providerType;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> metadata;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.providerType,
    this.isGuest = false,
    required this.createdAt,
    this.lastLoginAt,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {});

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProviderType? providerType,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      providerType: providerType ?? this.providerType,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          providerType == other.providerType &&
          isGuest == other.isGuest &&
          createdAt == other.createdAt &&
          lastLoginAt == other.lastLoginAt;

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        photoUrl,
        providerType,
        isGuest,
        createdAt,
        lastLoginAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'providerType': providerType.name,
        'isGuest': isGuest,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        photoUrl: json['photoUrl'] as String?,
        providerType: AuthProviderType.values.firstWhere(
          (e) => e.name == json['providerType'],
          orElse: () => AuthProviderType.guest,
        ),
        isGuest: json['isGuest'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.parse(json['lastLoginAt'] as String)
            : null,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );
}
