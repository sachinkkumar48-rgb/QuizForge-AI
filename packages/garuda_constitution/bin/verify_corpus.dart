import 'package:garuda_constitution/garuda_constitution.dart';

void main() async {
  print('=== GARUDA Complete Constitutional Corpus Verification ===');

  final repository = InMemoryConstitutionRepository();

  final parts = await repository.getParts();
  final schedules = await repository.getSchedules();
  final amendments = await repository.getAmendments();
  final chapters = await repository.getChapters();
  final articles = await repository.getArticles();

  print('Parts Count: ${parts.length} (Expected: 26)');
  print('Schedules Count: ${schedules.length} (Expected: 12)');
  print('Amendments Count: ${amendments.length} (Expected: 106)');
  print('Chapters Count: ${chapters.length}');
  print('Articles Count: ${articles.length}');

  assert(parts.length == 26, 'Parts count must be 26');
  assert(schedules.length == 12, 'Schedules count must be 12');
  assert(amendments.length == 106, 'Amendments count must be 106');
  assert(chapters.length >= 20, 'Chapters count must be >= 20');
  assert(articles.length >= 100, 'Articles count must be >= 100');

  // Verify Validation Engine
  final validation = await ConstitutionValidator.validateRepository(repository);
  print('Validation Result: ${validation.isValid ? "PASSED" : "FAILED"}');
  if (!validation.isValid) {
    for (final err in validation.errors) {
      print('  Validation Error: $err');
    }
    throw Exception('Repository validation failed!');
  }

  // Verify Analytics Engine
  final report = await ConstitutionAnalyzer.analyzeRepository(repository);
  print('Analyzer Report Summary: $report');
  print('Overall Coverage Rate: ${(report.overallCoverageRate * 100).toStringAsFixed(1)}%');
  assert(report.overallCoverageRate == 1.0, 'Overall coverage must be 100%');

  // Verify Amendment Query
  final amd106 = await repository.findAmendment('106th');
  print('106th Amendment Verified: ${amd106?.officialName}');
  assert(amd106 != null, '106th Amendment must exist');

  // Verify Chapter Query
  final chapV1 = await repository.findChapter('KO-CHAP-V-1');
  print('Chapter V-1 Verified: ${chapV1?.title}');
  assert(chapV1 != null, 'Chapter V-1 must exist');

  print('SUCCESS: All 100% Constitutional Corpus Verification Checks Passed Cleanly!');
}
