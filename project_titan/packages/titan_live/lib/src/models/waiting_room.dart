import 'package:meta/meta.dart';

/// Immutable domain model representing a waiting room before a live session starts.
@immutable
class WaitingRoom {
  final String id;
  final String sessionId;
  final bool isOpen;
  final List<String> waitingUserIds;
  final String welcomeMessage;

  WaitingRoom({
    required this.id,
    required this.sessionId,
    this.isOpen = true,
    required List<String> waitingUserIds,
    this.welcomeMessage = 'The class will begin shortly. Please stand by.',
  }) : waitingUserIds = List<String>.unmodifiable(waitingUserIds);

  WaitingRoom copyWith({
    String? id,
    String? sessionId,
    bool? isOpen,
    List<String>? waitingUserIds,
    String? welcomeMessage,
  }) {
    return WaitingRoom(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      isOpen: isOpen ?? this.isOpen,
      waitingUserIds: waitingUserIds ?? this.waitingUserIds,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'isOpen': isOpen,
        'waitingUserIds': waitingUserIds,
        'welcomeMessage': welcomeMessage,
      };

  factory WaitingRoom.fromJson(Map<String, dynamic> json) => WaitingRoom(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        isOpen: json['isOpen'] as bool? ?? true,
        waitingUserIds: (json['waitingUserIds'] as List? ?? []).cast<String>(),
        welcomeMessage: json['welcomeMessage'] as String? ??
            'The class will begin shortly. Please stand by.',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaitingRoom &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          isOpen == other.isOpen;

  @override
  int get hashCode => Object.hash(id, sessionId, isOpen);
}
