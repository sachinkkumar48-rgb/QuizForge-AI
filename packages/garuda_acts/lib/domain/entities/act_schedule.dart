library;

import 'package:meta/meta.dart';

/// Schedule attached to an Act.
@immutable
class ActSchedule {
  final String scheduleId;
  final String actId;
  final String scheduleNumber;
  final String title;
  final String content;
  final String description;

  const ActSchedule({
    required this.scheduleId,
    required this.actId,
    required this.scheduleNumber,
    required this.title,
    required this.content,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'actId': actId,
      'scheduleNumber': scheduleNumber,
      'title': title,
      'content': content,
      'description': description,
    };
  }

  factory ActSchedule.fromJson(Map<String, dynamic> json) {
    return ActSchedule(
      scheduleId: json['scheduleId'] as String,
      actId: json['actId'] as String,
      scheduleNumber: json['scheduleNumber'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      description: json['description'] as String,
    );
  }
}
