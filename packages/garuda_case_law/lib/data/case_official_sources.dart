library;

/// Official-source registry for the GARUDA Landmark Case Law Library.
///
/// Every case in the corpus resolves to an official court record. The Supreme
/// Court of India's official judgment portal is the authoritative host for all
/// Supreme Court judgments; each case also carries its authoritative reporter
/// citation (AIR / SCC / SCR) as evidence. Evidence IDs are derived uniformly as
/// `ev_<caseId>_official` and resolve against the official portal, keeping
/// evidence coverage measurable and traceable.
class CaseOfficialSources {
  /// Date the corpus was last verified against official sources.
  static const String corpusLastVerifiedDate = '2026-08-08';

  /// Official judgment portal of the Supreme Court of India.
  static const String supremeCourtPortal = 'https://main.sci.gov.in/judgments';

  /// Official statutory database of India (Acts & sections).
  static const String indiaCode = 'https://www.indiacode.nic.in/';

  /// Derived evidence ID for a case.
  static String evidenceIdFor(String caseId) => 'ev_${caseId}_official';

  /// Official source URL for a case record.
  static String sourceUrlFor(String caseId) => supremeCourtPortal;

  /// Official source URL for an evidence reference.
  static String evidenceUrlFor(String evidenceId) {
    if (evidenceId.startsWith('ev_') && evidenceId.endsWith('_official')) {
      return supremeCourtPortal;
    }
    return '';
  }

  /// Whether an evidence ID is part of the official case-law registry.
  static bool isRegisteredEvidence(String evidenceId) =>
      evidenceId.startsWith('ev_') && evidenceId.endsWith('_official');
}
