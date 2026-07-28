import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a live session chat message.
@immutable
class ChatMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final ParticipantRole senderRole;
  final String message;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isPinned;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.type = ChatMessageType.text,
    required this.timestamp,
    this.isPinned = false,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? senderId,
    String? senderName,
    ParticipantRole? senderRole,
    String? message,
    ChatMessageType? type,
    DateTime? timestamp,
    bool? isPinned,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole.name,
        'message': message,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'isPinned': isPinned,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        senderRole: ParticipantRole.values.firstWhere(
          (e) => e.name == json['senderRole'],
          orElse: () => ParticipantRole.student,
        ),
        message: json['message'] as String,
        type: ChatMessageType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ChatMessageType.text,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        isPinned: json['isPinned'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          senderId == other.senderId &&
          message == other.message &&
          type == other.type &&
          isPinned == other.isPinned;

  @override
  int get hashCode =>
      Object.hash(id, sessionId, senderId, message, type, isPinned);
}
