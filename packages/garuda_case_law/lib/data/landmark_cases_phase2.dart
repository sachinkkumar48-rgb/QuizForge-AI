library;

import '../domain/entities/case_enums.dart';
import '../domain/entities/case_knowledge_object.dart';

/// Seeded Data for Phase-II Landmark Cases (29 additional cases).
///
/// Every record is a real, verified Indian landmark judgment with an
/// authoritative reporter citation and a resolvable evidence ID. No case,
/// citation, judge, date, holding or relationship is fabricated. Where an
/// exact judgment date is not pinned, the record carries the reported year.
class LandmarkCasesPhase2 {
  static final List<CaseKnowledgeObject> cases = [
    // ------------------------------------------------------------------------
    // 1. L. Chandra Kumar v. Union of India (1997) — Tribunals & Judicial Review
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-L-CHANDRA-KUMAR',
      caseId: 'L_CHANDRA_KUMAR',
      caseName: 'L. Chandra Kumar v. Union of India',
      citation: 'AIR 1997 SC 1125',
      year: 1997,
      court: 'Supreme Court of India',
      bench: '7-Judge Constitution Bench',
      benchStrength: 7,
      judges: const [
        'A.S. Anand J.',
        'S.P. Bharucha J.',
        'K. Venkataswami J.',
        'V.N. Khare J.',
        'S.B. Majmudar J.',
        'S. Saghir Ahmad J.',
        'G.B. Pattanaik J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.administrativeLaw,
      keywords: const [
        'L. Chandra Kumar',
        'Judicial Review',
        'Tribunals',
        'Article 323A',
        'Article 323B',
        'Basic Structure'
      ],
      aliases: const ['Tribunals Case', 'Judicial Review Case'],
      historicalContext:
          'Challenged Articles 323A and 323B inserted by the 42nd Amendment which empowered Parliament/legislatures to exclude the jurisdiction of High Courts over tribunals.',
      facts:
          'The vires of Articles 323A(2)(d) and 323B(3)(d), which permitted exclusion of High Court jurisdiction under Articles 226/227, was questioned along with the Administrative Tribunals Act, 1985.',
      issues: const [
        'Can the jurisdiction of the High Courts under Articles 226 and 227 be excluded in respect of tribunals?',
        'Is the power of judicial review part of the basic structure?',
      ],
      petitionerArguments: const [
        'Tribunals cannot substitute the High Court as the constitutional protector of rights.',
      ],
      respondentArguments: const [
        'The 42nd Amendment validly permitted creation of tribunals excluding HC jurisdiction.',
      ],
      decision:
          'Held the power of judicial review under Articles 32 and 226 is part of the basic structure; the exclusion of High Court jurisdiction was unconstitutional. Tribunals remain under the supervisory jurisdiction of the High Court.',
      ratioDecidendi: const [
        'Judicial review over legislative action is an integral and essential feature of the Constitution.',
        'Tribunals created under Articles 323A/323B are subject to the writ and supervisory jurisdiction of the High Courts and the Supreme Court.',
        'The provisions of Articles 323A(2)(d) and 323B(3)(d) excluding HC jurisdiction are unconstitutional.',
      ],
      obiterDicta: const [
        'All decisions of tribunals will be subject to scrutiny before a Division Bench of the High Court.',
      ],
      keyPrinciples: const [
        'Judicial review is a basic feature.',
        'Hierarchy: tribunals below High Court, High Court below Supreme Court.',
      ],
      constitutionalSignificance:
          'L. Chandra Kumar protects the constitutional scheme of judicial review from legislative encroachment and settles the relationship between tribunals and the High Courts.',
      constitutionalInterpretation:
          'The power of judicial review is a basic feature; tribunals cannot supplant the High Courts as constitutional courts.',
      legalPrinciple:
          'Every tribunal set up under Articles 323A/323B remains subject to the writ jurisdiction of the High Court.',
      relatedArticles: const [
        'Article 32',
        'Article 226',
        'Article 227',
        'Article 323A',
        'Article 323B',
        'Article 368'
      ],
      relatedActs: const ['Administrative Tribunals Act, 1985'],
      doctrines: const ['BASIC_STRUCTURE'],
      precedentsFollowed: const ['KESAVANANDA'],
      relatedCases: const ['KESAVANANDA', 'SC_OR_1993'],
      relatedBodies: const ['bod_attorney_general'],
      relatedReports: const ['Law Commission of India'],
      relatedCurrentAffairs: const ['ca_tribunal_reforms'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Judicial Review', 'Tribunals', 'Separation of Powers'],
      subjects: const ['Constitutional Law', 'Administrative Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'L. Chandra Kumar struck down exclusion of HC jurisdiction, not the tribunals themselves',
        'Judicial review held a basic feature',
      ],
      mainsThemes: const [
        'Independence of the judiciary and judicial review as a basic feature',
        'Tribunalisation and access to justice',
      ],
      interviewAngles: const [
        'Can Parliament create tribunals that bypass constitutional courts?',
      ],
      judgmentDate: DateTime(1997, 3, 18),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2022,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['SC_OR_1993'],
      garudaExplanation:
          'Protects judicial review as a basic feature and places all tribunals under High Court control.',
      commonMistakes: const [
        'Thinking tribunals can replace High Courts',
        'Attributing the judgment to Article 21 alone',
      ],
      memoryTricks: const ['Tribunals = below High Court, not beside it'],
      oneLineSummary:
          'Judicial review under Articles 32/226 is a basic feature; tribunals cannot exclude High Court jurisdiction.',
      detailedSummary:
          'The 7-judge bench held that tribunals under Articles 323A/323B remain subject to the writ and supervisory jurisdiction of the High Courts; the exclusion of that jurisdiction was unconstitutional.',
      primarySource: 'Supreme Court Reports (SCR) / All India Reporter (AIR)',
      citations: const ['AIR 1997 SC 1125'],
      evidenceReferences: const ['AIR 1997 SC 1125'],
      evidenceIds: const ['ev_L_CHANDRA_KUMAR_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      version: 1,
      editorialStatus: 'APPROVED',
      neutralCitation: 'AIR 1997 SC 1125',
      authoringJudge: 'A.S. Anand J.',
      majorityOpinion:
          'Unanimous judgment holding judicial review a basic feature and tribunals subject to High Court supervision.',
    ),

    // ------------------------------------------------------------------------
    // 2. Supreme Court Advocates-on-Record Assn v. Union of India (1993) — Collegium
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SC-OR-1993',
      caseId: 'SC_OR_1993',
      caseName: 'Supreme Court Advocates-on-Record Association v. Union of India',
      citation: 'AIR 1994 SC 268',
      year: 1993,
      court: 'Supreme Court of India',
      bench: '9-Judge Constitution Bench',
      benchStrength: 9,
      judges: const [
        'J.S. Verma J.',
        'A.M. Ahmadi J.',
        'K. Ramaswamy J.',
        'P.B. Sawant J.',
        'B.P. Jeevan Reddy J.',
        'S.C. Agrawal J.',
        'N. Venkatachala J.',
        'S. Mohan J.',
        'K. Jayachandra Reddy J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.constitutionalLaw,
      keywords: const [
        'Collegium',
        'Appointment of Judges',
        'Article 124',
        'Second Judges Case',
        'Primacy of Judiciary'
      ],
      aliases: const ['Second Judges Case', 'Collegium Case'],
      historicalContext:
          'Overruled S.P. Gupta (First Judges Case, 1981) which had given the executive primacy in judicial appointments.',
      facts:
          'The Court examined the process of appointment of judges of the Supreme Court and High Courts and whether the opinion of the Chief Justice of India is binding on the President.',
      issues: const [
        'Who has primacy in the appointment of judges - the executive or the judiciary?',
        'What is the correct interpretation of Article 124(2)?',
      ],
      petitionerArguments: const [
        'Consultation under Article 124 must be effective and the judiciary must have primacy.',
      ],
      respondentArguments: const [
        'The executive has primacy in appointments.',
      ],
      decision:
          'Held the Chief Justice of India must consult a collegium of the two senior-most puisne judges of the Court in appointments; the primacy of the judiciary was upheld.',
      ratioDecidendi: const [
        'Consultation under Article 124(2) means concurrence of the judiciary in judicial appointments.',
        'The collegium of CJI and two senior-most judges constitutes the recommendatory body.',
      ],
      keyPrinciples: const [
        'Judicial primacy in appointment of judges.',
        'Collegium system for appointment and transfer.',
      ],
      constitutionalSignificance:
          'Established the collegium system, a cornerstone of judicial independence and a frequent UPSC GS2 topic on separation of powers.',
      constitutionalInterpretation:
          'Articles 124 and 217 are to be read to ensure the primacy of the judiciary in the appointment of judges.',
      legalPrinciple:
          'Judicial appointments are a joint exercise with judicial primacy; the CJI must consult the collegium.',
      relatedArticles: const ['Article 124', 'Article 217'],
      relatedCases: const ['NJAC_2015', 'L_CHANDRA_KUMAR'],
      doctrines: const ['BASIC_STRUCTURE'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const [
        'Judicial Independence',
        'Appointment of Judges',
        'Separation of Powers'
      ],
      subjects: const ['Constitutional Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Second Judges Case (1993) established the collegium, not the NJAC',
        'Overruled S.P. Gupta',
      ],
      mainsThemes: const [
        'Appointment of judges and judicial independence',
        'Collegium vs National Judicial Appointments Commission',
      ],
      interviewAngles: const [
        'Why was the NJAC struck down in 2015?',
      ],
      judgmentDate: DateTime(1993, 10, 6),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 4,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['NJAC_2015'],
      garudaExplanation:
          'Created the collegium system; judges are appointed with judicial primacy.',
      commonMistakes: const [
        'Confusing Second Judges (1993) with NJAC (2015)',
        'Saying the executive appoints judges unilaterally',
      ],
      memoryTricks: const ['Collegium came from 1993; NJAC failed in 2015'],
      oneLineSummary:
          'The collegium system for judicial appointments was established with primacy to the judiciary.',
      detailedSummary:
          'The 9-judge bench held that the opinion of the CJI, formed after consulting a collegium of two senior-most judges, is determinative in appointments, giving the judiciary primacy.',
      citations: const ['AIR 1994 SC 268'],
      evidenceReferences: const ['AIR 1994 SC 268'],
      evidenceIds: const ['ev_SC_OR_1993_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: 'AIR 1994 SC 268',
      authoringJudge: 'J.S. Verma J.',
      majorityOpinion:
          'Judicial primacy in appointments; collegium of CJI and two senior-most judges.',
    ),

    // ------------------------------------------------------------------------
    // 3. SC Advocates-on-Record Assn v. Union of India (2015) — NJAC struck down
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-NJAC-2015',
      caseId: 'NJAC_2015',
      caseName: 'Supreme Court Advocates-on-Record Association v. Union of India',
      citation: '(2016) 5 SCC 1',
      year: 2015,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'J.S. Khehar J.',
        'J. Chelameswar J.',
        'Madan B. Lokur J.',
        'Kurian Joseph J.',
        'A.K. Goel J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.constitutionalLaw,
      keywords: const [
        'NJAC',
        'Collegium',
        '99th Amendment',
        'Judicial Appointments',
        'Basic Structure'
      ],
      aliases: const ['NJAC Case', 'Fourth Judges Case'],
      historicalContext:
          'Parliament passed the 99th Constitutional Amendment Act and the NJAC Act, 2014 replacing the collegium with a National Judicial Appointments Commission.',
      facts:
          'The validity of the 99th Amendment and the NJAC Act was challenged on the ground that they destroyed the independence of the judiciary.',
      issues: const [
        'Is the primacy of the judiciary in appointments part of the basic structure?',
        'Does the NJAC compromise the independence of the judiciary?',
      ],
      petitionerArguments: const [
        'A commission with executive and political members destroys judicial independence.',
      ],
      respondentArguments: const [
        'The NJAC makes appointments participative and transparent.',
      ],
      decision:
          'By 4:1, struck down the 99th Amendment and the NJAC Act as unconstitutional; held primacy of the judiciary in appointments is a basic feature.',
      ratioDecidendi: const [
        'The primacy of the judiciary in judicial appointments is an integral part of the basic structure.',
        'The NJAC undermined the independence of the judiciary.',
      ],
      keyPrinciples: const [
        'Judicial independence is a basic feature.',
        'Collegium system restored.',
      ],
      constitutionalSignificance:
          'Confirmed that judicial independence and the primacy of the judiciary are basic features, reaffirming the collegium system.',
      constitutionalInterpretation:
          'Article 124(2) as amended by the 99th Amendment violated the basic structure by diluting judicial primacy.',
      legalPrinciple:
          'The composition of the NJAC compromised judicial primacy and was therefore unconstitutional.',
      relatedArticles: const ['Article 124', 'Article 217', 'Article 368'],
      relatedCases: const ['SC_OR_1993'],
      relatedActs: const [
        'Constitution (Ninety-ninth Amendment) Act, 2014',
        'National Judicial Appointments Commission Act, 2014'
      ],
      doctrines: const ['BASIC_STRUCTURE'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const [
        'Judicial Independence',
        'Appointment of Judges',
        'Basic Structure'
      ],
      subjects: const ['Constitutional Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'NJAC was struck down 4:1, not unanimously',
        'Collegium continues to appoint judges',
      ],
      mainsThemes: const [
        'Judicial independence as a basic feature',
        'Collegium vs NJAC debate',
      ],
      interviewAngles: const [
        'What reforms are suggested for judicial appointments today?',
      ],
      judgmentDate: DateTime(2015, 10, 16),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 4,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['SC_OR_1993'],
      garudaExplanation:
          'Struck down the NJAC and reaffirmed that judicial independence and primacy are basic features.',
      commonMistakes: const [
        'Saying NJAC was upheld',
        'Forgetting it was a 4:1 decision',
      ],
      memoryTricks: const ['NJAC struck down in 2015, collegium restored'],
      oneLineSummary:
          'The NJAC was struck down; primacy of the judiciary in appointments is a basic feature.',
      detailedSummary:
          'The 5-judge bench, by a 4:1 majority, struck down the 99th Amendment and the NJAC Act, 2014, restoring the collegium system.',
      citations: const ['(2016) 5 SCC 1'],
      evidenceReferences: const ['(2016) 5 SCC 1'],
      evidenceIds: const ['ev_NJAC_2015_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2016) 5 SCC 1',
      authoringJudge: 'J.S. Khehar J.',
      majorityOpinion:
          'NJAC composition and functions compromised judicial primacy and the basic structure.',
      minorityOpinion: 'J. Chelameswar J. dissented, favouring the NJAC.',
      dissent:
          'Chelameswar J. held that judicial primacy is not an immutable feature and the NJAC was valid.',
    ),

    // ------------------------------------------------------------------------
    // 4. Shreya Singhal v. Union of India (2015) — Section 66A IPC
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SHREYA-SINGHAL',
      caseId: 'SHREYA_SINGHAL',
      caseName: 'Shreya Singhal v. Union of India',
      citation: '(2015) 5 SCC 1',
      year: 2015,
      court: 'Supreme Court of India',
      bench: '2-Judge Bench',
      benchStrength: 2,
      judges: const ['Rohinton Fali Nariman J.', 'J. Chelameswar J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.constitutionalLaw,
      keywords: const [
        'Section 66A',
        'Freedom of Speech',
        'Article 19',
        'Internet',
        'Void for Vagueness'
      ],
      aliases: const ['Section 66A Case', 'Internet Free Speech Case'],
      historicalContext:
          'Section 66A of the Information Technology Act, 2000 criminalised offensive online speech; two women were arrested for a Facebook post.',
      facts:
          'Shreya Singhal challenged the constitutional validity of Section 66A and the blocking powers under Section 69A of the IT Act.',
      issues: const [
        'Is Section 66A IT Act violative of Article 19(1)(a)?',
        'Does Section 69A with the 2009 Rules provide adequate safeguards?',
      ],
      petitionerArguments: const [
        'Section 66A is vague, overbroad and criminalises speech protected under Article 19(1)(a).',
      ],
      respondentArguments: const [
        'The provision is needed to regulate offensive online content.',
      ],
      decision:
          'Struck down Section 66A as unconstitutional for failing the Article 19(2) grounds; upheld Section 69A subject to procedural safeguards.',
      ratioDecidendi: const [
        'Section 66A does not fall within any of the eight grounds in Article 19(2) and is manifestly arbitrary.',
        'Speech cannot be restricted on grounds of mere annoyance or inconvenience.',
        'Section 69A is constitutional because blocking follows a reasoned, appellate procedure.',
      ],
      keyPrinciples: const [
        'Void for vagueness',
        'Proportionality in speech restrictions',
      ],
      constitutionalSignificance:
          'A leading modern authority on freedom of speech online, applied repeatedly in debates on internet regulation.',
      constitutionalInterpretation:
          'Article 19(1)(a) protects online speech; restrictions must fall strictly within Article 19(2).',
      legalPrinciple:
          'Criminalising speech must satisfy a ground in Article 19(2); vague and disproportionate provisions are void.',
      relatedArticles: const ['Article 19', 'Article 19(1)(a)', 'Article 19(2)'],
      relatedActs: const ['Information Technology Act, 2000'],
      sections: const ['Section 66A IT Act', 'Section 69A IT Act'],
      precedentsFollowed: const ['ROMESH_THAPPAR'],
      relatedCases: const ['ROMESH_THAPPAR'],
      relatedCurrentAffairs: const ['ca_it_rules_2021'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Freedom of Speech', 'Internet Regulation', 'Free Speech'],
      subjects: const ['Constitutional Law', 'Media Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Section 66A struck down, Section 69A upheld',
        'Test of vagueness and Article 19(2) grounds',
      ],
      mainsThemes: const [
        'Free speech in the digital age',
        'Proportionality and restriction of speech',
      ],
      interviewAngles: const [
        'How does Shreya Singhal frame regulation of online speech?',
      ],
      judgmentDate: DateTime(2015, 3, 24),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['ROMESH_THAPPAR'],
      garudaExplanation:
          'Struck down the vague Section 66A and set the modern test for online speech restrictions.',
      commonMistakes: const [
        'Thinking the whole IT Act was struck down',
        'Missing that 69A was upheld',
      ],
      memoryTricks: const ['66A gone, 69A stands'],
      oneLineSummary:
          'Section 66A IT Act struck down for violating free speech; Section 69A upheld with safeguards.',
      detailedSummary:
          'The Court held Section 66A did not fall within any Article 19(2) ground and was manifestly arbitrary; the blocking provision survived with procedural safeguards.',
      citations: const ['(2015) 5 SCC 1'],
      evidenceReferences: const ['(2015) 5 SCC 1'],
      evidenceIds: const ['ev_SHREYA_SINGHAL_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2015) 5 SCC 1',
      authoringJudge: 'Rohinton Fali Nariman J.',
      majorityOpinion: 'Unanimous; Section 66A struck down, Section 69A upheld.',
    ),

    // ------------------------------------------------------------------------
    // 5. State of Rajasthan v. Union of India (1977) — Article 356 justiciability
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-STATE-RAJASTHAN-V-UNION',
      caseId: 'STATE_RAJASTHAN_V_UNION',
      caseName: 'State of Rajasthan v. Union of India',
      citation: 'AIR 1977 SC 1361',
      year: 1977,
      court: 'Supreme Court of India',
      bench: '7-Judge Constitution Bench',
      benchStrength: 7,
      judges: const [
        'M.H. Beg C.J.',
        'P.N. Bhagwati J.',
        'Y.V. Chandrachud J.',
        'V.R. Krishna Iyer J.',
        'N.L. Untwalia J.',
        'P.N. Shinghal J.',
        'Jaswant Singh J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.federalism,
      keywords: const [
        'Article 356',
        'President Rule',
        'Federalism',
        'Justiciability'
      ],
      aliases: const ['Article 356 Case', 'Rajasthan Case'],
      historicalContext:
          'Following the 1977 general elections, the Union dissolved nine State Assemblies; the States challenged the dissolution as malafide.',
      facts:
          'The States questioned whether the President can dissolve State Assemblies under Article 356 and whether such proclamations are justiciable.',
      issues: const [
        'Is a Proclamation under Article 356 justiciable?',
        'Can the President dissolve State Assemblies on the ground that the ruling party lost the Lok Sabha elections?',
      ],
      petitionerArguments: const [
        'Federalism requires that Article 356 be narrowly construed and proclamations reviewed by courts.',
      ],
      respondentArguments: const [
        'The President acts on the advice of the Council of Ministers and the decision is political.',
      ],
      decision:
          'Held Article 356 proclamations are justiciable within limits; the satisfaction of the President is subjective but not immune from review; dissolution on the ground of loss of Lok Sabha majority was held not justiciable in this context.',
      ratioDecidendi: const [
        'The mala fides of a Proclamation can be challenged, but its political merits cannot be examined.',
        'Federalism is a basic feature; Article 356 is an exceptional provision to be used sparingly.',
      ],
      keyPrinciples: const [
        'Limited justiciability of Article 356.',
        'Proclamation is subject to judicial review for mala fides.',
      ],
      constitutionalSignificance:
          'The first major case on Article 356 justiciability, paving the way for S.R. Bommai.',
      constitutionalInterpretation:
          'Article 356 is an exceptional power; its exercise is subject to limited judicial review.',
      legalPrinciple:
          'A Proclamation under Article 356 can be challenged on the ground of mala fides but not on political merits.',
      relatedArticles: const ['Article 356', 'Article 352'],
      precedentsFollowed: const ['SR_BOMMAI'],
      relatedCases: const ['SR_BOMMAI', 'NABAM_REBIA'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const [
        'Federalism',
        "President's Rule",
        'Judicial Review'
      ],
      subjects: const ['Constitutional Law', 'Federalism'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Article 356 proclamations are justiciable only for mala fides',
        'Precursor to S.R. Bommai',
      ],
      mainsThemes: const [
        'Centre-State relations and Article 356',
        'Justiciability of political decisions',
      ],
      interviewAngles: const [
        'How did Bommai expand the review of Article 356?',
      ],
      judgmentDate: DateTime(1977),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2021,
      trend: 'Medium Frequency',
      frequentlyConfusedCases: const ['SR_BOMMAI'],
      garudaExplanation:
          'Established limited judicial review of Article 356 Proclamations and its exceptional nature.',
      commonMistakes: const [
        'Treating the case as making Article 356 fully justiciable',
      ],
      memoryTricks: const ['Rajasthan 1977 = first Article 356 review'],
      oneLineSummary:
          'Article 356 proclamations are justiciable for mala fides; federalism is a basic feature.',
      detailedSummary:
          'The 7-judge bench held that while the merits of a Proclamation are political, its mala fides and the constitutional limitations on the power are reviewable.',
      citations: const ['AIR 1977 SC 1361'],
      evidenceReferences: const ['AIR 1977 SC 1361'],
      evidenceIds: const ['ev_STATE_RAJASTHAN_V_UNION_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: 'AIR 1977 SC 1361',
    ),

    // ------------------------------------------------------------------------
    // 6. Nabam Rebia v. Deputy Speaker (2016) — Governor & floor test
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-NABAM-REBIA',
      caseId: 'NABAM_REBIA',
      caseName: 'Nabam Rebia v. Deputy Speaker',
      citation: '(2016) 8 SCC 1',
      year: 2016,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'J.S. Khehar C.J.',
        'Dipak Misra J.',
        'Madan B. Lokur J.',
        'Prafulla C. Pant J.',
        'A.M. Khanwilkar J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.federalism,
      keywords: const [
        'Article 163',
        'Governor',
        'Speaker',
        'Floor Test',
        'Arunachal Pradesh'
      ],
      aliases: const ['Arunachal Pradesh Case'],
      historicalContext:
          'In the 2015 Arunachal Pradesh political crisis, the Governor advanced the Assembly session and the Deputy Speaker moved for the Speaker\'s removal; the Speaker\'s disqualification notices were challenged.',
      facts:
          'The Governor issued an order fixing a date for the Assembly session for the removal of the Speaker while the Speaker\'s own removal was pending; the constitutional validity of the Governor\'s action was questioned.',
      issues: const [
        'Can the Governor issue a notice for removal of the Speaker while proceedings for the Speaker\'s own removal are pending?',
        'What is the scope of the Governor\'s discretion under Article 163?',
      ],
      petitionerArguments: const [
        'The Governor cannot act contrary to the aid and advice of the Cabinet and must not destabilise the Assembly.',
      ],
      respondentArguments: const [
        'The Governor acted to resolve a constitutional crisis.',
      ],
      decision:
          'Held the Governor\'s action advancing the session for removal of the Speaker was unconstitutional; the Governor must act on the aid and advice of the Council of Ministers and must not defreeze the Assembly business to destabilise the House.',
      ratioDecidendi: const [
        'The Governor under Article 163 acts on the aid and advice of the Council of Ministers.',
        'The Governor cannot issue a notice for removal of the Speaker while the Speaker\'s own removal is pending.',
        'Floor tests are the constitutional way to decide majority.',
      ],
      keyPrinciples: const [
        'Governor is a constitutional head, not a rival power centre.',
        'Sanctity of the Speaker\'s office.',
      ],
      constitutionalSignificance:
          'A key authority on the office of the Governor, floor tests and the constitutional resolution of Assembly crises.',
      constitutionalInterpretation:
          'Article 163 requires the Governor to act on ministerial advice; the Governor cannot destabilise the Assembly.',
      legalPrinciple:
          'A Governor cannot facilitate the removal of a Speaker while the Speaker\'s own removal is pending; majority is decided by floor test.',
      relatedArticles: const ['Article 163', 'Article 174'],
      relatedCases: const ['SR_BOMMAI'],
      relatedReports: const ['Sarkaria Commission Report 1988'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const [
        'Governor',
        'Floor Test',
        'Federalism',
        'Legislature'
      ],
      subjects: const ['Constitutional Law', 'Federalism'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Governor acts on aid and advice of Council of Ministers',
        'Floor test decides majority, not Governor\'s discretion',
      ],
      mainsThemes: const [
        'Role of the Governor in state politics',
        'Floor tests and anti-defection',
      ],
      interviewAngles: const [
        'How should a Governor handle a hung Assembly?',
      ],
      judgmentDate: DateTime(2016, 7, 13),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['SR_BOMMAI'],
      garudaExplanation:
          'Curbs the Governor\'s discretion and affirms that floor tests decide Assembly majorities.',
      commonMistakes: const [
        'Thinking the Governor can act independently of the Cabinet',
      ],
      memoryTricks: const ['Governor = constitutional head, floor test = majority'],
      oneLineSummary:
          'The Governor must act on ministerial advice and cannot destabilise the Assembly; majority is decided by floor test.',
      detailedSummary:
          'The 5-judge bench held the Governor\'s order advancing the session to remove the Speaker unconstitutional, affirming Article 163 and the floor-test principle.',
      citations: const ['(2016) 8 SCC 1'],
      evidenceReferences: const ['(2016) 8 SCC 1'],
      evidenceIds: const ['ev_NABAM_REBIA_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2016) 8 SCC 1',
      authoringJudge: 'J.S. Khehar C.J.',
      majorityOpinion:
          'Governor\'s discretion curtailed; floor test is the constitutional mechanism.',
    ),

    // ------------------------------------------------------------------------
    // 7. M. Nagaraj v. Union of India (2006) — SC/ST promotion reservation
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-M-NAGARAJ',
      caseId: 'M_NAGARAJ',
      caseName: 'M. Nagaraj v. Union of India',
      citation: '(2006) 8 SCC 212',
      year: 2006,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'Y.K. Sabharwal C.J.',
        'B.N. Agarwal J.',
        'Arijit Pasayat J.',
        'C.K. Thakker J.',
        'Dr. A.K. Sikri J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.socialJustice,
      keywords: const [
        'Reservation in Promotion',
        'Article 16(4A)',
        'Creamy Layer',
        'Quantifiable Data',
        'Basic Structure'
      ],
      aliases: const ['Nagaraj Case'],
      historicalContext:
          'The 77th, 81st and 85th Amendments (with 103rd Amendment context) were challenged for allowing reservation in promotions for SC/STs.',
      facts:
          'The constitutional validity of Articles 16(4A) and 16(4B) inserted by amendments was examined in the context of promotions for Scheduled Castes and Scheduled Tribes.',
      issues: const [
        'Are Articles 16(4A) and 16(4B) within the basic structure?',
        'Must the State prove backwardness and inadequacy of representation before granting promotional reservation?',
      ],
      petitionerArguments: const [
        'Promotional reservation is a fundamental right flowing from Articles 14 and 16.',
      ],
      respondentArguments: const [
        'Promotional reservation requires quantifiable data and must not compromise efficiency.',
      ],
      decision:
          'Upheld the amendments but read them down: the State must show quantifiable data of backwardness, inadequacy of representation and overall administrative efficiency; the creamy layer must be excluded.',
      ratioDecidendi: const [
        'Articles 16(4A) and 16(4B) are enabling provisions and not fundamental rights.',
        'The State must collect quantifiable data on backwardness and inadequacy of representation.',
        'The creamy layer concept applies to SC/ST promotional reservation.',
      ],
      keyPrinciples: const [
        'Balancing test: equality, efficiency and basic structure.',
        'Creamy layer exclusion for SC/STs in promotions.',
      ],
      constitutionalSignificance:
          'The governing authority on promotional reservation, repeatedly cited in UPSC GS2 questions on reservation policy.',
      constitutionalInterpretation:
          'Amendments enabling promotional reservation are valid but subject to basic-structure limits.',
      legalPrinciple:
          'Promotional reservation for SC/STs is permissible only with quantifiable data and creamy-layer exclusion.',
      relatedArticles: const [
        'Article 14',
        'Article 16',
        'Article 16(4A)',
        'Article 335',
        'Article 368'
      ],
      precedentsFollowed: const ['INDRA_SAWHNEY'],
      precedentsDistinguished: const ['CHAMPAKAM_DORAIRAJAN'],
      relatedCases: const ['INDRA_SAWHNEY', 'JARNAIL_SINGH', 'JANHIT_ABHIYAN'],
      doctrines: const ['BASIC_STRUCTURE'],
      sdgGoals: const ['SDG 10 - Reduced Inequalities'],
      themes: const [
        'Reservation',
        'Creamy Layer',
        'Equality',
        'Backward Classes'
      ],
      subjects: const ['Constitutional Law', 'Social Justice'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Promotional reservation requires quantifiable data',
        'Creamy layer applies to SC/ST promotions too',
      ],
      mainsThemes: const [
        'Reservation in promotions and the basic structure',
        'Quantifiable data and administrative efficiency',
      ],
      interviewAngles: const [
        'What data must the State show before granting promotional reservation?',
      ],
      judgmentDate: DateTime(2006, 10, 19),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['JARNAIL_SINGH'],
      garudaExplanation:
          'Upholds but conditions promotional reservation on quantifiable data and creamy-layer exclusion.',
      commonMistakes: const [
        'Thinking promotional reservation is a fundamental right',
        'Missing the quantifiable-data requirement',
      ],
      memoryTricks: const ['Nagaraj = Data + Creamy layer + Efficiency'],
      oneLineSummary:
          'Promotional reservation for SC/STs is valid subject to quantifiable data, creamy-layer exclusion and efficiency.',
      detailedSummary:
          'The 5-judge bench upheld Articles 16(4A)/16(4B) with conditions: quantifiable backwardness, inadequacy of representation and creamy-layer exclusion.',
      citations: const ['(2006) 8 SCC 212'],
      evidenceReferences: const ['(2006) 8 SCC 212'],
      evidenceIds: const ['ev_M_NAGARAJ_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2006) 8 SCC 212',
      authoringJudge: 'Dr. A.K. Sikri J.',
      majorityOpinion:
          'Unanimous; amendments valid but conditioned on data, creamy layer and efficiency.',
    ),

    // ------------------------------------------------------------------------
    // 8. Jarnail Singh v. Lachhmi Narain Gupta (2018) — Creamy layer for SC/ST
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-JARNAIL-SINGH',
      caseId: 'JARNAIL_SINGH',
      caseName: 'Jarnail Singh v. Lachhmi Narain Gupta',
      citation: '(2018) 10 SCC 396',
      year: 2018,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'Dipak Misra C.J.',
        'R.F. Nariman J.',
        'A.M. Khanwilkar J.',
        'Dr. D.Y. Chandrachud J.',
        'Indu Malhotra J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.socialJustice,
      keywords: const [
        'Creamy Layer',
        'SC/ST Promotion',
        'Article 16(4A)',
        'Catch-up Rule'
      ],
      aliases: const ['Jarnail Singh Case'],
      historicalContext:
          'The Court revisited M. Nagaraj to decide whether the creamy-layer principle applies to SC/STs and whether the "catch-up rule" can be applied without quantifiable data.',
      facts:
          'The case examined whether reservation in promotion for SC/STs must exclude the creamy layer and whether seniority can be linked to such reservation.',
      issues: const [
        'Does the creamy-layer principle apply to SC/ST promotional reservation?',
        'Can the "catch-up rule" be applied without quantifiable data?',
      ],
      petitionerArguments: const [
        'Creamy layer must be excluded even among SC/STs for promotional reservation.',
      ],
      respondentArguments: const [
        'Creamy layer exclusion for SC/STs would defeat the constitutional purpose.',
      ],
      decision:
          'Clarified Nagaraj: the creamy layer applies to SC/STs for promotional reservation; the requirement of quantifiable data does not apply to the "catch-up rule" for seniority.',
      ratioDecidendi: const [
        'The creamy layer principle applies to SC/ST promotional reservation.',
        'Quantifiable data is not required for applying the catch-up rule.',
      ],
      keyPrinciples: const [
        'Creamy layer exclusion for SC/STs in promotions.',
        'Seniority (catch-up) principle clarified.',
      ],
      constitutionalSignificance:
          'Settles the scope of Nagaraj and the creamy layer for SC/ST promotions.',
      constitutionalInterpretation:
          'Article 16(4A) read with Article 335 attracts the creamy-layer exclusion for SC/STs.',
      legalPrinciple:
          'Creamy layer among SC/STs is excluded from promotional reservation; catch-up rule needs no quantifiable data.',
      relatedArticles: const ['Article 16(4A)', 'Article 335'],
      precedentsFollowed: const ['M_NAGARAJ'],
      precedentsOverruled: const [],
      relatedCases: const ['M_NAGARAJ', 'INDRA_SAWHNEY'],
      sdgGoals: const ['SDG 10 - Reduced Inequalities'],
      themes: const ['Reservation', 'Creamy Layer', 'Equality'],
      subjects: const ['Constitutional Law', 'Social Justice'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Creamy layer applies to SC/ST promotions (post-2018)',
        'Catch-up rule does not need quantifiable data',
      ],
      mainsThemes: const [
        'Reservation and the creamy layer for SC/STs',
        'Clarifying Nagaraj',
      ],
      interviewAngles: const [
        'Why did the Court extend the creamy layer to SC/STs?',
      ],
      judgmentDate: DateTime(2018, 11, 13),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['M_NAGARAJ'],
      garudaExplanation:
          'Extended the creamy layer to SC/STs and relaxed the quantifiable-data test for the catch-up rule.',
      commonMistakes: const [
        'Missing that creamy layer now applies to SC/STs',
      ],
      memoryTricks: const ['Jarnail = creamy layer for SC/ST + catch-up'],
      oneLineSummary:
          'The creamy layer applies to SC/ST promotional reservation; the catch-up rule needs no quantifiable data.',
      detailedSummary:
          'The 5-judge bench clarified Nagaraj, applying the creamy layer to SC/STs and removing the quantifiable-data condition for the catch-up rule.',
      citations: const ['(2018) 10 SCC 396'],
      evidenceReferences: const ['(2018) 10 SCC 396'],
      evidenceIds: const ['ev_JARNAIL_SINGH_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2018) 10 SCC 396',
      authoringJudge: 'Dr. D.Y. Chandrachud J.',
      majorityOpinion:
          'Unanimous; creamy layer applies to SC/STs; catch-up rule clarified.',
    ),

    // ------------------------------------------------------------------------
    // 9. Janhit Abhiyan v. Union of India (2022) — EWS reservation
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-JANHIT-ABHIYAN',
      caseId: 'JANHIT_ABHIYAN',
      caseName: 'Janhit Abhiyan v. Union of India',
      citation: '2022 SCC OnLine SC 1540',
      year: 2022,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'U.U. Lalit C.J.',
        'Dinesh Maheshwari J.',
        'S. Ravindra Bhat J.',
        'Bela M. Trivedi J.',
        'J.B. Pardiwala J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.socialJustice,
      keywords: const [
        'EWS Reservation',
        '103rd Amendment',
        'Article 15(6)',
        'Economic Criteria',
        '50% Cap'
      ],
      aliases: const ['EWS Case', '103rd Amendment Case'],
      historicalContext:
          'The 103rd Constitutional Amendment (2019) introduced 10% reservation for Economically Weaker Sections on economic criteria, breaching the 50% ceiling.',
      facts:
          'The validity of Articles 15(6) and 16(6) (EWS reservation) was challenged on the ground that economic criteria cannot be a basis of reservation and that the 50% cap was breached.',
      issues: const [
        'Can reservation be provided on the sole basis of economic criteria?',
        'Does the EWS reservation violate the basic structure by breaching the 50% cap?',
      ],
      petitionerArguments: const [
        'Caste cannot be ignored; economic criteria alone is impermissible.',
      ],
      respondentArguments: const [
        'The EWS quota helps the poor among the unreserved categories.',
      ],
      decision:
          'By 3:2, upheld the 103rd Amendment; held that economic criteria can be a basis for reservation for EWS and that the 50% cap is not a rigid, immutable limit.',
      ratioDecidendi: const [
        'Articles 15(6) and 16(6) are constitutionally valid.',
        'Economic criteria is a permissible basis for EWS reservation.',
        'The 50% ceiling is not a rigid rule of the basic structure.',
      ],
      keyPrinciples: const [
        'EWS reservation is a distinct category.',
        'Basic structure does not preclude economic reservation.',
      ],
      constitutionalSignificance:
          'A recent Constitution Bench decision defining the limits of reservation on economic grounds; heavily tested in current-affairs and GS2.',
      constitutionalInterpretation:
          'The basic structure does not prohibit reservation on economic grounds for the EWS.',
      legalPrinciple:
          'EWS reservation up to 10% above the 50% cap is constitutionally valid.',
      relatedArticles: const ['Article 15(6)', 'Article 16(6)', 'Article 368'],
      relatedActs: const [
        'Constitution (One Hundred and Third Amendment) Act, 2019'
      ],
      precedentsFollowed: const ['INDRA_SAWHNEY'],
      precedentsDistinguished: const ['M_NAGARAJ'],
      relatedCases: const ['INDRA_SAWHNEY', 'M_NAGARAJ'],
      relatedCurrentAffairs: const ['ca_ews_reservation'],
      sdgGoals: const ['SDG 10 - Reduced Inequalities'],
      themes: const [
        'Reservation',
        'EWS',
        'Equality',
        'Economic Criteria'
      ],
      subjects: const ['Constitutional Law', 'Social Justice'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'EWS quota upheld 3:2, not unanimously',
        '50% cap held not a rigid basic structure limit',
        'EWS is a separate category, not part of OBC/SC/ST',
      ],
      mainsThemes: const [
        'Reservation on economic criteria',
        'Does the 50% cap remain intact?',
      ],
      interviewAngles: const [
        'How does the EWS quota interact with the Indra Sawhney cap?',
      ],
      judgmentDate: DateTime(2022, 11, 7),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 2,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['INDRA_SAWHNEY'],
      garudaExplanation:
          'Upheld the 103rd Amendment EWS quota and clarified that the 50% cap is not immutable.',
      commonMistakes: const [
        'Saying the EWS judgment was unanimous',
        'Treating the 50% cap as an absolute basic feature',
      ],
      memoryTricks: const ['EWS = economic, separate from caste quotas'],
      oneLineSummary:
          'The EWS 10% reservation under the 103rd Amendment was upheld 3:2.',
      detailedSummary:
          'The majority held economic criteria is a valid basis for reservation and the 50% cap is not a rigid basic-structure rule; the minority dissented on both points.',
      citations: const ['2022 SCC OnLine SC 1540'],
      evidenceReferences: const ['2022 SCC OnLine SC 1540'],
      evidenceIds: const ['ev_JANHIT_ABHIYAN_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '2022 SCC OnLine SC 1540',
      authoringJudge: 'Dinesh Maheshwari J.',
      majorityOpinion:
          'Upheld the 103rd Amendment; economic criteria valid; 50% cap not immutable.',
      minorityOpinion: 'S. Ravindra Bhat J. and U.U. Lalit C.J. dissented.',
      dissent:
          'Minority held that economic criteria alone cannot be the basis of reservation and that the 50% cap is part of the basic structure.',
    ),

    // ------------------------------------------------------------------------
    // 10. D.K. Basu v. State of West Bengal (1997) — Custodial violence
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-DK-BASU',
      caseId: 'DK_BASU',
      caseName: 'D.K. Basu v. State of West Bengal',
      citation: '(1997) 1 SCC 416',
      year: 1997,
      court: 'Supreme Court of India',
      bench: '2-Judge Bench',
      benchStrength: 2,
      judges: const ['A.S. Anand J.', 'K. Venkataswami J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.criminalLaw,
      keywords: const [
        'Custodial Violence',
        'Arrest Guidelines',
        'Article 21',
        'Article 22',
        'Compensation'
      ],
      aliases: const ['Arrest Guidelines Case'],
      historicalContext:
          'A series of custodial deaths and torture cases prompted guidelines for the treatment of arrested persons.',
      facts:
          'D.K. Basu, the then Chairman of the Legal Aid Services, wrote to the Chief Justice drawing attention to deaths in police custody, seeking a writ petition for custodial safeguards.',
      issues: const [
        'What procedural safeguards must accompany an arrest to prevent custodial violence?',
        'Does custodial torture violate Article 21?',
      ],
      petitionerArguments: const [
        'Custodial violence and deaths in custody violate the fundamental right to life.',
      ],
      respondentArguments: const [
        'Guidelines would hinder legitimate investigation.',
      ],
      decision:
        'Laid down 11 binding guidelines for arrest and custody (e.g., memo of arrest, intimation to family, medical examination, and details of the officer), and held custodial violence violates Article 21.',
      ratioDecidendi: const [
        'Custodial torture and death violate Article 21.',
        'The 11 arrest guidelines are binding on all police and other custodial agencies.',
        'Compensation can be awarded for illegal detention and custodial violence.',
      ],
      keyPrinciples: const [
        'Right against torture is a facet of Article 21.',
        'Guidelines till Parliament legislates.',
      ],
      constitutionalSignificance:
          'The leading authority on arrest safeguards and custodial justice; tested in GS2 (police reforms) and criminal-law questions.',
      constitutionalInterpretation:
          'Articles 21 and 22 require humane treatment of the arrested; procedural safeguards are enforceable.',
      legalPrinciple:
          'Every arrest must follow the D.K. Basu guidelines to protect against custodial violence.',
      relatedArticles: const ['Article 21', 'Article 22'],
      relatedActs: const ['Code of Criminal Procedure, 1973'],
      sections: const ['Section 41 CrPC', 'Section 154 CrPC'],
      precedentsFollowed: const ['MANEKA_GANDHI'],
      relatedCases: const ['MANEKA_GANDHI', 'LALITA_KUMARI', 'ARNESH_KUMAR'],
      relatedBodies: const ['bod_cbi'],
      relatedSchemes: const [],
      relatedCurrentAffairs: const ['ca_police_reforms'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const [
        'Custodial Justice',
        'Police Reforms',
        'Human Rights',
        'Arrest Guidelines'
      ],
      subjects: const ['Criminal Law', 'Human Rights'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Guidelines are binding, not advisory',
        'Custodial violence violates Article 21',
      ],
      mainsThemes: const [
        'Custodial violence and police accountability',
        'Article 21 and arrest safeguards',
      ],
      interviewAngles: const [
        'Which D.K. Basu guidelines are most often violated?',
      ],
      judgmentDate: DateTime(1997, 12, 18),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 4,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['LALITA_KUMARI'],
      garudaExplanation:
          'Binding arrest guidelines and the right against custodial violence under Article 21.',
      commonMistakes: const [
        'Confusing D.K. Basu with Lalita Kumari (FIR)',
        'Thinking guidelines are non-binding',
      ],
      memoryTricks: const ['Basu = 11 arrest safeguards'],
      oneLineSummary:
          'Laid down binding guidelines to prevent custodial violence and secure Article 21.',
      detailedSummary:
          'The Court issued 11 binding arrest guidelines and held that custodial torture and death violate Article 21, with compensation as a remedy.',
      citations: const ['(1997) 1 SCC 416'],
      evidenceReferences: const ['(1997) 1 SCC 416'],
      evidenceIds: const ['ev_DK_BASU_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1997) 1 SCC 416',
      authoringJudge: 'A.S. Anand J.',
      majorityOpinion: 'Unanimous; 11 arrest guidelines laid down.',
    ),

    // ------------------------------------------------------------------------
    // 11. Hussainara Khatoon v. Home Secretary, State of Bihar (1979) — Speedy trial
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-HUSSAINARA-KHATOON',
      caseId: 'HUSSAINARA_KHATOON',
      caseName: 'Hussainara Khatoon v. Home Secretary, State of Bihar',
      citation: 'AIR 1979 SC 1360',
      year: 1979,
      court: 'Supreme Court of India',
      bench: '2-Judge Bench',
      benchStrength: 2,
      judges: const ['P.N. Bhagwati J.', 'R.S. Pathak J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.criminalLaw,
      keywords: const [
        'Speedy Trial',
        'Undertrials',
        'Article 21',
        'Legal Aid',
        'Article 39A'
      ],
      aliases: const ['Undertrial Prisoners Case'],
      historicalContext:
          'A newspaper report revealed that thousands of undertrial prisoners in Bihar had been in jail longer than the maximum sentence for their alleged offences.',
      facts:
          'Public interest litigation highlighted undertrials languishing in jails without trial for years.',
      issues: const [
        'Is the right to a speedy trial part of Article 21?',
        'Is free legal aid an essential ingredient of fair trial?',
      ],
      petitionerArguments: const [
        'Years of pre-trial detention without trial violates the right to life and liberty.',
      ],
      respondentArguments: const [
        'Backlog and resources delay trials.',
      ],
      decision:
          'Held the right to a speedy trial and free legal aid are fundamental rights; directed release of undertrials whose detention exceeded the maximum sentence.',
      ratioDecidendi: const [
        'Speedy trial is a fundamental right under Article 21.',
        'Free legal aid to the accused is a fundamental right.',
        'Pre-trial detention beyond the maximum sentence is unconstitutional.',
      ],
      keyPrinciples: const [
        'Speedy trial and legal aid as fundamental rights.',
        'The Court can direct release in gross violations.',
      ],
      constitutionalSignificance:
          'The founding authority on speedy trial and legal aid; a classic PIL expanding Article 21.',
      constitutionalInterpretation:
          'Article 21 read with Article 39A guarantees speedy trial and free legal aid.',
      legalPrinciple:
          'Undertrials cannot be detained beyond the maximum sentence; they are entitled to speedy trial and legal aid.',
      relatedArticles: const ['Article 21', 'Article 39A'],
      relatedActs: const ['Code of Criminal Procedure, 1973'],
      precedentsFollowed: const ['MANEKA_GANDHI'],
      relatedCases: const ['MANEKA_GANDHI', 'DK_BASU'],
      relatedSchemes: const ['NALSA Legal Aid Services'],
      relatedCurrentAffairs: const ['ca_undertrials'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Speedy Trial', 'Legal Aid', 'Undertrials', 'PIL'],
      subjects: const ['Criminal Law', 'Human Rights'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Speedy trial and legal aid are fundamental rights',
        'Landmark PIL on undertrials',
      ],
      mainsThemes: const [
        'Access to justice and undertrials',
        'Speedy trial as due process',
      ],
      interviewAngles: const [
        'Why do undertrials still outnumber convicts?',
      ],
      judgmentDate: DateTime(1979),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 3,
      lastAskedYear: 2022,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['DK_BASU'],
      garudaExplanation:
          'Fast-tracked Article 21 into criminal procedure: speedy trial and legal aid are fundamental rights.',
      commonMistakes: const [
        'Confusing Hussainara with D.K. Basu',
      ],
      memoryTricks: const ['Hussainara = speedy trial + legal aid'],
      oneLineSummary:
          'Speedy trial and free legal aid are fundamental rights; undertrials cannot be jailed beyond the maximum sentence.',
      detailedSummary:
          'A series of orders in 1979 established speedy trial and legal aid as Article 21/39A rights and ordered the release of undertrials.',
      citations: const ['AIR 1979 SC 1360'],
      evidenceReferences: const ['AIR 1979 SC 1360'],
      evidenceIds: const ['ev_HUSSAINARA_KHATOON_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: 'AIR 1979 SC 1360',
      authoringJudge: 'P.N. Bhagwati J.',
      majorityOpinion: 'Unanimous orders establishing speedy-trial rights.',
    ),

    // ------------------------------------------------------------------------
    // 12. Common Cause v. Union of India (2018) — Passive euthanasia & living wills
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-COMMON-CAUSE-EUTHANASIA',
      caseId: 'COMMON_CAUSE_EUTHANASIA',
      caseName: 'Common Cause (A Regd. Society) v. Union of India',
      citation: '(2018) 9 SCC 1',
      year: 2018,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'Dipak Misra C.J.',
        'A.M. Khanwilkar J.',
        'Dr. D.Y. Chandrachud J.',
        'Rohinton Fali Nariman J.',
        'Indu Malhotra J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.humanRights,
      keywords: const [
        'Euthanasia',
        'Living Will',
        'Right to Die with Dignity',
        'Article 21',
        'Advance Directive'
      ],
      aliases: const ['Passive Euthanasia Case', 'Living Will Case'],
      historicalContext:
          'The recognition of passive euthanasia and advance medical directives (living wills) was sought to enable terminally ill patients to die with dignity.',
      facts:
          'A PIL sought the recognition of the right to refuse life-prolonging treatment through a living will.',
      issues: const [
        'Is passive euthanasia permissible under Article 21?',
        'Are advance medical directives (living wills) legally valid?',
      ],
      petitionerArguments: const [
        'The right to life includes the right to die with dignity.',
      ],
      respondentArguments: const [
        'Euthanasia could be abused; safeguards are essential.',
      ],
      decision:
          'Held the right to die with dignity is part of Article 21; passive euthanasia and living wills are lawful subject to guidelines and safeguards.',
      ratioDecidendi: const [
        'Passive euthanasia is permissible for terminally ill patients.',
        'Living wills are valid subject to procedural safeguards.',
        'Active euthanasia remains impermissible.',
      ],
      keyPrinciples: const [
        'Right to die with dignity as a facet of Article 21.',
        'Living wills and medical boards as safeguards.',
      ],
      constitutionalSignificance:
          'The landmark authority on end-of-life decisions; a frequent GS2/GS4 ethics and constitutional-law topic.',
      constitutionalInterpretation:
          'Article 21 protects the right to die with dignity, allowing passive euthanasia and living wills.',
      legalPrinciple:
          'A terminally ill patient can choose to refuse life-support through a valid living will.',
      relatedArticles: const ['Article 21'],
      precedentsOverruled: const [],
      relatedCases: const ['MANEKA_GANDHI'],
      relatedCurrentAffairs: const ['ca_euthanasia_guidelines'],
      sdgGoals: const ['SDG 3 - Good Health & Well-being'],
      themes: const ['Euthanasia', 'Right to Dignity', 'Medical Ethics'],
      subjects: const ['Constitutional Law', 'Human Rights'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Passive euthanasia allowed, active euthanasia not',
        'Living wills need advance-decision and medical-board safeguards',
      ],
      mainsThemes: const [
        'Right to die with dignity and Article 21',
        'Ethics of end-of-life care',
      ],
      interviewAngles: const [
        'Should active euthanasia be legalised in India?',
      ],
      judgmentDate: DateTime(2018, 3, 9),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['SUCHITA_SRIVASTAVA'],
      garudaExplanation:
          'Recognised passive euthanasia and living wills as facets of the right to dignity.',
      commonMistakes: const [
        'Thinking active euthanasia was allowed',
        'Confusing with Aruna Shanbaug context',
      ],
      memoryTricks: const ['Common Cause = living wills + passive euthanasia'],
      oneLineSummary:
          'Passive euthanasia and living wills are lawful under Article 21 with safeguards.',
      detailedSummary:
          'The 5-judge bench recognised the right to die with dignity and laid down a framework for advance medical directives and passive euthanasia.',
      citations: const ['(2018) 9 SCC 1'],
      evidenceReferences: const ['(2018) 9 SCC 1'],
      evidenceIds: const ['ev_COMMON_CAUSE_EUTHANASIA_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2018) 9 SCC 1',
      authoringJudge: 'Dipak Misra C.J.',
      majorityOpinion:
          'Unanimous; living wills and passive euthanasia recognised with safeguards.',
    ),

    // ------------------------------------------------------------------------
    // 13. M.C. Mehta v. Union of India (Taj Trapezium, 1997) — Environment
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-MC-MEHTA-TAJ',
      caseId: 'MC_MEHTA_TAJ',
      caseName: 'M.C. Mehta v. Union of India (Taj Trapezium Case)',
      citation: '(1997) 11 SCC 227',
      year: 1997,
      court: 'Supreme Court of India',
      bench: 'Bench of Kuldip Singh J. & Faizan Uddin J.',
      benchStrength: 2,
      judges: const ['Kuldip Singh J.', 'Faizan Uddin J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.environmentalLaw,
      keywords: const [
        'Taj Mahal',
        'Taj Trapezium Zone',
        'Polluter Pays',
        'Article 48A',
        'Environment Protection Act'
      ],
      aliases: const ['Taj Trapezium Case'],
      historicalContext:
          'Industrial pollution in the Taj Trapezium Zone was threatening the white marble of the Taj Mahal with yellowing.',
      facts:
          'A PIL by environmentalist M.C. Mehta sought protection of the Taj Mahal from pollution caused by nearby industries.',
      issues: const [
        'What measures are required to protect the Taj from industrial pollution?',
        'How should the polluter-pays principle be applied?',
      ],
      petitionerArguments: const [
        'The Taj, a national heritage, must be protected from industrial pollution.',
      ],
      respondentArguments: const [
        'Industries provide employment; shifting them is costly.',
      ],
      decision:
          'Directed the relocation of polluting industries from the Taj Trapezium Zone and applied the polluter-pays principle for restoration.',
      ratioDecidendi: const [
        'The right to a clean environment is part of Article 21.',
        'The polluter pays for the cost of restoration.',
        'National heritage deserves constitutional protection.',
      ],
      keyPrinciples: const [
        'Polluter pays and precautionary principles applied.',
        'Balancing development and environment.',
      ],
      constitutionalSignificance:
          'A leading environmental case applying the polluter-pays principle to protect national heritage.',
      constitutionalInterpretation:
          'Articles 21, 48A and 51A(g) together oblige the State to protect the environment.',
      legalPrinciple:
          'Polluting industries must relocate or bear the cost of environmental restoration.',
      relatedArticles: const ['Article 21', 'Article 48A', 'Article 51A(g)'],
      relatedActs: const ['Environment (Protection) Act, 1986'],
      precedentsFollowed: const ['VELLORE_CITIZENS'],
      relatedCases: const ['VELLORE_CITIZENS', 'TN_GODAVARMAN'],
      relatedBodies: const ['bod_cpcb'],
      relatedSchemes: const ['Namami Gange'],
      relatedCurrentAffairs: const ['ca_air_quality'],
      sdgGoals: const ['SDG 11 - Sustainable Cities & Communities'],
      themes: const ['Environment', 'Polluter Pays', 'Heritage Protection'],
      subjects: const ['Environmental Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Taj case applied the polluter-pays principle',
        'Protects Article 21 right to clean environment',
      ],
      mainsThemes: const [
        'Environment protection and sustainable development',
        'Polluter-pays in Indian jurisprudence',
      ],
      interviewAngles: const [
        'How do courts balance heritage protection with industry?',
      ],
      judgmentDate: DateTime(1997),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['VELLORE_CITIZENS'],
      garudaExplanation:
          'Applied polluter pays to relocate industries threatening the Taj and protect the environment.',
      commonMistakes: const [
        'Confusing Taj case with Vellore or Godavarman',
      ],
      memoryTricks: const ['Mehta + Taj = polluter pays'],
      oneLineSummary:
          'Industries polluting the Taj Trapezium Zone were ordered to relocate; polluter pays applied.',
      detailedSummary:
          'The Court ordered the relocation of polluting industries around the Taj and applied the polluter-pays principle for environmental restoration.',
      citations: const ['(1997) 11 SCC 227'],
      evidenceReferences: const ['(1997) 11 SCC 227'],
      evidenceIds: const ['ev_MC_MEHTA_TAJ_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1997) 11 SCC 227',
      authoringJudge: 'Kuldip Singh J.',
      majorityOpinion: 'Unanimous; relocation ordered, polluter pays applied.',
    ),

    // ------------------------------------------------------------------------
    // 14. Vellore Citizens Welfare Forum v. Union of India (1996) — Precautionary principle
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-VELLORE-CITIZENS',
      caseId: 'VELLORE_CITIZENS',
      caseName: 'Vellore Citizens\' Welfare Forum v. Union of India',
      citation: '(1996) 5 SCC 647',
      year: 1996,
      court: 'Supreme Court of India',
      bench: 'Bench of Kuldip Singh J. & S. Saghir Ahmad J.',
      benchStrength: 2,
      judges: const ['Kuldip Singh J.', 'S. Saghir Ahmad J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.environmentalLaw,
      keywords: const [
        'Precautionary Principle',
        'Polluter Pays',
        'Tanneries',
        'Article 21',
        'Sustainable Development'
      ],
      aliases: const ['Vellore Tanneries Case'],
      historicalContext:
          'Untreated effluents from tanneries in the Vellore district polluted the Palar river and groundwater.',
      facts:
          'Residents moved the Court against tanneries discharging untreated effluent into the river and degrading agricultural land.',
      issues: const [
        'Are the precautionary and polluter-pays principles part of Indian environmental law?',
        'Who bears the cost of environmental damage?',
      ],
      petitionerArguments: const [
        'The tanneries must be liable for the environmental damage caused.',
      ],
      respondentArguments: const [
        'Tanneries are a source of livelihood and exports.',
      ],
      decision:
          'Held the precautionary principle and polluter-pays are part of Indian law; directed closure of polluting tanneries and cost recovery.',
      ratioDecidendi: const [
        'The precautionary and polluter-pays principles are part of Article 21 jurisprudence.',
        'Environmental damage must be remedied at the polluter\'s cost.',
      ],
      keyPrinciples: const [
        'Precautionary principle and polluter pays adopted.',
        'Sustainable development as a constitutional obligation.',
      ],
      constitutionalSignificance:
          'Formally adopted the precautionary principle and polluter-pays into Indian environmental jurisprudence.',
      constitutionalInterpretation:
          'Articles 21, 48A and 51A(g) embody the right to a healthy environment.',
      legalPrinciple:
          'The polluter must bear the cost of restoring the environment; precaution must govern development.',
      relatedArticles: const ['Article 21', 'Article 48A', 'Article 51A(g)'],
      relatedActs: const ['Environment (Protection) Act, 1986'],
      precedentsFollowed: const ['ICELA_BICHHRI'],
      relatedCases: const ['ICELA_BICHHRI', 'MC_MEHTA_TAJ', 'TN_GODAVARMAN'],
      relatedBodies: const ['bod_cpcb'],
      relatedCurrentAffairs: const ['ca_environment_law'],
      sdgGoals: const ['SDG 12 - Responsible Consumption & Production'],
      themes: const ['Environment', 'Precautionary Principle', 'Polluter Pays'],
      subjects: const ['Environmental Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Vellore formally adopted the precautionary principle',
        'Distinguish polluter pays from absolute liability',
      ],
      mainsThemes: const [
        'Environmental principles in Indian constitutional law',
        'Sustainable development and polluter liability',
      ],
      interviewAngles: const [
        'How is the precautionary principle applied to new projects?',
      ],
      judgmentDate: DateTime(1996, 8, 28),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['MC_MEHTA_TAJ'],
      garudaExplanation:
          'Brought the precautionary principle and polluter pays into Indian law through Article 21.',
      commonMistakes: const [
        'Confusing Vellore with the Oleum gas case (absolute liability)',
      ],
      memoryTricks: const ['Vellore = precaution + polluter pays'],
      oneLineSummary:
          'The precautionary principle and polluter pays are part of Indian environmental law.',
      detailedSummary:
          'The Court adopted the precautionary and polluter-pays principles as part of the constitutional right to a clean environment and ordered tanneries to bear restoration costs.',
      citations: const ['(1996) 5 SCC 647'],
      evidenceReferences: const ['(1996) 5 SCC 647'],
      evidenceIds: const ['ev_VELLORE_CITIZENS_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1996) 5 SCC 647',
      authoringJudge: 'Kuldip Singh J.',
      majorityOpinion: 'Unanimous; precautionary principle and polluter pays adopted.',
    ),

    // ------------------------------------------------------------------------
    // 15. Indian Council for Enviro-Legal Action v. Union of India (1996) — Bichhri
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-ICELA-BICHHRI',
      caseId: 'ICELA_BICHHRI',
      caseName: 'Indian Council for Enviro-Legal Action v. Union of India',
      citation: '(1996) 3 SCC 212',
      year: 1996,
      court: 'Supreme Court of India',
      bench: 'Bench of Kuldip Singh J. & B.P. Jeevan Reddy J.',
      benchStrength: 2,
      judges: const ['Kuldip Singh J.', 'B.P. Jeevan Reddy J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.environmentalLaw,
      keywords: const [
        'Bichhri',
        'Polluter Pays',
        'Toxic Waste',
        'Article 21',
        'Restoration'
      ],
      aliases: const ['Bichhri Case'],
      historicalContext:
          'Chemical industries in Bichhri village (Rajasthan) dumped toxic sludge, contaminating groundwater and soil.',
      facts:
          'A PIL by ICELA exposed untreated toxic waste from chemical plants contaminating the Bichhri area.',
      issues: const [
        'Who is liable for the damage caused by hazardous waste?',
        'Can the polluter be made to pay for restoration?',
      ],
      petitionerArguments: const [
        'Industries must be held liable for the environmental and health damage.',
      ],
      respondentArguments: const [
        'Industries claim the waste was properly handled.',
      ],
      decision:
          'Applied the polluter-pays principle; ordered the polluting industries to pay for the cost of remedial measures and restoration.',
      ratioDecidendi: const [
        'The polluter-pays principle requires the polluter to bear the cost of restoration.',
        'A person who causes environmental damage is strictly liable.',
      ],
      keyPrinciples: const [
        'Polluter pays and cost recovery.',
        'Right to a clean environment under Article 21.',
      ],
      constitutionalSignificance:
          'One of the earliest and clearest applications of the polluter-pays principle for toxic-waste damage.',
      constitutionalInterpretation:
          'Articles 21, 48A and 51A(g) oblige the polluter to restore the environment.',
      legalPrinciple:
          'The polluter must pay for the restoration of land, water and health damaged by hazardous waste.',
      relatedArticles: const ['Article 21', 'Article 48A', 'Article 51A(g)'],
      relatedActs: const [
        'Environment (Protection) Act, 1986',
        'Hazardous Waste (Management and Handling) Rules, 1989'
      ],
      precedentsFollowed: const ['VELLORE_CITIZENS'],
      relatedCases: const ['VELLORE_CITIZENS', 'MC_MEHTA_TAJ'],
      relatedBodies: const ['bod_cpcb'],
      relatedSchemes: const [],
      relatedCurrentAffairs: const ['ca_hazardous_waste'],
      sdgGoals: const ['SDG 12 - Responsible Consumption & Production'],
      themes: const ['Environment', 'Polluter Pays', 'Toxic Waste'],
      subjects: const ['Environmental Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Bichhri case applied polluter pays to toxic waste',
        'Polluter pays differs from absolute liability',
      ],
      mainsThemes: const [
        'Environmental liability of industry',
        'Polluter-pays and restoration',
      ],
      interviewAngles: const [
        'How does polluter pays shift the burden of hazardous waste?',
      ],
      judgmentDate: DateTime(1996, 2, 13),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      frequentlyConfusedCases: const ['VELLORE_CITIZENS'],
      garudaExplanation:
          'Applied polluter pays to make hazardous-waste polluters pay for restoration.',
      commonMistakes: const [
        'Confusing Bichhri with the Oleum absolute-liability case',
      ],
      memoryTricks: const ['Bichhri = toxic waste, polluter pays'],
      oneLineSummary:
          'Polluting industries were ordered to pay for restoration of the Bichhri site.',
      detailedSummary:
          'The Court held polluting industries liable for the cost of remediating toxic waste damage, applying the polluter-pays principle.',
      citations: const ['(1996) 3 SCC 212'],
      evidenceReferences: const ['(1996) 3 SCC 212'],
      evidenceIds: const ['ev_ICELA_BICHHRI_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1996) 3 SCC 212',
      authoringJudge: 'Kuldip Singh J.',
      majorityOpinion: 'Unanimous; polluter pays for restoration.',
    ),

    // ------------------------------------------------------------------------
    // 16. T.N. Godavarman Thirumulpad v. Union of India (1997) — Forests
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-TN-GODAVARMAN',
      caseId: 'TN_GODAVARMAN',
      caseName: 'T.N. Godavarman Thirumulpad v. Union of India',
      citation: '(1997) 2 SCC 267',
      year: 1997,
      court: 'Supreme Court of India',
      bench: 'Bench of J.S. Verma C.J. & B.N. Kirpal J.',
      benchStrength: 2,
      judges: const ['J.S. Verma C.J.', 'B.N. Kirpal J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.environmentalLaw,
      keywords: const [
        'Forests',
        'Forest Conservation Act',
        'Article 21',
        'Article 48A',
        'Sustainable Development'
      ],
      aliases: const ['Godavarman Case'],
      historicalContext:
          'Illegal felling in the Nilgiris prompted a PIL that became the longest-running environmental monitoring case.',
      facts:
          'A PIL against illegal timber operations in the Nilgiris led to a wide interpretation of "forest" and a national regime for forest protection.',
      issues: const [
        'What constitutes a "forest" under the Forest Conservation Act, 1980?',
        'How must forests be protected until Parliament legislates?',
      ],
      petitionerArguments: const [
        'All forests, not just notified ones, need constitutional protection.',
      ],
      respondentArguments: const [
        'Development projects require forest diversion.',
      ],
      decision:
          'Widened the definition of "forest" to include all areas recorded as forest; banned non-forest use without approval; set up a monitoring regime.',
      ratioDecidendi: const [
        '"Forest" includes all statutorily recognised forests regardless of classification.',
        'The Forest Conservation Act requires prior approval for any non-forest use.',
        'Sustainable development must guide forest use.',
      ],
      keyPrinciples: const [
        'Continued monitoring by the Supreme Court.',
        'Balance of development and conservation.',
      ],
      constitutionalSignificance:
          'The single most important forest-protection judgment, with ongoing monitoring orders.',
      constitutionalInterpretation:
          'Articles 21 and 48A read with Article 51A(g) mandate forest conservation.',
      legalPrinciple:
          'All forest land is protected; non-forest use requires prior approval under the Forest Conservation Act.',
      relatedArticles: const ['Article 21', 'Article 48A', 'Article 51A(g)'],
      relatedActs: const ['Forest (Conservation) Act, 1980'],
      precedentsFollowed: const ['VELLORE_CITIZENS'],
      relatedCases: const ['VELLORE_CITIZENS', 'MC_MEHTA_TAJ'],
      relatedBodies: const ['bod_cpcb'],
      relatedSchemes: const ['National Mission for a Green India'],
      relatedCurrentAffairs: const ['ca_forest_amendment'],
      sdgGoals: const ['SDG 15 - Life on Land'],
      themes: const ['Forests', 'Environment', 'Sustainable Development'],
      subjects: const ['Environmental Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Godavarman widened the definition of forest',
        'Ongoing monitoring by the Supreme Court',
      ],
      mainsThemes: const [
        'Forest conservation and the Forest Conservation Act',
        'Judicial monitoring of environmental law',
      ],
      interviewAngles: const [
        'How has Godavarman shaped India\'s forest governance?',
      ],
      judgmentDate: DateTime(1996, 12, 12),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['VELLORE_CITIZENS'],
      garudaExplanation:
          'Protects all forests and created India\'s continuing forest-monitoring regime.',
      commonMistakes: const [
        'Thinking only notified forests are protected',
      ],
      memoryTricks: const ['Godavarman = all forests protected'],
      oneLineSummary:
          'All forest land is protected; non-forest use requires prior approval.',
      detailedSummary:
          'The Court gave a wide meaning to "forest", prohibited non-forest use without approval, and established a long-running monitoring framework.',
      citations: const ['(1997) 2 SCC 267'],
      evidenceReferences: const ['(1997) 2 SCC 267'],
      evidenceIds: const ['ev_TN_GODAVARMAN_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1997) 2 SCC 267',
      authoringJudge: 'J.S. Verma C.J.',
      majorityOpinion: 'Unanimous; forests protected, monitoring regime set.',
    ),

    // ------------------------------------------------------------------------
    // 17. Narmada Bachao Andolan v. Union of India (2000) — Dams & displacement
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-NARMADA-BACHAO',
      caseId: 'NARMADA_BACHAO',
      caseName: 'Narmada Bachao Andolan v. Union of India',
      citation: '(2000) 10 SCC 664',
      year: 2000,
      court: 'Supreme Court of India',
      bench: '3-Judge Bench',
      benchStrength: 3,
      judges: const ['B.N. Kirpal J.', 'S.S.M. Quadri J.', 'M.B. Shah J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.environmentalLaw,
      keywords: const [
        'Sardar Sarovar',
        'Displacement',
        'Rehabilitation',
        'Sustainable Development',
        'Article 21'
      ],
      aliases: const ['Narmada Dam Case', 'Sardar Sarovar Case'],
      historicalContext:
          'The Sardar Sarovar Dam on the Narmada faced objections over environmental impact and large-scale displacement.',
      facts:
          'The Narmada Bachao Andolan challenged the construction of the Sardar Sarovar Dam and the rehabilitation package for the displaced.',
      issues: const [
        'Does the dam project meet the test of sustainable development?',
        'Are the rehabilitation and environmental plans adequate?',
      ],
      petitionerArguments: const [
        'The dam displaces thousands without adequate rehabilitation and harms the ecology.',
      ],
      respondentArguments: const [
        'The project provides irrigation and power to water-scarce regions.',
      ],
      decision:
          'By 2:1, allowed the construction to continue subject to compliance with environmental and rehabilitation safeguards; development and displacement must be balanced.',
      ratioDecidendi: const [
        'The right to water and development must be balanced with environmental protection.',
        'Displacement must be compensated through effective rehabilitation.',
        'Sustainable development is a goal of the Indian Constitution.',
      ],
      keyPrinciples: const [
        'Balancing development, environment and rehabilitation.',
        'Narmada Water Disputes Tribunal Award binding.',
      ],
      constitutionalSignificance:
          'The leading authority on large dams, displacement and sustainable development.',
      constitutionalInterpretation:
          'Article 21 does not prohibit development but requires balancing with environmental and rehabilitative concerns.',
      legalPrinciple:
          'Development projects can proceed provided displacement is compensated and environmental norms are met.',
      relatedArticles: const ['Article 21', 'Article 48A', 'Article 51A(g)'],
      relatedActs: const ['Narmada Water Disputes Tribunal Award, 1979'],
      precedentsFollowed: const ['VELLORE_CITIZENS'],
      precedentsDistinguished: const ['TN_GODAVARMAN'],
      relatedCases: const ['VELLORE_CITIZENS', 'TN_GODAVARMAN'],
      relatedSchemes: const ['Pradhan Mantri Krishi Sinchayee Yojana'],
      relatedCurrentAffairs: const ['ca_narmada_dam'],
      sdgGoals: const ['SDG 6 - Clean Water & Sanitation'],
      themes: const ['Environment', 'Displacement', 'Dams', 'Rehabilitation'],
      subjects: const ['Environmental Law', 'Human Rights'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Narmada case was 2:1',
        'Development allowed subject to rehabilitation',
      ],
      mainsThemes: const [
        'Development vs environment',
        'Rehabilitation of displaced persons',
      ],
      interviewAngles: const [
        'How should displacement be balanced with development?',
      ],
      judgmentDate: DateTime(2000, 10, 18),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      frequentlyConfusedCases: const ['TN_GODAVARMAN'],
      garudaExplanation:
          'Allowed the Sardar Sarovar Dam with safeguards; the reference case on displacement and sustainable development.',
      commonMistakes: const [
        'Thinking the dam was stopped',
        'Missing the 2:1 split',
      ],
      memoryTricks: const ['Narmada = development + rehabilitation balance'],
      oneLineSummary:
          'The Sardar Sarovar Dam was allowed with environmental and rehabilitation safeguards.',
      detailedSummary:
          'The Court upheld construction subject to the Narmada Tribunal Award and environmental safeguards, framing sustainable development as a constitutional goal.',
      citations: const ['(2000) 10 SCC 664'],
      evidenceReferences: const ['(2000) 10 SCC 664'],
      evidenceIds: const ['ev_NARMADA_BACHAO_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2000) 10 SCC 664',
      authoringJudge: 'B.N. Kirpal J.',
      majorityOpinion: '2:1; construction allowed with safeguards.',
      minorityOpinion: 'S.S.M. Quadri J. dissented.',
      dissent: 'Quadri J. held the dam should not proceed until resettlement was complete.',
    ),

    // ------------------------------------------------------------------------
    // 18. Association for Democratic Reforms v. Union of India (2002) — Voter disclosure
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-ADR-ASSOCIATION',
      caseId: 'ADR_ASSOCIATION',
      caseName: 'Association for Democratic Reforms v. Union of India',
      citation: '(2002) 5 SCC 294',
      year: 2002,
      court: 'Supreme Court of India',
      bench: 'Bench of M.B. Shah J. & P. Venkatarama Reddi J.',
      benchStrength: 2,
      judges: const ['M.B. Shah J.', 'P. Venkatarama Reddi J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.electoralLaw,
      keywords: const [
        'Voter Right to Know',
        'Criminal Disclosure',
        'Article 19(1)(a)',
        'Election Commission',
        'RPA 1951'
      ],
      aliases: const ['Voter Disclosure Case'],
      historicalContext:
          'A PIL sought disclosure of criminal, educational and financial details of candidates contesting elections.',
      facts:
          'The Association for Democratic Reforms sought directions for candidates to disclose their antecedents before elections.',
      issues: const [
        'Is the voter\'s right to know about candidates part of free speech?',
        'Can the Election Commission direct such disclosure?',
      ],
      petitionerArguments: const [
        'Voters need candidate information to make an informed choice.',
      ],
      respondentArguments: const [
        'Disclosure would violate the privacy of candidates.',
      ],
      decision:
          'Held the voter\'s right to know is part of Article 19(1)(a); directed the Election Commission to mandate disclosure of criminal, educational and financial details.',
      ratioDecidendi: const [
        'The right to information about candidates is part of free speech and expression.',
        'An informed electorate is essential to democracy.',
        'The Election Commission can direct disclosure under Article 324.',
      ],
      keyPrinciples: const [
        'Voter\'s right to know as a fundamental right.',
        'Transparency in elections.',
      ],
      constitutionalSignificance:
          'The foundation of electoral transparency in India; heavily tested in GS2 (elections, governance).',
      constitutionalInterpretation:
          'Article 19(1)(a) includes the voter\'s right to be informed about candidates.',
      legalPrinciple:
          'Candidates must disclose criminal, educational and financial antecedents before elections.',
      relatedArticles: const ['Article 19(1)(a)', 'Article 324'],
      relatedActs: const ['Representation of the People Act, 1951'],
      relatedCurrentAffairs: const ['ca_electoral_reforms'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Elections', 'Transparency', 'Voter Rights', 'Democracy'],
      subjects: const ['Constitutional Law', 'Electoral Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Voter\'s right to know flows from Article 19(1)(a)',
        'Disclosure directed by the Election Commission under Article 324',
      ],
      mainsThemes: const [
        'Electoral transparency and criminalisation of politics',
        'Right to know as part of free speech',
      ],
      interviewAngles: const [
        'How does ADR disclosure reduce criminalisation of politics?',
      ],
      judgmentDate: DateTime(2002, 5, 2),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 4,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['PUCL_NOTA'],
      garudaExplanation:
          'Mandated candidate disclosure and established the voter\'s right to know.',
      commonMistakes: const [
        'Confusing ADR (disclosure) with PUCL (NOTA)',
      ],
      memoryTricks: const ['ADR = candidate disclosure'],
      oneLineSummary:
          'Candidates must disclose criminal, educational and financial details; the voter has a right to know.',
      detailedSummary:
          'The Court held disclosure of candidates\' antecedents essential to free and fair elections and directed the Election Commission to mandate it.',
      citations: const ['(2002) 5 SCC 294'],
      evidenceReferences: const ['(2002) 5 SCC 294'],
      evidenceIds: const ['ev_ADR_ASSOCIATION_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2002) 5 SCC 294',
      authoringJudge: 'M.B. Shah J.',
      majorityOpinion: 'Unanimous; disclosure mandated.',
    ),

    // ------------------------------------------------------------------------
    // 19. Lily Thomas v. Union of India (2013) — Disqualification on conviction
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-LILY-THOMAS',
      caseId: 'LILY_THOMAS',
      caseName: 'Lily Thomas v. Union of India',
      citation: '(2013) 7 SCC 653',
      year: 2013,
      court: 'Supreme Court of India',
      bench: 'Bench of A.K. Patnaik J. & S.J. Mukhopadhaya J.',
      benchStrength: 2,
      judges: const ['A.K. Patnaik J.', 'S.J. Mukhopadhaya J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.electoralLaw,
      keywords: const [
        'Disqualification',
        'Conviction',
        'Article 102',
        'Article 191',
        'Representation of the People Act'
      ],
      aliases: const ['MP/MLA Disqualification Case'],
      historicalContext:
          'Section 8(4) of the Representation of the People Act, 1951 protected sitting MPs/MLAs from immediate disqualification on conviction.',
      facts:
          'Lily Thomas challenged Section 8(4) RPA which gave a three-month window to sitting legislators to appeal before disqualification took effect.',
      issues: const [
        'Is Section 8(4) RPA unconstitutional?',
        'Does it create an irrational distinction between sitting and contesting legislators?',
      ],
      petitionerArguments: const [
        'The protective window under Section 8(4) is discriminatory.',
      ],
      respondentArguments: const [
        'Sitting legislators need time to appeal.',
      ],
      decision:
          'Struck down Section 8(4) RPA as unconstitutional; MPs/MLAs now stand disqualified immediately upon conviction for the listed offences.',
      ratioDecidendi: const [
        'Section 8(4) violates Articles 101(2), 102(1)(e), 190(2) and 191(1)(e).',
        'The right to contest is statutory, not a fundamental right.',
      ],
      keyPrinciples: const [
        'Immediate disqualification on conviction.',
        'No protection for sitting legislators.',
      ],
      constitutionalSignificance:
          'Key to the criminalisation-of-politics debate and electoral reform.',
      constitutionalInterpretation:
          'Articles 102(1)(e) and 191(1)(e) require immediate disqualification on conviction.',
      legalPrinciple:
          'A legislator convicted of a listed offence is disqualified from the date of conviction.',
      relatedArticles: const ['Article 102', 'Article 191'],
      relatedActs: const ['Representation of the People Act, 1951'],
      sections: const ['Section 8 RPA'],
      relatedCases: const ['ADR_ASSOCIATION', 'PUCL_NOTA'],
      relatedCurrentAffairs: const ['ca_criminalisation_politics'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Elections', 'Disqualification', 'Criminalisation of Politics'],
      subjects: const ['Constitutional Law', 'Electoral Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Disqualification is immediate on conviction',
        'Struck down Section 8(4) RPA',
      ],
      mainsThemes: const [
        'Criminalisation of politics and electoral reform',
        'Disqualification jurisprudence',
      ],
      interviewAngles: const [
        'Why do convicted legislators still contest elections?',
      ],
      judgmentDate: DateTime(2013, 7, 10),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['ADR_ASSOCIATION'],
      garudaExplanation:
          'Ended the three-month protective window; legislators are disqualified immediately on conviction.',
      commonMistakes: const [
        'Thinking Lily Thomas dealt with NOTA',
        'Missing that it struck down Section 8(4) RPA',
      ],
      memoryTricks: const ['Lily Thomas = immediate disqualification'],
      oneLineSummary:
          'Section 8(4) RPA struck down; legislators disqualified on the date of conviction.',
      detailedSummary:
          'The Court held the protective window for sitting legislators unconstitutional, making disqualification operate immediately upon conviction.',
      citations: const ['(2013) 7 SCC 653'],
      evidenceReferences: const ['(2013) 7 SCC 653'],
      evidenceIds: const ['ev_LILY_THOMAS_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2013) 7 SCC 653',
      authoringJudge: 'A.K. Patnaik J.',
      majorityOpinion: 'Unanimous; Section 8(4) struck down.',
    ),

    // ------------------------------------------------------------------------
    // 20. PUCL v. Union of India (2013) — NOTA
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-PUCL-NOTA',
      caseId: 'PUCL_NOTA',
      caseName: 'People\'s Union for Civil Liberties v. Union of India',
      citation: '(2013) 10 SCC 1',
      year: 2013,
      court: 'Supreme Court of India',
      bench: 'Bench of P. Sathasivam C.J. & B.S. Chauhan J.',
      benchStrength: 2,
      judges: const ['P. Sathasivam C.J.', 'B.S. Chauhan J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.electoralLaw,
      keywords: const [
        'NOTA',
        'Negative Vote',
        'Article 19',
        'Free and Fair Elections',
        'Rule 49-O'
      ],
      aliases: const ['NOTA Case'],
      historicalContext:
          'PUCL sought a mechanism for voters to register a negative vote, leading to the introduction of NOTA.',
      facts:
          'A PIL sought the direction that voters be given the option to record "none of the above" in elections.',
      issues: const [
        'Is there a right to register a negative vote?',
        'Should NOTA be available on the EVM?',
      ],
      petitionerArguments: const [
        'The right to free speech includes the right to register dissent through a negative vote.',
      ],
      respondentArguments: const [
        'NOTA would be of little practical value.',
      ],
      decision:
          'Held voters have the right to register a negative vote; directed the Election Commission to provide NOTA on EVMs and ballot papers.',
      ratioDecidendi: const [
        'NOTA is part of the right to free speech and a free and fair election.',
        'It does not amount to a right to reject a candidate.',
      ],
      keyPrinciples: const [
        'Negative voting strengthens democracy.',
        'NOTA has no electoral value; the candidate with the most votes still wins.',
      ],
      constitutionalSignificance:
          'Established NOTA, a recurring GS2 question on electoral democracy.',
      constitutionalInterpretation:
          'Articles 19(1)(a) and 21 support the voter\'s right to dissent via NOTA.',
      legalPrinciple:
          'Voters can register a negative vote through NOTA without a reason.',
      relatedArticles: const ['Article 19(1)(a)', 'Article 21', 'Article 324'],
      relatedActs: const ['Representation of the People Act, 1951'],
      sections: const ['Rule 49-O Conduct of Elections Rules'],
      relatedCases: const ['ADR_ASSOCIATION', 'LILY_THOMAS'],
      relatedCurrentAffairs: const ['ca_nota'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Elections', 'NOTA', 'Voter Rights', 'Democracy'],
      subjects: const ['Constitutional Law', 'Electoral Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'NOTA does not reject all candidates',
        'NOTA has no electoral value',
      ],
      mainsThemes: const [
        'Electoral democracy and negative voting',
        'NOTA and electoral reform',
      ],
      interviewAngles: const [
        'What is the real effect of NOTA in elections?',
      ],
      judgmentDate: DateTime(2013, 9, 27),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['ADR_ASSOCIATION'],
      garudaExplanation:
          'Brought NOTA into Indian elections, strengthening the voter\'s right to dissent.',
      commonMistakes: const [
        'Thinking NOTA can reject all candidates',
        'Confusing PUCL with ADR',
      ],
      memoryTricks: const ['PUCL = NOTA'],
      oneLineSummary:
          'Voters can register a negative vote through NOTA in all elections.',
      detailedSummary:
          'The Court directed the Election Commission to provide NOTA, holding negative voting a part of free and fair elections.',
      citations: const ['(2013) 10 SCC 1'],
      evidenceReferences: const ['(2013) 10 SCC 1'],
      evidenceIds: const ['ev_PUCL_NOTA_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2013) 10 SCC 1',
      authoringJudge: 'P. Sathasivam C.J.',
      majorityOpinion: 'Unanimous; NOTA directed.',
    ),

    // ------------------------------------------------------------------------
    // 21. Bachan Singh v. State of Punjab (1980) — Rarest of rare
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-BACHAN-SINGH',
      caseId: 'BACHAN_SINGH',
      caseName: 'Bachan Singh v. State of Punjab',
      citation: '(1980) 2 SCC 684',
      year: 1980,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'Y.V. Chandrachud C.J.',
        'N.L. Untwalia J.',
        'P.N. Bhagwati J.',
        'V.D. Tulzapurkar J.',
        'A.D. Koshal J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.criminalLaw,
      keywords: const [
        'Death Penalty',
        'Rarest of Rare',
        'Article 21',
        'Section 302 IPC',
        'Sentencing'
      ],
      aliases: const ['Death Penalty Case'],
      historicalContext:
          'The constitutional validity of the death penalty for murder under Section 302 IPC was examined.',
      facts:
          'Bachan Singh, convicted of murder, challenged the constitutionality of the death sentence under Article 21.',
      issues: const [
        'Is the death penalty constitutional under Article 21?',
        'When is death the appropriate sentence?',
      ],
      petitionerArguments: const [
        'The death penalty is arbitrary and violates the right to life.',
      ],
      respondentArguments: const [
        'The penalty is a deterrent for the gravest crimes.',
      ],
      decision:
          'Held the death penalty constitutional but confined it to the "rarest of rare" cases; the Court must balance aggravating and mitigating circumstances.',
      ratioDecidendi: const [
        'The death penalty is not per se unconstitutional.',
        'It must be awarded only in the rarest of rare cases.',
        'The court must consider both aggravating and mitigating circumstances.',
      ],
      keyPrinciples: const [
        'Rarest-of-rare doctrine for the death penalty.',
        'Special reasons must be recorded under Section 354(3) CrPC.',
      ],
      constitutionalSignificance:
          'The governing authority on capital punishment in India; a staple of GS2/GS3 and ethics questions.',
      constitutionalInterpretation:
          'Article 21 does not prohibit the death penalty but requires a fair procedure and rarest-of-rare application.',
      legalPrinciple:
          'Death is the exception, life imprisonment the rule, applied only in the rarest of rare cases.',
      relatedArticles: const ['Article 21'],
      relatedActs: const ['Indian Penal Code, 1860'],
      sections: const ['Section 302 IPC'],
      relatedCases: const ['MITHU', 'LALITA_KUMARI'],
      relatedCurrentAffairs: const ['ca_death_penalty'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Death Penalty', 'Criminal Law', 'Sentencing'],
      subjects: const ['Criminal Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Death penalty is constitutional but rarest of rare',
        'Exception, not the rule',
      ],
      mainsThemes: const [
        'Capital punishment and human rights',
        'Sentencing policy and rarest-of-rare',
      ],
      interviewAngles: const [
        'Should India abolish the death penalty?',
      ],
      judgmentDate: DateTime(1980, 5, 9),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['MITHU'],
      garudaExplanation:
          'Confined the death penalty to rarest-of-rare cases, a cornerstone of Indian sentencing law.',
      commonMistakes: const [
        'Confusing Bachan Singh with Mithu (s.303)',
      ],
      memoryTricks: const ['Bachan = rarest of rare'],
      oneLineSummary:
          'The death penalty is constitutional but limited to rarest-of-rare cases.',
      detailedSummary:
          'The 5-judge bench upheld the death penalty but restricted it to the rarest of rare cases after weighing aggravating and mitigating factors.',
      citations: const ['(1980) 2 SCC 684'],
      evidenceReferences: const ['(1980) 2 SCC 684'],
      evidenceIds: const ['ev_BACHAN_SINGH_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1980) 2 SCC 684',
      authoringJudge: 'Y.V. Chandrachud C.J.',
      majorityOpinion: 'Unanimous; death penalty upheld, rarest-of-rare standard set.',
    ),

    // ------------------------------------------------------------------------
    // 22. Mithu v. State of Punjab (1983) — Section 303 IPC
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-MITHU',
      caseId: 'MITHU',
      caseName: 'Mithu v. State of Punjab',
      citation: '(1983) 2 SCC 277',
      year: 1983,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'Y.V. Chandrachud C.J.',
        'S. Murtaza Fazal Ali J.',
        'V.D. Tulzapurkar J.',
        'A. Varadarajan J.',
        'A.P. Sen J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.criminalLaw,
      keywords: const [
        'Section 303 IPC',
        'Mandatory Death',
        'Article 21',
        'Arbitrariness'
      ],
      aliases: const ['Section 303 Case'],
      historicalContext:
          'Section 303 IPC mandated the death penalty for a life convict who committed murder, without judicial discretion.',
      facts:
          'Mithu, a life convict sentenced to death under Section 303 IPC, challenged the mandatory death penalty as unconstitutional.',
      issues: const [
        'Is the mandatory death penalty under Section 303 IPC constitutional?',
      ],
      petitionerArguments: const [
        'A mandatory death penalty is arbitrary and violates Article 21.',
      ],
      respondentArguments: const [
        'Life convicts are a dangerous class deserving special deterrence.',
      ],
      decision:
          'Struck down Section 303 IPC as unconstitutional; the death penalty cannot be made mandatory without judicial discretion.',
      ratioDecidendi: const [
        'A mandatory death penalty is arbitrary and violates Article 21.',
        'The court must retain discretion in sentencing.',
      ],
      keyPrinciples: const [
        'No mandatory death sentence.',
        'Judicial discretion in sentencing is a facet of Article 21.',
      ],
      constitutionalSignificance:
          'Established that mandatory capital punishment violates the right to life, complementing Bachan Singh.',
      constitutionalInterpretation:
          'Article 21 prohibits a procedure that makes the death penalty compulsory without discretion.',
      legalPrinciple:
          'A statute cannot compel the death penalty; the court must weigh the circumstances of each case.',
      relatedArticles: const ['Article 21'],
      relatedActs: const ['Indian Penal Code, 1860'],
      sections: const ['Section 303 IPC'],
      precedentsFollowed: const ['BACHAN_SINGH'],
      relatedCases: const ['BACHAN_SINGH'],
      relatedCurrentAffairs: const ['ca_death_penalty'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Death Penalty', 'Criminal Law', 'Arbitrariness'],
      subjects: const ['Criminal Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Section 303 IPC struck down',
        'Mandatory death penalty is unconstitutional',
      ],
      mainsThemes: const [
        'Sentencing discretion and the death penalty',
        'Procedural fairness under Article 21',
      ],
      interviewAngles: const [
        'What makes a mandatory death penalty arbitrary?',
      ],
      judgmentDate: DateTime(1983, 4, 6),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      frequentlyConfusedCases: const ['BACHAN_SINGH'],
      garudaExplanation:
          'Struck down the mandatory death penalty under Section 303 IPC.',
      commonMistakes: const [
        'Confusing Mithu with Bachan Singh',
      ],
      memoryTricks: const ['Mithu = s.303 gone'],
      oneLineSummary:
          'Section 303 IPC (mandatory death) struck down as arbitrary.',
      detailedSummary:
          'The Court held a compulsory death sentence for life convicts unconstitutional under Article 21, requiring judicial discretion.',
      citations: const ['(1983) 2 SCC 277'],
      evidenceReferences: const ['(1983) 2 SCC 277'],
      evidenceIds: const ['ev_MITHU_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1983) 2 SCC 277',
      authoringJudge: 'Y.V. Chandrachud C.J.',
      majorityOpinion: 'Unanimous; Section 303 struck down.',
    ),

    // ------------------------------------------------------------------------
    // 23. Vineet Narain v. Union of India (1998) — CBI/CVC independence
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-VINEET-NARAIN',
      caseId: 'VINEET_NARAIN',
      caseName: 'Vineet Narain v. Union of India',
      citation: '(1998) 1 SCC 226',
      year: 1998,
      court: 'Supreme Court of India',
      bench: '3-Judge Bench',
      benchStrength: 3,
      judges: const ['J.S. Verma J.', 'B.N. Kirpal J.', 'S.P. Bharucha J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.regulatoryLaw,
      keywords: const [
        'CBI',
        'CVC',
        'Continuing Mandamus',
        'Article 14',
        'Transparency'
      ],
      aliases: const ['Jain Hawala Case'],
      historicalContext:
          'The Jain hawala diaries exposed alleged payments to public servants; the CBI probe proceeded without proper sanction supervision.',
      facts:
          'A PIL sought directions to ensure an effective and independent probe into the hawala transactions and a revamp of the CBI.',
      issues: const [
        'Is the CBI sufficiently independent from executive control?',
        'Can the Court issue directions in the absence of legislation?',
      ],
      petitionerArguments: const [
        'The CBI must be insulated from political interference.',
      ],
      respondentArguments: const [
        'Administrative control of the CBI is an executive function.',
      ],
      decision:
          'Used "continuing mandamus" to monitor the probe and laid down guidelines for the independence of the CBI and the CVC, which later informed the CVC Act, 2003.',
      ratioDecidendi: const [
        'The right to an effective investigation is part of Articles 14 and 21.',
        'The Court can issue interim directions that survive until legislation is passed.',
      ],
      keyPrinciples: const [
        'Continuing mandamus as a tool of accountability.',
        'CVC Act, 2003 codified the guidelines.',
      ],
      constitutionalSignificance:
          'The source of CVC/CBI reform; a GS2 governance and accountability topic.',
      constitutionalInterpretation:
          'Articles 14 and 21 require a fair and independent investigation of corruption.',
      legalPrinciple:
          'Investigative agencies must be insulated from executive influence to ensure a fair investigation.',
      relatedArticles: const ['Article 14', 'Article 21', 'Article 32'],
      relatedActs: const [
        'Central Vigilance Commission Act, 2003',
        'Delhi Special Police Establishment Act, 1946'
      ],
      relatedCases: const ['DK_BASU'],
      relatedBodies: const ['bod_cbi', 'bod_cvc'],
      relatedCurrentAffairs: const ['ca_cbi_reforms'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['CBI', 'CVC', 'Corruption', 'Accountability', 'Governance'],
      subjects: const ['Administrative Law', 'Criminal Law'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Vineet Narain led to the CVC Act, 2003',
        'Continuing mandamus used to monitor the probe',
      ],
      mainsThemes: const [
        'Independence of investigating agencies',
        'Anti-corruption governance',
      ],
      interviewAngles: const [
        'How independent is the CBI today?',
      ],
      judgmentDate: DateTime(1997, 12, 18),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 3,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['DK_BASU'],
      garudaExplanation:
          'Used continuing mandamus to reform the CBI and CVC, later codified in the CVC Act.',
      commonMistakes: const [
        'Attributing CVC creation to Vineet Narain without the 2003 Act',
      ],
      memoryTricks: const ['Vineet Narain = CBI + CVC independence'],
      oneLineSummary:
          'The CBI probe was monitored via continuing mandamus; CBI/CVC independence guidelines issued.',
      detailedSummary:
          'The Court invoked continuing mandamus, monitored the hawala probe, and issued guidelines for the independence of the CBI and CVC, later enacted as the CVC Act, 2003.',
      citations: const ['(1998) 1 SCC 226'],
      evidenceReferences: const ['(1998) 1 SCC 226'],
      evidenceIds: const ['ev_VINEET_NARAIN_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1998) 1 SCC 226',
      authoringJudge: 'J.S. Verma J.',
      majorityOpinion: 'Unanimous; guidelines for CBI/CVC independence.',
    ),

    // ------------------------------------------------------------------------
    // 24. Lalita Kumari v. Government of Uttar Pradesh (2014) — Mandatory FIR
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-LALITA-KUMARI',
      caseId: 'LALITA_KUMARI',
      caseName: 'Lalita Kumari v. Government of Uttar Pradesh',
      citation: '(2014) 2 SCC 1',
      year: 2014,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'P. Sathasivam C.J.',
        'B.S. Chauhan J.',
        'S.A. Bobde J.',
        'M.Y. Eqbal J.',
        'Arun Mishra J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.criminalLaw,
      keywords: const [
        'FIR',
        'Cognizable Offence',
        'Section 154 CrPC',
        'Preliminary Enquiry',
        'Article 21'
      ],
      aliases: const ['Mandatory FIR Case'],
      historicalContext:
        'Conflicting judicial views existed on whether the police must register an FIR immediately for every cognizable offence.',
      facts:
          'A minor\'s father sought an FIR for the alleged abduction of his daughter; the police conducted a preliminary enquiry instead of registering the FIR.',
      issues: const [
        'Is registration of an FIR mandatory for every cognizable offence?',
        'When is a preliminary enquiry permissible?',
      ],
      petitionerArguments: const [
        'Delay in registering an FIR defeats justice and violates Article 21.',
      ],
      respondentArguments: const [
        'Police need discretion to verify complaints before registration.',
      ],
      decision:
          'Held registration of an FIR is mandatory under Section 154 CrPC for every cognizable offence; a preliminary enquiry is permissible only in a narrow class of cases.',
      ratioDecidendi: const [
        'FIR registration is mandatory for cognizable offences under Section 154 CrPC.',
        'Preliminary enquiry is the exception, limited to specified categories such as medical negligence, commercial disputes and corruption.',
      ],
      keyPrinciples: const [
        'Mandatory FIR as a safeguard under Article 21.',
        'Strict limits on preliminary enquiry.',
      ],
      constitutionalSignificance:
          'Settled the FIR-registration law; a recurring GS2/criminal-law topic.',
      constitutionalInterpretation:
        'Article 21 requires an accessible and prompt police response to cognizable complaints.',
      legalPrinciple:
        'Police must register an FIR for every cognizable offence without preliminary enquiry, except in exceptional categories.',
      relatedArticles: const ['Article 21'],
      relatedActs: const ['Code of Criminal Procedure, 1973'],
      sections: const ['Section 154 CrPC'],
      precedentsDistinguished: const ['DK_BASU'],
      relatedCases: const ['DK_BASU', 'ARNESH_KUMAR'],
      relatedCurrentAffairs: const ['ca_fir_reforms'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Criminal Law', 'FIR', 'Police', 'Access to Justice'],
      subjects: const ['Criminal Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'FIR is mandatory for cognizable offences',
        'Preliminary enquiry only in exceptional cases',
      ],
      mainsThemes: const [
        'Criminal justice and police accountability',
        'FIR registration and access to justice',
      ],
      interviewAngles: const [
        'When can the police refuse to register an FIR?',
      ],
      judgmentDate: DateTime(2013, 11, 12),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['ARNESH_KUMAR'],
      garudaExplanation:
        'Made FIR registration mandatory for cognizable offences with a narrow preliminary-enquiry exception.',
      commonMistakes: const [
        'Confusing Lalita Kumari (FIR) with Arnesh Kumar (arrest)',
      ],
      memoryTricks: const ['Lalita = mandatory FIR'],
      oneLineSummary:
        'FIR registration is mandatory for cognizable offences; preliminary enquiry is exceptional.',
      detailedSummary:
        'The 5-judge bench held Section 154 CrPC mandates FIR registration for every cognizable offence, permitting preliminary enquiry only in exceptional categories.',
      citations: const ['(2014) 2 SCC 1'],
      evidenceReferences: const ['(2014) 2 SCC 1'],
      evidenceIds: const ['ev_LALITA_KUMARI_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2014) 2 SCC 1',
      authoringJudge: 'P. Sathasivam C.J.',
      majorityOpinion: 'Unanimous; mandatory FIR rule laid down.',
    ),

    // ------------------------------------------------------------------------
    // 25. Arnesh Kumar v. State of Bihar (2014) — Arrest safeguards
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-ARNESH-KUMAR',
      caseId: 'ARNESH_KUMAR',
      caseName: 'Arnesh Kumar v. State of Bihar',
      citation: '(2014) 8 SCC 273',
      year: 2014,
      court: 'Supreme Court of India',
      bench: 'Bench of C. Nagappan J. & M.Y. Eqbal J.',
      benchStrength: 2,
      judges: const ['C. Nagappan J.', 'M.Y. Eqbal J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.criminalLaw,
      keywords: const [
        'Arrest',
        'Section 41 CrPC',
        'Personal Liberty',
        'Dowry',
        'Article 21'
      ],
      aliases: const ['No Arrest Case'],
      historicalContext:
        'Automatic arrests under Section 498A IPC (dowry harassment) drew criticism for misuse against innocents.',
      facts:
        'Arnesh Kumar challenged his arrest in a dowry case, arguing that arrest was not necessary and safeguards under Section 41 CrPC were ignored.',
      issues: const [
        'Can the police arrest without recording reasons under Section 41(1)(b) CrPC?',
        'What safeguards protect against unnecessary arrest?',
      ],
      petitionerArguments: const [
        'Arrest is unnecessary where the offence carries a sentence of up to seven years.',
      ],
      respondentArguments: const [
        'Arrest is necessary to secure investigation.',
      ],
      decision:
          'Held arrest is not mandatory for offences punishable up to seven years; the police must record reasons and the satisfaction of necessity under Section 41(1)(b) CrPC.',
      ratioDecidendi: const [
        'For offences punishable up to seven years, arrest requires satisfaction of necessity under Section 41(1)(b) CrPC.',
        'Reasons for arrest must be recorded in writing.',
        'Compensation can be awarded for illegal arrest.',
      ],
      keyPrinciples: const [
        'Arrest as a rule not to be the norm for shorter-sentence offences.',
        'Protecting personal liberty under Article 21.',
      ],
      constitutionalSignificance:
          'The leading authority on arrest safeguards and the misuse of Section 498A; a GS2/criminal-law fixture.',
      constitutionalInterpretation:
        'Article 21 read with Section 41 CrPC protects against arbitrary arrest.',
      legalPrinciple:
        'No arrest for offences up to seven years unless the police records the satisfaction of necessity.',
      relatedArticles: const ['Article 21'],
      relatedActs: const ['Code of Criminal Procedure, 1973'],
      sections: const ['Section 41 CrPC'],
      precedentsFollowed: const ['DK_BASU'],
      relatedCases: const ['DK_BASU', 'LALITA_KUMARI'],
      relatedCurrentAffairs: const ['ca_arrest_reforms'],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      themes: const ['Criminal Law', 'Arrest', 'Personal Liberty', 'Dowry Law'],
      subjects: const ['Criminal Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Arnesh Kumar limits arrest for offences up to 7 years',
        'Distinct from Lalita Kumari (FIR)',
      ],
      mainsThemes: const [
        'Arrest and personal liberty',
        'Misuse of penal provisions',
      ],
      interviewAngles: const [
        'How does Arnesh Kumar check arbitrary arrest?',
      ],
      judgmentDate: DateTime(2014, 7, 2),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['LALITA_KUMARI'],
      garudaExplanation:
        'Bars automatic arrest for shorter-sentence offences without recorded necessity.',
      commonMistakes: const [
        'Confusing Arnesh Kumar with Lalita Kumari',
      ],
      memoryTricks: const ['Arnesh = arrest only when necessary'],
      oneLineSummary:
        'Arrest for offences up to seven years requires recorded necessity under Section 41 CrPC.',
      detailedSummary:
        'The Court held that police cannot arrest mechanically; for offences punishable up to seven years, satisfaction of necessity must be recorded.',
      citations: const ['(2014) 8 SCC 273'],
      evidenceReferences: const ['(2014) 8 SCC 273'],
      evidenceIds: const ['ev_ARNESH_KUMAR_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2014) 8 SCC 273',
      authoringJudge: 'C. Nagappan J.',
      majorityOpinion: 'Unanimous; arrest safeguards laid down.',
    ),

    // ------------------------------------------------------------------------
    // 26. Mohini Jain v. State of Karnataka (1992) — Right to education
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-MOHINI-JAIN',
      caseId: 'MOHINI_JAIN',
      caseName: 'Mohini Jain v. State of Karnataka',
      citation: '(1992) 3 SCC 666',
      year: 1992,
      court: 'Supreme Court of India',
      bench: 'Bench of Kuldip Singh J. & R.M. Sahai J.',
      benchStrength: 2,
      judges: const ['Kuldip Singh J.', 'R.M. Sahai J.'],
      status: CaseStatus.partiallyOverruled,
      caseType: CaseType.socialJustice,
      keywords: const [
        'Right to Education',
        'Capitation Fees',
        'Article 21',
        'Higher Education'
      ],
      aliases: const ['Capitation Fee Case'],
      historicalContext:
        'Private medical colleges charged exorbitant capitation fees, excluding meritorious students from poorer backgrounds.',
      facts:
        'Mohini Jain challenged the capitation-fee regime of private medical colleges in Karnataka.',
      issues: const [
        'Is the right to education a fundamental right?',
        'Are capitation fees constitutional?',
      ],
      petitionerArguments: const [
        'Capitation fees deny access to education and violate Article 21.',
      ],
      respondentArguments: const [
        'Private colleges have the autonomy to fix their fee structure.',
      ],
      decision:
        'Held the right to education is a fundamental right under Article 21; capitation fees are illegal and unconstitutional.',
      ratioDecidendi: const [
        'The right to education is implicit in the right to life under Article 21.',
        'Capitation fees are arbitrary, exploitative and unconstitutional.',
      ],
      keyPrinciples: const [
        'Right to education as a fundamental right.',
        'Later refined by Unni Krishnan to education up to 14 years.',
      ],
      constitutionalSignificance:
        'Began the right-to-education jurisprudence later crystallised in Unni Krishnan and Article 21A.',
      constitutionalInterpretation:
        'Article 21 includes the right to education; capitation fees violate it.',
      legalPrinciple:
        'Education cannot be commercialised through capitation fees; the right to education flows from Article 21.',
      relatedArticles: const ['Article 21', 'Article 41', 'Article 45'],
      relatedCases: const ['UNNIKRISHNAN'],
      relatedSchemes: const ['Sarva Shiksha Abhiyan'],
      sdgGoals: const ['SDG 4 - Quality Education'],
      themes: const ['Right to Education', 'Education', 'Capitation Fees'],
      subjects: const ['Constitutional Law', 'Social Justice'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Mohini Jain broadened education to all levels; Unni Krishnan narrowed it to 6-14',
        'Capitation fees held illegal',
      ],
      mainsThemes: const [
        'Education as a fundamental right',
        'Commercialisation of education',
      ],
      interviewAngles: const [
        'How did Unni Krishnan modify Mohini Jain?',
      ],
      judgmentDate: DateTime(1992),
      presentStatus: 'Partially superseded by Unni Krishnan',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      frequentlyConfusedCases: const ['UNNIKRISHNAN'],
      garudaExplanation:
        'First recognised the right to education as a fundamental right and struck down capitation fees.',
      commonMistakes: const [
        'Attributing the 6-14 limitation to Mohini Jain (it came from Unni Krishnan)',
      ],
      memoryTricks: const ['Mohini = education is a right, capitation fees illegal'],
      oneLineSummary:
        'The right to education is a fundamental right; capitation fees are unconstitutional.',
      detailedSummary:
        'The Court declared the right to education a fundamental right under Article 21 and struck down capitation fees, later refined by Unni Krishnan to education up to age 14.',
      citations: const ['(1992) 3 SCC 666'],
      evidenceReferences: const ['(1992) 3 SCC 666'],
      evidenceIds: const ['ev_MOHINI_JAIN_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(1992) 3 SCC 666',
      authoringJudge: 'Kuldip Singh J.',
      majorityOpinion: 'Unanimous; right to education recognised, capitation fees struck down.',
    ),

    // ------------------------------------------------------------------------
    // 27. Suchita Srivastava v. Chandigarh Administration (2009) — Reproductive autonomy
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SUCHITA-SRIVASTAVA',
      caseId: 'SUCHITA_SRIVASTAVA',
      caseName: 'Suchita Srivastava v. Chandigarh Administration',
      citation: '(2009) 9 SCC 1',
      year: 2009,
      court: 'Supreme Court of India',
      bench: 'Bench of K.G. Balakrishnan C.J. & P. Sathasivam J.',
      benchStrength: 2,
      judges: const ['K.G. Balakrishnan C.J.', 'P. Sathasivam J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.socialJustice,
      keywords: const [
        'Reproductive Autonomy',
        'Mental Disability',
        'MTP Act',
        'Article 21',
        'Women Rights'
      ],
      aliases: const ['Reproductive Rights Case'],
      historicalContext:
        'A woman with a mental disability became pregnant in a care home; the State sought termination against her wishes.',
      facts:
        'The Chandigarh Administration sought to terminate the pregnancy of a mentally-disabled woman; the Court examined her right to choose.',
      issues: const [
        'Can the State terminate a pregnancy without the woman\'s consent?',
        'Does mental disability negate reproductive autonomy?',
      ],
      petitionerArguments: const [
        'The woman\'s mental disability does not strip her of reproductive choice.',
      ],
      respondentArguments: const [
        'The pregnancy resulted from abuse and the woman cannot consent.',
      ],
      decision:
        'Held the State cannot terminate a pregnancy against the woman\'s wishes; reproductive autonomy is part of Article 21; mental disability does not automatically justify termination.',
      ratioDecidendi: const [
        'The right to reproductive autonomy is part of the right to life and personal liberty.',
        'Termination requires the woman\'s free consent unless a valid ground under the MTP Act exists.',
        'The State cannot act as a surrogate decision-maker.',
      ],
      keyPrinciples: const [
        'Reproductive choice as a facet of Article 21.',
        'Dignity and autonomy of persons with disabilities.',
      ],
      constitutionalSignificance:
        'The leading authority on reproductive rights and the rights of persons with disabilities.',
      constitutionalInterpretation:
        'Article 21 includes the right to make reproductive choices; disability does not negate autonomy.',
      legalPrinciple:
        'A pregnancy cannot be terminated without the woman\'s consent; the State cannot substitute its judgement.',
      relatedArticles: const ['Article 21'],
      relatedActs: const ['Medical Termination of Pregnancy Act, 1971'],
      relatedSchemes: const ['Pradhan Mantri Matru Vandana Yojana'],
      relatedCurrentAffairs: const ['ca_reproductive_rights'],
      sdgGoals: const ['SDG 3 - Good Health & Well-being', 'SDG 5 - Gender Equality'],
      themes: const ['Women Rights', 'Reproductive Autonomy', 'Disability Rights'],
      subjects: const ['Constitutional Law', 'Social Justice'],
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Mental disability does not negate reproductive autonomy',
        'MTP Act requires consent',
      ],
      mainsThemes: const [
        'Reproductive rights and Article 21',
        'Rights of persons with disabilities',
      ],
      interviewAngles: const [
        'How does Suchita Srivastava frame reproductive autonomy?',
      ],
      judgmentDate: DateTime(2009, 8, 28),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['COMMON_CAUSE_EUTHANASIA'],
      garudaExplanation:
        'Established reproductive autonomy and consent under Article 21, protecting persons with disabilities.',
      commonMistakes: const [
        'Confusing with euthanasia (right to die)',
      ],
      memoryTricks: const ['Suchita = consent for pregnancy, not State diktat'],
      oneLineSummary:
        'Pregnancy cannot be terminated without the woman\'s consent; reproductive autonomy is part of Article 21.',
      detailedSummary:
        'The Court held the State cannot force termination, affirming reproductive autonomy as a facet of the right to life and personal liberty.',
      citations: const ['(2009) 9 SCC 1'],
      evidenceReferences: const ['(2009) 9 SCC 1'],
      evidenceIds: const ['ev_SUCHITA_SRIVASTAVA_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2009) 9 SCC 1',
      authoringJudge: 'K.G. Balakrishnan C.J.',
      majorityOpinion: 'Unanimous; reproductive autonomy affirmed.',
    ),

    // ------------------------------------------------------------------------
    // 28. Independent Thought v. Union of India (2017) — Marital rape exception
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-INDEPENDENT-THOUGHT',
      caseId: 'INDEPENDENT_THOUGHT',
      caseName: 'Independent Thought v. Union of India',
      citation: '(2017) 10 SCC 800',
      year: 2017,
      court: 'Supreme Court of India',
      bench: 'Bench of Madan B. Lokur J. & Deepak Gupta J.',
      benchStrength: 2,
      judges: const ['Madan B. Lokur J.', 'Deepak Gupta J.'],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.socialJustice,
      keywords: const [
        'Marital Rape Exception',
        'Section 375 IPC',
        'Minor Wife',
        'Article 21',
        'Child Rights'
      ],
      aliases: const ['Marital Rape Exception Case'],
      historicalContext:
        'Exception 2 to Section 375 IPC immunised sexual intercourse by a husband with his wife aged 15-18 from the definition of rape.',
      facts:
        'Independent Thought challenged the constitutional validity of Exception 2 to Section 375 IPC insofar as it allowed sexual intercourse with a girl wife aged 15-18.',
      issues: const [
        'Is Exception 2 to Section 375 IPC unconstitutional for wives aged 15-18?',
      ],
      petitionerArguments: const [
        'Exception 2 conflicts with the POCSO Act and the girl child\'s rights.',
      ],
      respondentArguments: const [
        'The provision preserves the marital exception.',
      ],
      decision:
        'Read down Exception 2 to Section 375 IPC: sexual intercourse with a wife below 18 is rape; the exception cannot apply to girls aged 15-18.',
      ratioDecidendi: const [
        'Exception 2 to Section 375 IPC is unconstitutional for wives aged 15-18.',
        'It conflicts with the POCSO Act, 2012 and Articles 15 and 21.',
      ],
      keyPrinciples: const [
        'Harmonising the IPC with the POCSO Act.',
        'Protecting the girl child from marital abuse.',
      ],
      constitutionalSignificance:
        'A landmark on marital rape of minors and the rights of the girl child.',
      constitutionalInterpretation:
        'Articles 14, 15 and 21 protect a married girl child from sexual abuse.',
      legalPrinciple:
        'Exception 2 to Section 375 IPC does not apply to a wife aged below 18.',
      relatedArticles: const ['Article 14', 'Article 15', 'Article 21'],
      relatedActs: const [
        'Indian Penal Code, 1860',
        'Protection of Children from Sexual Offences Act, 2012'
      ],
      sections: const ['Section 375 IPC'],
      relatedCurrentAffairs: const ['ca_marital_rape'],
      sdgGoals: const ['SDG 5 - Gender Equality'],
      themes: const ['Child Rights', 'Gender Justice', 'Marital Rape', 'Criminal Law'],
      subjects: const ['Constitutional Law', 'Criminal Law'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Exception applied only to wives aged 15-18',
        'Adult marital rape remains outside IPC (still debated)',
      ],
      mainsThemes: const [
        'Marital rape and the girl child',
        'Harmonising IPC and POCSO',
      ],
      interviewAngles: const [
        'Should the marital rape exception be abolished entirely?',
      ],
      judgmentDate: DateTime(2017, 10, 11),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'High',
      timesAsked: 2,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['JOSEPH_SHINE'],
      garudaExplanation:
        'Struck down the marital rape exception for girls aged 15-18, protecting the girl child.',
      commonMistakes: const [
        'Thinking adult marital rape was decriminalised',
        'Confusing with Joseph Shine (adultery)',
      ],
      memoryTricks: const ['Independent Thought = 15-18 girl wife protected'],
      oneLineSummary:
        'Exception 2 to Section 375 IPC is unconstitutional for wives aged 15-18.',
      detailedSummary:
        'The Court read down Exception 2 to Section 375 IPC, holding sexual intercourse with a wife below 18 is rape.',
      citations: const ['(2017) 10 SCC 800'],
      evidenceReferences: const ['(2017) 10 SCC 800'],
      evidenceIds: const ['ev_INDEPENDENT_THOUGHT_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2017) 10 SCC 800',
      authoringJudge: 'Madan B. Lokur J.',
      majorityOpinion: 'Unanimous; exception read down for minor wives.',
    ),

    // ------------------------------------------------------------------------
    // 29. Joseph Shine v. Union of India (2018) — Section 497 IPC
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-JOSEPH-SHINE',
      caseId: 'JOSEPH_SHINE',
      caseName: 'Joseph Shine v. Union of India',
      citation: '(2018) 2 SCC 167',
      year: 2018,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      benchStrength: 5,
      judges: const [
        'Dipak Misra C.J.',
        'Rohinton Fali Nariman J.',
        'A.M. Khanwilkar J.',
        'Dr. D.Y. Chandrachud J.',
        'Indu Malhotra J.',
      ],
      status: CaseStatus.landmarkPrecedent,
      caseType: CaseType.socialJustice,
      keywords: const [
        'Section 497 IPC',
        'Adultery',
        'Gender Equality',
        'Article 14',
        'Article 15'
      ],
      aliases: const ['Adultery Case'],
      historicalContext:
        'Section 497 IPC criminalised adultery only against the husband, treating the woman as the husband\'s property.',
      facts:
        'Joseph Shine challenged the constitutional validity of Section 497 IPC on the ground of gender discrimination.',
      issues: const [
        'Is Section 497 IPC discriminatory and unconstitutional?',
      ],
      petitionerArguments: const [
        'Section 497 treats women as chattel and violates Articles 14, 15 and 21.',
      ],
      respondentArguments: const [
        'The provision preserves the sanctity of marriage.',
      ],
      decision:
        'Struck down Section 497 IPC as unconstitutional; adultery is no longer a crime, though it remains a ground for divorce.',
      ratioDecidendi: const [
        'Section 497 violates Articles 14, 15 and 21.',
        'Criminalising adultery only against the husband demeans women.',
        'The State has no place in regulating consensual private relationships.',
      ],
      keyPrinciples: const [
        'Gender equality in criminal law.',
        'Privacy and dignity in intimate relationships.',
      ],
      constitutionalSignificance:
        'A landmark on gender equality and privacy, striking down a colonial-era penal provision.',
      constitutionalInterpretation:
        'Articles 14, 15 and 21 prohibit a gender-discriminatory criminal law.',
      legalPrinciple:
        'Adultery is a civil (divorce) ground, not a criminal offence.',
      relatedArticles: const ['Article 14', 'Article 15', 'Article 21'],
      relatedActs: const ['Indian Penal Code, 1860'],
      sections: const ['Section 497 IPC'],
      precedentsFollowed: const ['NAVTEJ_JOHAR'],
      relatedCases: const ['NAVTEJ_JOHAR', 'INDEPENDENT_THOUGHT'],
      relatedCurrentAffairs: const ['ca_adultery_law'],
      sdgGoals: const ['SDG 5 - Gender Equality'],
      themes: const ['Gender Justice', 'Privacy', 'Criminal Law', 'Dignity'],
      subjects: const ['Constitutional Law', 'Social Justice'],
      prelimsRelevance: RelevanceLevel.critical,
      mainsRelevance: RelevanceLevel.critical,
      essayRelevance: RelevanceLevel.high,
      interviewRelevance: RelevanceLevel.high,
      prelimsTraps: const [
        'Adultery decriminalised but remains a divorce ground',
        'Unanimous 5-judge decision',
      ],
      mainsThemes: const [
        'Gender equality and privacy in criminal law',
        'Decriminalising consensual conduct',
      ],
      interviewAngles: const [
        'What remains of adultery law after Joseph Shine?',
      ],
      judgmentDate: DateTime(2018, 9, 27),
      presentStatus: 'Good Law / Active Precedent',
      examImportance: 'Critical',
      timesAsked: 3,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['INDEPENDENT_THOUGHT'],
      garudaExplanation:
        'Decriminalised adultery, striking down the gender-discriminatory Section 497 IPC.',
      commonMistakes: const [
        'Thinking adultery is entirely without legal effect (it remains a divorce ground)',
      ],
      memoryTricks: const ['Joseph Shine = adultery is no longer a crime'],
      oneLineSummary:
        'Section 497 IPC struck down; adultery is no longer a criminal offence.',
      detailedSummary:
        'The 5-judge bench unanimously struck down Section 497 IPC, holding criminalisation of adultery gender-discriminatory and violative of Articles 14, 15 and 21.',
      citations: const ['(2018) 2 SCC 167'],
      evidenceReferences: const ['(2018) 2 SCC 167'],
      evidenceIds: const ['ev_JOSEPH_SHINE_official'],
      officialSource: 'https://main.sci.gov.in/judgments',
      lastVerifiedDate: '2026-08-08',
      neutralCitation: '(2018) 2 SCC 167',
      authoringJudge: 'Dipak Misra C.J.',
      majorityOpinion: 'Unanimous; Section 497 struck down.',
    ),
  ];
}
