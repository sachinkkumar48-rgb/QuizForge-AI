library;

import '../domain/entities/current_affairs_knowledge_object.dart';
import '../domain/entities/news_event.dart';

/// Relationship Builder scanning events to automatically establish permanent knowledge links.
class CurrentAffairsRelationshipBuilder {
  static KnowledgeLinkSet buildLinks(NewsEvent event) {
    final text = '${event.headline} ${event.summary} ${event.content}'.toLowerCase();

    final List<String> articles = [];
    final List<String> parts = [];
    final List<String> schedules = [];
    final List<String> amendments = [];
    final List<String> acts = [];
    final List<String> sections = [];
    final List<String> cases = [];
    final List<String> doctrines = [];
    final List<String> committees = [];
    final List<String> commissions = [];
    final List<String> reports = [];
    final List<String> schemes = [];
    final List<String> intOrgs = [];
    final List<String> treaties = [];
    final List<String> pyqs = [];
    final List<String> concepts = [];
    final List<String> linkedObjects = [];

    // Articles
    final articleRegex = RegExp(r'article\s*(\d+[a-z]?)', caseSensitive: false);
    for (final match in articleRegex.allMatches(text)) {
      final artNum = match.group(1);
      if (artNum != null) {
        articles.add('Article $artNum');
      }
    }

    if (text.contains('article 14')) articles.add('Article 14');
    if (text.contains('article 19')) articles.add('Article 19');
    if (text.contains('article 21')) articles.add('Article 21');
    if (text.contains('article 32')) articles.add('Article 32');
    if (text.contains('article 368')) articles.add('Article 368');

    // Parts
    if (text.contains('part iii') || text.contains('fundamental rights')) parts.add('Part III');
    if (text.contains('part iv') || text.contains('dpsp') || text.contains('directive principles')) parts.add('Part IV');
    if (text.contains('part v') || text.contains('union executive')) parts.add('Part V');

    // Schedules
    if (text.contains('7th schedule') || text.contains('seventh schedule')) schedules.add('Seventh Schedule');
    if (text.contains('10th schedule') || text.contains('tenth schedule') || text.contains('anti-defection')) schedules.add('Tenth Schedule');

    // Amendments
    final amdtRegex = RegExp(r'(\d+)(st|nd|rd|th)?\s*(constitutional\s*)?amendment', caseSensitive: false);
    for (final match in amdtRegex.allMatches(text)) {
      final num = match.group(1);
      if (num != null) amendments.add('$num Amendment');
    }

    // Acts
    if (text.contains('data protection act') || text.contains('dpdp')) acts.add('Digital Personal Data Protection Act, 2023');
    if (text.contains('bharatiya nyaya sanhita') || text.contains('bns')) acts.add('Bharatiya Nyaya Sanhita, 2023');
    if (text.contains('insolvency and bankruptcy') || text.contains('ibc')) acts.add('Insolvency and Bankruptcy Code, 2016');
    if (text.contains('reserve bank of india act') || text.contains('rbi act')) acts.add('Reserve Bank of India Act, 1934');

    // Cases
    if (text.contains('kesavananda bharati')) cases.add('Kesavananda Bharati v. State of Kerala (1973)');
    if (text.contains('puttaswamy')) cases.add('K.S. Puttaswamy v. Union of India (2017)');
    if (text.contains('minerva mills')) cases.add('Minerva Mills v. Union of India (1980)');
    if (text.contains('maneka gandhi')) cases.add('Maneka Gandhi v. Union of India (1978)');

    // Doctrines
    if (text.contains('basic structure')) doctrines.add('Basic Structure Doctrine');
    if (text.contains('pith and substance')) doctrines.add('Doctrine of Pith and Substance');
    if (text.contains('severability')) doctrines.add('Doctrine of Severability');

    // Committees & Commissions
    if (text.contains('swaminathan')) committees.add('Swaminathan Committee');
    if (text.contains('kasturirangan')) committees.add('Kasturirangan Committee');
    if (text.contains('sarkaria')) commissions.add('Sarkaria Commission');
    if (text.contains('punchhi')) commissions.add('Punchhi Commission');

    // Schemes
    if (text.contains('pm-kisan') || text.contains('pm kisan')) schemes.add('PM-KISAN');
    if (text.contains('jal jeevan')) schemes.add('Jal Jeevan Mission');
    if (text.contains('ayushman bharat')) schemes.add('Ayushman Bharat');
    if (text.contains('pm gatishakti') || text.contains('gati shakti')) schemes.add('PM GatiShakti');

    // International Organisations
    if (text.contains('g20') || text.contains('g-20')) intOrgs.add('G20');
    if (text.contains('brics')) intOrgs.add('BRICS');
    if (text.contains('unsc') || text.contains('united nations security council')) intOrgs.add('UNSC');
    if (text.contains('quad')) intOrgs.add('QUAD');

    // Deduplicate lists
    return KnowledgeLinkSet(
      articleIds: articles.toSet().toList(),
      partIds: parts.toSet().toList(),
      scheduleIds: schedules.toSet().toList(),
      amendmentIds: amendments.toSet().toList(),
      actIds: acts.toSet().toList(),
      actSectionIds: sections.toSet().toList(),
      caseLawIds: cases.toSet().toList(),
      doctrineIds: doctrines.toSet().toList(),
      committeeNames: committees.toSet().toList(),
      commissionNames: commissions.toSet().toList(),
      reportNames: reports.toSet().toList(),
      schemeNames: schemes.toSet().toList(),
      internationalOrgNames: intOrgs.toSet().toList(),
      treatyNames: treaties.toSet().toList(),
      pyqIds: pyqs.toSet().toList(),
      conceptIds: concepts.toSet().toList(),
      linkedObjectIds: linkedObjects.toSet().toList(),
    );
  }
}
