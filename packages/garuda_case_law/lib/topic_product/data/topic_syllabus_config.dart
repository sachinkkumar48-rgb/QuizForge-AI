/// P14 syllabus configuration (TITAN-KO-015.0 P14).
///
/// The authoritative, static, versioned P14 syllabus configuration. It defines
/// the canonical pedagogical UPSC topics and the explicit, deterministic
/// mapping of validated P3/P4 case signals to those topics.
///
/// **Taxonomy status:** this is an EDITORIAL PEDAGOGICAL MAPPING, not an
/// official UPSC syllabus. The repository contains no authoritative UPSC
/// syllabus source, so no topic here claims official syllabus wording (see
/// [TopicMappingKind] and `P14_TOPIC_KNOWLEDGE_PRODUCT.md`). The distinction is
/// kept explicit: P4 source data (`p4:...`), the P14 pedagogical mapping
/// (`p14:...`) and (absent here) official syllabus wording are never conflated.
///
/// **Membership rule:** a case enters a topic only through an explicit
/// [TopicMembership] that cites a validated P3/P4 signal the case genuinely
/// carries. Membership is never inferred from graph connectivity, chronology,
/// doctrine membership alone, discovery or apparent relevance.
library;

import 'package:meta/meta.dart';

import '../../intelligence/domain/intelligence_enums.dart';
import '../domain/topic_identity.dart';
import '../domain/topic_membership.dart';
import '../domain/topic_product_enums.dart';

/// Immutable, versioned P14 syllabus configuration.
@immutable
class TopicSyllabusConfig {
  /// Deterministic configuration version. Bumped only when the mapping is
  /// deliberately revised; no runtime timestamp is involved.
  final String version;

  /// Explicit declaration of what topic membership is (and is not).
  final String mappingDeclaration;

  /// Canonical topics in deterministic order (topic ID ascending).
  final List<TopicIdentity> topics;

  /// Explicit case → topic memberships.
  final List<TopicMembership> memberships;

  /// topicId → editorial pedagogical overview (one sentence; editorial, never
  /// a legal claim).
  final Map<String, String> overviews;

  const TopicSyllabusConfig({
    required this.version,
    required this.mappingDeclaration,
    required this.topics,
    required this.memberships,
    required this.overviews,
  });

  /// All canonical topic IDs, sorted.
  List<String> get topicIds =>
      topics.map((t) => t.id).toList(growable: false)..sort();

  /// Resolves a topic by canonical ID or display name, or null when unknown.
  TopicIdentity? identityFor(String idOrName) {
    final key = idOrName.trim();
    for (final t in topics) {
      if (t.id == key || t.name == key) return t;
    }
    return null;
  }

  /// Whether [id] is a canonical topic ID.
  bool hasTopic(String id) => identityFor(id) != null;

  /// The editorial overview for [topicId], or '' when none is defined.
  String overviewFor(String topicId) => overviews[topicId] ?? '';

  /// All memberships for [topicId], in canonical (config) order.
  List<TopicMembership> membershipsForTopic(String topicId) =>
      List.unmodifiable([
        for (final m in memberships)
          if (m.topicId == topicId) m,
      ]);

  /// Unique member case IDs for [topicId], sorted (deterministic).
  List<String> memberCaseIdsFor(String topicId) {
    final set = <String>{
      for (final m in membershipsForTopic(topicId)) m.caseId,
    };
    final sorted = set.toList()..sort();
    return List.unmodifiable(sorted);
  }

  /// All distinct member case IDs across every topic, sorted.
  List<String> get allMemberCaseIds {
    final set = <String>{
      for (final m in memberships) m.caseId,
    };
    final sorted = set.toList()..sort();
    return List.unmodifiable(sorted);
  }
}

/// The canonical P14 syllabus configuration (version 1).
///
/// Twelve pedagogical topics grouped under the normalized P4 `UpscSyllabusArea`
/// areas. Every membership cites a signal string that was verified to be
/// carried verbatim by the mapped case in the actual 49-case corpus.
abstract final class UpscTopicSyllabus {
  /// The explicit statement of what topic membership does and does not mean.
  static const String mappingDeclaration =
      'Topic membership is a pedagogical grouping of existing validated '
      'case-law knowledge for UPSC preparation. It is NOT an official UPSC '
      'syllabus taxonomy; no entity is claimed to be officially classified '
      'under any topic. Topic membership does NOT establish a legal '
      'relationship (precedent, legal similarity, authority, overruling, '
      'refinement, extension, doctrinal evolution, causation or current-law '
      'status) between the included entities. Legal relationships among cases '
      'are established solely by the P5 precedent/doctrine graph.';

  /// The versioned configuration.
  static const TopicSyllabusConfig config = TopicSyllabusConfig(
    version: '1',
    mappingDeclaration: mappingDeclaration,
    topics: [
      TopicIdentity(
        id: 'amending_power_and_basic_structure',
        name: 'Amending Power & Basic Structure Doctrine',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Constitutional Governance → '
            'Amending Power & Basic Structure Doctrine',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'death_penalty_and_sentencing',
        name: 'Death Penalty & Sentencing',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Governance → Death Penalty & '
            'Sentencing',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'environmental_justice_and_sustainable_development',
        name: 'Environmental Justice & Sustainable Development',
        area: UpscSyllabusArea.gs3,
        pedagogicalPath: 'GS Paper III → Environment & Sustainable '
            'Development → Environmental Justice',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'federal_structure_and_presidents_rule',
        name: 'Federal Structure & President’s Rule',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Constitutional Governance → Federal '
            'Structure & President’s Rule',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'freedom_of_speech_and_expression',
        name: 'Freedom of Speech & Expression',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Fundamental Rights → Freedom of '
            'Speech & Expression',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'gender_justice_and_personal_autonomy',
        name: 'Gender Justice & Personal Autonomy',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Social Justice → Gender Justice & '
            'Personal Autonomy',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'judiciary_appointments_and_independence',
        name: 'Judiciary: Appointments & Independence',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Constitutional Governance → '
            'Judiciary: Appointments & Independence',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'personal_liberty_and_article_21',
        name: 'Personal Liberty & Article 21',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Fundamental Rights → Personal '
            'Liberty & Article 21',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'reservation_and_affirmative_action',
        name: 'Reservation & Affirmative Action',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Social Justice → Reservation & '
            'Affirmative Action',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'right_to_education',
        name: 'Right to Education',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Fundamental Rights → Right to '
            'Education',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'right_to_privacy_and_dignity',
        name: 'Right to Privacy & Dignity',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Fundamental Rights → Right to '
            'Privacy & Dignity',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
      TopicIdentity(
        id: 'union_territory_and_article_3',
        name: 'Union Territory & Article 3 (Reorganisation)',
        area: UpscSyllabusArea.gs2,
        pedagogicalPath: 'GS Paper II → Union & Its Territory → Article 3 '
            '(Reorganisation)',
        mappingKind: TopicMappingKind.pedagogicalMapping,
        configVersion: '1',
      ),
    ],
    memberships: [
      // -------------------------------------------------------------------
      // amending_power_and_basic_structure
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'SHANKARI_PRASAD',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Amending Power',
        note: 'First decision on the reach of Article 368.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'SAJJAN_SINGH',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Amending Power',
        note: 'Plenary reading of the amending power reaffirmed.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'GOLAKNATH',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Evolution of the basic structure doctrine',
        note: 'Forerunner of the basic structure doctrine.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'KESAVANANDA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue:
            'Basic structure doctrine and the limits of constitutional '
            'amendment',
        note: 'The originating basic-structure decision.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'MINERVA_MILLS',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Basic structure and the 42nd Amendment',
        note: 'Basic structure applied to the 42nd Amendment.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'IR_COELHO',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Ninth Schedule and the basic structure doctrine',
        note: 'Basic structure extended to Ninth Schedule laws.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'L_CHANDRA_KUMAR',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Tribunals and the basic structure doctrine',
        note: 'Judicial review as a basic feature over tribunals.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'SC_OR_1993',
        signalField: TopicSignalField.p4AnswerKeywords,
        signalValue: 'Basic Structure',
        note: 'Basic structure engaged in the appointments context.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'NJAC_2015',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Judicial appointments and the basic structure',
        note: 'Basic structure applied to the NJAC amendment.',
      ),
      TopicMembership(
        topicId: 'amending_power_and_basic_structure',
        caseId: 'SR_BOMMAI',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Secularism as a basic feature',
        note: 'Secularism and federalism held basic features.',
      ),
      // -------------------------------------------------------------------
      // judiciary_appointments_and_independence
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'judiciary_appointments_and_independence',
        caseId: 'SC_OR_1993',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Judicial Independence',
        note: 'Second Judges Case — collegium system.',
      ),
      TopicMembership(
        topicId: 'judiciary_appointments_and_independence',
        caseId: 'NJAC_2015',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Judicial Independence',
        note: 'NJAC struck down; collegium restored.',
      ),
      // -------------------------------------------------------------------
      // federal_structure_and_presidents_rule
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'federal_structure_and_presidents_rule',
        caseId: 'SR_BOMMAI',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'President\'s Rule under Article 356 and its limits',
        note: 'Article 356 made justiciable.',
      ),
      TopicMembership(
        topicId: 'federal_structure_and_presidents_rule',
        caseId: 'STATE_RAJASTHAN_V_UNION',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Article 356 and federalism',
        note: 'Early review of presidential discretion under Article 356.',
      ),
      TopicMembership(
        topicId: 'federal_structure_and_presidents_rule',
        caseId: 'NABAM_REBIA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Governor\'s discretionary powers and federalism',
        note: 'Floor test and gubernatorial discretion.',
      ),
      // -------------------------------------------------------------------
      // union_territory_and_article_3
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'union_territory_and_article_3',
        caseId: 'BERUBARI_UNION',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Article 3 and the constitutional method for territorial '
            'change',
        note: 'Cession of territory requires a constitutional amendment.',
      ),
      // -------------------------------------------------------------------
      // reservation_and_affirmative_action
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'reservation_and_affirmative_action',
        caseId: 'CHAMPAKAM_DORAIRAJAN',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Reservation',
        note: 'FR vs DPSP; First Amendment reservation framework.',
      ),
      TopicMembership(
        topicId: 'reservation_and_affirmative_action',
        caseId: 'INDRA_SAWHNEY',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Reservation',
        note: 'Mandal; creamy layer; 50% cap.',
      ),
      TopicMembership(
        topicId: 'reservation_and_affirmative_action',
        caseId: 'M_NAGARAJ',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Reservation in promotions and Article 16(4A)',
        note: 'Quantifiable data conditions for promotion reservation.',
      ),
      TopicMembership(
        topicId: 'reservation_and_affirmative_action',
        caseId: 'JARNAIL_SINGH',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Creamy layer and SC/ST reservation',
        note: 'Creamy layer extended to SC/ST promotions.',
      ),
      TopicMembership(
        topicId: 'reservation_and_affirmative_action',
        caseId: 'JANHIT_ABHIYAN',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Reservation beyond the 50% cap',
        note: 'EWS reservation under Article 15(6) upheld.',
      ),
      // -------------------------------------------------------------------
      // personal_liberty_and_article_21
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'AK_GOPALAN',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Article 21',
        note: 'Early narrow reading of Article 21.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'MANEKA_GANDHI',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Procedural due process under Article 21',
        note: 'Expansive reading; due process read in.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'OLGA_TELLIS',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Right to livelihood and urban evictions',
        note: 'Right to livelihood read into Article 21.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'SUCHITA_SRIVASTAVA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Reproductive rights and Article 21',
        note: 'Reproductive autonomy under Article 21.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'COMMON_CAUSE_EUTHANASIA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Right to life and the right to die with dignity',
        note: 'Advance directives under Article 21.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'ARNESH_KUMAR',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Arrest and the right to liberty',
        note: 'Arrest safeguards under Article 21.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'DK_BASU',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Custodial justice and Article 21',
        note: 'Custodial-violence guidelines.',
      ),
      TopicMembership(
        topicId: 'personal_liberty_and_article_21',
        caseId: 'HUSSAINARA_KHATOON',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Speedy trial and access to justice',
        note: 'Speedy trial read into Article 21.',
      ),
      // -------------------------------------------------------------------
      // freedom_of_speech_and_expression
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'freedom_of_speech_and_expression',
        caseId: 'ROMESH_THAPPAR',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Freedom of Speech',
        note: 'Early Article 19(1)(a) reasonable-restriction framework.',
      ),
      TopicMembership(
        topicId: 'freedom_of_speech_and_expression',
        caseId: 'SHREYA_SINGHAL',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Free speech and the internet',
        note: 'Section 66A struck down; online speech protected.',
      ),
      TopicMembership(
        topicId: 'freedom_of_speech_and_expression',
        caseId: 'ADR_ASSOCIATION',
        signalField: TopicSignalField.p4AnswerKeywords,
        signalValue: 'Article 19(1)(a)',
        note: 'Voters’ right to know under Article 19(1)(a).',
      ),
      TopicMembership(
        topicId: 'freedom_of_speech_and_expression',
        caseId: 'PUCL_NOTA',
        signalField: TopicSignalField.p4AnswerKeywords,
        signalValue: 'Article 19(1)(a)',
        note: 'Negative voting as expression under Article 19(1)(a).',
      ),
      // -------------------------------------------------------------------
      // gender_justice_and_personal_autonomy
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'gender_justice_and_personal_autonomy',
        caseId: 'VISHAKA',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Gender Equality',
        note: 'Workplace sexual-harassment guidelines.',
      ),
      TopicMembership(
        topicId: 'gender_justice_and_personal_autonomy',
        caseId: 'SUCHITA_SRIVASTAVA',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Women\'s bodily autonomy',
        note: 'Reproductive autonomy and the MTP framework.',
      ),
      TopicMembership(
        topicId: 'gender_justice_and_personal_autonomy',
        caseId: 'INDEPENDENT_THOUGHT',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Marital rape exception and child rights',
        note: 'Marital-rape exception read down for minors.',
      ),
      TopicMembership(
        topicId: 'gender_justice_and_personal_autonomy',
        caseId: 'SHAYARA_BANO',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Gender justice and uniform civil code debate',
        note: 'Triple talaq; personal law and fundamental rights.',
      ),
      TopicMembership(
        topicId: 'gender_justice_and_personal_autonomy',
        caseId: 'JOSEPH_SHINE',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Decriminalisation and gender equality',
        note: 'Adultery decriminalised under Articles 14 and 21.',
      ),
      TopicMembership(
        topicId: 'gender_justice_and_personal_autonomy',
        caseId: 'NAVTEJ_JOHAR',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Sexual orientation and fundamental rights',
        note: 'Section 377 read down.',
      ),
      // -------------------------------------------------------------------
      // right_to_privacy_and_dignity
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'right_to_privacy_and_dignity',
        caseId: 'PUTTASWAMY',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Right to Privacy',
        note: 'Privacy held a fundamental right.',
      ),
      TopicMembership(
        topicId: 'right_to_privacy_and_dignity',
        caseId: 'NAVTEJ_JOHAR',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Dignity and privacy of LGBTQ+ persons',
        note: 'Privacy and dignity of LGBTQ+ persons.',
      ),
      TopicMembership(
        topicId: 'right_to_privacy_and_dignity',
        caseId: 'JOSEPH_SHINE',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Privacy and the criminal law',
        note: 'Privacy engaged by the adultery provision.',
      ),
      // -------------------------------------------------------------------
      // environmental_justice_and_sustainable_development
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'environmental_justice_and_sustainable_development',
        caseId: 'ICELA_BICHHRI',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Absolute liability and the polluter-pays principle',
        note: 'Polluter-pays for hazardous industries.',
      ),
      TopicMembership(
        topicId: 'environmental_justice_and_sustainable_development',
        caseId: 'VELLORE_CITIZENS',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Polluter-pays and precautionary principles',
        note: 'Precautionary and polluter-pays constitutionalised.',
      ),
      TopicMembership(
        topicId: 'environmental_justice_and_sustainable_development',
        caseId: 'MC_MEHTA_TAJ',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Environment, heritage and Article 21',
        note: 'Taj Trapezium; heritage and environment under Article 21.',
      ),
      TopicMembership(
        topicId: 'environmental_justice_and_sustainable_development',
        caseId: 'TN_GODAVARMAN',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Forest conservation and Article 48A',
        note: 'Forest conservation; continuing mandamus.',
      ),
      TopicMembership(
        topicId: 'environmental_justice_and_sustainable_development',
        caseId: 'NARMADA_BACHAO',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Development projects and displacement',
        note: 'Displacement and rehabilitation under Article 21.',
      ),
      // -------------------------------------------------------------------
      // right_to_education
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'right_to_education',
        caseId: 'MOHINI_JAIN',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Right to Education',
        note: 'Right to education located in Article 21.',
      ),
      TopicMembership(
        topicId: 'right_to_education',
        caseId: 'UNNIKRISHNAN',
        signalField: TopicSignalField.p4MainsThemes,
        signalValue: 'Right to education and Article 21A',
        note: 'Regulated private education; Article 21A precursor.',
      ),
      // -------------------------------------------------------------------
      // death_penalty_and_sentencing
      // -------------------------------------------------------------------
      TopicMembership(
        topicId: 'death_penalty_and_sentencing',
        caseId: 'BACHAN_SINGH',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Death Penalty',
        note: 'Rarest-of-rare doctrine.',
      ),
      TopicMembership(
        topicId: 'death_penalty_and_sentencing',
        caseId: 'MITHU',
        signalField: TopicSignalField.p3Themes,
        signalValue: 'Death Penalty',
        note: 'Mandatory death penalty struck down.',
      ),
    ],
    overviews: {
      'amending_power_and_basic_structure':
          'Cases on the reach of the amending power under Article 368 and the '
              'development of the basic structure doctrine.',
      'death_penalty_and_sentencing':
          'Cases on the constitutionality of capital punishment and '
              'individualised sentencing.',
      'environmental_justice_and_sustainable_development':
          'Cases on environmental protection, sustainable development and the '
              'polluter-pays / precautionary principles.',
      'federal_structure_and_presidents_rule':
          'Cases on the federal structure, President’s Rule under Article 356 '
              'and gubernatorial discretion.',
      'freedom_of_speech_and_expression':
          'Cases on freedom of speech and expression under Article 19(1)(a), '
              'including online speech and electoral transparency.',
      'gender_justice_and_personal_autonomy':
          'Cases on gender equality, personal autonomy and the '
              'decriminalisation of private conduct.',
      'judiciary_appointments_and_independence':
          'Cases on judicial appointments, the collegium system and judicial '
              'independence.',
      'personal_liberty_and_article_21':
          'Cases on the scope of personal liberty and due process under '
              'Article 21.',
      'reservation_and_affirmative_action':
          'Cases on reservation policy, affirmative action and equality '
              'jurisprudence.',
      'right_to_education':
          'Cases locating the right to education in the Constitution.',
      'right_to_privacy_and_dignity':
          'Cases on the right to privacy, dignity and data protection.',
      'union_territory_and_article_3':
          'Cases on the constitutional method for territorial change and '
              'reorganisation under Article 3.',
    },
  );
}
