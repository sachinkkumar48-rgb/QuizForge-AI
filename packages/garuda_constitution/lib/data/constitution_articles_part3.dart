library;

import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_enums.dart';

/// Seeded Data for Part III (Fundamental Rights) Articles 12 through 35.
/// Every Article is a permanent Knowledge Object formatted for GARUDA engine.
class ConstitutionArticlesPart3 {
  static final List<ArticleKnowledgeObject> articles = [
    // ------------------------------------------------------------------------
    // Article 12: Definition of State
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-12',
      articleNumber: '12',
      officialTitle: 'Definition of State',
      part: 'Part III',
      chapter: 'General',
      originalNumber: '12',
      currentNumber: '12',
      title: 'Article 12: Definition of State',
      officialName: 'ARTICLE 12',
      description:
          'In this Part, unless the context otherwise requires, "the State" includes the Government and Parliament of India and the Government and the Legislature of each of the States and all local or other authorities within the territory of India or under the control of the Government of India.',
      officialConstitutionalText:
          'In this Part, unless the context otherwise requires, "the State" includes the Government and Parliament of India and the Government and the Legislature of each of the States and all local or other authorities within the territory of India or under the control of the Government of India.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 12 defines the entity called "the State" against which Fundamental Rights under Part III are enforceable. It comprises 4 categories: 1) Executive and Parliament of India, 2) Executive and Legislature of States, 3) Local Authorities (Municipalities, Panchayats, District Boards, Improvement Trusts), and 4) Other Authorities within India or under GoI control (bodies acting as instrumentalities or agencies of the State like LIC, ONGC, SAIL).',
      searchKeywords: const [
        'Article 12',
        'Definition of State',
        'Local authorities',
        'Other authorities',
        'Instrumentality of State',
        'Agency of State',
        'Part III general'
      ],
      keyTakeaways: const [
        'Defines "State" strictly for the purpose of Part III Fundamental Rights.',
        'Fundamental Rights are primarily enforceable against the State, not private individuals (unless specifically stated as in Art 17, 23, 24).',
        '"Other authorities" includes statutory and non-statutory bodies acting as agencies/instrumentalities of the government (Ajay Hasia test).',
        'BCCI is NOT a State under Art 12 (Zeev Telefilms case), though subject to Art 226 writ jurisdiction for public duties.'
      ],
      commonMisconceptions: const [
        'Misconception: Article 12 defines State for all parts of the Constitution. Reality: It applies specifically to Part III (and adopted by reference in Part IV Art 36).',
        'Misconception: Judiciary is explicitly included under Article 12. Reality: Judiciary on judicial side is not State, but on administrative side it acts as State.'
      ],
      memoryAids: const [
        'Mnemonic - PELO: Parliament/Executive, Executive/Legislature of States, Local Authorities, Other Authorities.'
      ],
      historicalBackground:
          'Adopted by the Constituent Assembly on November 25, 1948. Dr. B.R. Ambedkar explained that the scope of "State" had to be broad enough so that every authority having statutory power to make laws, rules, or regulations binding on citizens is bound by Fundamental Rights.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (November 25, 1948) - Debate on Draft Article 7 (became Article 12).',
        'Amendments by Pandit Lakshmi Kanta Maitra and H.V. Kamath regarding scope of local authorities.'
      ],
      objectivesResolutionLinks: const [
        'Ensures that the democratic rights guaranteed in the Objectives Resolution (1946) bind all tiers of public authority.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'University of Madras v. Shanta Bai',
          year: 1954,
          bench: 'Madras High Court',
          legalPrinciple:
              'Initially applied ejusdem generis rule for "other authorities", restricting it to governmental functions.',
          importance: 'Historical restrictive interpretation of Article 12.',
          status: 'Overruled by SC in Electricity Board Rajasthan',
        ),
        ArticleCaseLawRecord(
          caseName: 'Electricity Board, Rajasthan v. Mohan Lal',
          year: 1967,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Rejected ejusdem generis rule. Held "other authorities" includes all bodies created by Constitution or statute on whom powers are conferred by law.',
          importance: 'Broadened scope of Article 12 to statutory bodies.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Ramana Dayaram Shetty v. International Airport Authority of India (IAAI)',
          year: 1979,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Formulated 5-point test to determine if a body is an instrumentality or agency of the State.',
          importance: 'Test of Instrumentality/Agency of State.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Ajay Hasia v. Khalid Mujib Sehravardi',
          year: 1981,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Summarized guidelines for State agency: 1) Entire share capital held by Govt, 2) Deep & pervasive State control, 3) Monopoly status, 4) Public importance, 5) Govt department transferred.',
          importance: 'Definitive 6-factor test for Article 12 State status.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Pradeep Kumar Biswas v. Indian Institute of Chemical Biology',
          year: 2002,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Re-examined Sabhajit Tewary case. Held CSIR is an instrumentality of State under Art 12 due to financial, functional, and administrative dominance of Govt.',
          importance: 'Overruled Sabhajit Tewary (1975).',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Zeev Telefilms Ltd. v. Union of India',
          year: 2005,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'BCCI is not State under Art 12 because government does not hold share capital, enjoy monopoly conferred by law, or exercise pervasive control.',
          importance: 'Autonomous sports bodies not Art 12 State.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedArticles: const ['Article 13', 'Article 36', 'Article 226', 'Article 300'],
      relatedPYQs: const ['PYQ_UPSC_2015_ART12', 'PYQ_UPSC_2021_ART12', 'PYQ_CAPF_2019_ART12'],
      pyqIds: const ['PYQ_UPSC_2015_ART12', 'PYQ_UPSC_2021_ART12', 'PYQ_CAPF_2019_ART12'],
      learningObjectives: const [
        'Identify the four categories of State under Article 12.',
        'Apply the 6-factor Ajay Hasia test to determine if a body is State.',
        'Distinguish between Art 12 State and bodies subject to Art 226 writ jurisdiction.'
      ],
      difficulty: 'Medium',
      examImportance: 'High',
      revisionPoints: const [
        'State includes GoI + Parliament, State Govt + Legislature, Local Authorities, Other Authorities.',
        'Ajay Hasia test: Financial help, deep control, public function, monopoly, transfer of dept.',
        'CSIR is State (Pradeep Kumar Biswas 2002); BCCI is NOT State (Zeev Telefilms 2005).'
      ],
      trapAreas: const [
        'Confusing Art 12 definition with Art 36 or Art 308.',
        'Assuming private bodies performing public functions become Art 12 State automatically (they may be subject to Art 226, but not Art 12).'
      ],
      frequentlyConfusedWith: const ['Article 36 (DPSP definition of State)', 'Article 308'],
      timesAsked: 12,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 6, 'StatePSC': 4, 'CDS': 2},
      difficultyDistribution: const {'Easy': 2, 'Medium': 7, 'Hard': 3},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'CAD Vol. VII p. 607',
        'AIR 1981 SC 487 (Ajay Hasia)',
        '(2002) 5 SCC 111 (Pradeep Kumar Biswas)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_CAD_VOL7_ART12', 'REF_SC_AJAY_HASIA_1981'],
    ),

    // ------------------------------------------------------------------------
    // Article 13: Laws Inconsistent with or in Derogation of FRs
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-13',
      articleNumber: '13',
      officialTitle: 'Laws inconsistent with or in derogation of the fundamental rights',
      part: 'Part III',
      chapter: 'General',
      originalNumber: '13',
      currentNumber: '13',
      title: 'Article 13: Laws inconsistent with or in derogation of FRs',
      officialName: 'ARTICLE 13',
      description:
          '(1) All laws in force in the territory of India immediately before the commencement of this Constitution, in so far as they are inconsistent with the provisions of this Part, shall, to the extent of such inconsistency, be void.\n(2) The State shall not make any law which takes away or abridges the rights conferred by this Part and any law made in contravention of this clause shall, to the extent of the contravention, be void.\n(3) In this article, unless the context otherwise requires,— (a) "law" includes any Ordinance, order, bye-law, rule, regulation, notification, custom or usage having in the territory of India the force of law; (b) "laws in force" includes laws passed or made by a Legislature or other competent authority in the territory of India before the commencement of this Constitution and not previously repealed...\n(4) Nothing in this article shall apply to any amendment of this Constitution made under article 368.',
      officialConstitutionalText:
          '(1) All laws in force in the territory of India immediately before the commencement of this Constitution, in so far as they are inconsistent with the provisions of this Part, shall, to the extent of such inconsistency, be void.\n(2) The State shall not make any law which takes away or abridges the rights conferred by this Part and any law made in contravention of this clause shall, to the extent of the contravention, be void.\n(3) In this article, unless the context otherwise requires,— (a) "law" includes any Ordinance, order, bye-law, rule, regulation, notification, custom or usage having in the territory of India the force of law; (b) "laws in force" includes laws passed or made by a Legislature or other competent authority in the territory of India before the commencement of this Constitution and not previously repealed...\n(4) Nothing in this article shall apply to any amendment of this Constitution made under article 368.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 13 explicitly establishes the doctrine of Judicial Review in India. Clause (1) covers pre-constitutional laws (governed by Doctrine of Eclipse & Severability). Clause (2) covers post-constitutional laws (void ab initio if violating FRs). Clause (3) gives an expansive definition of "law" including ordinances, notifications, customs, and usages. Clause (4), added by 24th Amendment 1971, clarifies that Constitutional Amendments under Art 368 are not "law" under Art 13.',
      searchKeywords: const [
        'Article 13',
        'Judicial Review',
        'Doctrine of Eclipse',
        'Doctrine of Severability',
        'Definition of Law',
        'Void ab initio',
        '24th Amendment',
        'Article 368 vs Article 13'
      ],
      keyTakeaways: const [
        'Pillar of Judicial Review under Articles 32 and 226.',
        'Pre-constitutional laws inconsistent with FRs are shadowed, not dead (Doctrine of Eclipse).',
        'Post-constitutional laws violating FRs are void ab initio.',
        'Clause (4) inserted by 24th Amendment (1971) excludes Constitutional Amendments from "law" under Art 13.',
        'Kesavananda Bharati case (1973) held Art 13(4) valid, but ruled amendments cannot destroy the Basic Structure.'
      ],
      commonMisconceptions: const [
        'Misconception: Unconstitutional pre-constitutional laws are completely obliterated. Reality: They remain dormant under Doctrine of Eclipse and can be revived if the FR is amended.',
        'Misconception: Custom or usage is not law. Reality: Art 13(3)(a) explicitly includes custom or usage having force of law.'
      ],
      memoryAids: const [
        'Mnemonic - SEES: Severability, Eclipse, Ex-post void, Statutory scope.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on November 26, 1948 (Draft Article 8). Dr. Ambedkar described Clause (2) as the mandatory injunction against Parliament and State Legislatures from encroaching upon fundamental freedoms.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (November 26, 1948) - Debates on Draft Article 8.',
        'Discussion on inclusion of personal laws and custom within definition of law.'
      ],
      objectivesResolutionLinks: const [
        'Guarantees enforcement mechanisms ensuring statutory laws conform to democratic resolutions.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '24th Constitutional Amendment Act, 1971',
          beforeText: 'Article 13 consisted of clauses (1), (2), and (3).',
          afterText: 'Inserted clause (4): "Nothing in this article shall apply to any amendment of this Constitution made under article 368."',
          reason: 'To nullify SC Golaknath judgment (1967) which held constitutional amendments were "law" under Art 13.',
          effectiveDate: DateTime(1971, 11, 5),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of Bombay v. F.N. Balsara',
          year: 1951,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Applied Doctrine of Severability: Invalid provisions of Bombay Prohibition Act struck down while valid portions preserved.',
          importance: 'Established Doctrine of Severability under Art 13.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Bhikaji Narain Dhakras v. State of Madhya Pradesh',
          year: 1955,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Formulated Doctrine of Eclipse: Pre-constitutional law inconsistent with FR remains dormant, obscured by FR, but becomes active if FR is removed/amended.',
          importance: 'Established Doctrine of Eclipse.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Shankari Prasad Singh Deo v. Union of India',
          year: 1951,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held "law" under Art 13(2) refers to ordinary legislative laws, not constitutional amendments under Art 368.',
          importance: 'First SC ruling on Art 13 vs Art 368.',
          status: 'Overruled by Golaknath, then modified by Kesavananda',
        ),
        ArticleCaseLawRecord(
          caseName: 'I.C. Golaknath v. State of Punjab',
          year: 1967,
          bench: 'Supreme Court (11-Judge Bench)',
          legalPrinciple:
              'Ruled that Constitutional Amendments are "law" under Art 13(2) and Parliament cannot abridge FRs.',
          importance: 'Triggered 24th Amendment Act 1971.',
          status: 'Overruled by Kesavananda Bharati',
        ),
        ArticleCaseLawRecord(
          caseName: 'Kesavananda Bharati v. State of Kerala',
          year: 1973,
          bench: 'Supreme Court (13-Judge Bench)',
          legalPrinciple:
              'Upheld validity of Art 13(4). Ruled Parliament can amend any part of Constitution including FRs, but cannot alter the Basic Structure.',
          importance: 'Basic Structure Doctrine founded.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-XX'],
      relatedArticles: const ['Article 12', 'Article 32', 'Article 226', 'Article 368'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART13', 'PYQ_UPSC_2020_ART13', 'PYQ_CDS_2022_ART13'],
      pyqIds: const ['PYQ_UPSC_2017_ART13', 'PYQ_UPSC_2020_ART13', 'PYQ_CDS_2022_ART13'],
      learningObjectives: const [
        'Understand Doctrine of Eclipse and Doctrine of Severability.',
        'Explain the relationship between Article 13(2) and Article 368.',
        'Identify what constitutes "law" under Article 13(3).'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Art 13(1): Pre-constitutional laws (Eclipse applies).',
        'Art 13(2): Post-constitutional laws (Void ab initio).',
        'Art 13(3): Definition of law (Ordinances, rules, customs, usages).',
        'Art 13(4): 24th Amendment 1971 (Art 368 amendments exempt from Art 13).'
      ],
      trapAreas: const [
        'Confusing Doctrine of Eclipse with post-constitutional laws (Eclipse applies primarily to pre-constitutional laws).',
        'Believing personal laws are automatically invalidated by Art 13 (SC in Narasu Appa Mali held personal laws outside Art 13).'
      ],
      frequentlyConfusedWith: const ['Article 368 (Amendment Power)', 'Article 32'],
      timesAsked: 18,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 10, 'StatePSC': 5, 'CDS': 3},
      difficultyDistribution: const {'Easy': 1, 'Medium': 5, 'Hard': 12},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1955 SC 781 (Bhikaji Narain)',
        '(1973) 4 SCC 225 (Kesavananda Bharati)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_KESAVANANDA_1973', 'REF_SC_BHIKAJI_1955'],
    ),

    // ------------------------------------------------------------------------
    // Article 14: Equality before Law & Equal Protection of Laws
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-14',
      articleNumber: '14',
      officialTitle: 'Equality before law',
      part: 'Part III',
      chapter: 'Right to Equality',
      originalNumber: '14',
      currentNumber: '14',
      title: 'Article 14: Equality before law and equal protection of laws',
      officialName: 'ARTICLE 14',
      description:
          'The State shall not deny to any person equality before the law or the equal protection of the laws within the territory of India.',
      officialConstitutionalText:
          'The State shall not deny to any person equality before the law or the equal protection of the laws within the territory of India.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 14 contains two distinct concepts: 1) "Equality before the law" (derived from British Common Law / AV Dicey Rule of Law - negative concept, no special privileges for anyone), and 2) "Equal protection of the laws" (derived from US Constitution - positive concept, equal treatment under equal circumstances). Article 14 permits reasonable classification of persons/objects for legislative purposes, but prohibits class legislation.',
      searchKeywords: const [
        'Article 14',
        'Equality before law',
        'Equal protection of laws',
        'Rule of Law',
        'Reasonable classification',
        'Manifest arbitrariness',
        'EP Royappa',
        'Maneka Gandhi'
      ],
      keyTakeaways: const [
        'Applies to ALL persons (citizens and foreigners/aliens, legal corporations).',
        '"Equality before law" is British negative concept; "Equal protection of laws" is American positive concept.',
        'Test of Reasonable Classification (Ram Krishna Dalmia): 1) Intelligible Differentia, 2) Rational Nexus with objective.',
        'New Doctrine of Equality (EP Royappa / Maneka Gandhi): Equality is dynamic; arbitrariness is antithetical to equality.',
        'Manifest Arbitrariness test reaffirmed in Shayara Bano (2017).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 14 commands identical treatment for all individuals regardless of circumstance. Reality: It commands equal treatment for equals, allowing reasonable classification.',
        'Misconception: Article 14 only applies to Indian citizens. Reality: It applies to "any person" including foreigners and corporate bodies.'
      ],
      memoryAids: const [
        'Mnemonic - B-A-U: British negative (Equality Before), American positive (Equal Protection), Universal applicability.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on November 29, 1948 (Draft Article 9). Influenced by Article 1 of Universal Declaration of Human Rights (1948) and the 14th Amendment of the US Constitution.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (November 29, 1948) - Speeches by K.M. Munshi, Dr. B.R. Ambedkar.',
        'Emphasis on ensuring state power cannot act arbitrarily against any individual.'
      ],
      objectivesResolutionLinks: const [
        'Directly reflects the promise of "EQUALITY of status and of opportunity" in the Preamble & Objectives Resolution.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of West Bengal v. Anwar Ali Sarkar',
          year: 1952,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Struck down Special Courts Act giving unguided discretion to Executive to refer cases to special courts as violating Art 14.',
          importance: 'Early application of Art 14 to executive discretion.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Ram Krishna Dalmia v. Justice S.R. Tendolkar',
          year: 1958,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Formulated twin test of Reasonable Classification: 1) Intelligible differentia, 2) Rational nexus to object sought to be achieved.',
          importance: 'Classic Doctrine of Classification under Art 14.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'E.P. Royappa v. State of Tamil Nadu',
          year: 1974,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Justice Bhagwati introduced New Doctrine: "Equality is a dynamic concept. Arbitrariness is the antithesis of equality."',
          importance: 'Shift from classification test to non-arbitrariness.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Maneka Gandhi v. Union of India',
          year: 1978,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Interlinked Articles 14, 19, and 21 (Golden Triangle). Procedure under Art 21 must be just, fair, and reasonable, satisfying Art 14.',
          importance: 'Golden Triangle of Fundamental Rights.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Shayara Bano v. Union of India',
          year: 2017,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Struck down Instant Triple Talaq (Talaq-e-Biddat) as unconstitutional under Art 14 for being manifestly arbitrary.',
          importance: 'Manifest Arbitrariness doctrine applied.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 15', 'Article 16', 'Article 19', 'Article 21', 'Article 323A'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART14', 'PYQ_UPSC_2021_ART14', 'PYQ_NDA_2020_ART14'],
      pyqIds: const ['PYQ_UPSC_2018_ART14', 'PYQ_UPSC_2021_ART14', 'PYQ_NDA_2020_ART14'],
      learningObjectives: const [
        'Differentiate between Equality before law and Equal protection of laws.',
        'State the two conditions of the Ram Krishna Dalmia classification test.',
        'Explain the Golden Triangle (Articles 14, 19, 21).'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Equality before law (British) vs Equal protection (American).',
        'Ram Krishna Dalmia (1958): Intelligible Differentia + Rational Nexus.',
        'EP Royappa (1974) & Maneka Gandhi (1978): Non-arbitrariness doctrine.',
        'Shayara Bano (2017): Manifest Arbitrariness test.'
      ],
      trapAreas: const [
        'Believing Article 14 forbids all classification (it permits reasonable classification, bans class legislation).',
        'Assuming Article 14 only benefits Indian citizens (it covers all persons).'
      ],
      frequentlyConfusedWith: const ['Article 15 (Non-discrimination on specific grounds)'],
      timesAsked: 22,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 12, 'StatePSC': 6, 'CDS': 4},
      difficultyDistribution: const {'Easy': 2, 'Medium': 8, 'Hard': 12},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1958 SC 538 (Ram Krishna Dalmia)',
        'AIR 1974 SC 555 (EP Royappa)',
        '(2017) 9 SCC 1 (Shayara Bano)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_MANEKA_1978', 'REF_SC_SHAYARA_BANO_2017'],
    ),

    // ------------------------------------------------------------------------
    // Article 15: Prohibition of Discrimination
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-15',
      articleNumber: '15',
      officialTitle: 'Prohibition of discrimination on grounds of religion, race, caste, sex or place of birth',
      part: 'Part III',
      chapter: 'Right to Equality',
      originalNumber: '15',
      currentNumber: '15',
      title: 'Article 15: Non-discrimination & Special Affirmative Provisions',
      officialName: 'ARTICLE 15',
      description:
          '(1) The State shall not discriminate against any citizen on grounds only of religion, race, caste, sex, place of birth or any of them.\n(2) No citizen shall, on grounds only of religion, race, caste, sex, place of birth or any of them, be subject to any disability, liability, restriction or condition with regard to access to shops, public restaurants, hotels and places of public entertainment; or the use of wells, tanks, bathing ghats, roads and places of public resort maintained wholly or partly out of State funds or dedicated to the use of the general public.\n(3) Nothing in this article shall prevent the State from making any special provision for women and children.\n(4) [Added by 1st Amendment 1951] Special provisions for advancement of SEBCs, SCs, and STs.\n(5) [Added by 93rd Amendment 2005] Reservation in educational institutions (including private, aided or unaided, except minority institutions under Art 30(1)).\n(6) [Added by 103rd Amendment 2019] Special provisions & up to 10% reservation for Economically Weaker Sections (EWS).',
      officialConstitutionalText:
          '(1) The State shall not discriminate against any citizen on grounds only of religion, race, caste, sex, place of birth or any of them.\n(2) No citizen shall, on grounds only of religion, race, caste, sex, place of birth or any of them, be subject to any disability, liability, restriction or condition with regard to access to shops, public restaurants, hotels and places of public entertainment; or the use of wells, tanks, bathing ghats, roads and places of public resort maintained wholly or partly out of State funds or dedicated to the use of the general public.\n(3) Nothing in this article shall prevent the State from making any special provision for women and children.\n(4) Nothing in this article or in clause (2) of article 29 shall prevent the State from making any special provision for the advancement of any socially and educationally backward classes of citizens or for the Scheduled Castes and the Scheduled Tribes.\n(5) Nothing in this article or in sub-clause (g) of clause (1) of article 19 shall prevent the State from making any special provision, by law, for the advancement of any socially and educationally backward classes of citizens or for the Scheduled Castes or the Scheduled Tribes in so far as such special provisions relate to their admission to educational institutions including private educational institutions, whether aided or unaided by the State, other than the minority educational institutions referred to in clause (1) of article 30.\n(6) Nothing in this article or sub-clause (g) of clause (1) of article 19 or clause (2) of article 29 shall prevent the State from making special provisions/reservation for Economically Weaker Sections...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 15 guarantees non-discrimination specifically to CITIZENS on 5 prohibited grounds (Religion, Race, Caste, Sex, Place of birth). Word "only" means discrimination based on these grounds combined with other factors (e.g. physical requirement, qualifications) may be valid. Clauses 15(3), 15(4), 15(5), and 15(6) act as enabling provisions for affirmative action for women/children, SEBCs/SCs/STs, private educational admissions, and EWS.',
      searchKeywords: const [
        'Article 15',
        'Prohibition of discrimination',
        '5 grounds of discrimination',
        'Champakam Dorairajan',
        'Article 15(4) 1st Amendment',
        'Article 15(5) 93rd Amendment',
        'Article 15(6) 103rd Amendment EWS',
        'OBC Reservation in Education'
      ],
      keyTakeaways: const [
        'Guaranteed ONLY to Citizens of India.',
        '5 Prohibited Grounds: Religion, Race, Caste, Sex, Place of Birth (Mnemonic: R-R-C-S-P).',
        'Art 15(2) is enforceable against BOTH State and private citizens regarding access to public places.',
        'Art 15(4) added by 1st Amendment Act 1951 after Champakam Dorairajan case.',
        'Art 15(5) added by 93rd Amendment Act 2005 (upheld in Ashoka Kumar Thakur 2008). Exempts minority institutions.',
        'Art 15(6) added by 103rd Amendment Act 2019 (10% EWS reservation in education, upheld in Janhit Abhiyan 2022).'
      ],
      commonMisconceptions: const [
        'Misconception: Residence is a prohibited ground under Article 15. Reality: Place of birth is prohibited, but residence is NOT prohibited under Art 15 (though regulated under Art 16(3)).',
        'Misconception: Article 15(5) covers minority educational institutions. Reality: Minority educational institutions under Art 30(1) are explicitly exempted.'
      ],
      memoryAids: const [
        'Mnemonic - RRCSP: Religion, Race, Caste, Sex, Place of birth (5 grounds).',
        'Mnemonic - Amendments: 1st (15.4), 93rd (15.5), 103rd (15.6).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on November 29, 1948 (Draft Article 9). Designed to dismantle historic social discrimination, untouchability in public spaces, and educational exclusion.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (November 29, 1948) - Debates on discrimination in public wells/ghats.',
        'Contributions by Rev. Jerome D\'Souza, Ambedkar, and Jaspat Roy Kapoor.'
      ],
      objectivesResolutionLinks: const [
        'Translates social justice commitments into explicit statutory guarantees.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '1st Constitutional Amendment Act, 1951',
          beforeText: 'Article 15 consisted of clauses (1), (2), and (3).',
          afterText: 'Inserted clause (4): Special provisions for SEBCs, SCs, and STs in education.',
          reason: 'To overcome SC ruling in State of Madras v. Champakam Dorairajan (1951).',
          effectiveDate: DateTime(1951, 6, 18),
        ),
        ArticleAmendmentRecord(
          amendmentName: '93rd Constitutional Amendment Act, 2005',
          beforeText: 'Article 15 had clauses (1) to (4).',
          afterText: 'Inserted clause (5): Reservation in private aided/unaided educational institutions.',
          reason: 'To enable OBC/SC/ST reservations in private professional colleges.',
          effectiveDate: DateTime(2006, 1, 20),
        ),
        ArticleAmendmentRecord(
          amendmentName: '103rd Constitutional Amendment Act, 2019',
          beforeText: 'Article 15 had clauses (1) to (5).',
          afterText: 'Inserted clause (6): Up to 10% reservation for Economically Weaker Sections (EWS).',
          reason: 'To provide affirmative action based purely on economic criteria.',
          effectiveDate: DateTime(2019, 1, 14),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of Madras v. Champakam Dorairajan',
          year: 1951,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Struck down communal G.O. reserving seats in medical colleges. Held DPSP cannot override FRs.',
          importance: 'Led directly to the 1st Constitutional Amendment Act 1951 inserting Art 15(4).',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'M.R. Balaji v. State of Mysore',
          year: 1963,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held backwardness under Art 15(4) must be both social and educational. Total reservation should not exceed 50%.',
          importance: 'Set 50% ceiling rule for reservations.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Ashoka Kumar Thakur v. Union of India',
          year: 2008,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld validity of 93rd Amendment inserting Art 15(5) for 27% OBC reservation in central educational institutions (IITs/IIMs), excluding creamy layer.',
          importance: 'Upheld Art 15(5) OBC quota in higher education.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Janhit Abhiyan v. Union of India',
          year: 2022,
          bench: 'Supreme Court (5-Judge Bench - 3:2 Majority)',
          legalPrinciple:
              'Upheld 103rd Constitutional Amendment inserting Art 15(6) and 16(6) for 10% EWS reservation. Held economic criteria alone is valid and does not violate Basic Structure.',
          importance: 'Upheld EWS Constitutional Validity.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV', 'KO-PART-XVI'],
      relatedArticles: const ['Article 14', 'Article 16', 'Article 29', 'Article 30', 'Article 46'],
      relatedPYQs: const ['PYQ_UPSC_2016_ART15', 'PYQ_UPSC_2019_ART15', 'PYQ_CAPF_2021_ART15'],
      pyqIds: const ['PYQ_UPSC_2016_ART15', 'PYQ_UPSC_2019_ART15', 'PYQ_CAPF_2021_ART15'],
      learningObjectives: const [
        'Memorize the 5 prohibited grounds under Article 15.',
        'Trace the amendment history of Article 15 (1st, 93rd, 103rd Amendments).',
        'Distinguish between Art 15(4), 15(5), and 15(6).'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Applies only to Citizens.',
        '5 grounds: Religion, Race, Caste, Sex, Place of Birth (Residence NOT included).',
        '15(3): Women & Children special provisions.',
        '15(4): 1st Amendment 1951 (SEBC/SC/ST advancement).',
        '15(5): 93rd Amendment 2005 (Private educational instt, exempting Art 30 minority instt).',
        '15(6): 103rd Amendment 2019 (10% EWS quota).'
      ],
      trapAreas: const [
        'Confusing "Place of birth" with "Residence" (Residence is NOT a prohibited ground under Art 15).',
        'Believing Art 15(5) applies to minority institutions under Art 30(1) (Minority institutions are explicitly excluded).'
      ],
      frequentlyConfusedWith: const ['Article 16 (Employment equality)', 'Article 29(2) (State aided instt admissions)'],
      timesAsked: 25,
      lastAskedYear: 2023,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 14, 'StatePSC': 7, 'CDS': 4},
      difficultyDistribution: const {'Easy': 3, 'Medium': 8, 'Hard': 14},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1951 SC 226 (Champakam Dorairajan)',
        '(2008) 6 SCC 1 (Ashoka Kumar Thakur)',
        '(2023) 5 SCC 1 (Janhit Abhiyan)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_CHAMPAKAM_1951', 'REF_SC_JANHIT_2022'],
    ),

    // ------------------------------------------------------------------------
    // Article 16: Equality of Opportunity in Public Employment
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-16',
      articleNumber: '16',
      officialTitle: 'Equality of opportunity in matters of public employment',
      part: 'Part III',
      chapter: 'Right to Equality',
      originalNumber: '16',
      currentNumber: '16',
      title: 'Article 16: Public Employment Equality & Reservation Mechanics',
      officialName: 'ARTICLE 16',
      description:
          '(1) There shall be equality of opportunity for all citizens in matters relating to employment or appointment to any office under the State.\n(2) No citizen shall, on grounds only of religion, race, caste, sex, descent, place of birth, residence or any of them, be ineligible for, or discriminated against in respect of, any employment or office under the State.\n(3) Parliament power to prescribe residence requirement by law.\n(4) Reservation for backward classes not adequately represented.\n(4A) [77th Amd 1995 & 85th Amd 2001] Reservation in promotion with consequential seniority for SCs/STs.\n(4B) [81st Amd 2000] Carry forward of unfilled backlog vacancies (exempt from 50% limit).\n(5) Religion office requirement exception.\n(6) [103rd Amd 2019] Up to 10% EWS reservation in public employment.',
      officialConstitutionalText:
          '(1) There shall be equality of opportunity for all citizens in matters relating to employment or appointment to any office under the State.\n(2) No citizen shall, on grounds only of religion, race, caste, sex, descent, place of birth, residence or any of them, be ineligible for, or discriminated against in respect of, any employment or office under the State.\n(3) Nothing in this article shall prevent Parliament from making any law prescribing, in regard to a class or classes of employment or appointment to an office under the Government of, or any local or other authority within, a State or Union territory, any requirement as to residence within that State or Union territory prior to such employment or appointment.\n(4) Nothing in this article shall prevent the State from making any provision for the reservation of appointments or posts in favour of any backward class of citizens which, in the opinion of the State, is not adequately represented in the services under the State.\n(4A) Nothing in this article shall prevent the State from making any provision for reservation in matters of promotion, with consequential seniority, to any class or classes of posts in the services under the State in favour of the Scheduled Castes and the Scheduled Tribes which, in the opinion of the State, are not adequately represented in the services under the State.\n(4B) Nothing in this article shall prevent the State from considering any unfilled vacancies of a year which are reserved for being filled up in that year in accordance with any provision for reservation made under clause (4) or clause (4A) as a separate class of vacancies to be filled up in any succeeding year or years...\n(5) Religious office exception...\n(6) Up to 10% EWS reservation...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 16 guarantees equality of opportunity in public employment for CITIZENS. Clause (2) adds TWO grounds over Art 15: "Descent" and "Residence" (total 7 prohibited grounds: Religion, Race, Caste, Sex, Descent, Place of Birth, Residence). Clause (3) allows PARLIAMENT ALONE (not State Legislatures) to prescribe residence conditions. Clauses (4), (4A), (4B), and (6) govern reservation for backward classes, SC/ST promotions, backlog vacancies, and EWS.',
      searchKeywords: const [
        'Article 16',
        'Public Employment Equality',
        '7 prohibited grounds',
        'Indra Sawhney Mandal Case',
        'Creamy Layer',
        'Article 16(4A) 77th Amendment',
        'Article 16(4B) 81st Amendment',
        'Consequential Seniority 85th Amendment',
        'M Nagaraj Case',
        'Jarnail Singh Case'
      ],
      keyTakeaways: const [
        'Guaranteed ONLY to Citizens.',
        '7 Prohibited Grounds in Art 16(2): Religion, Race, Caste, Sex, Descent, Place of Birth, Residence (Mnemonic: R-R-C-S-D-P-R).',
        'ONLY Parliament can make laws specifying residence criteria under Art 16(3).',
        'Indra Sawhney (1992): 27% OBC reservation upheld, 50% cap fixed, creamy layer excluded, reservations restricted to initial appointments (no promotions).',
        '77th Amd (1995) & 85th Amd (2001): Introduced Art 16(4A) allowing SC/ST reservation in promotions with consequential seniority.',
        '81st Amd (2000): Introduced Art 16(4B) allowing carry forward of backlog vacancies past 50% cap.',
        'M. Nagaraj (2006) & Jarnail Singh (2018): Upheld 16(4A) & 16(4B), applied creamy layer to SC/ST promotions.'
      ],
      commonMisconceptions: const [
        'Misconception: State Legislatures can pass laws reserving jobs for local residents. Reality: Art 16(3) vests this power EXCLUSIVELY in Parliament.',
        'Misconception: Carry forward backlog vacancies are bound by the 50% annual reservation ceiling. Reality: Art 16(4B) explicitly exempts backlog vacancies from 50% ceiling.'
      ],
      memoryAids: const [
        'Mnemonic - Ground count: Art 15 has 5 grounds; Art 16 adds 2 more (Descent + Residence) = 7 grounds.',
        'Mnemonic - Amendments: 77th (Promotion), 81st (Backlog 50% bypass), 85th (Consequential Seniority), 103rd (EWS).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on November 30, 1948 (Draft Article 10). Dr. Ambedkar framed Clause (4) to reconcile equality of opportunity with equal representation for historically suppressed communities.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (November 30, 1948) - Intense debate on meaning of "backward class".',
        'Speeches by Dr. B.R. Ambedkar, Damodar Swarup Seth, H.N. Kunzru.'
      ],
      objectivesResolutionLinks: const [
        'Translates public service equity objectives into enforceable constitutional clauses.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '77th Constitutional Amendment Act, 1995',
          beforeText: 'Article 16 had clauses (1) to (4).',
          afterText: 'Inserted clause (4A): Reservation in promotion for SCs and STs.',
          reason: 'To overcome Indra Sawhney ruling barring reservation in promotions.',
          effectiveDate: DateTime(1995, 6, 17),
        ),
        ArticleAmendmentRecord(
          amendmentName: '81st Constitutional Amendment Act, 2000',
          beforeText: 'Article 16 lacked specific backlog carry forward clause.',
          afterText: 'Inserted clause (4B): Backlog unfilled vacancies exempt from 50% ceiling.',
          reason: 'To protect carry-forward posts for SCs/STs from 50% limit.',
          effectiveDate: DateTime(2000, 6, 9),
        ),
        ArticleAmendmentRecord(
          amendmentName: '85th Constitutional Amendment Act, 2001',
          beforeText: 'Clause (4A) did not explicitly state "consequential seniority".',
          afterText: 'Amended clause (4A) to include "with consequential seniority" retrospectively from June 1995.',
          reason: 'To protect seniority of SC/ST candidates promoted via reservation.',
          effectiveDate: DateTime(2002, 1, 4),
        ),
        ArticleAmendmentRecord(
          amendmentName: '103rd Constitutional Amendment Act, 2019',
          beforeText: 'Article 16 had clauses (1) to (5).',
          afterText: 'Inserted clause (6): Up to 10% EWS reservation in public employment.',
          reason: 'To grant economic reservation in government jobs.',
          effectiveDate: DateTime(2019, 1, 14),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'General Manager, Southern Railway v. Rangachari',
          year: 1962,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Initially held Art 16(4) includes reservation in promotions as well as initial appointments.',
          importance: 'Early SC position on promotion reservation.',
          status: 'Overruled by Indra Sawhney 1992',
        ),
        ArticleCaseLawRecord(
          caseName: 'Indra Sawhney v. Union of India (Mandal Case)',
          year: 1992,
          bench: 'Supreme Court (9-Judge Bench)',
          legalPrinciple:
              'Upheld 27% OBC reservation. Ruled: 1) Total reservation must not exceed 50%, 2) Creamy layer must be excluded, 3) Reservation confined to initial appointments (no promotions), 4) Backwardness cannot be determined solely by economic criteria.',
          importance: 'Watershed judgment on reservation law in India.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'M. Nagaraj v. Union of India',
          year: 2006,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld constitutional validity of 77th, 81st, 82nd, 85th Amendments. Imposed 3 mandatory conditions for SC/ST promotion quota: 1) Backwardness data, 2) Inadequate representation, 3) Maintenance of administrative efficiency (Art 335).',
          importance: 'Validation of 16(4A) & 16(4B) with conditions.',
          status: 'Modified by Jarnail Singh 2018',
        ),
        ArticleCaseLawRecord(
          caseName: 'Jarnail Singh v. Lachhmi Narain Gupta',
          year: 2018,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Modified Nagaraj: State does NOT need to collect quantifiable data on backwardness of SCs/STs (presumed backward). However, Creamy Layer test DOES apply to SC/ST promotion reservations.',
          importance: 'Creamy Layer extended to SC/ST promotions.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-XVI'],
      relatedArticles: const ['Article 14', 'Article 15', 'Article 335', 'Article 340'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART16', 'PYQ_UPSC_2020_ART16', 'PYQ_CAPF_2022_ART16'],
      pyqIds: const ['PYQ_UPSC_2017_ART16', 'PYQ_UPSC_2020_ART16', 'PYQ_CAPF_2022_ART16'],
      learningObjectives: const [
        'List the 7 prohibited grounds under Article 16(2).',
        'Analyze the Indra Sawhney 9-Judge Bench guidelines.',
        'Compare Art 16(4A), 16(4B), and 16(6) amendment provisions.'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        '7 grounds: Religion, Race, Caste, Sex, Descent, Place of birth, Residence.',
        'Art 16(3): Residence power ONLY with Parliament.',
        'Indra Sawhney (1992): 27% OBC quota, 50% cap, Creamy layer exclusion.',
        '16(4A): 77th & 85th Amd (SC/ST Promotion + Consequential Seniority).',
        '16(4B): 81st Amd (Backlog 50% bypass).',
        'Jarnail Singh (2018): Creamy layer applies to SC/ST promotions.'
      ],
      trapAreas: const [
        'Believing State Legislatures can prescribe residence for state jobs (ONLY Parliament has this power under Art 16(3)).',
        'Confusing Art 15 grounds (5 grounds) with Art 16 grounds (7 grounds - adds Descent & Residence).'
      ],
      frequentlyConfusedWith: const ['Article 15', 'Article 335 (Efficiency of administration)'],
      timesAsked: 28,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 16, 'StatePSC': 8, 'CDS': 4},
      difficultyDistribution: const {'Easy': 2, 'Medium': 8, 'Hard': 18},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1993 SC 477 (Indra Sawhney)',
        '(2006) 8 SCC 212 (M Nagaraj)',
        '(2018) 10 SCC 396 (Jarnail Singh)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_INDRA_SAWHNEY_1992', 'REF_SC_JARNAIL_2018'],
    ),

    // ------------------------------------------------------------------------
    // Article 17: Abolition of Untouchability
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-17',
      articleNumber: '17',
      officialTitle: 'Abolition of Untouchability',
      part: 'Part III',
      chapter: 'Right to Equality',
      originalNumber: '17',
      currentNumber: '17',
      title: 'Article 17: Abolition of Untouchability',
      officialName: 'ARTICLE 17',
      description:
          '"Untouchability" is abolished and its practice in any form is forbidden. The enforcement of any disability arising out of "Untouchability" shall be an offence punishable in accordance with law.',
      officialConstitutionalText:
          '"Untouchability" is abolished and its practice in any form is forbidden. The enforcement of any disability arising out of "Untouchability" shall be an offence punishable in accordance with law.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 17 completely abolishes "Untouchability" in any form. It is an absolute right (no exceptions/restrictions). The word "Untouchability" is NOT defined in the Constitution or any statute; Mysore High Court (Devarajiah case) clarified it refers to historical social practice of imposing disabilities on persons due to birth in certain castes. Enforceable against BOTH State and private individuals. Enacted via Untouchability (Offences) Act 1955 -> Protection of Civil Rights Act 1955 -> SC & ST (Prevention of Atrocities) Act 1989.',
      searchKeywords: const [
        'Article 17',
        'Abolition of Untouchability',
        'Protection of Civil Rights Act 1955',
        'SC ST Prevention of Atrocities Act 1989',
        'Absolute Right',
        'Enforceable against private individuals'
      ],
      keyTakeaways: const [
        'Absolute Fundamental Right without any statutory exceptions.',
        'Enforceable against BOTH State and private individuals.',
        'Word "Untouchability" is NOT defined in the Constitution.',
        'Parliament enacted Untouchability (Offences) Act, 1955 under Art 35 (renamed Protection of Civil Rights Act in 1976).',
        'SC & ST (Prevention of Atrocities) Act, 1989 is the current stringent legislative enactment under Art 17 & Art 35.'
      ],
      commonMisconceptions: const [
        'Misconception: "Untouchability" is defined in the Protection of Civil Rights Act. Reality: Neither the Constitution nor any Act defines the term explicitly.',
        'Misconception: Article 17 is only enforceable against state officials. Reality: It is enforceable against any private individual who practices untouchability.'
      ],
      memoryAids: const [
        'Mnemonic - 17 = Absolute Clean Sweep (Abolition of Untouchability).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on November 29, 1948 amid resounding cheers of "Mahatma Gandhi ki Jai". Spearheaded by Dr. B.R. Ambedkar to root out the centuries-old systemic caste oppression.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (November 29, 1948) - historic debate on Draft Article 11.',
        'Speeches by V.I. Muniswamy Pillai, Monomohan Das, K.T. Shah, and B.R. Ambedkar.'
      ],
      objectivesResolutionLinks: const [
        'Fulfills core promise of Dignity of the Individual in Preamble.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'People\'s Union for Democratic Rights (PUDR) v. Union of India',
          year: 1982,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Held Art 17 is enforceable against private individuals and it is the constitutional duty of State to ensure compliance.',
          importance: 'Enforceability against private persons confirmed.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'State of Karnataka v. Appa Balu Ingale',
          year: 1995,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Abolition of untouchability is the cornerstone of human rights in Indian democracy; strict enforcement of civil rights act mandated.',
          importance: 'Human rights foundation of Article 17.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Prathvi Raj Chauhan v. Union of India',
          year: 2020,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Upheld 2018 amendment to SC/ST Prevention of Atrocities Act restoring bar on anticipatory bail (Section 18A).',
          importance: 'Upheld stringent SC/ST Atrocities Act.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 15', 'Article 23', 'Article 35'],
      relatedPYQs: const ['PYQ_UPSC_2015_ART17', 'PYQ_UPSC_2020_ART17', 'PYQ_CDS_2021_ART17'],
      pyqIds: const ['PYQ_UPSC_2017_ART17', 'PYQ_UPSC_2020_ART17', 'PYQ_CDS_2021_ART17'],
      learningObjectives: const [
        'Explain why Article 17 is classified as an absolute right.',
        'Trace the legislative progression from 1955 Act to 1989 SC/ST Atrocities Act.',
        'Understand judicial interpretation of "untouchability" (Devarajiah case).'
      ],
      difficulty: 'Medium',
      examImportance: 'High',
      revisionPoints: const [
        'Absolute right; no exceptions.',
        'Enforceable against private individuals.',
        'Not defined in Constitution.',
        'Enacted via Art 35 (Protection of Civil Rights Act 1955, SC/ST Act 1989).'
      ],
      trapAreas: const [
        'Selecting options stating "Untouchability is defined in Article 17" (It is NOT defined).',
        'Thinking Article 17 requires state action alone (it binds private individuals too).'
      ],
      frequentlyConfusedWith: const ['Article 15', 'Article 23'],
      timesAsked: 15,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 8, 'StatePSC': 5, 'CDS': 2},
      difficultyDistribution: const {'Easy': 5, 'Medium': 7, 'Hard': 3},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1982 SC 1473 (PUDR)',
        '(2020) 4 SCC 727 (Prathvi Raj Chauhan)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_PUDR_1982', 'REF_SC_PRATHVI_RAJ_2020'],
    ),

    // ------------------------------------------------------------------------
    // Article 18: Abolition of Titles
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-18',
      articleNumber: '18',
      officialTitle: 'Abolition of titles',
      part: 'Part III',
      chapter: 'Right to Equality',
      originalNumber: '18',
      currentNumber: '18',
      title: 'Article 18: Abolition of Titles & National Honours',
      officialName: 'ARTICLE 18',
      description:
          '(1) No title, not being a military or academic distinction, shall be conferred by the State.\n(2) No citizen of India shall accept any title from any foreign State.\n(3) No non-citizen holding office of profit under State shall accept title from foreign State without President\'s consent.\n(4) No person holding office of profit shall accept present/emolument/office from foreign State without President\'s consent.',
      officialConstitutionalText:
          '(1) No title, not being a military or academic distinction, shall be conferred by the State.\n(2) No citizen of India shall accept any title from any foreign State.\n(3) No person who is not a citizen of India shall, while he holds any office of profit or trust under the State, accept without the consent of the President any title from any foreign State.\n(4) No person holding any office of profit or trust under the State shall, without the consent of the President, accept any present, emolument, or office of any kind from or under any foreign State.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 18 abolishes hereditary titles of nobility (e.g. Maharaja, Rai Bahadur, Sir) to enforce democratic equality. Exceptions: Military (e.g. Param Vir Chakra, Major) and Academic distinctions (e.g. Doctor, Professor). National Honours (Bharat Ratna, Padma Vibhushan, Padma Bhushan, Padma Shri) introduced in 1954 were upheld in Balaji Raghavan case (1996) as decorous awards, provided they are NOT used as prefixes or suffixes to recipient names.',
      searchKeywords: const [
        'Article 18',
        'Abolition of titles',
        'National Awards Bharat Ratna',
        'Balaji Raghavan Case',
        'Academic and military distinctions'
      ],
      keyTakeaways: const [
        'Prohibits hereditary titles of nobility.',
        'Exceptions allowed: Military distinctions and Academic distinctions.',
        'Citizens cannot accept foreign titles.',
        'National Awards (Bharat Ratna, Padma Awards) are VALID decorous honours, NOT titles (Balaji Raghavan 1996).',
        'Recipients using Bharat Ratna/Padma awards as prefix/suffix forfeit the award.'
      ],
      commonMisconceptions: const [
        'Misconception: Bharat Ratna and Padma awards are unconstitutional titles under Article 18. Reality: SC ruled in Balaji Raghavan that they are decorations, not prohibited titles under Art 18.',
        'Misconception: Military ranks like General or Captain violate Article 18. Reality: Military distinctions are explicitly exempted under Art 18(1).'
      ],
      memoryAids: const [
        'Mnemonic - 18 = No hereditary royal titles (Equality of nobility).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 1, 1948 (Draft Article 12). Designed to eliminate feudal titles conferred by British Colonial rule that created artificial social hierarchies.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 1, 1948) - Speeches by K.T. Shah, H.V. Kamath, Ambedkar.',
        'Debate on distinguishing awards for merit from aristocratic titles.'
      ],
      objectivesResolutionLinks: const [
        'Reinforces republican equality by eliminating feudal titles.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Balaji Raghavan v. Union of India',
          year: 1996,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld constitutional validity of National Awards (Bharat Ratna, Padma awards). Held they are not "titles" within Art 18 provided they are not used as prefix or suffix.',
          importance: 'National Awards validity established under Art 18.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 14', 'Article 19'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART18', 'PYQ_CDS_2020_ART18'],
      pyqIds: const ['PYQ_UPSC_2018_ART18', 'PYQ_CDS_2020_ART18'],
      learningObjectives: const [
        'Explain the exceptions to Article 18(1) (military and academic distinctions).',
        'State the Supreme Court ruling in Balaji Raghavan regarding National Awards.',
        'Identify rules governing foreign titles for citizens vs non-citizens.'
      ],
      difficulty: 'Easy',
      examImportance: 'Medium',
      revisionPoints: const [
        'Bans aristocratic titles.',
        'Exceptions: Military & Academic distinctions.',
        'Foreign titles barred for Indian citizens.',
        'Bharat Ratna/Padma awards are constitutional (Balaji Raghavan 1996), but cannot be used as name prefix/suffix.'
      ],
      trapAreas: const [
        'Thinking Bharat Ratna is prohibited under Art 18 (It is valid as a decoration, not a title).',
        'Believing non-citizens holding office of profit can accept foreign titles freely (Requires President\'s consent).'
      ],
      frequentlyConfusedWith: const ['Article 14', 'Article 19'],
      timesAsked: 8,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      examDistribution: const {'UPSC': 4, 'StatePSC': 3, 'CDS': 1},
      difficultyDistribution: const {'Easy': 5, 'Medium': 3, 'Hard': 0},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        '(1996) 1 SCC 361 (Balaji Raghavan)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_BALAJI_RAGHAVAN_1996'],
    ),

    // ------------------------------------------------------------------------
    // Article 19: Protection of 6 Fundamental Freedoms
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-19',
      articleNumber: '19',
      officialTitle: 'Protection of certain rights regarding freedom of speech, etc.',
      part: 'Part III',
      chapter: 'Right to Freedom',
      originalNumber: '19',
      currentNumber: '19',
      title: 'Article 19: Six Fundamental Freedoms & Reasonable Restrictions',
      officialName: 'ARTICLE 19',
      description:
          '(1) All citizens shall have the right—\n(a) to freedom of speech and expression;\n(b) to assemble peaceably and without arms;\n(c) to form associations or unions [or co-operative societies];\n(d) to move freely throughout the territory of India;\n(e) to reside and settle in any part of the territory of India; and\n[(f) Right to property - DELETED by 44th Amd 1978]\n(g) to practise any profession, or to carry on any occupation, trade or business.\n(2)-(6) Reasonable Restrictions on ground of sovereignty, security, public order, decency, court contempt, defamation, incitement, trade qualifications, state monopoly.',
      officialConstitutionalText:
          '(1) All citizens shall have the right—\n(a) to freedom of speech and expression;\n(b) to assemble peaceably and without arms;\n(c) to form associations or unions or co-operative societies;\n(d) to move freely throughout the territory of India;\n(e) to reside and settle in any part of the territory of India; and\n(g) to practise any profession, or to carry on any occupation, trade or business.\n(2) Nothing in sub-clause (a) of clause (1) shall affect the operation of any existing law, or prevent the State from making any law, in so far as such law imposes reasonable restrictions on the exercise of the right conferred by the said sub-clause in the interests of the sovereignty and integrity of India, the security of the State, friendly relations with foreign States, public order, decency or morality, or in relation to contempt of court, defamation or incitement to an offence...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 19 guarantees 6 basic democratic freedoms strictly to Indian CITIZENS (not foreigners or corporations). Right to Property (19(1)(f)) was removed by 44th Amendment Act 1978. These rights are NOT absolute; each right is subject to specific "Reasonable Restrictions" laid down under Clauses (2) to (6). "Sovereignty and integrity of India" was added to 19(2) by 16th Amendment Act 1963. Co-operative societies was added to 19(1)(c) by 97th Amendment Act 2011.',
      searchKeywords: const [
        'Article 19',
        'Six Freedoms',
        'Freedom of speech and expression',
        'Reasonable restrictions',
        '44th Amendment Right to Property',
        'Romesh Thappar',
        'Shreya Singhal Sec 66A',
        'Anuradha Bhasin Internet freedom'
      ],
      keyTakeaways: const [
        'Guaranteed ONLY to Citizens of India.',
        '6 Freedoms: 19(1)(a) Speech, (b) Assembly, (c) Association/Co-operatives, (d) Movement, (e) Residence, (g) Trade/Profession.',
        '19(1)(f) Right to Property DELETED by 44th Amendment Act 1978.',
        '19(2) 8 Grounds for restrictions on Speech: Sovereignty & Integrity of India (added by 16th Amd 1963), Security of State, Friendly foreign relations, Public Order, Decency/Morality, Contempt of Court, Defamation, Incitement to offence.',
        'Shreya Singhal (2015): Struck down Sec 66A IT Act for vagueness violating 19(1)(a).',
        'Anuradha Bhasin (2020): Internet access protected under 19(1)(a) & 19(1)(g).'
      ],
      commonMisconceptions: const [
        'Misconception: Foreigners can claim Article 19 freedoms in India. Reality: Article 19 rights are available EXCLUSIVELY to Indian citizens.',
        'Misconception: Right to Strike is a Fundamental Right under Art 19(1)(c). Reality: SC in TK Rangarajan held there is no FR to strike.'
      ],
      memoryAids: const [
        'Mnemonic - SAAMRT: Speech, Assembly, Association, Movement, Residence, Trade (6 freedoms).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 1-2, 1948 (Draft Article 13). Pandit Bhargava and Ambedkar introduced the word "reasonable" before "restrictions" to ensure judicial review over legislative curbs.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 1-2, 1948) - Intense debate on limits of state restrictions.',
        'Pandit Thakur Das Bhargava amendment inserting "reasonable" to empower courts.'
      ],
      objectivesResolutionLinks: const [
        'Embodies Preamble promise of LIBERTY of thought, expression, belief, faith and worship.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '1st Constitutional Amendment Act, 1951',
          beforeText: 'Article 19(2) lacked "Public Order", "Friendly relations with foreign States", "Incitement to offence".',
          afterText: 'Substituted 19(2) adding Public Order, Friendly relations with foreign States, Incitement to offence.',
          reason: 'Overcame Romesh Thappar & Brij Bhushan judgments restricting state control on speech.',
          effectiveDate: DateTime(1951, 6, 18),
        ),
        ArticleAmendmentRecord(
          amendmentName: '16th Constitutional Amendment Act, 1963',
          beforeText: 'Clause (2), (3), (4) lacked "Sovereignty and integrity of India".',
          afterText: 'Added "Sovereignty and integrity of India" as a ground for restrictions across 19(2), 19(3), 19(4).',
          reason: 'Counter secessionist tendencies after National Integration Council recommendations.',
          effectiveDate: DateTime(1963, 10, 5),
        ),
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act, 1978',
          beforeText: 'Article 19(1)(f) guaranteed Right to acquire, hold, and dispose of property.',
          afterText: 'Omitted clause (1)(f) and clause (5) reference to property.',
          reason: 'Removed right to property as a fundamental right; made legal right under Art 300A.',
          effectiveDate: DateTime(1979, 6, 20),
        ),
        ArticleAmendmentRecord(
          amendmentName: '97th Constitutional Amendment Act, 2011',
          beforeText: 'Article 19(1)(c) stated "associations or unions".',
          afterText: 'Inserted "or co-operative societies" into Art 19(1)(c).',
          reason: 'To promote co-operative societies as a fundamental right.',
          effectiveDate: DateTime(2012, 2, 15),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Romesh Thappar v. State of Madras',
          year: 1950,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Freedom of speech includes freedom of circulation of newspapers. State cannot restrict speech merely on ground of "public safety".',
          importance: 'Foundational ruling on press freedom; triggered 1st Amendment.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Bennett Coleman & Co. v. Union of India',
          year: 1972,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Newsprint import control policy restricting page limit of newspapers violated freedom of press under Art 19(1)(a).',
          importance: 'Press freedom protected against newsprint quotas.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Shreya Singhal v. Union of India',
          year: 2015,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Struck down Section 66A of Information Technology Act 2000 in its entirety as unconstitutionally vague and overbroad under Art 19(1)(a) & 19(2).',
          importance: 'Digital free speech milestone.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Anuradha Bhasin v. Union of India',
          year: 2020,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Ruled that freedom of speech & expression and trade/profession over Internet are constitutionally protected under Art 19(1)(a) & 19(1)(g). Indefinite Internet shutdown illegal.',
          importance: 'Internet access declared FR.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Kaushal Kishor v. State of Uttar Pradesh',
          year: 2023,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held grounds for restricting free speech under Art 19(2) are EXHAUSTIVE. Additional restrictions cannot be imposed on Minister speech. Art 19 rights can be enforced horizontally against non-State actors.',
          importance: 'Exhaustiveness of 19(2) grounds & Horizontal application.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 14', 'Article 21', 'Article 300A', 'Article 358'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART19', 'PYQ_UPSC_2021_ART19', 'PYQ_CAPF_2020_ART19'],
      pyqIds: const ['PYQ_UPSC_2017_ART19', 'PYQ_UPSC_2021_ART19', 'PYQ_CAPF_2020_ART19'],
      learningObjectives: const [
        'Identify all 6 freedoms guaranteed under Article 19(1).',
        'Memorize the 8 grounds for reasonable restrictions on free speech under 19(2).',
        'Understand key landmark judgments (Romesh Thappar, Shreya Singhal, Anuradha Bhasin, Kaushal Kishor).'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Applies only to Citizens.',
        '6 freedoms: Speech, Assembly, Association, Movement, Residence, Trade.',
        'Property 19(1)(f) deleted by 44th Amd 1978.',
        '19(2) 8 restrictions: Sovereignty (16th Amd), Security, Foreign relations, Public order, Decency, Contempt, Defamation, Incitement.',
        'Internet freedom protected (Anuradha Bhasin 2020).'
      ],
      trapAreas: const [
        'Believing "Public Interest" is a ground under 19(2) for speech restriction (Public Interest is under 19(5) and 19(6), NOT 19(2)).',
        'Confusing internal movement under 19(1)(d) with foreign travel under Art 21.'
      ],
      frequentlyConfusedWith: const ['Article 21 (Right to life & personal liberty / Foreign travel)'],
      timesAsked: 32,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 18, 'StatePSC': 9, 'CDS': 5},
      difficultyDistribution: const {'Easy': 2, 'Medium': 10, 'Hard': 20},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1950 SC 124 (Romesh Thappar)',
        '(2015) 5 SCC 1 (Shreya Singhal)',
        '(2020) 3 SCC 637 (Anuradha Bhasin)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_ROMESH_THAPPAR_1950', 'REF_SC_SHREYA_SINGHAL_2015'],
    ),

    // ------------------------------------------------------------------------
    // Article 20: Protection in Respect of Conviction for Offences
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-20',
      articleNumber: '20',
      officialTitle: 'Protection in respect of conviction for offences',
      part: 'Part III',
      chapter: 'Right to Freedom',
      originalNumber: '20',
      currentNumber: '20',
      title: 'Article 20: Protection against Ex-post facto, Double Jeopardy & Self-Incrimination',
      officialName: 'ARTICLE 20',
      description:
          '(1) Protection against Ex-post Facto Penal Law: No person shall be convicted of any offence except for violation of a law in force at the time of the commission of the act, nor subjected to penalty greater than prescribed at commission.\n(2) Protection against Double Jeopardy: No person shall be prosecuted and punished more than once for the same offence.\n(3) Protection against Self-Incrimination: No person accused of any offence shall be compelled to be a witness against himself.',
      officialConstitutionalText:
          '(1) No person shall be convicted of any offence except for violation of a law in force at the time of the commission of the act charged as an offence, nor be subjected to a penalty greater than that which might have been inflicted under the law in force at the time of the commission of the offence.\n(2) No person shall be prosecuted and punished more than once for the same offence.\n(3) No person accused of any offence shall be compelled to be a witness against himself.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 20 provides criminal justice safeguards for ALL persons (citizens and non-citizens). Clause 20(1) bars retroactive penal laws and enhancement of penalties (does not apply to civil liabilities or tax laws). Clause 20(2) protects against Double Jeopardy (requires both prosecution AND punishment before a judicial court/tribunal). Clause 20(3) bars compelled self-incrimination for an accused (Selvi case held narco-analysis without consent violates 20(3)). Cannot be suspended even during National Emergency (44th Amendment Act 1978).',
      searchKeywords: const [
        'Article 20',
        'Ex-post facto law',
        'Double jeopardy',
        'Self incrimination',
        'Selvi Narco Analysis Case',
        'Kathi Kalu Oghad',
        'Non-suspendable during Emergency'
      ],
      keyTakeaways: const [
        'Applies to ALL persons (citizens and non-citizens).',
        '20(1) Ex-Post Facto protection applies ONLY to Criminal laws, NOT Civil/Tax laws.',
        '20(2) Double Jeopardy protection requires BOTH prosecution AND punishment in court of law. Departmental inquiries are NOT barred.',
        '20(3) Self-Incrimination applies to accused persons; protects against giving testimonial evidence (thumb impression, handwriting samples allowed - Kathi Kalu Oghad).',
        'Selvi v. State of Karnataka (2010): Involuntary Narco-analysis, Polygraph, Brain mapping violate Art 20(3) & Art 21.',
        'Cannot be suspended during National Emergency under Art 359 (44th Amendment Act 1978).'
      ],
      commonMisconceptions: const [
        'Misconception: Departmental inquiry after court conviction violates Double Jeopardy. Reality: Art 20(2) only bars multiple judicial prosecutions/punishments by courts of law.',
        'Misconception: Giving thumb impressions or DNA samples violates self-incrimination. Reality: SC in Kathi Kalu Oghad held physical evidence is allowed; 20(3) only bars compelled testimonial evidence.'
      ],
      memoryAids: const [
        'Mnemonic - EDS: Ex-post facto (20.1), Double jeopardy (20.2), Self-incrimination (20.3).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 3, 1948 (Draft Article 14). Inspired by US Constitution Article I Sec 9 & 10 (ex-post facto) and 5th Amendment (double jeopardy & self-incrimination).',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 3, 1948) - Speeches by K.T. Shah, Tajamul Husain, Ambedkar.',
        'Focus on preventing executive despotism in criminal prosecution.'
      ],
      objectivesResolutionLinks: const [
        'Secures fundamental legal justice for all accused persons.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act, 1978',
          beforeText: 'Article 20 could be suspended during National Emergency under Art 359.',
          afterText: 'Amended Article 359 ensuring Article 20 and Article 21 CANNOT be suspended even during National Emergency.',
          reason: 'Prevent misuse of Emergency powers experienced during 1975 Emergency.',
          effectiveDate: DateTime(1979, 6, 20),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Maqbool Hussain v. State of Bombay',
          year: 1953,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Confiscation of gold by Sea Customs authority is administrative; subsequent prosecution under FERA in criminal court is NOT double jeopardy under Art 20(2).',
          importance: 'Departmental proceedings distinct from judicial prosecution under 20(2).',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'State of Bombay v. Kathi Kalu Oghad',
          year: 1961,
          bench: 'Supreme Court (11-Judge Bench)',
          legalPrinciple:
              'Compelling an accused to give specimen handwriting, signature, thumb impression, or physical exposure does not violate Art 20(3). "To be a witness" means imparting personal knowledge (testimonial evidence).',
          importance: 'Testimonial vs Physical evidence distinguished under 20(3).',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Selvi v. State of Karnataka',
          year: 2010,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Involuntary administration of Narco-analysis, Polygraph (lie detector), and Brain Electrical Activation Profile (BEAP) tests violates Art 20(3) and Art 21.',
          importance: 'Involuntary neuroscientific tests held unconstitutional under 20(3).',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 21', 'Article 22', 'Article 359'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART20', 'PYQ_UPSC_2021_ART20', 'PYQ_CDS_2019_ART20'],
      pyqIds: const ['PYQ_UPSC_2018_ART20', 'PYQ_UPSC_2021_ART20', 'PYQ_CDS_2019_ART20'],
      learningObjectives: const [
        'Explain the three protections under Article 20.',
        'Distinguish between criminal ex-post facto laws and civil retrospective laws.',
        'Analyze the impact of Selvi (2010) on modern criminal investigation.'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Applies to all persons.',
        '20(1): Criminal ex-post facto barred (civil/tax allowed).',
        '20(2): Double jeopardy requires judicial court prosecution + punishment.',
        '20(3): Self-incrimination bars compelled testimonial evidence.',
        'Cannot be suspended during Emergency (44th Amd 1978).'
      ],
      trapAreas: const [
        'Believing tax laws cannot be enacted retrospectively (Art 20(1) bars ONLY criminal retrospective laws).',
        'Thinking Art 20 can be suspended during National Emergency (Art 20 and 21 CANNOT be suspended).'
      ],
      frequentlyConfusedWith: const ['Article 21', 'Article 22 (Preventive Detention)'],
      timesAsked: 20,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 10, 'StatePSC': 6, 'CDS': 4},
      difficultyDistribution: const {'Easy': 2, 'Medium': 6, 'Hard': 12},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1953 SC 325 (Maqbool Hussain)',
        'AIR 1961 SC 1808 (Kathi Kalu Oghad)',
        '(2010) 7 SCC 1 (Selvi)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_KATHI_KALU_1961', 'REF_SC_SELVI_2010'],
    ),

    // ------------------------------------------------------------------------
    // Article 21: Protection of Life and Personal Liberty
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-21',
      articleNumber: '21',
      officialTitle: 'Protection of life and personal liberty',
      part: 'Part III',
      chapter: 'Right to Freedom',
      originalNumber: '21',
      currentNumber: '21',
      title: 'Article 21: Right to Life and Personal Liberty',
      officialName: 'ARTICLE 21',
      description:
          'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
      officialConstitutionalText:
          'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 21 is the heart and reservoir of Fundamental Rights in the Indian Constitution. Guaranteed to ALL persons (citizens and non-citizens). In AK Gopalan (1950), SC interpreted "procedure established by law" narrowly as statutory procedure. In Maneka Gandhi (1978), SC expanded it to mean "Due Process of Law"—the procedure must be just, fair, and reasonable. Dozens of implicit rights have been read into Art 21: Privacy (Puttaswamy), Clean environment (MC Mehta), Speedy trial (Hussainara Khatoon), Free legal aid (Hoskot), Dignified death (Common Cause). Cannot be suspended during Emergency (44th Amendment Act 1978).',
      searchKeywords: const [
        'Article 21',
        'Right to Life',
        'Personal Liberty',
        'Procedure established by law',
        'Due Process of Law',
        'Maneka Gandhi case',
        'Puttaswamy Right to Privacy',
        'Olga Tellis Livelihood',
        'Golden Triangle'
      ],
      keyTakeaways: const [
        'Applies to ALL persons (citizens and non-citizens).',
        'AK Gopalan (1950) narrow interpretation -> Maneka Gandhi (1978) expansive "Due Process" interpretation.',
        'Procedure depriving life or liberty must be Just, Fair, and Reasonable (satisfying Art 14, 19, 21 Golden Triangle).',
        'Puttaswamy (2017): 9-Judge Bench unanimously declared Right to Privacy an intrinsic part of Art 21.',
        'Common Cause (2018): Right to die with dignity / Passive Euthanasia and Living Will recognized under Art 21.',
        'Cannot be suspended under any circumstances during National Emergency (44th Amendment Act 1978).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 21 only protects physical existence. Reality: "Life" means dignified life with human dignity, not mere animal existence (Francis Coralie Mullin case).',
        'Misconception: Article 21 can be suspended during National Emergency. Reality: 44th Amendment 1978 permanently exempted Art 20 and 21 from suspension under Art 359.'
      ],
      memoryAids: const [
        'Mnemonic - 21 = Foundation of Human Dignity (Life + Liberty + Privacy).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 6, 1948 (Draft Article 15). Drafting Committee replaced US phrase "due process of law" with Japanese formulation "procedure established by law" on advice of Justice Felix Frankfurter to B.N. Rau. Re-infused with Due Process substance by SC in Maneka Gandhi (1978).',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 6, 1948) - Debates on "due process of law" vs "procedure established by law".',
        'Speeches by K.M. Munshi (favoring due process), B.N. Rau, and B.R. Ambedkar.'
      ],
      objectivesResolutionLinks: const [
        'Core realization of Liberty and Dignity of the Individual.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act, 1978',
          beforeText: 'Article 21 could be suspended during Emergency.',
          afterText: 'Amended Article 359 ensuring Article 21 CANNOT be suspended even during National Emergency.',
          reason: 'To protect life and personal liberty from executive tyranny during Emergency.',
          effectiveDate: DateTime(1979, 6, 20),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'A.K. Gopalan v. State of Madras',
          year: 1950,
          bench: 'Supreme Court (6-Judge Bench)',
          legalPrinciple:
              'Narrow literal interpretation: "Procedure established by law" means procedure enacted by law-making body. Articles 14, 19, and 21 treated as mutually exclusive water-tight compartments.',
          importance: 'Initial restrictive view of Art 21.',
          status: 'Overruled by Maneka Gandhi 1978',
        ),
        ArticleCaseLawRecord(
          caseName: 'Maneka Gandhi v. Union of India',
          year: 1978,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Revolutionary ruling: Procedure under Art 21 must be Just, Fair, and Reasonable, incorporating American "Due Process". Interlinked Articles 14, 19, and 21 (Golden Triangle). Right to travel abroad held part of personal liberty.',
          importance: 'Established Indian Due Process & Golden Triangle.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Olga Tellis v. Bombay Municipal Corporation',
          year: 1985,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Right to Livelihood is an integral part of Right to Life under Article 21.',
          importance: 'Right to Livelihood recognized.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Justice K.S. Puttaswamy (Retd.) v. Union of India',
          year: 2017,
          bench: 'Supreme Court (9-Judge Bench)',
          legalPrinciple:
              'Unanimously held Right to Privacy is a fundamental right protected as an intrinsic part of Art 21 and Part III.',
          importance: 'Right to Privacy landmark judgment.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Common Cause v. Union of India',
          year: 2018,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held Right to die with dignity is a fundamental right under Art 21; legalized Passive Euthanasia and Living Will.',
          importance: 'Passive Euthanasia & Living Will legalized.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 14', 'Article 19', 'Article 20', 'Article 21A', 'Article 22', 'Article 359'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART21', 'PYQ_UPSC_2021_ART21', 'PYQ_UPSC_2023_ART21'],
      pyqIds: const ['PYQ_UPSC_2018_ART21', 'PYQ_UPSC_2021_ART21', 'PYQ_UPSC_2023_ART21'],
      learningObjectives: const [
        'Compare AK Gopalan and Maneka Gandhi interpretations of Article 21.',
        'List key implicit rights derived under Article 21 by Supreme Court.',
        'Explain the Puttaswamy Privacy judgment and 3-fold test of proportionality.'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Applies to all persons (citizens + aliens).',
        'Maneka Gandhi (1978): "Procedure established by law" must be Just, Fair & Reasonable (Due Process).',
        'Golden Triangle: Art 14 + Art 19 + Art 21.',
        'Puttaswamy (2017): Right to Privacy is FR.',
        'Common Cause (2018): Right to die with dignity (Passive Euthanasia).',
        'Cannot be suspended in Emergency (44th Amd 1978).'
      ],
      trapAreas: const [
        'Assuming Right to Marry person of choice is under Art 19 (SC in Hadiya case held it is under Art 21).',
        'Thinking foreign travel is under Art 19(1)(d) (Internal movement is 19(1)(d); foreign travel is under Art 21 - Maneka Gandhi).'
      ],
      frequentlyConfusedWith: const ['Article 19(1)(d) (Internal Movement)', 'Article 22'],
      timesAsked: 40,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 22, 'StatePSC': 12, 'CDS': 6},
      difficultyDistribution: const {'Easy': 2, 'Medium': 10, 'Hard': 28},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1978 SC 597 (Maneka Gandhi)',
        '(2017) 10 SCC 1 (Puttaswamy)',
        '(2018) 5 SCC 1 (Common Cause)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_MANEKA_1978', 'REF_SC_PUTTASWAMY_2017'],
    ),

    // ------------------------------------------------------------------------
    // Article 21A: Right to Education
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-21A',
      articleNumber: '21A',
      officialTitle: 'Right to Education',
      part: 'Part III',
      chapter: 'Right to Freedom',
      originalNumber: '21A',
      currentNumber: '21A',
      title: 'Article 21A: Right to Free & Compulsory Education (6-14 years)',
      officialName: 'ARTICLE 21A',
      description:
          'The State shall provide free and compulsory education to all children of the age of six to fourteen years in such manner as the State may, by law, determine.',
      officialConstitutionalText:
          'The State shall provide free and compulsory education to all children of the age of six to fourteen years in such manner as the State may, by law, determine.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 21A was inserted by the 86th Constitutional Amendment Act, 2002 to make free and compulsory education a Fundamental Right for children aged 6 to 14 years. Implemented via the Right of Children to Free and Compulsory Education (RTE) Act, 2009 (enforced April 1, 2010). Section 12(1)(c) of RTE Act mandates 25% quota for disadvantaged children in private non-minority schools (upheld in Society for Unaided Private Schools case 2012).',
      searchKeywords: const [
        'Article 21A',
        'Right to Education',
        '86th Amendment Act 2002',
        'RTE Act 2009',
        'Age group 6 to 14',
        '25% private school quota',
        'Mohini Jain',
        'Unni Krishnan'
      ],
      keyTakeaways: const [
        'Inserted by 86th Constitutional Amendment Act, 2002.',
        'Applies specifically to children aged 6 to 14 years.',
        'Enacted legislatively through RTE Act, 2009 (came into force April 1, 2010).',
        '86th Amendment ALSO added Fundamental Duty Art 51A(k) for parents/guardians AND modified DPSP Art 45 (0-6 years early childhood care).',
        'Pramati Educational Trust (2014): SC held RTE Act non-applicable to minority educational institutions (aided or unaided) under Art 30(1).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 21A guarantees education right from birth to 18 years. Reality: Art 21A applies strictly to age group 6 to 14 years (age 0-6 is under DPSP Art 45).',
        'Misconception: 25% RTE reservation applies to minority schools under Art 30. Reality: Minority educational institutions are completely exempted.'
      ],
      memoryAids: const [
        'Mnemonic - 86 @ 2002: 86th Amd in 2002 added Art 21A for 6-14 age group.'
      ],
      historicalBackground:
          'Originates from DPSP Article 45. SC in Mohini Jain (1992) and Unni Krishnan (1993) declared right to education an implicit part of Art 21. Parliament responded by passing 86th Amendment 2002 to explicitly anchor it in Part III.',
      constituentAssemblyDebates: const [
        'Reflects Constituent Assembly debates on Draft Article 36 (became DPSP Art 45).',
        'Pundit Hirday Nath Kunzru and B.R. Ambedkar envisioned free elementary education within 10 years of Constitution commencement.'
      ],
      objectivesResolutionLinks: const [
        'Empowers citizens through universal elementary literacy.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '86th Constitutional Amendment Act, 2002',
          beforeText: 'No explicit fundamental right to education in Part III.',
          afterText: 'Inserted Article 21A into Part III guaranteeing free & compulsory education for age 6-14.',
          reason: 'Fulfill constitutional commitment to universal primary education.',
          effectiveDate: DateTime(2002, 12, 12),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Mohini Jain v. State of Karnataka',
          year: 1992,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Declared Right to Education as a fundamental right flowing from Right to Life under Art 21; struck down capitation fees in medical colleges.',
          importance: 'First SC declaration of Education as FR.',
          status: 'Modified by Unni Krishnan 1993',
        ),
        ArticleCaseLawRecord(
          caseName: 'Unni Krishnan J.P. v. State of Andhra Pradesh',
          year: 1993,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Refined Mohini Jain: Right to education is a fundamental right under Art 21 ONLY up to age 14 years. Beyond 14, right is subject to state economic capacity.',
          importance: 'Anchored 6-14 age limit for FR to education.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Society for Unaided Private Schools of Rajasthan v. Union of India',
          year: 2012,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Upheld constitutional validity of RTE Act 2009 and 25% reservation for poor children in private unaided non-minority schools under Art 21A.',
          importance: 'Upheld 25% RTE private school quota.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Pramati Educational & Cultural Trust v. Union of India',
          year: 2014,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held RTE Act 2009 insofar as it applies to minority schools (aided or unaided) under Art 30(1) is unconstitutional.',
          importance: 'Exempted Art 30 minority institutions from RTE Act.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV', 'KO-PART-IVA'],
      relatedArticles: const ['Article 21', 'Article 30', 'Article 45', 'Article 51A'],
      relatedPYQs: const ['PYQ_UPSC_2016_ART21A', 'PYQ_UPSC_2019_ART21A', 'PYQ_CDS_2022_ART21A'],
      pyqIds: const ['PYQ_UPSC_2016_ART21A', 'PYQ_UPSC_2019_ART21A', 'PYQ_CDS_2022_ART21A'],
      learningObjectives: const [
        'Identify the Amendment Act that added Article 21A (86th Amendment Act 2002).',
        'State the age bracket covered by Article 21A (6 to 14 years).',
        'Understand the tripartite impact of 86th Amendment (Art 21A, Art 45, Art 51A(k)).'
      ],
      difficulty: 'Medium',
      examImportance: 'High',
      revisionPoints: const [
        'Added by 86th Amd 2002.',
        'Age group: 6 to 14 years.',
        'Enforcing law: RTE Act 2009 (w.e.f. April 1, 2010).',
        '25% private school quota (Upheld 2012, minority schools exempt 2014).'
      ],
      trapAreas: const [
        'Thinking 86th Amendment only added Article 21A (It ALSO changed DPSP Art 45 and added Fundamental Duty 51A(k)).',
        'Believing 25% RTE quota applies to minority institutions under Art 30 (They are exempt).'
      ],
      frequentlyConfusedWith: const ['Article 45 (DPSP early childhood care 0-6 years)', 'Article 51A(k)'],
      timesAsked: 18,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 9, 'StatePSC': 6, 'CDS': 3},
      difficultyDistribution: const {'Easy': 4, 'Medium': 8, 'Hard': 6},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        '(1993) 1 SCC 645 (Unni Krishnan)',
        '(2012) 6 SCC 1 (Society for Unaided Private Schools)',
        '(2014) 8 SCC 1 (Pramati Educational Trust)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(2002, 12, 12),
      evidenceReferences: const ['REF_SC_UNNI_KRISHNAN_1993', 'REF_SC_PRAMATI_2014'],
    ),

    // ------------------------------------------------------------------------
    // Article 22: Protection Against Arrest and Detention
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-22',
      articleNumber: '22',
      officialTitle: 'Protection against arrest and detention in certain cases',
      part: 'Part III',
      chapter: 'Right to Freedom',
      originalNumber: '22',
      currentNumber: '22',
      title: 'Article 22: Punitive & Preventive Detention Safeguards',
      officialName: 'ARTICLE 22',
      description:
          '(1)-(3) Punitive Detention Safeguards: Informed of grounds of arrest as soon as may be, right to consult & be defended by legal practitioner of choice, produced before nearest magistrate within 24 hours (excluding travel time).\nExceptions: Enemy aliens & persons detained under Preventive Detention laws.\n(4)-(7) Preventive Detention Safeguards: Max 3 months detention without Advisory Board report (High Court judges); right to make representation; non-disclosure of facts against public interest.',
      officialConstitutionalText:
          '(1) No person who is arrested shall be detained in custody without being informed, as soon as may be, of the grounds for such arrest nor shall he be denied the right to consult, and to be defended by, a legal practitioner of his choice.\n(2) Every person who is arrested and detained in custody shall be produced before the nearest magistrate within a period of twenty-four hours of such arrest excluding the time necessary for the journey from the place of arrest to the court of the magistrate and no such person shall be detained in custody beyond the said period without the authority of a magistrate.\n(3) Nothing in clauses (1) and (2) shall apply— (a) to any person who for the time being is an enemy alien; or (b) to any person who is arrested or detained under any law providing for preventive detention...\n(4)-(7) Preventive detention rules...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 22 provides safeguards against arrest and detention, divided into two parts: 1) Punitive Detention (Clauses 1-3): Safeguards for criminal arrest (inform grounds, legal counsel, produce before Magistrate in 24 hrs). Exemptions: enemy aliens and preventive detainees. 2) Preventive Detention (Clauses 4-7): Detention without trial to prevent future offense. Maximum period 3 months (44th Amd passed reduction to 2 months, but not enforced by executive notification). Advisory Board must approve extension.',
      searchKeywords: const [
        'Article 22',
        'Punitive detention',
        'Preventive detention',
        '24 hours magistrate rule',
        'Legal practitioner choice',
        'Advisory Board 3 months',
        'DK Basu Guidelines',
        'COFEPOSA NSA UAPA'
      ],
      keyTakeaways: const [
        'Covers BOTH Punitive Detention (post-offense) and Preventive Detention (pre-offense).',
        'Punitive safeguards (24 hr magistrate production, grounds, lawyer) do NOT apply to Enemy Aliens or Preventive Detainees.',
        '24-hour limit EXCLUDES travel time from place of arrest to magistrate.',
        'Preventive detention max period: 3 months (requires Advisory Board approval for extension).',
        'DK Basu (1997): Supreme Court laid down 11 mandatory guidelines for arrest and custody to prevent custodial violence.'
      ],
      commonMisconceptions: const [
        'Misconception: Preventive detention is only applicable during Emergency. Reality: Preventive detention laws exist during peacetime (e.g. NSA, UAPA, COFEPOSA).',
        'Misconception: The 24-hour production rule under 22(2) includes travel time. Reality: Travel time is explicitly EXCLUDED from the 24 hours.'
      ],
      memoryAids: const [
        'Mnemonic - 22 = 24 Hours Rule & 3 Months Advisory Limit.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on September 15-16, 1949 (Draft Article 15A). Dr. Ambedkar framed it as a necessary defense mechanism against preventive detention abuses, ensuring judicial oversight.',
      constituentAssemblyDebates: const [
        'CAD Vol. IX (September 15-16, 1949) - Speeches by Bakshi Tek Chand, Pandit Thakur Das Bhargava, Ambedkar.',
        'Intense opposition to preventive detention in peacetime; compromise reached with Advisory Board safeguards.'
      ],
      objectivesResolutionLinks: const [
        'Provides procedural security against arbitrary executive detention.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act, 1978',
          beforeText: 'Max preventive detention period without Advisory Board was 3 months.',
          afterText: 'Amended Art 22(4) reducing period from 3 months to 2 months and changing Advisory Board composition.',
          reason: 'To curb executive preventive detention powers.',
          effectiveDate: DateTime(1979, 6, 20),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'A.K. Gopalan v. State of Madras',
          year: 1950,
          bench: 'Supreme Court (6-Judge Bench)',
          legalPrinciple:
              'Upheld Preventive Detention Act 1950; held Art 22 is a complete self-contained code for preventive detention.',
          importance: 'First major ruling on preventive detention.',
          status: 'Modified by later expanded jurisprudence',
        ),
        ArticleCaseLawRecord(
          caseName: 'D.K. Basu v. State of West Bengal',
          year: 1997,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Laid down 11 mandatory guidelines to be followed by police during arrest and detention to prevent custodial torture and death.',
          importance: 'Landmark Arrest & Custodial Rights Guidelines.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 20', 'Article 21', 'Article 226'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART22', 'PYQ_UPSC_2021_ART22', 'PYQ_CAPF_2019_ART22'],
      pyqIds: const ['PYQ_UPSC_2017_ART22', 'PYQ_UPSC_2021_ART22', 'PYQ_CAPF_2019_ART22'],
      learningObjectives: const [
        'Differentiate between punitive detention and preventive detention.',
        'List the exceptions to Article 22(1) and 22(2).',
        'State the DK Basu guidelines for arrest.'
      ],
      difficulty: 'High',
      examImportance: 'High',
      revisionPoints: const [
        'Punitive: Grounds + Lawyer choice + Produce before Magistrate in 24 hrs (excluding travel time).',
        'Exceptions: Enemy aliens & Preventive detainees.',
        'Preventive: Max 3 months without Advisory Board approval.',
        'DK Basu (1997) arrest guidelines.'
      ],
      trapAreas: const [
        'Believing the 44th Amendment 2-month preventive detention limit is active (Executive never notified it, so 3 months remains in force).',
        'Including travel time in the 24-hour Magistrate production rule (Travel time is excluded).'
      ],
      frequentlyConfusedWith: const ['Article 20', 'Article 21'],
      timesAsked: 16,
      lastAskedYear: 2022,
      trend: 'Medium-High Frequency',
      examDistribution: const {'UPSC': 8, 'StatePSC': 5, 'CDS': 3},
      difficultyDistribution: const {'Easy': 2, 'Medium': 6, 'Hard': 8},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1950 SC 27 (AK Gopalan)',
        '(1997) 1 SCC 416 (DK Basu)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_AK_GOPALAN_1950', 'REF_SC_DK_BASU_1997'],
    ),

    // ------------------------------------------------------------------------
    // Article 23: Prohibition of Traffic in Human Beings and Forced Labour
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-23',
      articleNumber: '23',
      officialTitle: 'Prohibition of traffic in human beings and forced labour',
      part: 'Part III',
      chapter: 'Right against Exploitation',
      originalNumber: '23',
      currentNumber: '23',
      title: 'Article 23: Prohibition of Human Trafficking, Begar & Forced Labour',
      officialName: 'ARTICLE 23',
      description:
          '(1) Traffic in human beings and begar and other similar forms of forced labour are prohibited and any contravention of this provision shall be an offence punishable in accordance with law.\n(2) Exemption: Nothing in this article shall prevent the State from imposing compulsory service for public purposes (without discrimination on grounds of religion, race, caste, or class).',
      officialConstitutionalText:
          '(1) Traffic in human beings and begar and other similar forms of forced labour are prohibited and any contravention of this provision shall be an offence punishable in accordance with law.\n(2) Nothing in this article shall prevent the State from imposing compulsory service for public purposes, and in imposing such service the State shall not make any discrimination on grounds only of religion, race, caste or class or any of them.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 23 protects both citizens and non-citizens against exploitation. It bans 3 specific practices: 1) Human trafficking (selling/buying humans like goods, prostitution, devadasi), 2) Begar (involuntary work without payment), and 3) Forced labour (working under force, compulsion, or below minimum wage). Enforceable against BOTH State and private individuals. Clause (2) permits State to impose compulsory public service (e.g. military conscription, social service) provided there is no discrimination.',
      searchKeywords: const [
        'Article 23',
        'Begar',
        'Forced labour',
        'Human trafficking',
        'PUDR Asiad Workers Case',
        'Sanjit Roy',
        'Bonded Labour Abolition Act 1976',
        'Compulsory service exemption'
      ],
      keyTakeaways: const [
        'Enforceable against BOTH State and private individuals.',
        'Bans Human Trafficking, Begar, and Forced Labour.',
        'PUDR Case (1982): Paying less than minimum wage constitutes "forced labour" under Art 23.',
        'Bonded Labour System (Abolition) Act, 1976 enacted pursuant to Art 23 & Art 35.',
        'Art 23(2) permits compulsory service for public purposes (e.g. military service), provided no discrimination on religion, race, caste, or class (Sex is NOT listed in 23(2)).'
      ],
      commonMisconceptions: const [
        'Misconception: Compulsory military conscription violates Article 23. Reality: Article 23(2) explicitly allows compulsory service for public purposes.',
        'Misconception: Forced labour requires physical force or locks. Reality: SC held economic compulsion or paying less than minimum wage equals forced labour.'
      ],
      memoryAids: const [
        'Mnemonic - 23 = Ban on Trafficking & Begar.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 3, 1948 (Draft Article 17). K.M. Munshi and Dr. Ambedkar fought to eradicate feudal begar and bonded labor prevalent in landlord systems.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 3, 1948) - Speeches by Raj Bahadur, Shibban Lal Saksena, Ambedkar.',
        'Abolition of zamindari-linked begar and compulsory village labor.'
      ],
      objectivesResolutionLinks: const [
        'Fulfills economic justice commitments.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'People\'s Union for Democratic Rights (PUDR) v. Union of India (Asiad Workers Case)',
          year: 1982,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Held paying less than statutory minimum wage to workers amounts to "forced labour" under Art 23. Article 23 is enforceable against private contractors.',
          importance: 'Minimum wage violation declared forced labor.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Sanjit Roy v. State of Rajasthan',
          year: 1983,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'State paying less than minimum wage to famine relief workers violates Art 23; famine relief cannot justify forced labour.',
          importance: 'Famine relief workers protected under Art 23.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Bandhua Mukti Morcha v. Union of India',
          year: 1984,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Identified bonded labourers in stone quarries; ordered rehabilitation under Bonded Labour System (Abolition) Act 1976.',
          importance: 'PIL for bonded labour release & rehabilitation.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 24', 'Article 35', 'Article 39(e)'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART23', 'PYQ_UPSC_2021_ART23', 'PYQ_CDS_2020_ART23'],
      pyqIds: const ['PYQ_UPSC_2017_ART23', 'PYQ_UPSC_2021_ART23', 'PYQ_CDS_2020_ART23'],
      learningObjectives: const [
        'Define Begar and Forced Labour.',
        'Explain the PUDR judgment on minimum wages and Article 23.',
        'Identify the ground NOT mentioned in Article 23(2) exception (Sex).'
      ],
      difficulty: 'Medium',
      examImportance: 'High',
      revisionPoints: const [
        'Bans human trafficking, begar, forced labor.',
        'Binds private persons & State.',
        'Paying below minimum wage = forced labor (PUDR 1982).',
        '23(2) exception: Compulsory service for public purpose (no discrimination on religion, race, caste, class).'
      ],
      trapAreas: const [
        'Believing "Sex" is listed as a prohibited discrimination ground in 23(2) (Grounds in 23(2) are Religion, Race, Caste, Class—Sex is omitted).',
        'Assuming Art 23 only applies to state actions.'
      ],
      frequentlyConfusedWith: const ['Article 24 (Child Labour)'],
      timesAsked: 14,
      lastAskedYear: 2023,
      trend: 'Medium-High Frequency',
      examDistribution: const {'UPSC': 7, 'StatePSC': 5, 'CDS': 2},
      difficultyDistribution: const {'Easy': 3, 'Medium': 7, 'Hard': 4},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1982 SC 1473 (PUDR Asiad)',
        '(1984) 3 SCC 161 (Bandhua Mukti Morcha)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_PUDR_1982', 'REF_SC_BANDHUA_MUKTI_1984'],
    ),

    // ------------------------------------------------------------------------
    // Article 24: Prohibition of Employment of Children in Factories, etc.
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-24',
      articleNumber: '24',
      officialTitle: 'Prohibition of employment of children in factories, etc.',
      part: 'Part III',
      chapter: 'Right against Exploitation',
      originalNumber: '24',
      currentNumber: '24',
      title: 'Article 24: Prohibition of Child Labour (Below 14 years)',
      officialName: 'ARTICLE 24',
      description:
          'No child below the age of fourteen years shall be employed to work in any factory or mine or engaged in any other hazardous employment.',
      officialConstitutionalText:
          'No child below the age of fourteen years shall be employed to work in any factory or mine or engaged in any other hazardous employment.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 24 prohibits employment of children below 14 years in factories, mines, or hazardous occupations (such as construction, fireworks, match factories). Absolute prohibition. Child Labour (Prohibition and Regulation) Amendment Act, 2016 completely banned child labour under 14 in ALL occupations and processes, and banned adolescent (14-18 yrs) employment in hazardous occupations.',
      searchKeywords: const [
        'Article 24',
        'Prohibition of child labour',
        'Below 14 years age limit',
        'MC Mehta Sivakasi Case',
        'Child Labour Amendment Act 2016',
        'Hazardous occupations'
      ],
      keyTakeaways: const [
        'Prohibits employment of children below 14 years in hazardous industries (factories, mines).',
        'Enforceable against State and private employers.',
        'M.C. Mehta Case (1996): SC directed creation of Child Labour Rehabilitation Welfare Fund.',
        'Child Labour Amendment Act 2016: Complete ban under 14 years in ALL occupations, and 14-18 years in hazardous occupations.'
      ],
      commonMisconceptions: const [
        'Misconception: Article 24 originally banned child labour in non-hazardous innocent work like family farms. Reality: Originally Art 24 banned hazardous work; 2016 Amendment expanded complete ban under 14.'
      ],
      memoryAids: const [
        'Mnemonic - 24 = Below 14 Child Labour Ban in Factories.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 3, 1948 (Draft Article 18). Aimed at eradicating child exploitation in colonial mines and textile mills.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 3, 1948) - Speeches by Shibban Lal Saksena, Damodar Swarup Seth.',
        'Unanimous support for protecting children from industrial exploitation.'
      ],
      objectivesResolutionLinks: const [
        'Protects childhood and youth against moral and material abandonment.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'M.C. Mehta v. State of Tamil Nadu (Sivakasi Child Labour Case)',
          year: 1996,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Directed survey of child labour in fireworks factories in Sivakasi; mandated employer fine of Rs 20,000 per child to be deposited into Child Labour Rehabilitation Welfare Fund.',
          importance: 'Child Labour Rehabilitation Fund established.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedArticles: const ['Article 21A', 'Article 23', 'Article 39(e)', 'Article 39(f)'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART24', 'PYQ_CDS_2021_ART24'],
      pyqIds: const ['PYQ_UPSC_2018_ART24', 'PYQ_CDS_2021_ART24'],
      learningObjectives: const [
        'State the age limit in Article 24 (14 years).',
        'Describe the M.C. Mehta Sivakasi judgment directions.',
        'Compare original Art 24 with 2016 Child Labour Amendment Act provisions.'
      ],
      difficulty: 'Easy',
      examImportance: 'Medium-High',
      revisionPoints: const [
        'Below 14 years child labour prohibited in hazardous work.',
        'MC Mehta (1996): Rs 20,000 fine per child into Rehabilitation Fund.',
        '2016 Act: Complete ban under 14 in all jobs; 14-18 banned in hazardous jobs.'
      ],
      trapAreas: const [
        'Confusing Article 21A age bracket (6-14) with Article 24 (below 14).'
      ],
      frequentlyConfusedWith: const ['Article 21A', 'Article 23'],
      timesAsked: 10,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      examDistribution: const {'UPSC': 5, 'StatePSC': 3, 'CDS': 2},
      difficultyDistribution: const {'Easy': 4, 'Medium': 5, 'Hard': 1},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        '(1996) 6 SCC 756 (MC Mehta Sivakasi)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_MC_MEHTA_1996'],
    ),

    // ------------------------------------------------------------------------
    // Article 25: Freedom of Conscience and Free Profession, Practice, Propagation
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-25',
      articleNumber: '25',
      officialTitle: 'Freedom of conscience and free profession, practice and propagation of religion',
      part: 'Part III',
      chapter: 'Right to Freedom of Religion',
      originalNumber: '25',
      currentNumber: '25',
      title: 'Article 25: Freedom of Conscience & Religious Profession, Practice, Propagation',
      officialName: 'ARTICLE 25',
      description:
          '(1) Subject to public order, morality and health and to the other provisions of this Part, all persons are equally entitled to freedom of conscience and the right freely to profess, practise and propagate religion.\n(2) State power: (a) Regulating economic, financial, political, or secular activity associated with religious practice; (b) Providing for social welfare and reform or opening of Hindu religious institutions to all classes and sections of Hindus.\nExplanation I: Wearing Kirpans by Sikhs included in profession of Sikh religion.\nExplanation II: Reference to Hindus includes Sikhs, Jains, and Buddhists.',
      officialConstitutionalText:
          '(1) Subject to public order, morality and health and to the other provisions of this Part, all persons are equally entitled to freedom of conscience and the right freely to profess, practise and propagate religion.\n(2) Nothing in this article shall affect the operation of any existing law or prevent the State from making any law— (a) regulating or restricting any economic, financial, political or other secular activity which may be associated with religious practice; (b) providing for social welfare and reform or the throwing open of Hindu religious institutions of a public character to all classes and sections of Hindus.\nExplanation I.—The wearing and carrying of kirpans shall be deemed to be included in the profession of the Sikh religion.\nExplanation II.—In sub-clause (b) of clause (2), the reference to Hindus shall be construed as including a reference to persons professing the Sikh, Jaina or Buddhist religion...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 25 guarantees individual religious freedom to ALL persons (citizens and aliens). Includes: 1) Freedom of conscience (inner freedom to mold relationship with God), 2) Right to profess (declare belief openly), 3) Right to practise (perform rituals/worship), and 4) Right to propagate (transmit/disseminate tenets). Rev. Stainislaus (1977) held propagation does NOT include right to forcibly convert. Subject to 4 restrictions: Public order, Morality, Health, and other Fundamental Rights. Essential Religious Practices (ERP) doctrine developed by SC controls state intervention.',
      searchKeywords: const [
        'Article 25',
        'Freedom of conscience',
        'Propagate religion',
        'Essential Religious Practices ERP',
        'Shirur Mutt Case',
        'Rev Stainislaus Forced Conversion',
        'Sabarimala Case',
        'Kirpan Sikh Explanation I'
      ],
      keyTakeaways: const [
        'Guaranteed to ALL persons (citizens and non-citizens).',
        '4 Restrictions: Public Order, Morality, Health, and other Part III Rights.',
        'Right to propagate does NOT include right to forcibly convert another person (Rev. Stainislaus 1977).',
        'Shirur Mutt Case (1954): Supreme Court formulated the Essential Religious Practices (ERP) doctrine.',
        'Explanation I: Wearing and carrying of Kirpans by Sikhs is protected under Art 25.',
        'Explanation II: "Hindus" includes Sikhs, Jains, and Buddhists for social reform laws under 25(2)(b).'
      ],
      commonMisconceptions: const [
        'Misconception: Right to propagate religion includes right to convert others by force/allurement. Reality: SC in Stainislaus held Art 25 gives right to transmit tenets, not to convert.',
        'Misconception: All religious practices are protected under Art 25. Reality: ONLY practices essential to the religion (ERP test) are protected.'
      ],
      memoryAids: const [
        'Mnemonic - CPPP: Conscience, Profession, Practice, Propagation.',
        'Mnemonic - Restrictions: PMH + FRs (Public Order, Morality, Health, Fundamental Rights).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 3, 1948 (Draft Article 19). K.M. Munshi and Tajamul Husain emphasized that Indian secularism respects all religions equally (Sarva Dharma Sambhava) while permitting social reforms like temple entry.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 3-6, 1948) - Intense debate on word "propagate".',
        'K.M. Munshi, Rev. Jerome D\'Souza, and Pandit Maitra assured Assembly that "propagate" is a peaceful expression of faith.'
      ],
      objectivesResolutionLinks: const [
        'Translates Liberty of belief, faith and worship into individual constitutional rights.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Commissioner, Hindu Religious Endowments, Madras v. Sri Lakshmindra Thirtha Swamiar (Shirur Mutt Case)',
          year: 1954,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Formulated Essential Religious Practices (ERP) doctrine: What constitutes an essential part of a religion is to be determined with reference to the doctrines of that religion itself.',
          importance: 'Birth of Essential Religious Practices (ERP) doctrine.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Rev. Stainislaus v. State of Madhya Pradesh',
          year: 1977,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld anti-conversion laws of MP and Odisha. Held right to propagate religion does not include the right to convert another person, as forced conversion affects public order.',
          importance: 'Right to propagate vs forced conversion clarified.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Shayara Bano v. Union of India',
          year: 2017,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held Instant Triple Talaq (Talaq-e-biddat) is not an essential religious practice of Islam and violates Art 14.',
          importance: 'ERP test applied to Triple Talaq.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Indian Young Lawyers Association v. State of Kerala (Sabarimala Case)',
          year: 2018,
          bench: 'Supreme Court (5-Judge Bench - 4:1 Majority)',
          legalPrinciple:
              'Exclusion of women aged 10-50 from Sabarimala temple is not an essential religious practice and violates Art 25, 14, 15, 21.',
          importance: 'Gender equality prioritized over non-essential practice.',
          status: 'Referred to 9-Judge Bench for review',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 26', 'Article 27', 'Article 28', 'Article 44'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART25', 'PYQ_UPSC_2019_ART25', 'PYQ_CDS_2021_ART25'],
      pyqIds: const ['PYQ_UPSC_2017_ART25', 'PYQ_UPSC_2019_ART25', 'PYQ_CDS_2021_ART25'],
      learningObjectives: const [
        'List the 4 components of individual religious freedom in Article 25(1).',
        'State the 4 grounds of restrictions on Article 25.',
        'Explain the Essential Religious Practices (ERP) doctrine originating in Shirur Mutt case.'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Applies to all persons.',
        '4 aspects: Conscience, Profession, Practice, Propagation.',
        'Propagation != Forced conversion (Stainislaus 1977).',
        'Restrictions: Public Order, Morality, Health, Part III FRs.',
        'Shirur Mutt (1954): ERP Doctrine.',
        'Sikh Kirpans explicitly protected (Explanation I).'
      ],
      trapAreas: const [
        'Thinking Article 25 is subject ONLY to Public Order, Morality, and Health (It is ALSO subject to "other provisions of Part III").',
        'Believing Article 25 is available only to Indian citizens (It covers all persons).'
      ],
      frequentlyConfusedWith: const ['Article 26 (Group/Denominational Religious Freedom)'],
      timesAsked: 26,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 14, 'StatePSC': 8, 'CDS': 4},
      difficultyDistribution: const {'Easy': 2, 'Medium': 8, 'Hard': 16},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1954 SC 282 (Shirur Mutt)',
        'AIR 1977 SC 908 (Stainislaus)',
        '(2019) 11 SCC 1 (Sabarimala)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_SHIRUR_MUTT_1954', 'REF_SC_STAINISLAUS_1977'],
    ),

    // ------------------------------------------------------------------------
    // Article 26: Freedom to Manage Religious Affairs
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-26',
      articleNumber: '26',
      officialTitle: 'Freedom to manage religious affairs',
      part: 'Part III',
      chapter: 'Right to Freedom of Religion',
      originalNumber: '26',
      currentNumber: '26',
      title: 'Article 26: Corporate / Denominational Freedom to Manage Religious Affairs',
      officialName: 'ARTICLE 26',
      description:
          'Subject to public order, morality and health, every religious denomination or any section thereof shall have the right—\n(a) to establish and maintain institutions for religious and charitable purposes;\n(b) to manage its own affairs in matters of religion;\n(c) to own and acquire movable and immovable property; and\n(d) to administer such property in accordance with law.',
      officialConstitutionalText:
          'Subject to public order, morality and health, every religious denomination or any section thereof shall have the right—\n(a) to establish and maintain institutions for religious and charitable purposes;\n(b) to manage its own affairs in matters of religion;\n(c) to own and acquire movable and immovable property; and\n(d) to administer such property in accordance with law.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 26 guarantees denominational or collective freedom to religious groups. Unlike Art 25 (individual right), Art 26 protects religious denominations and sections thereof. 3 Conditions for Religious Denomination (SP Mittal case): 1) Collection of individuals with common system of beliefs, 2) Common organization, 3) Distinctive name. Article 26 is subject to Public Order, Morality, and Health (NOT subject to other FR provisions, unlike Art 25). Clause 26(b) protects matters of religion; 26(d) allows state regulation of property administration.',
      searchKeywords: const [
        'Article 26',
        'Religious denomination',
        'Manage religious affairs',
        'SP Mittal Auroville Case',
        'Shirur Mutt',
        'Denominational rights',
        '3 tests of religious denomination'
      ],
      keyTakeaways: const [
        'Protects collective/corporate rights of "Religious Denominations".',
        '3-point test for Religious Denomination (SP Mittal 1983): Common faith, Common organization, Distinctive name.',
        'Subject ONLY to 3 restrictions: Public Order, Morality, Health (NOT subject to other Part III FRs).',
        'Distinction: Art 26(b) management of religious matters is an absolute right; Art 26(d) administration of property is subject to State law.',
        'Auroville is NOT a religious denomination (SP Mittal 1983); Ramakrishna Mission IS a religious denomination within Hinduism (Bramchari Sidheswar Shai 1995).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 26 is subject to all other Fundamental Rights just like Article 25. Reality: Article 26 is subject ONLY to Public Order, Morality, and Health.',
        'Misconception: State cannot regulate the administration of religious property under Art 26. Reality: Art 26(d) explicitly permits State regulation of property administration in accordance with law.'
      ],
      memoryAids: const [
        'Mnemonic - EMOA: Establish institutions (a), Manage religious affairs (b), Own property (c), Administer property (d).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 7, 1948 (Draft Article 20). Aimed at safeguarding autonomous governance of mathas, trusts, and denominational bodies.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 7, 1948) - Speeches by Syed Abdur Rouf, Jaspat Roy Kapoor, Ambedkar.',
        'Harmonizing denominational autonomy with statutory property regulation.'
      ],
      objectivesResolutionLinks: const [
        'Protects institutional religious autonomy.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Shirur Mutt Case',
          year: 1954,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Held a Matha or religious trust is a religious denomination under Art 26. State can regulate secular property management but cannot interfere in essential religious rituals under 26(b).',
          importance: 'Scope of Art 26(b) vs 26(d) established.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'S.P. Mittal v. Union of India (Auroville Case)',
          year: 1983,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Formulated 3 conditions for Religious Denomination: 1) Common faith, 2) Common organization, 3) Distinctive name. Held Sri Aurobindo\'s philosophy is not a religion, so Auroville Society is NOT a religious denomination under Art 26.',
          importance: '3-point test for Religious Denomination.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 25', 'Article 27', 'Article 28'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART26', 'PYQ_UPSC_2021_ART26', 'PYQ_CDS_2020_ART26'],
      pyqIds: const ['PYQ_UPSC_2018_ART26', 'PYQ_UPSC_2021_ART26', 'PYQ_CDS_2020_ART26'],
      learningObjectives: const [
        'Contrast individual right (Art 25) with collective denominational right (Art 26).',
        'State the 3 criteria for a religious denomination under SP Mittal.',
        'Distinguish between Art 26(b) religious affairs and Art 26(d) property administration.'
      ],
      difficulty: 'High',
      examImportance: 'High',
      revisionPoints: const [
        'Denominational right.',
        '3 tests: Common faith, Common organization, Distinctive name (SP Mittal 1983).',
        '3 restrictions: Public order, Morality, Health.',
        '26(b) Religious affairs (absolute); 26(d) Property administration (state regulated).'
      ],
      trapAreas: const [
        'Assuming Article 26 is subject to "other provisions of Part III" (Unlike Art 25, Art 26 omits this clause).',
        'Thinking property administration under 26(d) cannot be legislated upon by State.'
      ],
      frequentlyConfusedWith: const ['Article 25', 'Article 29'],
      timesAsked: 18,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 10, 'StatePSC': 5, 'CDS': 3},
      difficultyDistribution: const {'Easy': 2, 'Medium': 6, 'Hard': 10},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1954 SC 282 (Shirur Mutt)',
        'AIR 1983 SC 1 (SP Mittal)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_SHIRUR_MUTT_1954', 'REF_SC_SP_MITTAL_1983'],
    ),

    // ------------------------------------------------------------------------
    // Article 27: Freedom as to Payment of Taxes for Promotion of Religion
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-27',
      articleNumber: '27',
      officialTitle: 'Freedom as to payment of taxes for promotion of any particular religion',
      part: 'Part III',
      chapter: 'Right to Freedom of Religion',
      originalNumber: '27',
      currentNumber: '27',
      title: 'Article 27: Freedom from Religious Taxation',
      officialName: 'ARTICLE 27',
      description:
          'No person shall be compelled to pay any taxes, the proceeds of which are specifically appropriated in payment of expenses for the promotion or maintenance of any particular religion or religious denomination.',
      officialConstitutionalText:
          'No person shall be compelled to pay any taxes, the proceeds of which are specifically appropriated in payment of expenses for the promotion or maintenance of any particular religion or religious denomination.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 27 prohibits the State from spending public tax money for promoting or maintaining any SPECIFIC religion or religious denomination. Embodies secularism by preventing state favouritism. Crucial distinction: Prohibits TAXES, but permits FEES. A fee can be levied on religious institutions/pilgrims to provide secular services, safety, or administrative regulation (Ratilal Panachand Gandhi case). State CAN spend tax money for secular promotion of ALL religions equally (e.g. Haj subsidy phaseout, Kailash Mansarovar road development).',
      searchKeywords: const [
        'Article 27',
        'No tax for specific religion',
        'Tax vs Fee distinction',
        'Ratilal Panachand Gandhi',
        'Secular spending'
      ],
      keyTakeaways: const [
        'Prohibits compulsory taxation whose proceeds promote a PARTICULAR religion.',
        'Does NOT prohibit state from levying FEES for administrative or safety services at religious sites.',
        'State CAN spend general public revenues for secular promotion/protection of ALL religions equally.',
        'Protects all persons (citizens and non-citizens).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 27 prohibits levying any fee on religious trusts or pilgrims. Reality: Fees levied for secular services/administration are fully constitutional.',
        'Misconception: State cannot spend any money on religious monuments. Reality: State can spend funds for heritage/tourism/all religions equally.'
      ],
      memoryAids: const [
        'Mnemonic - 27 = No Specific Religion TAX (Fees allowed).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 7, 1948 (Draft Article 21). Introduced to ensure state neutrality and prevent jizya-like or church-rate taxation in free India.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 7, 1948) - Speeches by M. Ananthasayanam Ayyangar, Ambedkar.',
        'Ensuring tax money collected from all citizens is not used to favor one religion.'
      ],
      objectivesResolutionLinks: const [
        'Secures state secular neutrality.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Ratilal Panachand Gandhi v. State of Bombay',
          year: 1954,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Distinguished Tax from Fee: Art 27 prohibits tax for specific religion, but fee levied under Public Trusts Act for controlling trust administration is valid as quid pro quo.',
          importance: 'Tax vs Fee distinction under Art 27.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 25', 'Article 26', 'Article 28'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART27', 'PYQ_CDS_2019_ART27'],
      pyqIds: const ['PYQ_UPSC_2017_ART27', 'PYQ_CDS_2019_ART27'],
      learningObjectives: const [
        'Explain the prohibition under Article 27.',
        'Distinguish between a Tax and a Fee under Article 27.',
        'Understand when state expenditure on religious heritage is valid.'
      ],
      difficulty: 'Medium',
      examImportance: 'Medium',
      revisionPoints: const [
        'Bans tax spent on specific religion.',
        'Fee for service/administration is allowed (Ratilal 1954).',
        'Equal spending on all religions allowed.'
      ],
      trapAreas: const [
        'Selecting options claiming state cannot levy fees on religious pilgrims (Fees ARE allowed).'
      ],
      frequentlyConfusedWith: const ['Article 28'],
      timesAsked: 9,
      lastAskedYear: 2021,
      trend: 'Medium Frequency',
      examDistribution: const {'UPSC': 5, 'StatePSC': 3, 'CDS': 1},
      difficultyDistribution: const {'Easy': 3, 'Medium': 5, 'Hard': 1},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1954 SC 388 (Ratilal)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_RATILAL_1954'],
    ),

    // ------------------------------------------------------------------------
    // Article 28: Religious Instruction in Educational Institutions
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-28',
      articleNumber: '28',
      officialTitle: 'Freedom as to attendance at religious instruction or religious worship in certain educational institutions',
      part: 'Part III',
      chapter: 'Right to Freedom of Religion',
      originalNumber: '28',
      currentNumber: '28',
      title: 'Article 28: Religious Instruction in Educational Institutions',
      officialName: 'ARTICLE 28',
      description:
          '(1) No religious instruction in institutions wholly maintained out of State funds.\n(2) Exception: Institutions administered by State but established under endowment/trust requiring religious instruction.\n(3) State-recognized or state-aided institutions: Religious instruction/worship VOLUNTARY (requires consent of individual, or guardian if minor).',
      officialConstitutionalText:
          '(1) No religious instruction shall be provided in any educational institution wholly maintained out of State funds.\n(2) Nothing in clause (1) shall apply to an educational institution which is administered by the State but has been established under any endowment or trust which requires that religious instruction shall be imparted in such institution.\n(3) No person attending any educational institution recognised by the State or receiving aid out of State funds shall be required to take part in any religious instruction that may be imparted in such institution or to attend any religious worship that may be conducted in such institution or in any premises attached thereto unless such person or, if such person is a minor, his guardian has given his consent thereto.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 28 regulates religious instruction across 4 categories of educational institutions: 1) Wholly maintained by State: Religious instruction COMPLETELY PROHIBITED. 2) Administered by State but established under trust/endowment: Religious instruction PERMITTED. 3) Recognized by State: Religious instruction VOLUNTARY (consent required). 4) Receiving aid from State: Religious instruction VOLUNTARY (consent required). Value education / study of religions is NOT religious instruction (Aruna Roy case).',
      searchKeywords: const [
        'Article 28',
        'Religious instruction',
        'State maintained institutions',
        'Voluntary consent minor',
        'Aruna Roy Value Education Case',
        'DAV College'
      ],
      keyTakeaways: const [
        '4-tier classification of educational institutions regarding religious instruction.',
        '1) Wholly State Maintained: Strictly BANNED.',
        '2) Administered by State under Trust: PERMITTED.',
        '3 & 4) State Recognized / Aided: VOLUNTARY (requires explicit consent of student or guardian).',
        'Aruna Roy (2002): Teaching value education and academic study of religions is constitutional and does not violate Art 28.'
      ],
      commonMisconceptions: const [
        'Misconception: Studying comparative religion or moral values violates Article 28(1). Reality: SC in Aruna Roy held value education is secular and permitted.',
        'Misconception: Private schools recognized by state can force students to attend morning prayers of a specific religion. Reality: Under Art 28(3), attendance is voluntary and requires consent.'
      ],
      memoryAids: const [
        'Mnemonic - 4 Categories: State-Wholly (No), State-Trust (Yes), Recognized (Voluntary), Aided (Voluntary).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 7, 1948 (Draft Article 22). Ambedkar balanced state secular neutrality with historical religious trust endowments.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 7, 1948) - Speeches by Panday, Tajamul Husain, Ambedkar.',
        'Resolving how state-run schools must remain religiously neutral.'
      ],
      objectivesResolutionLinks: const [
        'Protects freedom of thought and belief in educational spheres.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'D.A.V. College v. State of Punjab',
          year: 1971,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Academic study of Guru Nanak\'s life and teachings in university syllabus is not "religious instruction" under Art 28(1).',
          importance: 'Academic study distinguished from religious instruction.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Aruna Roy v. Union of India',
          year: 2002,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Upheld NCFSE curriculum including National Values and study of religions. Held value-based education is not "religious instruction" banned under Art 28(1).',
          importance: 'Value education upheld as secular.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 25', 'Article 26', 'Article 27', 'Article 29', 'Article 30'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART28', 'PYQ_CDS_2020_ART28'],
      pyqIds: const ['PYQ_UPSC_2018_ART28', 'PYQ_CDS_2020_ART28'],
      learningObjectives: const [
        'Categorize the 4 types of educational institutions under Article 28.',
        'Distinguish religious instruction from value-based academic study.',
        'Identify rules governing minors under Article 28(3).'
      ],
      difficulty: 'Medium',
      examImportance: 'Medium-High',
      revisionPoints: const [
        'Wholly state funded = No religious instruction.',
        'State administered trust = Allowed.',
        'State recognized/aided = Voluntary (consent needed).',
        'Aruna Roy (2002): Value education allowed.'
      ],
      trapAreas: const [
        'Confusing State-administered trust institutions (where religious instruction IS allowed under 28(2)) with wholly state-funded institutions (where it is BANNED under 28(1)).'
      ],
      frequentlyConfusedWith: const ['Article 27', 'Article 30'],
      timesAsked: 11,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      examDistribution: const {'UPSC': 6, 'StatePSC': 4, 'CDS': 1},
      difficultyDistribution: const {'Easy': 3, 'Medium': 6, 'Hard': 2},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1971 SC 1737 (DAV College)',
        '(2002) 7 SCC 368 (Aruna Roy)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_DAV_COLLEGE_1971', 'REF_SC_ARUNA_ROY_2002'],
    ),

    // ------------------------------------------------------------------------
    // Article 29: Protection of Interests of Minorities
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-29',
      articleNumber: '29',
      officialTitle: 'Protection of interests of minorities',
      part: 'Part III',
      chapter: 'Cultural and Educational Rights',
      originalNumber: '29',
      currentNumber: '29',
      title: 'Article 29: Protection of Language, Script, Culture & Non-Discrimination in Admissions',
      officialName: 'ARTICLE 29',
      description:
          '(1) Any section of citizens residing in India having a distinct language, script or culture of its own shall have the right to conserve the same.\n(2) No citizen shall be denied admission into any educational institution maintained by the State or receiving aid out of State funds on grounds only of religion, race, caste, language or any of them.',
      officialConstitutionalText:
          '(1) Any section of citizens residing in India having a distinct language, script or culture of its own shall have the right to conserve the same.\n(2) No citizen shall be denied admission into any educational institution maintained by the State or receiving aid out of State funds on grounds only of religion, race, caste, language or any of them.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 29 protects cultural and educational rights. Clause 29(1) protects "any section of citizens" (covers both MINORITIES and MAJORITY) having a distinct language, script, or culture to conserve the same. Includes right to agitate for protection of language. Clause 29(2) guarantees individual non-discrimination in state-funded or state-aided educational admissions on 4 grounds: Religion, Race, Caste, Language (omits Sex and Place of Birth). Covers ALL citizens.',
      searchKeywords: const [
        'Article 29',
        'Protection of minorities',
        'Conserve language script culture',
        'State aided educational instt admissions',
        'Section of citizens majority and minority',
        'Bombay Education Society Case'
      ],
      keyTakeaways: const [
        'Art 29(1) applies to "any section of citizens" (protects Majority AND Minority groups).',
        'Right to conserve language includes political agitation to protect language (Jagdev Singh Sidhanti case).',
        'Art 29(2) protects INDIVIDUAL citizens against admission denial in state-maintained or state-aided institutions.',
        '4 Grounds under 29(2): Religion, Race, Caste, Language (omits Sex & Place of birth compared to Art 15).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 29 applies strictly to religious and linguistic minorities. Reality: SC in TMA Pai held Art 29(1) extends to "any section of citizens" including majority community.',
        'Misconception: Article 29(2) includes "Sex" as a prohibited ground for admission. Reality: Art 29(2) lists Religion, Race, Caste, Language; Sex is NOT included.'
      ],
      memoryAids: const [
        'Mnemonic - LSC: Language, Script, Culture (29.1).',
        'Mnemonic - RRCL: Religion, Race, Caste, Language (29.2 grounds).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 8, 1948 (Draft Article 23). Marginal heading refers to "Minorities", but text broadened to "any section of citizens".',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 8, 1948) - Speeches by Pandit Thakur Das Bhargava, Dr. B.R. Ambedkar.',
        'Ambedkar explained why "section of citizens" was chosen over restrictive word "minorities".'
      ],
      objectivesResolutionLinks: const [
        'Preserves India\'s rich linguistic and cultural pluralism.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of Bombay v. Bombay Education Society',
          year: 1954,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'State order restricting English-medium school admissions to Anglo-Indians violated Art 29(2). Art 29(2) applies to ALL citizens.',
          importance: 'Universal individual right under Art 29(2).',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'T.M.A. Pai Foundation v. State of Karnataka',
          year: 2002,
          bench: 'Supreme Court (11-Judge Bench)',
          legalPrinciple:
              'Clarified Art 29(1) grants right to any section of citizens (majority or minority). Unit for determining minority status is the STATE, not the nation.',
          importance: 'State as unit for determining minority status.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 15', 'Article 30', 'Article 347', 'Article 350A', 'Article 350B'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART29', 'PYQ_UPSC_2020_ART29', 'PYQ_CDS_2021_ART29'],
      pyqIds: const ['PYQ_UPSC_2017_ART29', 'PYQ_UPSC_2020_ART29', 'PYQ_CDS_2021_ART29'],
      learningObjectives: const [
        'Explain why Art 29(1) applies to both majority and minority citizens.',
        'List the 4 grounds under Article 29(2).',
        'State the unit for determining minority status established in TMA Pai.'
      ],
      difficulty: 'High',
      examImportance: 'High',
      revisionPoints: const [
        '29(1): Any section of citizens (language, script, culture).',
        '29(2): Non-discrimination in state-aided admissions (Religion, Race, Caste, Language).',
        'Minority status determined STATE-wise (TMA Pai 2002).'
      ],
      trapAreas: const [
        'Believing Article 29(1) is restricted to minorities only (It covers "any section of citizens").',
        'Including "Sex" in Art 29(2) grounds (Sex is NOT listed in 29(2)).'
      ],
      frequentlyConfusedWith: const ['Article 15(1)', 'Article 30'],
      timesAsked: 17,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 9, 'StatePSC': 5, 'CDS': 3},
      difficultyDistribution: const {'Easy': 2, 'Medium': 6, 'Hard': 9},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1954 SC 561 (Bombay Education Society)',
        '(2002) 8 SCC 481 (TMA Pai)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_BOMBAY_EDU_1954', 'REF_SC_TMA_PAI_2002'],
    ),

    // ------------------------------------------------------------------------
    // Article 30: Right of Minorities to Establish and Administer Educational Institutions
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-30',
      articleNumber: '30',
      officialTitle: 'Right of minorities to establish and administer educational institutions',
      part: 'Part III',
      chapter: 'Cultural and Educational Rights',
      originalNumber: '30',
      currentNumber: '30',
      title: 'Article 30: Minority Rights to Establish & Administer Educational Institutions',
      officialName: 'ARTICLE 30',
      description:
          '(1) All minorities, whether based on religion or language, shall have the right to establish and administer educational institutions of their choice.\n(1A) [Added by 44th Amd 1978] Compensation for compulsory acquisition of property of minority educational institution.\n(2) State non-discrimination in granting aid to educational institutions based on minority management.',
      officialConstitutionalText:
          '(1) All minorities, whether based on religion or language, shall have the right to establish and administer educational institutions of their choice.\n(1A) In making any law providing for the compulsory acquisition of any property of an educational institution established and administered by a minority, referred to in clause (1), the State shall ensure that the amount fixed by or determined under such law for the acquisition of such property is such as would not restrict or abridge the right guaranteed under that clause.\n(2) The State shall not, in granting aid to educational institutions, discriminate against any educational institution on the ground that it is under the management of a minority, whether based on religion or language.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 30 guarantees exclusive protection specifically to MINORITIES (Religious or Linguistic). Does NOT extend to majority community. Right includes: 1) Right to establish, 2) Right to administer (select governing body, staff, students, fees). Not absolute—subject to state regulations for academic excellence, health, sanitation, labor welfare (PA Inamdar). 44th Amd 1978 added 30(1A) protecting minority institution property compensation. Exempt from 25% RTE quota (Pramati 2014) and Art 15(5) reservation quota.',
      searchKeywords: const [
        'Article 30',
        'Minority educational institutions',
        'Religious or linguistic minorities',
        'Establish and administer',
        'TMA Pai 11-Judge Bench',
        'PA Inamdar',
        'Exempt from RTE quota',
        'Article 30(1A) 44th Amendment'
      ],
      keyTakeaways: const [
        'Guaranteed ONLY to Religious and Linguistic Minorities (NOT majority).',
        'Covers establishing AND administering educational institutions "of their choice" (general education included).',
        'Unit for determining minority status is the STATE (TMA Pai 2002).',
        '44th Amendment Act 1978 inserted 30(1A) ensuring full market compensation if minority institution property is acquired.',
        'Minority institutions are EXEMPT from Art 15(5) reservation quotas and 25% RTE quota (Pramati 2014).',
        'State CAN enforce secular regulations (academic standards, teacher qualifications, labor laws) without violating Art 30.'
      ],
      commonMisconceptions: const [
        'Misconception: Article 30 allows minority institutions to teach ONLY their religion/language. Reality: They can impart general modern education (medical, engineering, law).',
        'Misconception: Article 30 gives absolute immunity from state regulations. Reality: Regulatory measures for academic excellence, sanitation, and labor welfare apply to minority institutions.'
      ],
      memoryAids: const [
        'Mnemonic - 30 = Religious & Linguistic Minorities Charter for Schools/Colleges.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 8, 1948 (Draft Article 23). Dr. Ambedkar assured religious and linguistic minorities that their educational autonomy would be preserved in secular India.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 8, 1948) - Speeches by Z.H. Lari, Begum Aizaz Rasul, K.M. Munshi, Ambedkar.',
        'Creating confidence among minorities regarding cultural and educational preservation.'
      ],
      objectivesResolutionLinks: const [
        'Fulfills sacred pledge to protect minority rights in India.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act, 1978',
          beforeText: 'Article 30 lacked clause (1A).',
          afterText: 'Inserted clause (1A): Guaranteeing full compensation for acquisition of minority educational property.',
          reason: 'To protect minority institutions when Right to Property (Art 31) was deleted.',
          effectiveDate: DateTime(1979, 6, 20),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'In re Kerala Education Bill',
          year: 1958,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Right to administer does not mean right to maladminister. State can impose reasonable regulations for educational standards.',
          importance: 'Foundational ruling on minority institution regulation.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'T.M.A. Pai Foundation v. State of Karnataka',
          year: 2002,
          bench: 'Supreme Court (11-Judge Bench)',
          legalPrinciple:
              'Landmark 11-Judge Bench ruling: 1) Minority status determined STATE-wise, 2) Unaided minority institutions have maximum autonomy in admissions & fee structure, 3) State cannot force reservation policy on unaided minority institutions.',
          importance: 'Definitive charter on minority educational rights.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'P.A. Inamdar v. State of Maharashtra',
          year: 2005,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Neither State reservation policy nor NRI quota seats can be imposed by State on private unaided minority/non-minority educational institutions.',
          importance: 'Autonomy of private unaided colleges reaffirmed.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Pramati Educational & Cultural Trust v. Union of India',
          year: 2014,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld exemption of Art 30 minority institutions (aided or unaided) from the 25% quota under RTE Act 2009.',
          importance: 'RTE Act exemption for minority schools upheld.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 15(5)', 'Article 21A', 'Article 29', 'Article 300A'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART30', 'PYQ_UPSC_2020_ART30', 'PYQ_CAPF_2021_ART30'],
      pyqIds: const ['PYQ_UPSC_2018_ART30', 'PYQ_UPSC_2020_ART30', 'PYQ_CAPF_2021_ART30'],
      learningObjectives: const [
        'Identify the two types of minorities recognized under Article 30 (Religious and Linguistic).',
        'State the impact of the 44th Amendment inserting Article 30(1A).',
        'Explain the key principles of the TMA Pai Foundation judgment.'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Applies ONLY to Minorities (Religious & Linguistic).',
        'Determined STATE-wise (TMA Pai 2002).',
        '30(1A): Full property compensation guaranteed (44th Amd 1978).',
        'Exempt from Art 15(5) & RTE 25% quota (Pramati 2014).',
        'Regulation allowed for academic excellence (not maladministration).'
      ],
      trapAreas: const [
        'Believing majority community can claim Article 30 rights (Article 30 is EXCLUSIVELY for minorities).',
        'Thinking minority status is determined at national level (It is determined STATE-wise).'
      ],
      frequentlyConfusedWith: const ['Article 29 (General section of citizens)'],
      timesAsked: 30,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 16, 'StatePSC': 9, 'CDS': 5},
      difficultyDistribution: const {'Easy': 2, 'Medium': 8, 'Hard': 20},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1958 SC 956 (Kerala Education Bill)',
        '(2002) 8 SCC 481 (TMA Pai)',
        '(2014) 8 SCC 1 (Pramati)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_KERALA_EDU_1958', 'REF_SC_TMA_PAI_2002'],
    ),

    // ------------------------------------------------------------------------
    // Article 31: [REPEALED] Compulsory Acquisition of Property
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-31',
      articleNumber: '31',
      officialTitle: 'Compulsory acquisition of property [Repealed]',
      part: 'Part III',
      chapter: 'Right to Property',
      originalNumber: '31',
      currentNumber: '31',
      title: 'Article 31: Compulsory Acquisition of Property [REPEALED]',
      officialName: 'ARTICLE 31 [REPEALED]',
      description:
          'Guaranteed right to property and full compensation for state acquisition. Repealed by 44th Constitutional Amendment Act, 1978 and converted into a legal/constitutional right under Article 300A in Part XII.',
      officialConstitutionalText:
          '[Repealed by the Constitution (Forty-fourth Amendment) Act, 1978, section 6 (w.e.f. 20-6-1979).]',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 31 originally guaranteed the Fundamental Right to Property (no deprivation except by authority of law & full market compensation). Triggered landmark historic clashes between Parliament and Judiciary over agrarian land reforms and bank nationalization (Kameshwar Singh, Bela Banerjee, Golaknath, RC Cooper, Kesavananda Bharati). Modified by 1st, 4th, 25th Amendments. Finally REPEALED by 44th Constitutional Amendment Act 1978 under Morarji Desai Janata Govt, shifting property right to Article 300A as a legal right.',
      searchKeywords: const [
        'Article 31',
        'Right to property repealed',
        '44th Amendment Act 1978',
        'Article 300A',
        'Bela Banerjee',
        'RC Cooper Bank Nationalisation',
        'Kameshwar Singh'
      ],
      keyTakeaways: const [
        'REPEALED from Part III by the 44th Constitutional Amendment Act, 1978 (w.e.f. June 20, 1979).',
        'Right to Property shifted to Article 300A in Part XII as a Constitutional/Legal Right.',
        'As a legal right under Art 300A: Not a Basic Structure element; enforceable via Art 226 High Court writ, but NOT via Art 32 Supreme Court writ.',
        'Two constitutional exceptions where full compensation is STILL mandatory under Part III: 1) Art 30(1A) Minority Educational Institution property, 2) Art 31A(1) 2nd Proviso Land under personal cultivation within ceiling limit.'
      ],
      commonMisconceptions: const [
        'Misconception: Right to property is completely abolished in India. Reality: It was removed as a Fundamental Right, but remains a constitutional/legal right under Article 300A.',
        'Misconception: Violation of Art 300A can be challenged directly under Art 32. Reality: Art 32 applies ONLY to Part III Fundamental Rights.'
      ],
      memoryAids: const [
        'Mnemonic - 44 in 78 deleted 31: 44th Amendment in 1978 repealed Article 31 -> shifted to Art 300A.'
      ],
      historicalBackground:
          'Adopted after fierce Constituent Assembly debates in September 1949 (Draft Article 24). Nehru insisted state land acquisition for public zamindari abolition should not be stalled by market compensation claims.',
      constituentAssemblyDebates: const [
        'CAD Vol. IX (September 9-12, 1949) - Speeches by Jawaharlal Nehru, Patel, K.M. Munshi, Alladi Krishnaswami Ayyar.',
        'Nehru\'s historic statement: "No individual\'s right can allowed to come in the way of the progress of the community."'
      ],
      objectivesResolutionLinks: const [
        'Balanced individual ownership with socio-economic redistributive justice.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '1st Constitutional Amendment Act, 1951',
          beforeText: 'Article 31 had no savings clauses for agrarian reforms.',
          afterText: 'Inserted Articles 31A and 31B (and Ninth Schedule) to protect land reform laws.',
          reason: 'Overcome High Court rulings striking down Zamindari abolition laws (Kameshwar Singh).',
          effectiveDate: DateTime(1951, 6, 18),
        ),
        ArticleAmendmentRecord(
          amendmentName: '4th Constitutional Amendment Act, 1955',
          beforeText: 'Adequacy of compensation was open to judicial review.',
          afterText: 'Made adequacy of compensation non-justiciable in courts.',
          reason: 'Overcome SC Bela Banerjee judgment requiring full market value compensation.',
          effectiveDate: DateTime(1955, 4, 27),
        ),
        ArticleAmendmentRecord(
          amendmentName: '25th Constitutional Amendment Act, 1971',
          beforeText: 'Word "compensation" used in Article 31(2).',
          afterText: 'Substituted word "compensation" with "amount" and inserted Article 31C.',
          reason: 'Overcome RC Cooper (Bank Nationalisation) case.',
          effectiveDate: DateTime(1972, 4, 20),
        ),
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act, 1978',
          beforeText: 'Article 31 was a active Fundamental Right in Part III.',
          afterText: 'Omitted Article 31 completely from Part III and inserted Article 300A in Part XII.',
          reason: 'Abolish Fundamental Right status of property while retaining constitutional protection.',
          effectiveDate: DateTime(1979, 6, 20),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of West Bengal v. Bela Banerjee',
          year: 1954,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held "compensation" in Art 31(2) means just equivalent or full market value of property acquired.',
          importance: 'Triggered 4th Amendment Act 1955.',
          status: 'Historically Relevant - Repealed',
        ),
        ArticleCaseLawRecord(
          caseName: 'R.C. Cooper v. Union of India (Bank Nationalisation Case)',
          year: 1970,
          bench: 'Supreme Court (11-Judge Bench)',
          legalPrinciple:
              'Struck down Banking Companies Act 1969 for providing illusory compensation violating Art 31(2).',
          importance: 'Triggered 25th Amendment Act 1971.',
          status: 'Historically Relevant - Repealed',
        ),
        ArticleCaseLawRecord(
          caseName: 'K.T. Plantation Pvt. Ltd. v. State of Karnataka',
          year: 2011,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Confirmed that under Art 300A, requirement of public purpose and reasonable compensation still exists as inherent facets of Rule of Law.',
          importance: 'Modern interpretation of Art 300A legal right.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-XII'],
      relatedArticles: const ['Article 31A', 'Article 31B', 'Article 31C', 'Article 300A'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART31', 'PYQ_UPSC_2020_ART31', 'PYQ_CDS_2021_ART31'],
      pyqIds: const ['PYQ_UPSC_2017_ART31', 'PYQ_UPSC_2020_ART31', 'PYQ_CDS_2021_ART31'],
      learningObjectives: const [
        'Trace the amendment history of Article 31 from 1st to 44th Amendment.',
        'Compare Right to Property as FR (Art 31) vs Legal Right (Art 300A).',
        'Identify the two exceptions where Part III still mandates property compensation (Art 30(1A) & Art 31A(1) 2nd Proviso).'
      ],
      difficulty: 'High',
      examImportance: 'High',
      revisionPoints: const [
        'Repealed by 44th Amd 1978.',
        'Shifted to Art 300A (Part XII) as Legal Right.',
        'Art 32 writ NOT available for 300A (Art 226 available).',
        '2 exceptions for Part III compensation: Art 30(1A) & Art 31A(1) 2nd proviso.'
      ],
      trapAreas: const [
        'Selecting options stating Right to Property is a Basic Structure element (It is NOT part of Basic Structure).',
        'Claiming Art 32 writs can be filed for Art 300A violations (Art 32 is restricted to Part III FRs).'
      ],
      frequentlyConfusedWith: const ['Article 300A', 'Article 31A'],
      timesAsked: 25,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 15, 'StatePSC': 7, 'CDS': 3},
      difficultyDistribution: const {'Easy': 3, 'Medium': 8, 'Hard': 14},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1954 SC 170 (Bela Banerjee)',
        'AIR 1970 SC 564 (RC Cooper)',
        '(2011) 9 SCC 1 (KT Plantation)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.repealed,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_BELA_BANERJEE_1954', 'REF_SC_RC_COOPER_1970'],
    ),

    // ------------------------------------------------------------------------
    // Article 31A: Saving of Laws Providing for Acquisition of Estates
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-31A',
      articleNumber: '31A',
      officialTitle: 'Saving of laws providing for acquisition of estates, etc.',
      part: 'Part III',
      chapter: 'Saving of Certain Laws',
      originalNumber: '31A',
      currentNumber: '31A',
      title: 'Article 31A: Protection of Agrarian & Economic Reforms',
      officialName: 'ARTICLE 31A',
      description:
          'Saves 5 categories of laws from being challenged under Article 14 and Article 19: 1) Acquisition of estates/rights by State, 2) Taking over management of property, 3) Amalgamation of corporations, 4) Extinction/modification of corporate rights, 5) Modification of mining leases/agreements.\nProviso: State law must receive assent of the President to enjoy Art 31A protection.\n2nd Proviso: Full market value compensation required if land under personal cultivation within ceiling limit is acquired.',
      officialConstitutionalText:
          'Notwithstanding anything contained in article 13, no law providing for— (a) the acquisition by the State of any estate or of any rights therein or the extinguishment or modification of any such rights, or (b) the taking over of the management of any property by the State for a limited period either in the public interest or in order to secure the proper management of the property, or (c) the amalgamation of two or more corporations either in the public interest or in order to secure the proper management of any of the corporations, or (d) the extinguishment or modification of any rights of managing agents, secretaries and treasurers, managing directors, directors or managers of corporations, or of any voting rights of shareholders thereof, or (e) the extinguishment or modification of any rights accruing by virtue of any agreement, lease or licence for the purpose of searching for, or winning, any mineral or mineral oil, or the premature termination or cancellation of any such agreement, lease or licence, shall be deemed to be void on the ground that it is inconsistent with, or takes away or abridges any of the rights conferred by article 14 or article 19...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 31A was added by 1st Constitutional Amendment Act 1951 (and expanded by 4th, 17th, 44th Amendments) to protect agrarian land reforms and state economic controls from being struck down under Article 14 and Article 19. If a state law falls under one of the 5 categories and receives Presidential assent, it cannot be challenged for violating Art 14 or 19. Second Proviso guarantees market compensation if self-cultivated land within land ceiling limit is acquired.',
      searchKeywords: const [
        'Article 31A',
        'Acquisition of estates',
        '1st Amendment 1951',
        'Presidential assent proviso',
        'Land ceiling compensation 2nd proviso',
        'Agrarian reform protection'
      ],
      keyTakeaways: const [
        'Inserted by 1st Constitutional Amendment Act, 1951.',
        'Protects 5 categories of reform laws from challenge under Article 14 and Article 19.',
        'Mandatory Condition: State laws MUST receive Presidential Assent to claim Art 31A protection.',
        '2nd Proviso (inserted by 17th Amd 1964): Compensation at market value mandatory if acquiring personal cultivation land within ceiling limit.'
      ],
      commonMisconceptions: const [
        'Misconception: State land reform laws automatically get Article 31A immunity. Reality: Presidential Assent is mandatory for State laws under Art 31A.'
      ],
      memoryAids: const [
        'Mnemonic - 5 Categories: Estate acquisition, Management takeover, Corporation amalgamation, Corporate rights modification, Mining lease modification.'
      ],
      historicalBackground:
          'Introduced by Jawaharlal Nehru via 1st Amendment 1951 to prevent court injunctions against Zamindari abolition legislations.',
      constituentAssemblyDebates: const [
        'Post-Constituent Assembly provisional parliament debate in May-June 1951 on 1st Amendment Bill.'
      ],
      objectivesResolutionLinks: const [
        'Facilitates socialistic agrarian distribution.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '1st Constitutional Amendment Act, 1951',
          beforeText: 'Article 31A did not exist.',
          afterText: 'Inserted Article 31A protecting estate acquisition laws.',
          reason: 'To safeguard Zamindari abolition laws.',
          effectiveDate: DateTime(1951, 6, 18),
        ),
        ArticleAmendmentRecord(
          amendmentName: '17th Constitutional Amendment Act, 1964',
          beforeText: 'Definition of "estate" was narrow.',
          afterText: 'Expanded definition of "estate" and inserted 2nd Proviso for ceiling limit land compensation.',
          reason: 'Protect ryotwari land reforms.',
          effectiveDate: DateTime(1964, 6, 20),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Shankari Prasad Singh Deo v. Union of India',
          year: 1951,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld constitutional validity of 1st Amendment inserting Art 31A & 31B.',
          importance: 'Art 31A validity affirmed.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 14', 'Article 19', 'Article 31B', 'Article 31C'],
      relatedPYQs: const ['PYQ_UPSC_2019_ART31A', 'PYQ_CDS_2020_ART31A'],
      pyqIds: const ['PYQ_UPSC_2019_ART31A', 'PYQ_CDS_2020_ART31A'],
      learningObjectives: const [
        'List the 5 categories covered by Article 31A.',
        'Explain the role of Presidential Assent under Article 31A proviso.',
        'State the 2nd Proviso land ceiling compensation rule.'
      ],
      difficulty: 'High',
      examImportance: 'Medium-High',
      revisionPoints: const [
        '1st Amd 1951.',
        'Saves 5 categories from Art 14 & 19.',
        'Requires Presidential Assent for state laws.',
        '2nd Proviso: Ceiling limit land requires market compensation.'
      ],
      trapAreas: const [
        'Forgetting that Art 31A protects against Art 14 and Art 19 (NOT all FRs).'
      ],
      frequentlyConfusedWith: const ['Article 31B', 'Article 31C'],
      timesAsked: 11,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      examDistribution: const {'UPSC': 6, 'StatePSC': 3, 'CDS': 2},
      difficultyDistribution: const {'Easy': 1, 'Medium': 5, 'Hard': 5},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1951 SC 458 (Shankari Prasad)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1951, 6, 18),
      evidenceReferences: const ['REF_SC_SHANKARI_PRASAD_1951'],
    ),

    // ------------------------------------------------------------------------
    // Article 31B: Validation of Certain Acts and Regulations (Ninth Schedule)
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-31B',
      articleNumber: '31B',
      officialTitle: 'Validation of certain Acts and Regulations',
      part: 'Part III',
      chapter: 'Saving of Certain Laws',
      originalNumber: '31B',
      currentNumber: '31B',
      title: 'Article 31B: Ninth Schedule Protection & Judicial Review',
      officialName: 'ARTICLE 31B',
      description:
          'Acts and Regulations specified in the Ninth Schedule shall not be deemed void on ground of inconsistency with any Fundamental Rights in Part III.\nIR Coelho Case (2007): SC ruled Ninth Schedule laws enacted AFTER April 24, 1973 are subject to Judicial Review under the Basic Structure Doctrine.',
      officialConstitutionalText:
          'Without prejudice to the generality of the provisions contained in article 31A, none of the Acts and Regulations specified in the Ninth Schedule nor any of the provisions thereof shall be deemed to be void, or ever to have become void, on the ground that such Act, Regulation or provision is inconsistent with, or takes away or abridges any of the rights conferred by, any provisions of this Part...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 31B was added by the 1st Constitutional Amendment Act 1951 along with the Ninth Schedule. It creates a constitutional protective shield for any law placed in the Ninth Schedule against challenge under ALL Fundamental Rights (broader than 31A which covers only 14 & 19). However, in I.R. Coelho v. State of Tamil Nadu (2007), a 9-Judge Bench ruled that Ninth Schedule laws added AFTER April 24, 1973 (date of Kesavananda Bharati judgment) are subject to judicial review if they damage the Basic Structure.',
      searchKeywords: const [
        'Article 31B',
        'Ninth Schedule',
        '1st Amendment 1951',
        'IR Coelho Case 2007',
        'April 24 1973 cutoff date',
        'Basic Structure Judicial Review'
      ],
      keyTakeaways: const [
        'Added by 1st Constitutional Amendment Act, 1951 together with Ninth Schedule.',
        'Protects laws placed in Ninth Schedule against violation of ALL Part III Fundamental Rights.',
        'Article 31B is independent of Article 31A (broader scope).',
        'I.R. Coelho (2007): 9-Judge Bench held laws added to 9th Schedule AFTER April 24, 1973 are OPEN to judicial review based on Basic Structure test.'
      ],
      commonMisconceptions: const [
        'Misconception: Ninth Schedule laws are completely immune from judicial review today. Reality: Post-April 24, 1973 laws in 9th Schedule can be struck down if they violate Basic Structure (IR Coelho).'
      ],
      memoryAids: const [
        'Mnemonic - 31B = Blanket Shield (Ninth Schedule), with April 24, 1973 Cutoff.'
      ],
      historicalBackground:
          'Enacted in 1951 to protect land reform Acts of state legislatures from court challenges. Originally contained 13 Acts; now contains 284 Acts.',
      constituentAssemblyDebates: const [
        'Provisional Parliament debates in May-June 1951.'
      ],
      objectivesResolutionLinks: const [
        'Protects progressive agrarian redistribution legislation.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '1st Constitutional Amendment Act, 1951',
          beforeText: 'Article 31B and Ninth Schedule did not exist.',
          afterText: 'Inserted Article 31B and Ninth Schedule.',
          reason: 'Provide absolute immunity to state agrarian laws.',
          effectiveDate: DateTime(1951, 6, 18),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'I.R. Coelho v. State of Tamil Nadu',
          year: 2007,
          bench: 'Supreme Court (9-Judge Bench)',
          legalPrinciple:
              'Unanimously held: 1) Judicial review is a basic feature of Constitution, 2) Laws placed in Ninth Schedule after April 24, 1973 are subject to judicial review, 3) If a Ninth Schedule law violates FRs forming part of Basic Structure, it will be struck down.',
          importance: 'Ninth Schedule immunity subjected to Basic Structure.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 13', 'Article 31A', 'Article 31C', 'Article 368'],
      relatedSchedules: const ['KO-SCHED-9'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART31B', 'PYQ_UPSC_2020_ART31B', 'PYQ_CDS_2022_ART31B'],
      pyqIds: const ['PYQ_UPSC_2018_ART31B', 'PYQ_UPSC_2020_ART31B', 'PYQ_CDS_2022_ART31B'],
      learningObjectives: const [
        'Explain the purpose of Article 31B and Ninth Schedule.',
        'State the cutoff date established in I.R. Coelho (April 24, 1973).',
        'Compare the scope of Article 31A (Art 14 & 19) with Article 31B (All FRs).'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        '1st Amd 1951 + Ninth Schedule.',
        'Protects against ALL FRs.',
        'IR Coelho (2007): Laws added post-April 24, 1973 subject to Judicial Review under Basic Structure.'
      ],
      trapAreas: const [
        'Selecting options stating Ninth Schedule has absolute immunity today (Post-1973 laws are subject to judicial review).'
      ],
      frequentlyConfusedWith: const ['Article 31A', 'Article 31C'],
      timesAsked: 22,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 12, 'StatePSC': 7, 'CDS': 3},
      difficultyDistribution: const {'Easy': 2, 'Medium': 6, 'Hard': 14},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        '(2007) 2 SCC 1 (IR Coelho)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1951, 6, 18),
      evidenceReferences: const ['REF_SC_IR_COELHO_2007'],
    ),

    // ------------------------------------------------------------------------
    // Article 31C: Saving of Laws Giving Effect to Certain Directive Principles
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-31C',
      articleNumber: '31C',
      officialTitle: 'Saving of laws giving effect to certain directive principles',
      part: 'Part III',
      chapter: 'Saving of Certain Laws',
      originalNumber: '31C',
      currentNumber: '31C',
      title: 'Article 31C: Primacy of DPSP Art 39(b) & 39(c) over FR Articles 14 & 19',
      officialName: 'ARTICLE 31C',
      description:
          'Laws enacted to give effect to DPSP Article 39(b) and 39(c) cannot be struck down for violating Article 14 or Article 19.\nSecond part ("no law containing declaration shall be called in question in any court") struck down in Kesavananda Bharati (1973).\n42nd Amd expansion to ALL DPSPs struck down in Minerva Mills (1980). Valid version restores primacy of ONLY 39(b) & 39(c).',
      officialConstitutionalText:
          'Notwithstanding anything contained in article 13, no law giving effect to the policy of the State towards securing all or any of the principles laid down in clause (b) or clause (c) of article 39 shall be deemed to be void on the ground that it is inconsistent with, or takes away or abridges any of the rights conferred by article 14 or article 19; and no law containing a declaration that it is for giving effect to such policy shall be called in question in any court on the ground that it does not give effect to such policy...',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 31C was inserted by the 25th Constitutional Amendment Act 1971 to give primacy to DPSP Article 39(b) (distribution of material resources) and 39(c) (prevention of concentration of wealth) over Fundamental Rights Articles 14 and 19. It famously declared: "Where Article 31C comes in, Article 14 goes out." The 42nd Amendment 1976 attempted to extend this immunity to ALL DPSPs, but SC in Minerva Mills (1980) struck down that expansion as violating Basic Structure. Thus, ONLY laws giving effect to Art 39(b) & 39(c) enjoy Art 31C immunity.',
      searchKeywords: const [
        'Article 31C',
        'Primacy of DPSP over FR',
        '25th Amendment 1971',
        'Article 39(b) and 39(c)',
        'Minerva Mills Case 1980',
        'Kesavananda Bharati',
        'Property Redistributive Bench 2024'
      ],
      keyTakeaways: const [
        'Inserted by 25th Constitutional Amendment Act, 1971.',
        'Saves laws securing DPSP Art 39(b) and 39(c) from challenge under Art 14 and Art 19.',
        'Kesavananda Bharati (1973): Upheld 1st part of 31C; struck down 2nd part barring judicial review.',
        '42nd Amendment (1976) expanded 31C to ALL DPSPs; struck down by SC in Minerva Mills (1980) as damaging Basic Structure.',
        'Current Constitutional Position: ONLY laws implementing Art 39(b) and 39(c) override Articles 14 and 19.'
      ],
      commonMisconceptions: const [
        'Misconception: All Directive Principles override Fundamental Rights Articles 14 and 19. Reality: Minerva Mills struck down total DPSP primacy. ONLY Art 39(b) & 39(c) have primacy under 31C.',
        'Misconception: Courts cannot check if a law actually gives effect to Art 39(b)/39(c). Reality: The second part barring court scrutiny was invalidated in Kesavananda Bharati.'
      ],
      memoryAids: const [
        'Mnemonic - 31C = 39(b) + 39(c) > 14 + 19.'
      ],
      historicalBackground:
          'Enacted by Indira Gandhi Govt in 1971 to facilitate socialist economic policies, land ceiling, and nationalization of key industries.',
      constituentAssemblyDebates: const [
        'Post-Constituent Assembly legislative development during 25th Amendment debates in Parliament (1971).'
      ],
      objectivesResolutionLinks: const [
        'Translates socialist economic justice principles.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '25th Constitutional Amendment Act, 1971',
          beforeText: 'Article 31C did not exist.',
          afterText: 'Inserted Article 31C giving primacy to Art 39(b) & (c) over Art 14, 19, 31.',
          reason: 'Enable socialist economic legislation.',
          effectiveDate: DateTime(1972, 4, 20),
        ),
        ArticleAmendmentRecord(
          amendmentName: '42nd Constitutional Amendment Act, 1976',
          beforeText: 'Article 31C applied only to Art 39(b) and (c).',
          afterText: 'Extended Article 31C protection to ALL Directive Principles in Part IV.',
          reason: 'Establish total supremacy of DPSPs over Fundamental Rights.',
          effectiveDate: DateTime(1977, 1, 3),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Kesavananda Bharati v. State of Kerala',
          year: 1973,
          bench: 'Supreme Court (13-Judge Bench)',
          legalPrinciple:
              'Upheld validity of 1st part of Art 31C (protecting Art 39(b)&(c) laws). Struck down 2nd part ("no law shall be called in question in any court") as violating Judicial Review / Basic Structure.',
          importance: 'Partial invalidation of Art 31C.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Minerva Mills Ltd. v. Union of India',
          year: 1980,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Struck down 42nd Amendment expansion of Art 31C to all DPSPs. Held harmony & balance between Part III FRs and Part IV DPSPs is an essential feature of Basic Structure.',
          importance: 'Restored original scope of Art 31C.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Property Redistributive Case (State of Maharashtra v. Reliance Airport Developers)',
          year: 2024,
          bench: 'Supreme Court (9-Judge Bench)',
          legalPrinciple:
              'Re-examined Art 31C and Art 39(b). Held not all private property falls automatically within "material resources of the community" under Art 39(b).',
          importance: 'Modern interpretation of Art 39(b) & 31C.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedArticles: const ['Article 14', 'Article 19', 'Article 39(b)', 'Article 39(c)', 'Article 368'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART31C', 'PYQ_UPSC_2020_ART31C', 'PYQ_CDS_2021_ART31C'],
      pyqIds: const ['PYQ_UPSC_2017_ART31C', 'PYQ_UPSC_2020_ART31C', 'PYQ_CDS_2021_ART31C'],
      learningObjectives: const [
        'Explain the relation between Article 31C and Articles 39(b) & 39(c).',
        'State the Kesavananda Bharati ruling on the second part of Article 31C.',
        'Describe the Minerva Mills judgment on the 42nd Amendment expansion of Article 31C.'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        '25th Amd 1971.',
        'Art 39(b) & (c) laws > Art 14 & 19.',
        'Kesavananda (1973): Struck down bar on judicial review.',
        'Minerva Mills (1980): Struck down 42nd Amd expansion to all DPSPs.',
        'Balance between FRs & DPSPs = Basic Structure.'
      ],
      trapAreas: const [
        'Believing 42nd Amendment expansion of 31C is active (Minerva Mills struck it down in 1980).',
        'Thinking 31C protects laws implementing ALL DPSPs (It protects ONLY Art 39(b) and 39(c)).'
      ],
      frequentlyConfusedWith: const ['Article 31A', 'Article 31B'],
      timesAsked: 24,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 14, 'StatePSC': 7, 'CDS': 3},
      difficultyDistribution: const {'Easy': 1, 'Medium': 5, 'Hard': 18},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        '(1973) 4 SCC 225 (Kesavananda)',
        'AIR 1980 SC 1789 (Minerva Mills)',
        '2024 INSC 834 (9-Judge Bench Property Case)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1972, 4, 20),
      evidenceReferences: const ['REF_SC_KESAVANANDA_1973', 'REF_SC_MINERVA_MILLS_1980'],
    ),

    // ------------------------------------------------------------------------
    // Article 31D: [REPEALED] Saving of Laws in Respect of Anti-National Activities
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-31D',
      articleNumber: '31D',
      officialTitle: 'Saving of laws in respect of anti-national activities [Repealed]',
      part: 'Part III',
      chapter: 'Saving of Certain Laws',
      originalNumber: '31D',
      currentNumber: '31D',
      title: 'Article 31D: Protection of Anti-National Activity Laws [REPEALED]',
      officialName: 'ARTICLE 31D [REPEALED]',
      description:
          'Inserted by 42nd Constitutional Amendment Act, 1976 to save laws controlling anti-national activities and associations from Part III challenge. Repealed by 43rd Constitutional Amendment Act, 1977.',
      officialConstitutionalText:
          '[Repealed by the Constitution (Forty-third Amendment) Act, 1977, section 2 (w.e.f. 13-4-1978).]',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 31D was inserted during the Emergency by the 42nd Constitutional Amendment Act 1976 to protect laws prohibiting "anti-national activities" or "anti-national associations" from being challenged under any Fundamental Right in Part III. Criticized for giving draconian unguided power to Parliament to ban political opposition groups. REPEALED in its entirety by the 43rd Constitutional Amendment Act 1977 under the Janata Party administration.',
      searchKeywords: const [
        'Article 31D',
        'Anti national activities repealed',
        '42nd Amendment 1976',
        '43rd Amendment 1977',
        'Emergency legislation repealed'
      ],
      keyTakeaways: const [
        'Inserted by 42nd Constitutional Amendment Act, 1976 during National Emergency.',
        'Saved laws preventing anti-national activities from Part III FR challenges.',
        'REPEALED completely by 43rd Constitutional Amendment Act, 1977 (w.e.f. April 13, 1978).',
        'Demonstrates restoration of fundamental civil liberties after Emergency.'
      ],
      commonMisconceptions: const [
        'Misconception: Article 31D is still active in the Indian Constitution. Reality: It was repealed in 1977 by the 43rd Amendment Act.'
      ],
      memoryAids: const [
        'Mnemonic - 42 inserted 31D, 43 deleted 31D.'
      ],
      historicalBackground:
          'Enacted during 1975-77 Emergency to suppress opposition associations. Promptly repealed by post-Emergency Parliament.',
      constituentAssemblyDebates: const [
        'Post-Constituent Assembly parliamentary history of Emergency amendments.'
      ],
      objectivesResolutionLinks: const [
        'Restores democratic freedom of association.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '42nd Constitutional Amendment Act, 1976',
          beforeText: 'Article 31D did not exist.',
          afterText: 'Inserted Article 31D protecting anti-national activity laws.',
          reason: 'Grant draconian powers to curb anti-national associations.',
          effectiveDate: DateTime(1977, 1, 3),
        ),
        ArticleAmendmentRecord(
          amendmentName: '43rd Constitutional Amendment Act, 1977',
          beforeText: 'Article 31D was present in Part III.',
          afterText: 'Omitted Article 31D from Part III in its entirety.',
          reason: 'Restore civil liberties and dismantle Emergency provisions.',
          effectiveDate: DateTime(1978, 4, 13),
        )
      ],
      caseLaw: const [],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 19(1)(c)', 'Article 31A', 'Article 31B', 'Article 31C'],
      relatedPYQs: const ['PYQ_UPSC_2019_ART31D'],
      pyqIds: const ['PYQ_UPSC_2019_ART31D'],
      learningObjectives: const [
        'Identify the Amendment Act that inserted Art 31D (42nd Amd 1976) and repealed it (43rd Amd 1977).'
      ],
      difficulty: 'Medium',
      examImportance: 'Low-Medium',
      revisionPoints: const [
        '42nd Amd 1976 inserted.',
        '43rd Amd 1977 REPEALED.',
        'Protected laws against anti-national activities.'
      ],
      trapAreas: const [
        'Confusing Article 31D (Repealed) with Article 31C (Active).'
      ],
      frequentlyConfusedWith: const ['Article 31C', 'Article 32A'],
      timesAsked: 4,
      lastAskedYear: 2019,
      trend: 'Low Frequency',
      examDistribution: const {'UPSC': 2, 'StatePSC': 2},
      difficultyDistribution: const {'Easy': 2, 'Medium': 2, 'Hard': 0},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.repealed,
      effectiveDate: DateTime(1977, 1, 3),
      evidenceReferences: const ['REF_PARL_43RD_AMD_1977'],
    ),

    // ------------------------------------------------------------------------
    // Article 32: Remedies for Enforcement of Rights (Heart and Soul)
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-32',
      articleNumber: '32',
      officialTitle: 'Remedies for enforcement of rights conferred by this Part',
      part: 'Part III',
      chapter: 'Right to Constitutional Remedies',
      originalNumber: '32',
      currentNumber: '32',
      title: 'Article 32: Right to Constitutional Remedies & Writs',
      officialName: 'ARTICLE 32',
      description:
          '(1) Guaranteed right to move Supreme Court by appropriate proceedings for enforcement of Part III rights.\n(2) Supreme Court power to issue directions/orders/writs (Habeas Corpus, Mandamus, Prohibition, Quo Warranto, Certiorari).\n(3) Parliament power to empower other courts to issue writs within local limits.\n(4) Right guaranteed by this article shall NOT be suspended except as otherwise provided by this Constitution (Article 359 during Emergency).\nDr. Ambedkar: "Heart and Soul of the Constitution". Part of Basic Structure.',
      officialConstitutionalText:
          '(1) The right to move the Supreme Court by appropriate proceedings for the enforcement of the rights conferred by this Part is guaranteed.\n(2) The Supreme Court shall have power to issue directions or orders or writs, including writs in the nature of habeas corpus, mandamus, prohibition, quo warranto and certiorari, whichever may be appropriate, for the enforcement of any of the rights conferred by this Part.\n(3) Without prejudice to the powers conferred on the Supreme Court by clauses (1) and (2), Parliament may by law empower any other court to exercise within the local limits of its jurisdiction all or any of the powers exercisable by the Supreme Court under clause (2).\n(4) The right guaranteed by this article shall not be suspended except as otherwise provided for by this Constitution.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 32 is itself a Fundamental Right to enforce all other Fundamental Rights. Dr. B.R. Ambedkar called it "the very soul of the Constitution and the very heart of it." Guaranteed right to move the Supreme Court directly. SC is the protector and guarantor of FRs. 5 High Writs: 1) Habeas Corpus (To have the body - against state & private persons), 2) Mandamus (We command - perform public duty), 3) Prohibition (To forbid - lower judicial court preventive), 4) Certiorari (To be certified - quash lower court order corrective), 5) Quo Warranto (By what authority - public office title). Article 32 is part of the Basic Structure (L. Chandra Kumar case). Res Judicata applies except for Habeas Corpus.',
      searchKeywords: const [
        'Article 32',
        'Heart and Soul of Constitution',
        'Constitutional Remedies',
        'Five Writs',
        'Habeas Corpus',
        'Mandamus',
        'Prohibition',
        'Certiorari',
        'Quo Warranto',
        'L Chandra Kumar Basic Structure',
        'Res Judicata Daryao'
      ],
      keyTakeaways: const [
        'Article 32 is ITSELF a Fundamental Right (unlike Art 226 which is a constitutional right).',
        'Dr. B.R. Ambedkar termed Article 32 as "the Heart and Soul of the Constitution".',
        'Part of Basic Structure of the Constitution (Fertilizer Corp 1981, L. Chandra Kumar 1997).',
        '5 Writs: Habeas Corpus (body release), Mandamus (perform public duty), Prohibition (prevent lower court excess), Certiorari (quash lower court order), Quo Warranto (check title to public office).',
        'Habeas Corpus can be issued against BOTH State and private individuals.',
        'Res Judicata applies to Art 32 petitions (Daryao 1961), EXCEPT for Habeas Corpus petitions.',
        'Art 32 applies ONLY for enforcement of Part III FRs (unlike Art 226 which covers FRs + legal rights).'
      ],
      commonMisconceptions: const [
        'Misconception: Article 32 writ jurisdiction is wider than Article 226. Reality: Article 226 is WIDER than Art 32 because Art 226 covers FRs AND ordinary legal/constitutional rights, whereas Art 32 covers ONLY Part III FRs.',
        'Misconception: Mandamus can be issued against a private individual or discretionary duty. Reality: Mandamus lies ONLY against public authorities to enforce mandatory statutory duties.'
      ],
      memoryAids: const [
        'Mnemonic - 5 Writs: H-M-P-Q-C (Habeas corpus, Mandamus, Prohibition, Quo warranto, Certiorari).',
        'Mnemonic - Ambedkar: "Heart and Soul of the Constitution".'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 9, 1948 (Draft Article 25). Dr. Ambedkar declared that without Article 32, the entire Constitution would be a nullity.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 9, 1948) - Historic debate on Draft Article 25.',
        'Dr. B.R. Ambedkar\'s famous quote: "If I was asked to name any particular article in this Constitution as the most important... I could not specify any other article except this one. It is the very soul of the Constitution and the very heart of it."'
      ],
      objectivesResolutionLinks: const [
        'Provides the ultimate enforcement mechanism for all constitutional guarantees.'
      ],
      amendmentHistory: [],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Romesh Thappar v. State of Madras',
          year: 1950,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Held Supreme Court is the protector and guarantor of Fundamental Rights; petitioner need not exhaust remedies in High Court before moving SC under Art 32.',
          importance: 'Direct access to Supreme Court under Art 32 established.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Daryao v. State of Uttar Pradesh',
          year: 1961,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Rule of Res Judicata applies to Art 32. If a High Court dismisses Art 226 petition on merits, Art 32 petition on same facts in SC is barred (appeal lies to SC). Exception: Habeas Corpus.',
          importance: 'Res Judicata applicable to Art 32 except Habeas Corpus.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Bandhua Mukti Morcha v. Union of India',
          year: 1984,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Public Interest Litigation (PIL) relaxed locus standi under Art 32. Any public-spirited citizen can move SC for enforcement of FRs of disadvantaged groups.',
          importance: 'PIL expansion under Article 32.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'M.C. Mehta v. Union of India (Oleum Gas Leak Case)',
          year: 1987,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'SC power under Art 32 is not limited to issuing traditional writs; includes power to award monetary compensation for FR violation and formulate new remedies (Absolute Liability doctrine).',
          importance: 'Compensation & Absolute Liability under Art 32.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'L. Chandra Kumar v. Union of India',
          year: 1997,
          bench: 'Supreme Court (7-Judge Bench)',
          legalPrinciple:
              'Unanimously held writ jurisdiction of Supreme Court under Art 32 and High Courts under Art 226 forms part of the Basic Structure of the Constitution. Cannot be excluded by constitutional amendment.',
          importance: 'Writ Jurisdiction declared Basic Structure.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III', 'KO-PART-V'],
      relatedArticles: const ['Article 13', 'Article 139', 'Article 142', 'Article 226', 'Article 359'],
      relatedPYQs: const ['PYQ_UPSC_2017_ART32', 'PYQ_UPSC_2019_ART32', 'PYQ_UPSC_2022_ART32'],
      pyqIds: const ['PYQ_UPSC_2017_ART32', 'PYQ_UPSC_2019_ART32', 'PYQ_UPSC_2022_ART32'],
      learningObjectives: const [
        'Explain why Dr. Ambedkar called Article 32 the "Heart and Soul of the Constitution".',
        'Compare the scope of writ jurisdiction under Article 32 and Article 226.',
        'Define each of the 5 writs (Habeas Corpus, Mandamus, Prohibition, Certiorari, Quo Warranto).'
      ],
      difficulty: 'High',
      examImportance: 'Critical',
      revisionPoints: const [
        'Fundamental Right to enforce FRs.',
        '"Heart & Soul" (Ambedkar).',
        'Basic Structure (L. Chandra Kumar 1997).',
        '5 Writs: Habeas Corpus (State + Private), Mandamus, Prohibition, Certiorari, Quo Warranto.',
        'Art 32 narrower than Art 226 in subject scope (Art 32 = FRs only; Art 226 = FRs + legal rights).',
        'Res Judicata applies except Habeas Corpus (Daryao 1961).'
      ],
      trapAreas: const [
        'Claiming Art 32 is wider than Art 226 (Art 226 is wider in subject scope).',
        'Thinking Mandamus can be issued against private bodies (Mandamus lies ONLY against public/statutory bodies).'
      ],
      frequentlyConfusedWith: const ['Article 226 (High Court Writ Jurisdiction)', 'Article 139'],
      timesAsked: 45,
      lastAskedYear: 2024,
      trend: 'Very High Frequency',
      examDistribution: const {'UPSC': 25, 'StatePSC': 12, 'CDS': 8},
      difficultyDistribution: const {'Easy': 3, 'Medium': 12, 'Hard': 30},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'CAD Vol. VII p. 953',
        'AIR 1950 SC 124 (Romesh Thappar)',
        '(1997) 3 SCC 261 (L. Chandra Kumar)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_CAD_VOL7_ART32', 'REF_SC_L_CHANDRA_KUMAR_1997'],
    ),

    // ------------------------------------------------------------------------
    // Article 32A: [REPEALED] Constitutional Validity of State Laws
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-32A',
      articleNumber: '32A',
      officialTitle: 'Constitutional validity of State laws not to be considered in proceedings under article 32 [Repealed]',
      part: 'Part III',
      chapter: 'Right to Constitutional Remedies',
      originalNumber: '32A',
      currentNumber: '32A',
      title: 'Article 32A: Bar on SC Considering State Laws under Art 32 [REPEALED]',
      officialName: 'ARTICLE 32A [REPEALED]',
      description:
          'Inserted by 42nd Constitutional Amendment Act, 1976 to prohibit Supreme Court from considering constitutional validity of State laws under Article 32. Repealed by 43rd Constitutional Amendment Act, 1977.',
      officialConstitutionalText:
          '[Repealed by the Constitution (Forty-third Amendment) Act, 1977, section 3 (w.e.f. 13-4-1978).]',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 32A was inserted during the Emergency by the 42nd Constitutional Amendment Act 1976. It barred the Supreme Court from examining the constitutional validity of State laws in Article 32 writ petitions unless the validity of a Central law was also questioned. Severe restriction on judicial review. REPEALED by the 43rd Constitutional Amendment Act 1977.',
      searchKeywords: const [
        'Article 32A',
        'State laws validity bar repealed',
        '42nd Amendment 1976',
        '43rd Amendment 1977'
      ],
      keyTakeaways: const [
        'Inserted by 42nd Constitutional Amendment Act, 1976.',
        'Attempted to restrict Supreme Court writ powers over State laws.',
        'REPEALED by 43rd Constitutional Amendment Act, 1977 (w.e.f. April 13, 1978).'
      ],
      commonMisconceptions: const [
        'Misconception: Supreme Court cannot examine State laws under Article 32 today. Reality: Article 32A was repealed in 1977.'
      ],
      memoryAids: const [
        'Mnemonic - 42 inserted 32A restriction; 43 deleted 32A restriction.'
      ],
      historicalBackground:
          'Emergency amendment designed to compartmentalize state vs central judicial review. Dismantled post-Emergency.',
      constituentAssemblyDebates: const [
        'Post-Constituent Assembly parliamentary legislative history.'
      ],
      objectivesResolutionLinks: const [
        'Restores unified judicial review.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '42nd Constitutional Amendment Act, 1976',
          beforeText: 'Article 32A did not exist.',
          afterText: 'Inserted Article 32A restricting SC judicial review over State laws.',
          reason: 'Restrict judicial review powers of Supreme Court during Emergency.',
          effectiveDate: DateTime(1977, 1, 3),
        ),
        ArticleAmendmentRecord(
          amendmentName: '43rd Constitutional Amendment Act, 1977',
          beforeText: 'Article 32A was present in Part III.',
          afterText: 'Omitted Article 32A from Part III.',
          reason: 'Restore full judicial review power of Supreme Court under Art 32.',
          effectiveDate: DateTime(1978, 4, 13),
        )
      ],
      caseLaw: const [],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 32', 'Article 226', 'Article 228A'],
      relatedPYQs: const ['PYQ_UPSC_2019_ART32A'],
      pyqIds: const ['PYQ_UPSC_2019_ART32A'],
      learningObjectives: const [
        'Identify 42nd Amd insertion and 43rd Amd repeal of Article 32A.'
      ],
      difficulty: 'Medium',
      examImportance: 'Low',
      revisionPoints: const [
        '42nd Amd 1976 inserted.',
        '43rd Amd 1977 REPEALED.'
      ],
      trapAreas: const [
        'Confusing Article 32 (Active) with Article 32A (Repealed).'
      ],
      frequentlyConfusedWith: const ['Article 32', 'Article 31D'],
      timesAsked: 3,
      lastAskedYear: 2019,
      trend: 'Low Frequency',
      examDistribution: const {'UPSC': 2, 'StatePSC': 1},
      difficultyDistribution: const {'Easy': 2, 'Medium': 1, 'Hard': 0},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.repealed,
      effectiveDate: DateTime(1977, 1, 3),
      evidenceReferences: const ['REF_PARL_43RD_AMD_1977'],
    ),

    // ------------------------------------------------------------------------
    // Article 33: Power of Parliament to Modify Rights for Forces
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-33',
      articleNumber: '33',
      officialTitle: 'Power of Parliament to modify the rights conferred by this Part in their application to Forces, etc.',
      part: 'Part III',
      chapter: 'Right to Constitutional Remedies',
      originalNumber: '33',
      currentNumber: '33',
      title: 'Article 33: Modification of Fundamental Rights for Armed Forces & Agencies',
      officialName: 'ARTICLE 33',
      description:
          'Parliament may by law restrict or abrogate Fundamental Rights in their application to: (a) Armed Forces, (b) Forces charged with maintenance of public order (Police/Paramilitary), (c) Intelligence/counter-intelligence agencies, (d) Telecommunication systems connected to forces/agencies, to ensure proper discharge of duties and maintenance of discipline.\nPARLIAMENT ALONE has this power (not State Legislatures). Court Martials exempt from SC writ jurisdiction under Art 136(2).',
      officialConstitutionalText:
          'Parliament may, by law, determine to what extent any of the rights conferred by this Part shall, in their application to,— (a) the members of the Armed Forces; or (b) the members of the Forces charged with the maintenance of public order; or (c) persons employed in any bureau or other organisation established by the State for purposes of intelligence or counter intelligence; or (d) persons employed in, or in connection with, the telecommunication systems set up for the purposes of any force, bureau or organisation referred to in clauses (a) to (c), be restricted or abrogated so as to ensure the proper discharge of their duties and the maintenance of discipline among them.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 33 empowers PARLIAMENT EXCLUSIVELY to restrict or abrogate any Fundamental Rights of members of the Armed Forces, Police Forces, Intelligence Bureaus (IB, R&AW), and associated telecom personnel to ensure strict military discipline and duty performance. Laws passed under Art 33 (e.g. Army Act 1950, Navy Act 1957, Air Force Act 1950, BSF Act 1968) cannot be challenged in any court for violating Part III FRs. Applies to non-combatant employees (cooks, barbers, mechanics) of armed forces as well (LD Balam case).',
      searchKeywords: const [
        'Article 33',
        'Armed Forces Fundamental Rights',
        'Parliament exclusive power',
        'Police and Intelligence personnel',
        'Army Act Air Force Act Navy Act',
        'LD Balam Case non-combatants'
      ],
      keyTakeaways: const [
        'EXCLUSIVELY Parliament can make laws under Article 33 (State Legislatures cannot).',
        'Applies to Armed Forces, Police/Public order forces, Intelligence agencies, and connected Telecommunication staff.',
        'Covers BOTH combatant personnel and non-combatant civilian employees (cooks, tailors, barbers, mechanics) in armed forces units.',
        'Laws passed under Art 33 are immune from challenge under Part III FRs.',
        'Court Martials (military courts) are exempt from SC Special Leave Petition jurisdiction under Art 136(2).'
      ],
      commonMisconceptions: const [
        'Misconception: State Legislatures can restrict fundamental rights of state police personnel. Reality: ONLY Parliament has the power under Art 33 to restrict FRs of police or armed forces.',
        'Misconception: Non-combatant workers in military units retain full Art 19 rights. Reality: SC in LD Balam held Art 33 covers non-combatant employees of armed forces as well.'
      ],
      memoryAids: const [
        'Mnemonic - 33 = Armed Forces Discipline (Parliament Only).'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 9, 1948 (Draft Article 26). Essential to ensure national defense security and prevent mutiny or political strikes in armed forces.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 9, 1948) - Speeches by Ambedkar, K.T. Shah.',
        'Unanimous agreement that military discipline requires restricted civil freedoms.'
      ],
      objectivesResolutionLinks: const [
        'Safeguards sovereign security and territorial integrity.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '50th Constitutional Amendment Act, 1984',
          beforeText: 'Article 33 covered Armed Forces and Public Order Forces.',
          afterText: 'Substituted Article 33 expanding coverage to Intelligence agencies and Telecommunication systems.',
          reason: 'Cover IB, R&AW, and defense telecom staff.',
          effectiveDate: DateTime(1984, 9, 11),
        )
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Ram Sarup v. Union of India',
          year: 1965,
          bench: 'Supreme Court (5-Judge Bench)',
          legalPrinciple:
              'Upheld Army Act 1950 under Art 33. Held provisions of Army Act restricting fundamental rights of armed forces personnel are valid even if inconsistent with Part III.',
          importance: 'Army Act validity under Art 33 affirmed.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Lt. Col. Prithi Pal Singh Bedi v. Union of India',
          year: 1982,
          bench: 'Supreme Court (3-Judge Bench)',
          legalPrinciple:
              'Held while Art 33 permits restriction of FRs for armed forces, court-martial procedure must still maintain basic fairness and human dignity.',
          importance: 'Basic fairness in court martial required.',
          status: 'Landmark Precedent',
        ),
        ArticleCaseLawRecord(
          caseName: 'Union of India v. L.D. Balam',
          year: 2002,
          bench: 'Supreme Court (2-Judge Bench)',
          legalPrinciple:
              'Held expression "members of Armed Forces" in Art 33 includes non-combatant employees such as cooks, barbers, carpenters, and tailors attached to military units.',
          importance: 'Non-combatant coverage under Art 33.',
          status: 'Landmark Precedent',
        )
      ],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 19', 'Article 34', 'Article 35', 'Article 136(2)'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART33', 'PYQ_UPSC_2021_ART33', 'PYQ_CDS_2020_ART33'],
      pyqIds: const ['PYQ_UPSC_2018_ART33', 'PYQ_UPSC_2021_ART33', 'PYQ_CDS_2020_ART33'],
      learningObjectives: const [
        'Identify who has exclusive power under Article 33 (Parliament).',
        'List the 4 categories of personnel covered by Article 33.',
        'State the impact of the 50th Amendment Act 1984 on Article 33.'
      ],
      difficulty: 'Medium',
      examImportance: 'High',
      revisionPoints: const [
        'PARLIAMENT EXCLUSIVE power.',
        'Covers Armed Forces, Police, Intelligence, Telecom staff.',
        'Includes non-combatant employees (LD Balam 2002).',
        '50th Amd 1984 added Intelligence & Telecom personnel.'
      ],
      trapAreas: const [
        'Selecting options giving State Legislatures power under Art 33 (ONLY Parliament has power).',
        'Excluding cooks/barbers in military units from Art 33 (Non-combatants ARE covered).'
      ],
      frequentlyConfusedWith: const ['Article 34 (Martial Law)', 'Article 35'],
      timesAsked: 14,
      lastAskedYear: 2023,
      trend: 'Medium-High Frequency',
      examDistribution: const {'UPSC': 7, 'StatePSC': 4, 'CDS': 3},
      difficultyDistribution: const {'Easy': 2, 'Medium': 8, 'Hard': 4},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'AIR 1965 SC 247 (Ram Sarup)',
        '(2002) 5 SCC 745 (LD Balam)'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_SC_RAM_SARUP_1965', 'REF_SC_LD_BALAM_2002'],
    ),

    // ------------------------------------------------------------------------
    // Article 34: Restriction on Rights While Martial Law is in Force
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-34',
      articleNumber: '34',
      officialTitle: 'Restriction on rights conferred by this Part while martial law is in force in any area',
      part: 'Part III',
      chapter: 'Right to Constitutional Remedies',
      originalNumber: '34',
      currentNumber: '34',
      title: 'Article 34: Restriction of Rights During Martial Law & Indemnity Act',
      officialName: 'ARTICLE 34',
      description:
          'Parliament may by law indemnify any person in service of Union or State or any other person for any act done in connection with maintenance or restoration of order in any area where Martial Law was in force, and validate any sentence, punishment, or forfeiture.\nMartial Law (military rule) is NOT defined in Constitution; distinct from National Emergency (Article 352).',
      officialConstitutionalText:
          'Notwithstanding anything in the foregoing provisions of this Part, Parliament may by law indemnify any person in the service of the Union or of a State or any other person in respect of any act done by him in connection with the maintenance or restoration of order in any area within the territory of India where martial law was in force or validate any sentence passed, punishment sentenced, forfeiture ordered or other act done under martial law in such area.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 34 empowers Parliament to enact an Act of Indemnity protecting military or government personnel from legal liability for actions taken during Martial Law (military rule) to restore public order. "Martial Law" is borrowed from British common law and means military authority taking over civilian administration during extraordinary breakdown of law and order. Martial Law is NOT defined in the Constitution. Distinct from National Emergency (Art 352): Martial Law affects FRs severely, suspends civilian courts, applies to specific local areas, and has no formal constitutional declaration procedure.',
      searchKeywords: const [
        'Article 34',
        'Martial Law',
        'Act of Indemnity',
        'Distinction between Martial Law and National Emergency',
        'Military Rule'
      ],
      keyTakeaways: const [
        'Empowers Parliament to pass Act of Indemnity protecting officials for actions during Martial Law.',
        'Word "Martial Law" is NOT defined anywhere in the Constitution.',
        'Applies to specific local areas where civilian administration has collapsed and military takes control.',
        'Distinction: National Emergency (Art 352) covers whole country/state, affects executive-legislative relations, backed by explicit constitutional procedure; Martial Law affects FRs & civilian courts locally.'
      ],
      commonMisconceptions: const [
        'Misconception: Martial Law is defined under Article 34. Reality: It is nowhere defined in the Constitution.',
        'Misconception: Martial Law and National Emergency (Art 352) are identical. Reality: They are separate concepts; Martial Law involves actual military rule replacing civilian courts locally.'
      ],
      memoryAids: const [
        'Mnemonic - 34 = Martial Law & Act of Indemnity.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 9, 1948 (Draft Article 27). Borrowed from British Common Law indemnity practice during rebellion or armed insurrection.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 9, 1948) - Speeches by Thakur Das Bhargava, Ambedkar.',
        'Reassuring Assembly that Act of Indemnity can only be passed by Parliament after martial law ends.'
      ],
      objectivesResolutionLinks: const [
        'Maintains public order during extreme civil insurrection.'
      ],
      amendmentHistory: [],
      caseLaw: [],
      relatedParts: const ['KO-PART-III', 'KO-PART-XVIII'],
      relatedArticles: const ['Article 19', 'Article 33', 'Article 35', 'Article 352'],
      relatedPYQs: const ['PYQ_UPSC_2019_ART34', 'PYQ_CDS_2021_ART34'],
      pyqIds: const ['PYQ_UPSC_2019_ART34', 'PYQ_CDS_2021_ART34'],
      learningObjectives: const [
        'Explain the concept of Act of Indemnity under Article 34.',
        'Differentiate between Martial Law and National Emergency (Article 352).'
      ],
      difficulty: 'Medium',
      examImportance: 'Medium',
      revisionPoints: const [
        'Parliament power to pass Act of Indemnity.',
        'Martial Law NOT defined in Constitution.',
        'Local military rule replacing civilian courts.',
        'Distinct from National Emergency (Art 352).'
      ],
      trapAreas: const [
        'Selecting options claiming Martial Law is defined in Art 34 (It is NOT defined).'
      ],
      frequentlyConfusedWith: const ['Article 352 (National Emergency)', 'Article 33'],
      timesAsked: 9,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      examDistribution: const {'UPSC': 5, 'StatePSC': 3, 'CDS': 1},
      difficultyDistribution: const {'Easy': 3, 'Medium': 5, 'Hard': 1},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_CAD_VOL7_ART34'],
    ),

    // ------------------------------------------------------------------------
    // Article 35: Legislation to Give Effect to the Provisions of Part III
    // ------------------------------------------------------------------------
    ArticleKnowledgeObject(
      objectId: 'KO-ART-35',
      articleNumber: '35',
      officialTitle: 'Legislation to give effect to the provisions of this Part',
      part: 'Part III',
      chapter: 'Right to Constitutional Remedies',
      originalNumber: '35',
      currentNumber: '35',
      title: 'Article 35: Exclusive Parliamentary Power to Legislate on Part III Offences',
      officialName: 'ARTICLE 35',
      description:
          'Power to make laws to give effect to Part III is vested EXCLUSIVELY in Parliament (State Legislatures have NO power):\n(a)(i) Prescribing residence requirements for employment under Art 16(3);\n(a)(ii) Empowering courts other than SC/HC to issue writs under Art 32(3);\n(a)(iii) Modifying FRs for Armed Forces under Art 33 & Indemnity under Art 34;\n(b) Prescribing punishment for acts declared as offences under Part III (Untouchability Art 17, Human Trafficking/Begar Art 23).\nAll pre-constitutional laws declaring punishments for these offences continue until altered by Parliament.',
      officialConstitutionalText:
          'Notwithstanding anything in this Constitution,— (a) Parliament shall have, and the Legislature of a State shall not have, power to make laws— (i) with respect to any of the matters which under clause (3) of article 16, clause (3) of article 32, article 33 and article 34 may be provided for by law by Parliament; and (ii) for prescribing punishment for those acts which are declared to be offences under this Part; and Parliament shall, as soon as may be after the commencement of this Constitution, make laws for prescribing punishment for the acts referred to in sub-clause (ii);\n(b) any law in force immediately before the commencement of this Constitution... shall continue in force until altered or repealed by Parliament.',
      officialSource: 'Legislative Department, Ministry of Law and Justice',
      languageSupportReady: true,
      originalGarudaExplanation:
          'Article 35 ensures uniform application of Fundamental Rights across all States in India. It vests EXCLUSIVE law-making power in Parliament (to the complete exclusion of State Legislatures) for: 1) Residence criteria for public employment (Art 16(3)), 2) Empowering lower courts to issue writs (Art 32(3)), 3) Restricting FRs for Armed Forces (Art 33), 4) Act of Indemnity (Art 34), and 5) Prescribing punishments for offences against FRs (Untouchability Art 17, Human Trafficking & Forced Labour Art 23). State Legislatures CANNOT pass laws prescribing punishment for Art 17 or Art 23 offences.',
      searchKeywords: const [
        'Article 35',
        'Exclusive Parliamentary legislation',
        'State Legislatures barred',
        'Punishment for Article 17 untouchability',
        'Punishment for Article 23 forced labour',
        'Protection of Civil Rights Act 1955',
        'SC ST Atrocities Act 1989'
      ],
      keyTakeaways: const [
        'Power to enact laws giving effect to Part III rests EXCLUSIVELY with Parliament (State Legislatures barred).',
        'Ensures uniformity of Fundamental Rights and criminal penalization throughout the territory of India.',
        'Parliament enacted Untouchability (Offences) Act 1955 / Protection of Civil Rights Act 1955 under Art 35.',
        'Parliament enacted SC & ST (Prevention of Atrocities) Act 1989 under Art 35.',
        'Parliament enacted Bonded Labour System (Abolition) Act 1976 under Art 35.'
      ],
      commonMisconceptions: const [
        'Misconception: State Legislatures can enact laws prescribing criminal punishments for practicing untouchability under Art 17. Reality: Article 35 vests this power EXCLUSIVELY in Parliament.'
      ],
      memoryAids: const [
        'Mnemonic - 35 = Exclusively Parliament Enforces Part III Penalties.'
      ],
      historicalBackground:
          'Adopted by Constituent Assembly on December 9, 1948 (Draft Article 27A). Dr. Ambedkar insisted that penal laws enforcing fundamental rights must be uniform across the Indian Union, avoiding varied state penalties.',
      constituentAssemblyDebates: const [
        'CAD Vol. VII (December 9, 1948) - Speeches by Dr. B.R. Ambedkar, K.M. Munshi.',
        'Dr. Ambedkar: "If this power were given to State Legislatures, the punishments for untouchability or forced labor would vary from State to State, destroying national uniformity."'
      ],
      objectivesResolutionLinks: const [
        'Guarantees uniform national enforcement of fundamental civil rights.'
      ],
      amendmentHistory: [],
      caseLaw: [],
      relatedParts: const ['KO-PART-III'],
      relatedArticles: const ['Article 16(3)', 'Article 17', 'Article 23', 'Article 32(3)', 'Article 33', 'Article 34'],
      relatedPYQs: const ['PYQ_UPSC_2018_ART35', 'PYQ_UPSC_2021_ART35', 'PYQ_CDS_2022_ART35'],
      pyqIds: const ['PYQ_UPSC_2018_ART35', 'PYQ_UPSC_2021_ART35', 'PYQ_CDS_2022_ART35'],
      learningObjectives: const [
        'Explain why Article 35 vests law-making power exclusively in Parliament.',
        'List the specific Part III provisions where State Legislatures are barred from making laws.',
        'Identify statutes enacted under Article 35 (PCR Act 1955, SC/ST Act 1989).'
      ],
      difficulty: 'High',
      examImportance: 'High',
      revisionPoints: const [
        'PARLIAMENT EXCLUSIVE power (State Legislatures barred).',
        'Ensures national uniformity.',
        'Covers Art 16(3), Art 32(3), Art 33, Art 34.',
        'Covers criminal penalties for Art 17 (Untouchability) & Art 23 (Forced Labour).'
      ],
      trapAreas: const [
        'Selecting options stating State Legislatures share concurrent power under Art 35 (Parliament power is EXCLUSIVE).'
      ],
      frequentlyConfusedWith: const ['Article 33', 'Article 34'],
      timesAsked: 16,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      examDistribution: const {'UPSC': 9, 'StatePSC': 5, 'CDS': 2},
      difficultyDistribution: const {'Easy': 2, 'Medium': 6, 'Hard': 8},
      citations: const [
        'Legislative Department, Ministry of Law & Justice, Govt of India',
        'CAD Vol. VII p. 981'
      ],
      reviewerId: 'CHIEF_CONSTITUTIONAL_ENGINEER',
      status: ConstitutionStatus.active,
      effectiveDate: DateTime(1950, 1, 26),
      evidenceReferences: const ['REF_CAD_VOL7_ART35'],
    ),
  ];
}
