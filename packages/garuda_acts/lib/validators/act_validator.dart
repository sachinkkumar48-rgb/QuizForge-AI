library;

import '../domain/entities/act_knowledge_object.dart';
import '../domain/entities/act_enums.dart';

/// Single validation issue detected in Central Acts repository.
class ActValidationIssue {
  final String actId;
  final String issueType; // e.g. 'MissingSection', 'BrokenReference', 'DuplicateAct', 'InvalidMetadata', 'MissingGazette', 'MissingEvidence'
  final String message;
  final bool isCritical;

  const ActValidationIssue({
    required this.actId,
    required this.issueType,
    required this.message,
    this.isCritical = false,
  });

  @override
  String toString() => '[$issueType] Act $actId: $message';
}

/// Consolidated Validation Report for GARUDA Central Acts Library.
class ActValidationReport {
  final int totalActsValidated;
  final List<ActValidationIssue> issues;

  const ActValidationReport({
    required this.totalActsValidated,
    required this.issues,
  });

  bool get isValid => issues.isEmpty;
  int get criticalIssueCount => issues.where((i) => i.isCritical).length;
}

/// Comprehensive Validation Engine for Central Acts Library.
class ActValidator {
  /// Validate a collection of Acts for structural and statutory integrity.
  static ActValidationReport validateCorpus(List<ActKnowledgeObject> acts) {
    final issues = <ActValidationIssue>[];
    final actIdSet = <String>{};
    final officialNameSet = <String>{};

    for (final act in acts) {
      // 1. Duplicate Acts Check
      if (actIdSet.contains(act.actId)) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'DuplicateAct',
          message: 'Duplicate Act ID detected: ${act.actId}',
          isCritical: true,
        ));
      } else {
        actIdSet.add(act.actId);
      }

      if (officialNameSet.contains(act.metadata.officialName)) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'DuplicateAct',
          message: 'Duplicate Official Name detected: ${act.metadata.officialName}',
          isCritical: false,
        ));
      } else {
        officialNameSet.add(act.metadata.officialName);
      }

      // 2. Invalid Metadata Check
      if (act.metadata.officialName.trim().isEmpty) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'InvalidMetadata',
          message: 'Official Name is empty.',
          isCritical: true,
        ));
      }

      if (act.metadata.shortTitle.trim().isEmpty) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'InvalidMetadata',
          message: 'Short Title is empty.',
          isCritical: true,
        ));
      }

      if (act.metadata.year < 1700 || act.metadata.year > DateTime.now().year + 1) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'InvalidMetadata',
          message: 'Invalid enactment year: ${act.metadata.year}',
          isCritical: true,
        ));
      }

      // 3. Missing Gazette Check
      if (act.metadata.gazetteReference.trim().isEmpty) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'MissingGazette',
          message: 'Official Gazette Reference is missing.',
          isCritical: false,
        ));
      }

      if (act.metadata.officialPdfUrl.trim().isEmpty) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'MissingGazette',
          message: 'Official PDF URL is missing.',
          isCritical: false,
        ));
      }

      // 4. Missing Sections Check (excluding cross-link only Acts like Constitution)
      if (act.actId != 'act_const_india' && act.sections.isEmpty) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'MissingSection',
          message: 'Act has no registered sections.',
          isCritical: false,
        ));
      }

      // Check Chapter Section reference alignment
      final actSectionNums = act.sections.map((s) => s.sectionNumber).toSet();
      for (final chap in act.chapters) {
        for (final secNum in chap.sectionNumbers) {
          if (!actSectionNums.contains(secNum)) {
            issues.add(ActValidationIssue(
              actId: act.actId,
              issueType: 'BrokenReference',
              message: 'Chapter ${chap.chapterNumber} references Section $secNum which is missing in Act section list.',
              isCritical: false,
            ));
          }
        }
      }

      // 5. Missing Evidence Check
      if (act.editorialStatus == EditorialStatus.productionReady &&
          act.evidenceReferences.isEmpty &&
          act.metadata.gazetteReference.isEmpty) {
        issues.add(ActValidationIssue(
          actId: act.actId,
          issueType: 'MissingEvidence',
          message: 'Production-ready Act lacks evidence references and gazette reference.',
          isCritical: false,
        ));
      }
    }

    return ActValidationReport(
      totalActsValidated: acts.length,
      issues: issues,
    );
  }
}
