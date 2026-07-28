import 'package:meta/meta.dart';
import 'enums.dart';
import 'participant.dart';
import 'chat_message.dart';
import 'poll.dart';
import 'whiteboard_snapshot.dart';
import 'recording.dart';
import 'live_resource.dart';

/// Immutable domain model representing an active or completed live class session.
@immutable
class LiveSession {
  final String id;
  final String liveClassId;
  final LiveSessionStatus status;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final List<Participant> participants;
  final List<ChatMessage> chatMessages;
  final Poll? activePoll;
  final List<WhiteboardSnapshot> whiteboardSnapshots;
  final Recording? recording;
  final List<LiveResource> resources;
  final List<String> knowledgeNodeIds;

  LiveSession({
    required this.id,
    required this.liveClassId,
    this.status = LiveSessionStatus.scheduled,
    this.actualStartTime,
    this.actualEndTime,
    required List<Participant> participants,
    required List<ChatMessage> chatMessages,
    this.activePoll,
    required List<WhiteboardSnapshot> whiteboardSnapshots,
    this.recording,
    required List<LiveResource> resources,
    required List<String> knowledgeNodeIds,
  })  : participants = List<Participant>.unmodifiable(participants),
        chatMessages = List<ChatMessage>.unmodifiable(chatMessages),
        whiteboardSnapshots =
            List<WhiteboardSnapshot>.unmodifiable(whiteboardSnapshots),
        resources = List<LiveResource>.unmodifiable(resources),
        knowledgeNodeIds = List<String>.unmodifiable(knowledgeNodeIds);

  LiveSession copyWith({
    String? id,
    String? liveClassId,
    LiveSessionStatus? status,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    List<Participant>? participants,
    List<ChatMessage>? chatMessages,
    Poll? activePoll,
    List<WhiteboardSnapshot>? whiteboardSnapshots,
    Recording? recording,
    List<LiveResource>? resources,
    List<String>? knowledgeNodeIds,
  }) {
    return LiveSession(
      id: id ?? this.id,
      liveClassId: liveClassId ?? this.liveClassId,
      status: status ?? this.status,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      participants: participants ?? this.participants,
      chatMessages: chatMessages ?? this.chatMessages,
      activePoll: activePoll ?? this.activePoll,
      whiteboardSnapshots: whiteboardSnapshots ?? this.whiteboardSnapshots,
      recording: recording ?? this.recording,
      resources: resources ?? this.resources,
      knowledgeNodeIds: knowledgeNodeIds ?? this.knowledgeNodeIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'liveClassId': liveClassId,
        'status': status.name,
        'actualStartTime': actualStartTime?.toIso8601String(),
        'actualEndTime': actualEndTime?.toIso8601String(),
        'participants': participants.map((p) => p.toJson()).toList(),
        'chatMessages': chatMessages.map((c) => c.toJson()).toList(),
        'activePoll': activePoll?.toJson(),
        'whiteboardSnapshots':
            whiteboardSnapshots.map((w) => w.toJson()).toList(),
        'recording': recording?.toJson(),
        'resources': resources.map((r) => r.toJson()).toList(),
        'knowledgeNodeIds': knowledgeNodeIds,
      };

  factory LiveSession.fromJson(Map<String, dynamic> json) => LiveSession(
        id: json['id'] as String,
        liveClassId: json['liveClassId'] as String,
        status: LiveSessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LiveSessionStatus.scheduled,
        ),
        actualStartTime: json['actualStartTime'] != null
            ? DateTime.parse(json['actualStartTime'] as String)
            : null,
        actualEndTime: json['actualEndTime'] != null
            ? DateTime.parse(json['actualEndTime'] as String)
            : null,
        participants: (json['participants'] as List? ?? [])
            .map((p) =>
                Participant.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
        chatMessages: (json['chatMessages'] as List? ?? [])
            .map((c) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        activePoll: json['activePoll'] != null
            ? Poll.fromJson(
                Map<String, dynamic>.from(json['activePoll'] as Map))
            : null,
        whiteboardSnapshots: (json['whiteboardSnapshots'] as List? ?? [])
            .map((w) => WhiteboardSnapshot.fromJson(
                Map<String, dynamic>.from(w as Map)))
            .toList(),
        recording: json['recording'] != null
            ? Recording.fromJson(
                Map<String, dynamic>.from(json['recording'] as Map))
            : null,
        resources: (json['resources'] as List? ?? [])
            .map((r) =>
                LiveResource.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        knowledgeNodeIds:
            (json['knowledgeNodeIds'] as List? ?? []).cast<String>(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          liveClassId == other.liveClassId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, liveClassId, status);
}
