library;

import '../domain/entities/scheme_beneficiary.dart';
import '../domain/entities/scheme_enums.dart';
import '../domain/entities/scheme_knowledge_object.dart';
import '../domain/entities/scheme_ministry.dart';
import '../search/scheme_search_engine.dart';

/// Corpus-coverage metrics for the Government Schemes Library.
class SchemeCorpusReport {
  final int totalExpectedSchemes;
  final int totalImportedSchemes;
  final double schemeCoveragePercentage;
  final int ministryCount;
  final int categoryCount;
  final int sectorCount;
  final Map<SchemeMinistry, int> ministryDistribution;
  final Map<SchemeCategory, int> categoryDistribution;
  final Map<SchemeType, int> schemeTypeDistribution;
  final Map<SchemeStatus, int> statusDistribution;
  final int totalConstitutionalLinks;
  final int totalActLinks;
  final int totalCommitteeLinks;
  final int totalReportLinks;
  final int totalCaseLawLinks;
  final int totalDoctrineLinks;
  final int totalPyqLinks;
  final int totalCurrentAffairsLinks;
  final int totalSdgLinks;
  final int totalSchemeRelationships;
  final int totalBenefits;
  final int totalComponents;

  const SchemeCorpusReport({
    required this.totalExpectedSchemes,
    required this.totalImportedSchemes,
    required this.schemeCoveragePercentage,
    required this.ministryCount,
    required this.categoryCount,
    required this.sectorCount,
    required this.ministryDistribution,
    required this.categoryDistribution,
    required this.schemeTypeDistribution,
    required this.statusDistribution,
    required this.totalConstitutionalLinks,
    required this.totalActLinks,
    required this.totalCommitteeLinks,
    required this.totalReportLinks,
    required this.totalCaseLawLinks,
    required this.totalDoctrineLinks,
    required this.totalPyqLinks,
    required this.totalCurrentAffairsLinks,
    required this.totalSdgLinks,
    required this.totalSchemeRelationships,
    required this.totalBenefits,
    required this.totalComponents,
  });
}

/// Abstract repository interface for Government Scheme Knowledge Objects.
abstract class SchemeRepository {
  Future<void> saveScheme(SchemeKnowledgeObject object);
  Future<SchemeKnowledgeObject?> getSchemeById(String id);
  Future<List<SchemeKnowledgeObject>> getAllSchemes();
  Future<SchemeKnowledgeObject?> getSchemeByExactName(String name);
  Future<SchemeKnowledgeObject?> getSchemeByAcronym(String acronym);

  Future<List<SchemeKnowledgeObject>> getSchemesByMinistry(SchemeMinistry ministry);
  Future<List<SchemeKnowledgeObject>> getSchemesByDepartment(String department);
  Future<List<SchemeKnowledgeObject>> getSchemesByCategory(SchemeCategory category);
  Future<List<SchemeKnowledgeObject>> getSchemesBySector(SchemeSector sector);
  Future<List<SchemeKnowledgeObject>> getSchemesByBeneficiary(BeneficiaryGroup beneficiary);
  Future<List<SchemeKnowledgeObject>> getSchemesByStateUt(String stateUt);
  Future<List<SchemeKnowledgeObject>> getSchemesByLaunchYear(int year);
  Future<List<SchemeKnowledgeObject>> getSchemesByStatus(SchemeStatus status);
  Future<List<SchemeKnowledgeObject>> getSchemesByArticle(String article);
  Future<List<SchemeKnowledgeObject>> getSchemesByAct(String act);
  Future<List<SchemeKnowledgeObject>> getSchemesByCommittee(String committeeId);
  Future<List<SchemeKnowledgeObject>> getSchemesByReport(String reportId);
  Future<List<SchemeKnowledgeObject>> getSchemesByPyq(String pyqId);
  Future<List<SchemeKnowledgeObject>> getSchemesByCurrentAffairs(String currentAffairsId);
  Future<List<SchemeKnowledgeObject>> getRelatedSchemes(SchemeKnowledgeObject scheme);

  Future<List<SchemeKnowledgeObject>> searchSchemes(SchemeSearchQuery query);
  Future<SchemeCorpusReport> generateCorpusReport();
}
