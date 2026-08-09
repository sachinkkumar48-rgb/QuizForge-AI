/// Evidence presentation for the P8 export layer (TITAN-KO-015.0 P8).
///
/// Evidence is a critical integrity boundary. `EvidenceEntry` renders ONLY
/// evidence already present on a validated corpus record, resolving its label
/// and URL against the existing official-source registry. It never invents
/// evidence IDs, URLs or citations, never fetches anything, and never guesses a
/// source for missing evidence.
library;

import 'package:meta/meta.dart';

import '../data/case_official_sources.dart';

/// A faithfully-presented evidence record derived from a corpus evidence ID.
@immutable
class EvidenceEntry {
  /// The evidence ID as carried by the corpus record (e.g. `ev_KESAVANANDA_official`).
  final String evidenceId;

  /// A label derived from the official-source registry, or '' when the ID does
  /// not resolve to a registry type (rendered without a type then).
  final String typeLabel;

  /// Registry-resolved source URL, or '' when the ID resolves to no URL. Only
  /// URLs that resolve against the official registry are ever presented.
  final String url;

  /// Whether the evidence ID resolves against the official-source registry
  /// (the same predicate P7 uses for evidence coverage).
  final bool verified;

  const EvidenceEntry({
    required this.evidenceId,
    required this.typeLabel,
    required this.url,
    required this.verified,
  });

  /// Derives a presentation entry for one corpus evidence ID.
  factory EvidenceEntry.fromId(String evidenceId) {
    final official = CaseOfficialSources.isRegisteredEvidence(evidenceId);
    return EvidenceEntry(
      evidenceId: evidenceId,
      typeLabel: official ? 'Official court record' : '',
      url: CaseOfficialSources.evidenceUrlFor(evidenceId),
      verified: official,
    );
  }
}
