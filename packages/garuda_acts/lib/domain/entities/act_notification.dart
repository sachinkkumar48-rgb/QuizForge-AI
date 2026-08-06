library;

import 'package:meta/meta.dart';

/// Official Executive Notification / S.O. / G.S.R. issued under an Act.
@immutable
class ActNotification {
  final String notificationId;
  final String actId;
  final String notificationNumber;
  final String title;
  final DateTime issueDate;
  final String gazetteReference;
  final String content;
  final String effect;

  const ActNotification({
    required this.notificationId,
    required this.actId,
    required this.notificationNumber,
    required this.title,
    required this.issueDate,
    required this.gazetteReference,
    required this.content,
    required this.effect,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'actId': actId,
      'notificationNumber': notificationNumber,
      'title': title,
      'issueDate': issueDate.toIso8601String(),
      'gazetteReference': gazetteReference,
      'content': content,
      'effect': effect,
    };
  }

  factory ActNotification.fromJson(Map<String, dynamic> json) {
    return ActNotification(
      notificationId: json['notificationId'] as String,
      actId: json['actId'] as String,
      notificationNumber: json['notificationNumber'] as String,
      title: json['title'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      gazetteReference: json['gazetteReference'] as String,
      content: json['content'] as String,
      effect: json['effect'] as String,
    );
  }
}
