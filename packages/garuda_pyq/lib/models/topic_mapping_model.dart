import 'package:meta/meta.dart';

@immutable
class TopicMapping {
  final String subject;
  final String topic;
  final String? subtopic;
  final String? microtopic;
  final List<String> taxonomyCodes;

  const TopicMapping({
    required this.subject,
    required this.topic,
    this.subtopic,
    this.microtopic,
    this.taxonomyCodes = const [],
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'topic': topic,
        'subtopic': subtopic,
        'microtopic': microtopic,
        'taxonomyCodes': taxonomyCodes,
      };

  factory TopicMapping.fromJson(Map<String, dynamic> json) => TopicMapping(
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        subtopic: json['subtopic'] as String?,
        microtopic: json['microtopic'] as String?,
        taxonomyCodes: List<String>.from(json['taxonomyCodes'] ?? []),
      );
}
