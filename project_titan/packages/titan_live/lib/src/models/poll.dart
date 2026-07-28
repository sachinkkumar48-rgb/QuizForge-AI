import 'package:meta/meta.dart';
import 'enums.dart';
import 'poll_option.dart';

/// Immutable domain model representing an interactive live poll.
@immutable
class Poll {
  final String id;
  final String sessionId;
  final String question;
  final List<PollOption> options;
  final PollStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final Map<String, String> userVotes; // userId -> optionId

  Poll({
    required this.id,
    required this.sessionId,
    required this.question,
    required List<PollOption> options,
    this.status = PollStatus.draft,
    required this.createdAt,
    this.closedAt,
    Map<String, String>? userVotes,
  })  : options = List<PollOption>.unmodifiable(options),
        userVotes = Map<String, String>.unmodifiable(userVotes ?? {});

  Poll copyWith({
    String? id,
    String? sessionId,
    String? question,
    List<PollOption>? options,
    PollStatus? status,
    DateTime? createdAt,
    DateTime? closedAt,
    Map<String, String>? userVotes,
  }) {
    return Poll(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      question: question ?? this.question,
      options: options ?? this.options,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      userVotes: userVotes ?? this.userVotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'userVotes': userVotes,
      };

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        question: json['question'] as String,
        options: (json['options'] as List? ?? [])
            .map(
                (o) => PollOption.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList(),
        status: PollStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PollStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        closedAt: json['closedAt'] != null
            ? DateTime.parse(json['closedAt'] as String)
            : null,
        userVotes: Map<String, String>.from(json['userVotes'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Poll &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          question == other.question &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, sessionId, question, status);
}
