import 'package:meta/meta.dart';

/// Links supporting future GARUDA Knowledge Graph object references.
/// Supports links to: Constitution Articles, Case Laws, Acts, Amendments,
/// Committees, Reports, Schemes, People, Institutions, Lessons, PYQs,
/// Maps, Timeline, and Current Affairs.
@immutable
class KnowledgeObjectLinks {
  final List<String> constitutionArticles;
  final List<String> caseLaws;
  final List<String> acts;
  final List<String> amendments;
  final List<String> committees;
  final List<String> reports;
  final List<String> schemes;
  final List<String> people;
  final List<String> institutions;
  final List<String> lessons;
  final List<String> pyqs;
  final List<String> maps;
  final List<String> timeline;
  final List<String> currentAffairs;

  const KnowledgeObjectLinks({
    this.constitutionArticles = const [],
    this.caseLaws = const [],
    this.acts = const [],
    this.amendments = const [],
    this.committees = const [],
    this.reports = const [],
    this.schemes = const [],
    this.people = const [],
    this.institutions = const [],
    this.lessons = const [],
    this.pyqs = const [],
    this.maps = const [],
    this.timeline = const [],
    this.currentAffairs = const [],
  });

  KnowledgeObjectLinks copyWith({
    List<String>? constitutionArticles,
    List<String>? caseLaws,
    List<String>? acts,
    List<String>? amendments,
    List<String>? committees,
    List<String>? reports,
    List<String>? schemes,
    List<String>? people,
    List<String>? institutions,
    List<String>? lessons,
    List<String>? pyqs,
    List<String>? maps,
    List<String>? timeline,
    List<String>? currentAffairs,
  }) {
    return KnowledgeObjectLinks(
      constitutionArticles: constitutionArticles ?? List.from(this.constitutionArticles),
      caseLaws: caseLaws ?? List.from(this.caseLaws),
      acts: acts ?? List.from(this.acts),
      amendments: amendments ?? List.from(this.amendments),
      committees: committees ?? List.from(this.committees),
      reports: reports ?? List.from(this.reports),
      schemes: schemes ?? List.from(this.schemes),
      people: people ?? List.from(this.people),
      institutions: institutions ?? List.from(this.institutions),
      lessons: lessons ?? List.from(this.lessons),
      pyqs: pyqs ?? List.from(this.pyqs),
      maps: maps ?? List.from(this.maps),
      timeline: timeline ?? List.from(this.timeline),
      currentAffairs: currentAffairs ?? List.from(this.currentAffairs),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constitutionArticles': constitutionArticles,
      'caseLaws': caseLaws,
      'acts': acts,
      'amendments': amendments,
      'committees': committees,
      'reports': reports,
      'schemes': schemes,
      'people': people,
      'institutions': institutions,
      'lessons': lessons,
      'pyqs': pyqs,
      'maps': maps,
      'timeline': timeline,
      'currentAffairs': currentAffairs,
    };
  }

  factory KnowledgeObjectLinks.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return KnowledgeObjectLinks(
      constitutionArticles: parseStringList(json['constitutionArticles']),
      caseLaws: parseStringList(json['caseLaws']),
      acts: parseStringList(json['acts']),
      amendments: parseStringList(json['amendments']),
      committees: parseStringList(json['committees']),
      reports: parseStringList(json['reports']),
      schemes: parseStringList(json['schemes']),
      people: parseStringList(json['people']),
      institutions: parseStringList(json['institutions']),
      lessons: parseStringList(json['lessons']),
      pyqs: parseStringList(json['pyqs']),
      maps: parseStringList(json['maps']),
      timeline: parseStringList(json['timeline']),
      currentAffairs: parseStringList(json['currentAffairs']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeObjectLinks &&
        _listEquals(other.constitutionArticles, constitutionArticles) &&
        _listEquals(other.caseLaws, caseLaws) &&
        _listEquals(other.acts, acts) &&
        _listEquals(other.amendments, amendments) &&
        _listEquals(other.committees, committees) &&
        _listEquals(other.reports, reports) &&
        _listEquals(other.schemes, schemes) &&
        _listEquals(other.people, people) &&
        _listEquals(other.institutions, institutions) &&
        _listEquals(other.lessons, lessons) &&
        _listEquals(other.pyqs, pyqs) &&
        _listEquals(other.maps, maps) &&
        _listEquals(other.timeline, timeline) &&
        _listEquals(other.currentAffairs, currentAffairs);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        constitutionArticles.length,
        caseLaws.length,
        acts.length,
        amendments.length,
        committees.length,
        reports.length,
        schemes.length,
        people.length,
        institutions.length,
        lessons.length,
        pyqs.length,
        maps.length,
        timeline.length,
        currentAffairs.length,
      );

  @override
  String toString() =>
      'KnowledgeObjectLinks(totalLinks: ${constitutionArticles.length + caseLaws.length + acts.length + amendments.length + committees.length + reports.length + schemes.length + people.length + institutions.length + lessons.length + pyqs.length + maps.length + timeline.length + currentAffairs.length})';
}
