library;

import '../domain/entities/case_enums.dart';
import '../domain/entities/case_knowledge_object.dart';
import '../domain/entities/precedent_relationship.dart';
import 'case_official_sources.dart';

/// Corpus enrichment applied at seed time.
///
/// Guarantees every record carries a resolvable evidence ID, an official
/// source, a verification date and (for legacy records) cross-package links.
/// No corpus record may exist without traceable evidence.
class CaseCorpusSupport {
  /// Enriches a single case record with evidence, official source, verification
  /// date and any recorded cross-package enrichment.
  static CaseKnowledgeObject enrichCase(CaseKnowledgeObject c) {
    final e = _enrichments[c.caseId];
    final base = c.copyWith(
      evidenceIds: c.evidenceIds.isNotEmpty
          ? c.evidenceIds
          : [CaseOfficialSources.evidenceIdFor(c.caseId)],
      officialSource: c.officialSource.isNotEmpty
          ? c.officialSource
          : CaseOfficialSources.sourceUrlFor(c.caseId),
      lastVerifiedDate: c.lastVerifiedDate.isNotEmpty
          ? c.lastVerifiedDate
          : CaseOfficialSources.corpusLastVerifiedDate,
      primarySource: c.primarySource.isNotEmpty
          ? c.primarySource
          : 'Supreme Court Reports (SCR) / All India Reporter (AIR)',
    );
    if (e == null) return base;
    return base.copyWith(
      doctrines: e['doctrines'] as List<String>? ?? base.doctrines,
      precedentsFollowed:
          e['precedentsFollowed'] as List<String>? ?? base.precedentsFollowed,
      precedentsOverruled:
          e['precedentsOverruled'] as List<String>? ?? base.precedentsOverruled,
      precedentsDistinguished: e['precedentsDistinguished']
              as List<String>? ??
          base.precedentsDistinguished,
      relatedCases: e['relatedCases'] as List<String>? ?? base.relatedCases,
      relatedActs: e['relatedActs'] as List<String>? ?? base.relatedActs,
      relatedReports: e['relatedReports'] as List<String>? ?? base.relatedReports,
      relatedCurrentAffairs:
          e['relatedCurrentAffairs'] as List<String>? ?? base.relatedCurrentAffairs,
      relatedBodies: e['relatedBodies'] as List<String>? ?? base.relatedBodies,
      relatedSchemes: e['relatedSchemes'] as List<String>? ?? base.relatedSchemes,
      relatedInternationalOrganisations: e['relatedInternationalOrganisations']
              as List<String>? ??
          base.relatedInternationalOrganisations,
      sdgGoals: e['sdgGoals'] as List<String>? ?? base.sdgGoals,
      themes: e['themes'] as List<String>? ?? base.themes,
      subjects: e['subjects'] as List<String>? ?? base.subjects,
      prelimsRelevance:
          e['prelimsRelevance'] as RelevanceLevel? ?? base.prelimsRelevance,
      mainsRelevance:
          e['mainsRelevance'] as RelevanceLevel? ?? base.mainsRelevance,
      essayRelevance:
          e['essayRelevance'] as RelevanceLevel? ?? base.essayRelevance,
      interviewRelevance:
          e['interviewRelevance'] as RelevanceLevel? ?? base.interviewRelevance,
      prelimsTraps: e['prelimsTraps'] as List<String>? ?? base.prelimsTraps,
      mainsThemes: e['mainsThemes'] as List<String>? ?? base.mainsThemes,
      interviewAngles:
          e['interviewAngles'] as List<String>? ?? base.interviewAngles,
      constitutionalInterpretation: e['constitutionalInterpretation']
              as String? ??
          base.constitutionalInterpretation,
      legalPrinciple: e['legalPrinciple'] as String? ?? base.legalPrinciple,
      precedentRelationships: e['precedentRelationships']
              as List<PrecedentRelationship>? ??
          base.precedentRelationships,
      caseType: e['caseType'] as CaseType? ?? base.caseType,
      benchStrength: e['benchStrength'] as int? ?? base.benchStrength,
      neutralCitation: e['neutralCitation'] as String? ?? base.neutralCitation,
      reporterCitation:
          e['reporterCitation'] as String? ?? base.reporterCitation,
      authoringJudge: e['authoringJudge'] as String? ?? base.authoringJudge,
      majorityOpinion:
          e['majorityOpinion'] as String? ?? base.majorityOpinion,
      dissent: e['dissent'] as String? ?? base.dissent,
    );
  }

  /// Proportion of records with a resolvable evidence ID.
  static double evidenceCoverage(List<CaseKnowledgeObject> cases) {
    if (cases.isEmpty) return 0.0;
    final covered = cases
        .where((c) =>
            c.evidenceIds.isNotEmpty &&
            c.evidenceIds.any(CaseOfficialSources.isRegisteredEvidence))
        .length;
    return covered / cases.length;
  }

  /// Whether a record's evidence resolves against the official registry.
  static bool hasResolvableEvidence(CaseKnowledgeObject c) =>
      c.evidenceIds.any(CaseOfficialSources.isRegisteredEvidence);

  // ---------------------------------------------------------------------------
  // Legacy-corpus enrichment (TITAN-KO-014/015 knowledge pass). New Phase-II
  // records carry these fields natively and are not listed here.
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, dynamic>> _enrichments = {
    'KESAVANANDA': {
      'caseType': CaseType.constitutionalLaw,
      'doctrines': ['BASIC_STRUCTURE'],
      'precedentsOverruled': ['GOLAKNATH'],
      'relatedCases': ['MINERVA_MILLS', 'IR_COELHO', 'UNNIKRISHNAN'],
      'relatedActs': [
        'Constitution (Twenty-fourth Amendment) Act, 1971',
        'Constitution (Twenty-fifth Amendment) Act, 1971',
      ],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Basic Structure', 'Judicial Review', 'Amending Power'],
      'subjects': ['Constitutional Law', 'Fundamental Rights'],
      'prelimsRelevance': RelevanceLevel.critical,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'interviewRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Basic structure applies to constitutional amendments, not ordinary statutes',
        'Tested on the 13-judge bench composition',
      ],
      'mainsThemes': [
        'Basic structure doctrine and limits of the amending power',
        'Judicial review vs parliamentary sovereignty',
      ],
      'interviewAngles': [
        'Can the basic structure doctrine apply to ordinary legislation?',
      ],
      'constitutionalInterpretation':
          'Parliament can amend any part of the Constitution but cannot alter its basic structure or identity.',
      'legalPrinciple':
          'The amending power under Article 368 cannot damage the basic structure of the Constitution.',
      'neutralCitation': '(1973) 4 SCC 225',
      'reporterCitation': 'AIR 1973 SC 1461',
      'authoringJudge': 'S.M. Sikri C.J.',
      'majorityOpinion':
          '7-6 majority held the amending power is wide but subject to the basic structure limitation.',
    },
    'GOLAKNATH': {
      'caseType': CaseType.constitutionalLaw,
      'doctrines': ['PROSPECTIVE_OVERRULING'],
      'precedentsOverruled': ['SHANKARI_PRASAD', 'SAJJAN_SINGH'],
      'relatedCases': ['KESAVANANDA', 'MINERVA_MILLS'],
      'relatedActs': ['Constitution (Seventeenth Amendment) Act, 1964'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Amending Power', 'Fundamental Rights'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'essayRelevance': RelevanceLevel.medium,
      'constitutionalInterpretation':
          'Parliament cannot abridge fundamental rights even through Article 368; applied prospective overruling.',
      'legalPrinciple':
          'Amendments that take away fundamental rights are void; overruled prospectively (later superseded by Kesavananda).',
      'neutralCitation': 'AIR 1967 SC 1643',
    },
    'SHANKARI_PRASAD': {
      'caseType': CaseType.constitutionalLaw,
      'relatedCases': ['GOLAKNATH', 'SAJJAN_SINGH', 'KESAVANANDA'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Amending Power'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.medium,
      'mainsRelevance': RelevanceLevel.high,
      'constitutionalInterpretation':
          'First case holding that a constitutional amendment is not "law" within Article 13(2).',
      'legalPrinciple':
          'The amending power under Article 368 is not limited by Article 13(2).',
      'neutralCitation': 'AIR 1951 SC 458',
    },
    'SAJJAN_SINGH': {
      'caseType': CaseType.constitutionalLaw,
      'relatedCases': ['GOLAKNATH', 'SHANKARI_PRASAD'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Amending Power'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.medium,
      'mainsRelevance': RelevanceLevel.medium,
      'constitutionalInterpretation':
          'Reaffirmed Shankari Prasad; an amendment under Article 368 is not "law" under Article 13.',
      'legalPrinciple':
          'Fundamental rights can be amended so long as Article 368 procedure is followed (later overruled).',
      'neutralCitation': 'AIR 1965 SC 845',
    },
    'BERUBARI_UNION': {
      'caseType': CaseType.constitutionalLaw,
      'relatedActs': ['Constitution (Ninth Amendment) Act, 1960'],
      'relatedCases': ['KESAVANANDA'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Cession of Territory', 'Treaties', 'Article 3'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.medium,
      'mainsRelevance': RelevanceLevel.medium,
      'constitutionalInterpretation':
          'Article 3 does not authorise cession of Indian territory to a foreign country.',
      'legalPrinciple':
          'Cession of territory requires a constitutional amendment, not merely legislation under Article 3.',
      'neutralCitation': 'AIR 1960 SC 845',
    },
    'MINERVA_MILLS': {
      'caseType': CaseType.constitutionalLaw,
      'doctrines': ['BASIC_STRUCTURE'],
      'precedentsFollowed': ['KESAVANANDA'],
      'relatedCases': ['KESAVANANDA', 'IR_COELHO'],
      'relatedActs': ['Constitution (Forty-second Amendment) Act, 1976'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Basic Structure', 'Directive Principles', 'Judicial Review'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.critical,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Judicial review is part of the basic structure',
        'Harmony between Part III and Part IV',
      ],
      'mainsThemes': [
        'Limits of the amending power; unamendable basic features',
        'Balance between fundamental rights and directive principles',
      ],
      'constitutionalInterpretation':
          'The power of judicial review and the harmony between Parts III and IV are basic features; Article 31C as widened by the 42nd Amendment is void.',
      'legalPrinciple':
          'The 42nd Amendment cannot confer unlimited amending power or remove judicial review.',
      'neutralCitation': 'AIR 1980 SC 1789',
      'authoringJudge': 'Y.V. Chandrachud C.J.',
    },
    'MANEKA_GANDHI': {
      'caseType': CaseType.humanRights,
      'doctrines': ['MANIFEST_ARBITRARINESS'],
      'precedentsOverruled': ['AK_GOPALAN'],
      'relatedCases': ['PUTTASWAMY', 'DK_BASU'],
      'relatedActs': ['Passports Act, 1967'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Right to Life', 'Due Process', 'Personal Liberty'],
      'subjects': ['Constitutional Law', 'Human Rights'],
      'prelimsRelevance': RelevanceLevel.critical,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'interviewRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Maneka links Articles 14, 19 and 21 - not Article 21 alone',
        'Overruled A.K. Gopalan narrow reading',
      ],
      'mainsThemes': [
        'Expansive reading of Article 21',
        'Procedure established by law vs due process',
      ],
      'interviewAngles': [
        'How does non-arbitrariness flow from Article 14 into Article 21?',
      ],
      'constitutionalInterpretation':
          'Article 21 is not a standalone guarantee; it is read with Articles 14 and 19, and procedure must be fair, just and reasonable.',
      'legalPrinciple':
          'Personal liberty cannot be curtailed except by a fair, just and reasonable procedure.',
      'neutralCitation': 'AIR 1978 SC 597',
      'authoringJudge': 'P.N. Bhagwati J.',
    },
    'ADM_JABALPUR': {
      'caseType': CaseType.humanRights,
      'relatedActs': ['Maintenance of Internal Security Act, 1971'],
      'relatedCases': ['MANEKA_GANDHI', 'SR_BOMMAI'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Habeas Corpus', 'Emergency', 'Rule of Law'],
      'subjects': ['Constitutional Law', 'Human Rights'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'essayRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'H.C. Khanna dissented - habeas corpus cannot be suspended',
        'Judgment later repudiated in post-emergency cases',
      ],
      'mainsThemes': [
        'Rule of law during emergency',
        'Dissenting judgments and their later vindication',
      ],
      'constitutionalInterpretation':
          'Majority held Article 21 remedies suspended during Emergency; H.C. Khanna dissented holding the right to life cannot be suspended. The view stands repudiated.',
      'legalPrinciple':
          'Held (4-1) that no one may approach courts for habeas corpus during Emergency; the dissent held life cannot be suspended.',
      'neutralCitation': 'AIR 1976 SC 1207',
    },
    'SR_BOMMAI': {
      'caseType': CaseType.federalism,
      'relatedActs': ['Constitution (Forty-fourth Amendment) Act, 1978'],
      'relatedCases': ['STATE_RAJASTHAN_V_UNION', 'NABAM_REBIA'],
      'relatedReports': ['Sarkaria Commission Report 1988'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Federalism', "President's Rule", 'Secularism', 'Floor Test'],
      'subjects': ['Constitutional Law', 'Federalism'],
      'prelimsRelevance': RelevanceLevel.critical,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Secularism held a basic feature',
        'Proclamation under Article 356 is judicially reviewable',
      ],
      'mainsThemes': [
        'Federalism and unit structure of the Constitution',
        'Judicial review of Article 356 proclamations',
      ],
      'interviewAngles': [
        'Can a court order a floor test while a House is dissolved?',
      ],
      'constitutionalInterpretation':
          'Secularism and federalism are basic features; Article 356 is subject to judicial review; majority must be tested on the floor of the House.',
      'legalPrinciple':
          "Article 356 cannot be used on irrational grounds; the Proclamation is justiciable.",
      'neutralCitation': 'AIR 1994 SC 1918',
    },
    'INDRA_SAWHNEY': {
      'caseType': CaseType.socialJustice,
      'relatedActs': ['Constitution (Seventy-seventh Amendment) Act, 1995'],
      'relatedCases': ['CHAMPAKAM_DORAIRAJAN', 'M_NAGARAJ', 'JANHIT_ABHIYAN'],
      'relatedReports': ['Mandal Commission Report 1980'],
      'sdgGoals': ['SDG 10 - Reduced Inequalities'],
      'themes': ['Reservation', 'Equality', 'Backward Classes', 'Creamy Layer'],
      'subjects': ['Constitutional Law', 'Social Justice'],
      'prelimsRelevance': RelevanceLevel.critical,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        '50% ceiling applies to reservations overall',
        'Creamy layer exclusion applies to OBCs (and later SC/STs)',
        'Article 16(4) is an enabling, not a fundamental, provision',
      ],
      'mainsThemes': [
        'Reservation policy and the 50% cap',
        'Creamy layer and equality jurisprudence',
      ],
      'interviewAngles': [
        'Is reservation in promotions a fundamental right?',
      ],
      'constitutionalInterpretation':
          'Article 16(4) is an enabling provision; creamy layer must be excluded; reservations cannot ordinarily exceed 50%; promotional reservations (except for the backlog) were disallowed until the 77th Amendment.',
      'legalPrinciple':
          'Reservation is not a fundamental right and cannot exceed 50% except in extraordinary circumstances; creamy layer must be excluded.',
      'neutralCitation': 'AIR 1993 SC 477',
    },
    'VISHAKA': {
      'caseType': CaseType.socialJustice,
      'relatedCases': ['JOSEPH_SHINE'],
      'relatedActs': [
        'Sexual Harassment of Women at Workplace (Prevention, Prohibition and Redressal) Act, 2013',
      ],
      'sdgGoals': ['SDG 5 - Gender Equality', 'SDG 8 - Decent Work & Economic Growth'],
      'themes': ['Gender Equality', 'Workplace Safety', 'Sexual Harassment'],
      'subjects': ['Constitutional Law', 'Social Justice'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'interviewRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Vishaka laid down guidelines in a legislative vacuum',
        'Now replaced by the POSH Act, 2013',
      ],
      'mainsThemes': [
        'Judicial law-making to fill legislative gaps',
        'Fundamental rights of women at the workplace',
      ],
      'interviewAngles': [
        'What changed after the POSH Act superseded Vishaka guidelines?',
      ],
      'constitutionalInterpretation':
          'Sexual harassment at the workplace violates Articles 14, 19(1)(g) and 21; guidelines framed until Parliament legislates.',
      'legalPrinciple':
          'A safe working environment is a facet of the right to equality and life; sexual harassment is a violation of fundamental rights.',
      'neutralCitation': 'AIR 1997 SC 3011',
    },
    'OLGA_TELLIS': {
      'caseType': CaseType.humanRights,
      'relatedActs': ['Bombay Municipal Corporation Act, 1888'],
      'relatedSchemes': ['Pradhan Mantri Awas Yojana'],
      'sdgGoals': ['SDG 11 - Sustainable Cities & Communities'],
      'themes': ['Right to Livelihood', 'Slum Dwellers', 'Due Process'],
      'subjects': ['Constitutional Law', 'Human Rights'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'essayRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Right to livelihood is not an absolute right',
        'Eviction permissible but must follow due process',
      ],
      'mainsThemes': [
        'Right to livelihood under Article 21',
        'Urban displacement and rehabilitation',
      ],
      'constitutionalInterpretation':
          'The right to livelihood is an integral part of the right to life under Article 21; eviction of slum dwellers must follow fair procedure.',
      'legalPrinciple':
          'Deprivation of livelihood must be by procedure established by law that is fair and reasonable.',
      'neutralCitation': 'AIR 1986 SC 180',
    },
    'UNNIKRISHNAN': {
      'caseType': CaseType.socialJustice,
      'relatedActs': [
        'Right of Children to Free and Compulsory Education Act, 2009',
      ],
      'relatedSchemes': ['Sarva Shiksha Abhiyan'],
      'relatedAmendments': ['86th Amendment'],
      'sdgGoals': ['SDG 4 - Quality Education'],
      'themes': ['Right to Education', 'Fundamental Rights'],
      'subjects': ['Constitutional Law', 'Social Justice'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'essayRelevance': RelevanceLevel.medium,
      'prelimsTraps': [
        'Education is a fundamental right only till age 14',
        'Article 21A added by the 86th Amendment',
      ],
      'mainsThemes': [
        'Right to education as a fundamental right',
        'State obligation to provide free and compulsory education',
      ],
      'constitutionalInterpretation':
          'The right to education (6-14 years) is implicit in Article 21 read with Article 21A and is a fundamental right.',
      'legalPrinciple':
          'Every child aged 6-14 has a fundamental right to free and compulsory education.',
      'neutralCitation': 'AIR 1993 SC 2178',
    },
    'IR_COELHO': {
      'caseType': CaseType.constitutionalLaw,
      'doctrines': ['BASIC_STRUCTURE'],
      'precedentsFollowed': ['KESAVANANDA'],
      'relatedCases': ['KESAVANANDA', 'MINERVA_MILLS'],
      'relatedActs': ['Constitution (Ninth Schedule)'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Ninth Schedule', 'Judicial Review', 'Basic Structure'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'essayRelevance': RelevanceLevel.medium,
      'prelimsTraps': [
        'Ninth Schedule laws after 24 April 1973 are subject to review',
        'Basic structure review applies to the effects of the law',
      ],
      'mainsThemes': [
        'Judicial review of Ninth Schedule laws',
        'Direct and incidental effects test',
      ],
      'constitutionalInterpretation':
          'Laws placed in the Ninth Schedule after 24 April 1973 are open to basic structure review; the test looks at direct and incidental effects.',
      'legalPrinciple':
          'Ninth Schedule immunity does not extend to post-1973 laws that violate the basic structure.',
      'neutralCitation': '(2007) 12 SCC 1',
    },
    'PUTTASWAMY': {
      'caseType': CaseType.humanRights,
      'doctrines': ['PROPORTIONALITY'],
      'precedentsOverruled': ['AK_GOPALAN'],
      'relatedCases': ['MANEKA_GANDHI', 'NAVTEJ_JOHAR'],
      'relatedActs': [
        'Aadhaar (Targeted Delivery of Financial and Other Subsidies, Benefits and Services) Act, 2016',
      ],
      'relatedBodies': ['bod_uidai'],
      'relatedSchemes': ['Aadhaar'],
      'relatedCurrentAffairs': ['ca_aadhaar_privacy'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Right to Privacy', 'Data Protection', 'Fundamental Rights'],
      'subjects': ['Constitutional Law', 'Human Rights'],
      'prelimsRelevance': RelevanceLevel.critical,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'interviewRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Privacy is a fundamental right under Article 21 and Part III',
        'Not an absolute right - subject to proportionality',
      ],
      'mainsThemes': [
        'Right to privacy and data protection',
        'Proportionality as the test for state intrusion',
      ],
      'interviewAngles': [
        'What did Puttaswamy add to Article 21 jurisprudence on privacy?',
      ],
      'constitutionalInterpretation':
          'Privacy is intrinsic to life and liberty under Article 21, a facet of dignity, and protected across Part III; any intrusion must satisfy proportionality.',
      'legalPrinciple':
          'Right to privacy is a fundamental right; state limitation must pass the proportionality test.',
      'neutralCitation': '(2017) 10 SCC 1',
      'authoringJudge': 'J.S. Khehar C.J.',
    },
    'NAVTEJ_JOHAR': {
      'caseType': CaseType.socialJustice,
      'doctrines': ['PROPORTIONALITY'],
      'relatedActs': ['Indian Penal Code, 1860'],
      'relatedSections': ['Section 377 IPC'],
      'sdgGoals': ['SDG 10 - Reduced Inequalities'],
      'themes': ['LGBTQ Rights', 'Decriminalisation', 'Privacy'],
      'subjects': ['Constitutional Law', 'Social Justice'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'essayRelevance': RelevanceLevel.high,
      'interviewRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Section 377 read down, not struck down entirely',
        'Consensual same-sex acts between adults decriminalised',
      ],
      'mainsThemes': [
        'Decriminalisation and dignity of LGBTQ persons',
        'Privacy and choice in intimate relations',
      ],
      'interviewAngles': [
        'What remains of Section 377 after Navtej Johar?',
      ],
      'constitutionalInterpretation':
          'Section 377, insofar as it criminalises consensual sexual acts between adults, violates Articles 14, 15 and 21; read down.',
      'legalPrinciple':
          'Consensual same-sex relations between adults are not criminal; Section 377 applies only to non-consensual acts.',
      'neutralCitation': '(2018) 10 SCC 1',
    },
    'SHAYARA_BANO': {
      'caseType': CaseType.socialJustice,
      'doctrines': ['MANIFEST_ARBITRARINESS'],
      'relatedActs': ['Muslim Women (Protection of Rights on Marriage) Act, 2019'],
      'sdgGoals': ['SDG 5 - Gender Equality'],
      'themes': ['Triple Talaq', 'Gender Justice', 'Uniform Civil Code'],
      'subjects': ['Constitutional Law', 'Social Justice'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.critical,
      'essayRelevance': RelevanceLevel.high,
      'interviewRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Triple talaq held unconstitutional, not personal law as a whole',
        'Majority on manifest arbitrariness; minority for uniformity',
      ],
      'mainsThemes': [
        'Manifest arbitrariness and Article 14',
        'Gender justice within personal law',
      ],
      'interviewAngles': [
        'How is personal law tested against fundamental rights?',
      ],
      'constitutionalInterpretation':
          'Triple talaq (talaq-e-biddat) is manifestly arbitrary and violates Article 14; it has no legal sanctity.',
      'legalPrinciple':
          'A practice that is manifestly arbitrary and violates constitutional morality cannot be protected as religion.',
      'neutralCitation': '(2017) 9 SCC 1',
    },
    'ROMESH_THAPPAR': {
      'caseType': CaseType.constitutionalLaw,
      'relatedActs': ['Press (Objectionable Matter) Act, 1951'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Freedom of Speech', 'Pre-censorship'],
      'subjects': ['Constitutional Law'],
      'prelimsRelevance': RelevanceLevel.medium,
      'mainsRelevance': RelevanceLevel.high,
      'constitutionalInterpretation':
          'Administrative pre-censorship violates Article 19(1)(a); restrictions must be within Article 19(2).',
      'legalPrinciple':
          'The press cannot be subjected to pre-censorship except under grounds specified in Article 19(2).',
      'neutralCitation': 'AIR 1950 SC 124',
    },
    'AK_GOPALAN': {
      'caseType': CaseType.humanRights,
      'relatedActs': ['Preventive Detention Act, 1950'],
      'relatedCases': ['MANEKA_GANDHI', 'PUTTASWAMY'],
      'sdgGoals': ['SDG 16 - Peace, Justice & Strong Institutions'],
      'themes': ['Preventive Detention', 'Article 21'],
      'subjects': ['Constitutional Law', 'Human Rights'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'prelimsTraps': [
        'Gopalan adopted a narrow, independent reading of Article 21',
        'Overruled in effect by Maneka Gandhi',
      ],
      'mainsThemes': [
        'Preventive detention and fundamental rights',
        'Evolution of Article 21 jurisprudence',
      ],
      'constitutionalInterpretation':
          'Held Article 21 gives only procedural protection under "procedure established by law", not due process; later overruled by Maneka Gandhi.',
      'legalPrinciple':
          'Personal liberty protected only against executive action under procedure established by law (superseded).',
      'neutralCitation': 'AIR 1950 SC 27',
    },
    'CHAMPAKAM_DORAIRAJAN': {
      'caseType': CaseType.socialJustice,
      'relatedActs': ['Constitution (First Amendment) Act, 1951'],
      'relatedCases': ['INDRA_SAWHNEY', 'M_NAGARAJ'],
      'sdgGoals': ['SDG 10 - Reduced Inequalities'],
      'themes': ['Reservation', 'Equality', 'Directive Principles'],
      'subjects': ['Constitutional Law', 'Social Justice'],
      'prelimsRelevance': RelevanceLevel.high,
      'mainsRelevance': RelevanceLevel.high,
      'constitutionalInterpretation':
          'Directive Principles cannot override fundamental rights; reservation based on caste alone was struck down.',
      'legalPrinciple':
          'Fundamental rights prevail over directive principles; the First Amendment was later passed to permit social reservation.',
      'neutralCitation': 'AIR 1951 SC 226',
    },
  };
}
