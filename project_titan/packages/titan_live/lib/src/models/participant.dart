import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a participant in a live session.
@immutable
class Participant {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isHandRaised;
  final bool isMuted;
  final bool isVideoOn;

  const Participant({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.isHandRaised = false,
    this.isMuted = true,
    this.isVideoOn = false,
  });

  Participant copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatarUrl,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isHandRaised,
    bool? isMuted,
    bool? isVideoOn,
  }) {
    return Participant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
        'leftAt': leftAt?.toIso8601String(),
        'isHandRaised': isHandRaised,
        'isMuted': isMuted,
        'isVideoOn': isVideoOn,
      };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        role: ParticipantRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => ParticipantRole.student,
        ),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        leftAt: json['leftAt'] != null
            ? DateTime.parse(json['leftAt'] as String)
            : null,
        isHandRaised: json['isHandRaised'] as bool? ?? false,
        isMuted: json['isMuted'] as bool? ?? true,
        isVideoOn: json['isVideoOn'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          role == other.role &&
          isHandRaised == other.isHandRaised &&
          isMuted == other.isMuted &&
          isVideoOn == other.isVideoOn;

  @override
  int get hashCode =>
      Object.hash(id, userId, role, isHandRaised, isMuted, isVideoOn);
}
