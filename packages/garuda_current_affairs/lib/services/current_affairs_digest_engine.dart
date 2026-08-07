library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class CurrentAffairsDigest {
  final String id;
  final String title;
  final DigestFrequency type;
  final DateTime generatedAt;
  final List<CurrentAffairsKnowledgeObject> items;
  final String markdownContent;

  const CurrentAffairsDigest({
    required this.id,
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.items,
    required this.markdownContent,
  });
}

class CurrentAffairsDigestEngine {
  static CurrentAffairsDigest generateDigest({
    required List<CurrentAffairsKnowledgeObject> objects,
    required DigestFrequency frequency,
    String? topic,
  }) {
    final now = DateTime.now();
    final items = List<CurrentAffairsKnowledgeObject>.from(objects)
      ..sort((a, b) => b.publicationDate.compareTo(a.publicationDate));

    final buffer = StringBuffer();
    final title = '${frequency.name.toUpperCase()} UPSC Current Affairs Brief (${items.length} Events)';

    buffer.writeln('# $title');
    buffer.writeln('**Generated On**: ${now.toIso8601String()}\n');
    buffer.writeln('---');

    for (var i = 0; i < items.length; i++) {
      final obj = items[i];
      buffer.writeln('## ${i + 1}. ${obj.headline}');
      buffer.writeln('**Category**: ${obj.category.displayName} | **Source**: ${obj.officialSource}');
      buffer.writeln('**Importance**: ${obj.importance.name.toUpperCase()} | **UPSC Relevance**: ${obj.intelligence.relevanceScore}/100\n');
      buffer.writeln('### Summary');
      buffer.writeln('${obj.summary}\n');
      if (obj.links.articleIds.isNotEmpty) {
        buffer.writeln('**Linked Articles**: ${obj.links.articleIds.join(", ")}');
      }
      if (obj.links.actIds.isNotEmpty) {
        buffer.writeln('**Linked Acts**: ${obj.links.actIds.join(", ")}');
      }
      if (obj.links.caseLawIds.isNotEmpty) {
        buffer.writeln('**Landmark Cases**: ${obj.links.caseLawIds.join(", ")}');
      }
      buffer.writeln('\n---');
    }

    return CurrentAffairsDigest(
      id: 'digest_${frequency.name}_${now.millisecondsSinceEpoch}',
      title: title,
      type: frequency,
      generatedAt: now,
      items: items,
      markdownContent: buffer.toString(),
    );
  }

  static CurrentAffairsDigest generateDailyBrief(List<CurrentAffairsKnowledgeObject> objects) =>
      generateDigest(objects: objects, frequency: DigestFrequency.daily);

  static CurrentAffairsDigest generateWeeklyBrief(List<CurrentAffairsKnowledgeObject> objects) =>
      generateDigest(objects: objects, frequency: DigestFrequency.weekly);

  static CurrentAffairsDigest generateMonthlyMagazine(List<CurrentAffairsKnowledgeObject> objects) =>
      generateDigest(objects: objects, frequency: DigestFrequency.monthly);

  static CurrentAffairsDigest generateYearlyCompilation(List<CurrentAffairsKnowledgeObject> objects) =>
      generateDigest(objects: objects, frequency: DigestFrequency.yearly);

  static CurrentAffairsDigest generateTopicRevisionSheets(
    List<CurrentAffairsKnowledgeObject> objects, {
    required String topic,
  }) {
    final filtered = objects
        .where((o) =>
            o.subcategory.toLowerCase().contains(topic.toLowerCase()) ||
            o.headline.toLowerCase().contains(topic.toLowerCase()) ||
            o.category.displayName.toLowerCase().contains(topic.toLowerCase()))
        .toList();
    return generateDigest(objects: filtered, frequency: DigestFrequency.topicWise, topic: topic);
  }
}

