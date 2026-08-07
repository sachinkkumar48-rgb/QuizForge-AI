library;

import '../domain/entities/case_enums.dart';
import '../domain/entities/case_knowledge_object.dart';

/// Seeded Data for Phase I Landmark Constitutional Cases (20 Cases).
/// Every judgment is a permanent Knowledge Object formatted for GARUDA engine.
class LandmarkCasesPhase1 {
  static final List<CaseKnowledgeObject> cases = [
    // ------------------------------------------------------------------------
    // 1. Kesavananda Bharati v. State of Kerala (1973)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-KESAVANANDA',
      caseId: 'KESAVANANDA',
      caseName: 'Kesavananda Bharati v. State of Kerala',
      citation: 'AIR 1973 SC 1461',
      year: 1973,
      court: 'Supreme Court of India',
      bench: '13-Judge Constitution Bench',
      judges: const [
        'S.M. Sikri C.J.',
        'J.M. Shelat J.',
        'K.S. Hegde J.',
        'A.N. Grover J.',
        'A.N. Ray J.',
        'P.J. Reddy J.',
        'D.G. Palekar J.',
        'H.R. Khanna J.',
        'A.K. Mukherjee J.',
        'Y.V. Chandrachud J.',
        'K.K. Mathew J.',
        'M.H. Beg J.',
        'S.N. Dwivedi J.'
      ],
      status: CaseStatus.landmarkPrecedent,
      keywords: const [
        'Kesavananda Bharati',
        'Basic Structure Doctrine',
        'Article 368',
        '24th Amendment',
        '25th Amendment',
        '29th Amendment',
        'Fundamental Rights vs DPSP',
        'Judicial Review'
      ],
      aliases: const ['Fundamental Rights Case', 'Basic Structure Case'],
      historicalContext:
          'Challenged the 24th, 25th, and 29th Constitutional Amendment Acts enacted by Parliament to override earlier decisions in Golaknath, R.C. Cooper, and Madhavrao Scindia cases.',
      facts:
          'Swami Kesavananda Bharati, head of Edneer Mutt in Kerala, challenged Kerala Land Reforms Amendment Acts under Art 26. During proceedings, Parliament passed 24th, 25th, and 29th Amendments limiting judicial review and placing Kerala land reform laws in Ninth Schedule.',
      issues: const [
        'Whether Parliament’s amending power under Article 368 is unlimited.',
        'Whether Parliament can alter or destroy the Basic Structure of the Constitution.',
        'Validity of 24th, 25th, and 29th Constitutional Amendment Acts.'
      ],
      petitionerArguments: const [
        'Article 368 confers power to amend, not to abrogate or rewrite the Constitution.',
        'Fundamental Rights are essential human rights beyond legislative destruction.',
        'Judicial review cannot be completely barred under Article 31C.'
      ],
      respondentArguments: const [
        'Parliament’s amending power is sovereign and unlimited under Article 368.',
        'No distinction exists between constituent power and ordinary legislative power.',
        'Socio-economic objectives under DPSP outweigh individual fundamental rights.'
      ],
      decision:
          '7:6 Majority held Parliament can amend any part of Constitution including Fundamental Rights under Art 368, provided it does NOT alter or destroy the "Basic Structure" of the Constitution.',
      ratioDecidendi: const [
        'Parliament has wide constituent power under Art 368 to amend any provision including Part III.',
        'Amending power does NOT extend to damaging or destroying the Basic Structure or essential features of the Constitution.',
        'The second clause of Article 31C (barring judicial review) was declared unconstitutional and void.'
      ],
      obiterDicta: const [
        'Basic Structure includes supremacy of Constitution, republican and democratic form of government, secularism, separation of powers, and federal character.'
      ],
      keyPrinciples: const [
        'Basic Structure Doctrine',
        'Harmonious Construction between Part III (FRs) and Part IV (DPSPs)',
        'Judicial Review as an immutable pillar of Constitutionalism'
      ],
      constitutionalSignificance:
          'Established the Basic Structure Doctrine, creating an unalterable core of the Indian Constitution and preserving judicial review against legislative overreach.',
      relatedArticles: const ['13', '14', '19', '31', '31A', '31B', '31C', '32', '368'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV', 'KO-PART-XX'],
      relatedSchedules: const ['KO-SCHED-9'],
      relatedAmendments: const ['24th Amendment', '25th Amendment', '29th Amendment', '42nd Amendment'],
      pyqIds: const ['PYQ_UPSC_2020_01', 'PYQ_UPSC_2019_04', 'PYQ_UPSC_2017_09'],
      judgmentDate: DateTime(1973, 4, 24),
      filingDate: DateTime(1970, 3, 21),
      timeline: const [
        '1970-03-21: Petition filed by Kesavananda Bharati',
        '1972-10-31: 13-Judge Bench constituted',
        '1973-04-24: Landmark 7:6 Judgment delivered'
      ],
      subsequentDevelopments: const [
        'Reaffirmed and applied in Indira Gandhi v. Raj Narain (1975), Minerva Mills (1980), and I.R. Coelho (2007).'
      ],
      presentStatus: 'Good Law / Supreme Landmark Precedent',
      examImportance: 'Critical',
      timesAsked: 48,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['Golaknath Case (1967)', 'Minerva Mills Case (1980)'],
      garudaExplanation:
          'Kesavananda Bharati (1973) is the most critical judgment in Indian Constitutional Law. A 13-judge bench (largest ever) overruled Golaknath by ruling that Parliament CAN amend Fundamental Rights, BUT formulated the Basic Structure Doctrine holding that Parliament cannot alter the basic framework or identity of the Constitution.',
      commonMistakes: const [
        'Mistake: Believing Kesavananda held Fundamental Rights CANNOT be amended. Reality: It held FRs CAN be amended, as long as the Basic Structure is not destroyed.',
        'Mistake: Thinking Basic Structure is defined exhaustively in Article 368. Reality: It is a judicially evolved doctrine not defined in the text.'
      ],
      memoryTricks: const [
        'Mnemonic - 13-7-6-BASIC: 13 judges, 7 to 6 decision, basic structure born on April 24, 1973.'
      ],
      oneLineSummary:
          'Parliament can amend any part of the Constitution under Art 368 but cannot alter its Basic Structure.',
      detailedSummary:
          'In Kesavananda Bharati (1973), a 13-judge Supreme Court bench evaluated the validity of the 24th, 25th, and 29th Amendments. By a 7-6 majority, Chief Justice Sikri and 6 judges held that while Parliament possesses broad amending power under Article 368, it does not possess the power to abrogate or alter the fundamental pillars (Basic Structure) of the Constitution.',
      primarySource: 'AIR 1973 SC 1461; (1973) 4 SCC 225',
      citations: const ['AIR 1973 SC 1461', '(1973) 4 SCC 225'],
      evidenceReferences: const [
        'Official Supreme Court Report 1973',
        'Constitutional Law of India by H.M. Seervai'
      ],
    ),

    // ------------------------------------------------------------------------
    // 2. I.C. Golaknath v. State of Punjab (1967)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-GOLAKNATH',
      caseId: 'GOLAKNATH',
      caseName: 'I.C. Golaknath v. State of Punjab',
      citation: 'AIR 1967 SC 1643',
      year: 1967,
      court: 'Supreme Court of India',
      bench: '11-Judge Constitution Bench',
      judges: const [
        'K. Subba Rao C.J.',
        'K.N. Wanchoo J.',
        'M. Hidayatullah J.',
        'J.C. Shah J.',
        'S.M. Sikri J.',
        'R.S. Bachawat J.',
        'V. Ramaswami J.',
        'J.M. Shelat J.',
        'V. Bhargava J.',
        'G.K. Mitter J.',
        'C.A. Vaidialingam J.'
      ],
      status: CaseStatus.overruled,
      keywords: const [
        'Golaknath',
        'Fundamental Rights unamendable',
        'Article 13(2)',
        'Article 368 procedure only',
        'Doctrine of Prospective Overruling'
      ],
      aliases: const ['Golaknath Case'],
      historicalContext:
          'Challenged 1st, 4th, and 17th Constitutional Amendments which placed state land reform acts into Ninth Schedule, restricting land ownership of Golaknath family in Punjab.',
      facts:
          'Henry and William Golaknath owned 500 acres of land in Jalandhar. Under Punjab Security of Land Tenures Act 1953, state held they could keep only 30 acres each. Family challenged this as violation of Art 14 and 19(1)(f).',
      issues: const [
        'Whether an Amendment under Article 368 is a "law" within the meaning of Article 13(2).',
        'Whether Parliament has power to amend Fundamental Rights in Part III.'
      ],
      petitionerArguments: const [
        'Constitutional amendments are laws under Article 13(2) and cannot take away or abridge Part III Fundamental Rights.'
      ],
      respondentArguments: const [
        'Constituent power under Article 368 is distinct from ordinary legislative power under Article 13.'
      ],
      decision:
          '6:5 Majority held Fundamental Rights are transcendental and inviolable; Parliament has NO power to amend Part III. Applied Prospective Overruling.',
      ratioDecidendi: const [
        'An Amendment under Art 368 is "law" under Art 13(2).',
        'Article 368 merely provides procedure for amendment, not power to amend.',
        'Parliament cannot take away or abridge Fundamental Rights.'
      ],
      obiterDicta: const [
        'To amend Fundamental Rights, a new Constituent Assembly would have to be convened.'
      ],
      keyPrinciples: const [
        'Transcendental status of Fundamental Rights',
        'Doctrine of Prospective Overruling'
      ],
      constitutionalSignificance:
          'Led directly to Parliament passing the 24th Amendment Act 1971, setting up the historic showdown in Kesavananda Bharati.',
      relatedArticles: const ['13', '14', '19', '31', '368'],
      relatedParts: const ['KO-PART-III', 'KO-PART-XX'],
      relatedAmendments: const ['1st Amendment', '4th Amendment', '17th Amendment', '24th Amendment'],
      pyqIds: const ['PYQ_UPSC_2018_02', 'PYQ_CDS_2021_05'],
      judgmentDate: DateTime(1967, 2, 27),
      timeline: const [
        '1965: Petition filed by Golaknath estate',
        '1967-02-27: 6:5 Judgment holding FRs unamendable (Overruled in 1973 by Kesavananda)'
      ],
      subsequentDevelopments: const [
        'Overruled by 13-Judge Bench in Kesavananda Bharati v. State of Kerala (1973).'
      ],
      presentStatus: 'Overruled by Kesavananda Bharati (1973)',
      examImportance: 'High',
      timesAsked: 28,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      frequentlyConfusedCases: const ['Shankari Prasad (1951)', 'Kesavananda Bharati (1973)'],
      garudaExplanation:
          'Golaknath (1967) ruled by 6:5 majority under CJI Subba Rao that Fundamental Rights are "transcendental and immutable", and constitutional amendments under Art 368 are subject to Art 13(2) prohibition. Overruled later in Kesavananda Bharati.',
      commonMistakes: const [
        'Mistake: Believing Golaknath is current law. Reality: It was overruled by Kesavananda Bharati in 1973.'
      ],
      memoryTricks: const ['Golaknath = Gate locked for amending Fundamental Rights (until 1973).'],
      oneLineSummary: 'Held Fundamental Rights are transcendental and cannot be abridged by Constitutional Amendments.',
      detailedSummary:
          'In Golaknath (1967), an 11-judge bench ruled that Parliament could not amend Part III. The court invoked the Doctrine of Prospective Overruling so that earlier amendments (1st, 4th, 17th) remained intact, but future amendments taking away FRs were prohibited.',
      primarySource: 'AIR 1967 SC 1643; (1967) 2 SCR 762',
      citations: const ['AIR 1967 SC 1643'],
      evidenceReferences: const ['SCR 1967 Vol 2'],
    ),

    // ------------------------------------------------------------------------
    // 3. Shankari Prasad Singh Deo v. Union of India (1951)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SHANKARI-PRASAD',
      caseId: 'SHANKARI_PRASAD',
      caseName: 'Shankari Prasad Singh Deo v. Union of India',
      citation: 'AIR 1951 SC 458',
      year: 1951,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['H.J. Kania C.J.', 'Paitanjali Sastri J.', 'B.K. Mukherjea J.', 'S.R. Das J.', 'N. Chandrasekhara Aiyar J.'],
      status: CaseStatus.overruled,
      keywords: const ['Shankari Prasad', '1st Amendment', 'Ninth Schedule', 'Constituent Power vs Legislative Power', 'Article 13 vs 368'],
      aliases: const ['Shankari Prasad Case'],
      historicalContext:
          'First major constitutional challenge to land reform laws and the First Constitutional Amendment Act, 1951.',
      facts:
          'Zamindars challenged 1st Amendment Act 1951 which inserted Art 31A, 31B and Ninth Schedule to protect land reform laws from judicial review.',
      issues: const ['Whether 1st Constitutional Amendment Act 1951 violates Article 13(2).'],
      decision:
          'Unanimous 5-judge decision upholding 1st Amendment. Held "law" in Art 13(2) includes only ordinary legislative law, NOT constituent constitutional amendments under Art 368.',
      ratioDecidendi: const ['Constituent power under Art 368 is supreme and distinct from ordinary legislative power under Art 13(2).'],
      constitutionalSignificance:
          'Established initial precedent that Parliament can amend any part of the Constitution including Fundamental Rights.',
      relatedArticles: const ['13', '19', '31', '31A', '31B', '368'],
      relatedParts: const ['KO-PART-III', 'KO-PART-XX'],
      relatedSchedules: const ['KO-SCHED-9'],
      relatedAmendments: const ['1st Amendment'],
      pyqIds: const ['PYQ_UPSC_2016_03'],
      judgmentDate: DateTime(1951, 10, 5),
      presentStatus: 'Overruled by Golaknath (1967) / Kesavananda (1973)',
      examImportance: 'Medium',
      timesAsked: 18,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      garudaExplanation:
          'Shankari Prasad (1951) was the first case testing Parliament’s power to amend Fundamental Rights. The SC unanimously ruled that Art 368 constituent power is separate from Art 13(2) ordinary laws.',
      commonMistakes: const ['Mistake: Thinking Shankari Prasad restricted Parliament. Reality: It gave Parliament absolute power to amend FRs.'],
      memoryTricks: const ['Shankari = Starts the amendment jurisprudence journey in 1951.'],
      oneLineSummary: 'Upholds Parliament’s power to amend Fundamental Rights under Article 368.',
      detailedSummary:
          'The 5-judge Supreme Court bench led by CJI Kania upheld the First Amendment Act 1951, validating Article 31A, 31B, and Ninth Schedule.',
      citations: const ['AIR 1951 SC 458'],
    ),

    // ------------------------------------------------------------------------
    // 4. Sajjan Singh v. State of Rajasthan (1965)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SAJJAN-SINGH',
      caseId: 'SAJJAN_SINGH',
      caseName: 'Sajjan Singh v. State of Rajasthan',
      citation: 'AIR 1965 SC 845',
      year: 1965,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['P.B. Gajendragadkar C.J.', 'K.N. Wanchoo J.', 'M. Hidayatullah J.', 'J.C. Shah J.', 'J.R. Mudholkar J.'],
      status: CaseStatus.overruled,
      keywords: const ['Sajjan Singh', '17th Amendment', 'Ninth Schedule', 'Mudholkar doubt on Basic Features'],
      aliases: const ['Sajjan Singh Case'],
      historicalContext: 'Challenged validity of 17th Amendment Act 1964 which added 44 land reform statutes to Ninth Schedule.',
      facts: 'Rajasthan landholders challenged 17th Amendment following Shankari Prasad precedent.',
      issues: ['Whether 17th Amendment Act required ratification by state legislatures under Art 368 proviso.'],
      decision: '3:2 Majority upheld 17th Amendment following Shankari Prasad, but Justice Mudholkar & Justice Hidayatullah expressed doubts regarding unamendable basic features.',
      ratioDecidendi: const ['Reaffirmed Shankari Prasad: Art 368 includes power to amend Part III.'],
      obiterDicta: const ['Justice J.R. Mudholkar referenced "basic features" of Constitution, planting seeds for Basic Structure doctrine.'],
      constitutionalSignificance: 'First judicial mention of "basic features" by Justice Mudholkar.',
      relatedArticles: const ['13', '31A', '31B', '368'],
      relatedAmendments: const ['17th Amendment'],
      pyqIds: const ['PYQ_UPSC_2017_04'],
      judgmentDate: DateTime(1965, 1, 30),
      presentStatus: 'Overruled',
      examImportance: 'Medium',
      timesAsked: 14,
      lastAskedYear: 2021,
      trend: 'Medium Frequency',
      garudaExplanation:
          'Sajjan Singh (1965) upheld 17th Amendment, but Justice Mudholkar’s dissent introduced the concept of "basic features" later developed in Kesavananda.',
      commonMistakes: const ['Mistake: Crediting Kesavananda alone for coining basic feature term. Reality: Mudholkar J. hinted at it in Sajjan Singh (1965).'],
      memoryTricks: const ['Sajjan Singh = Seed of Basic Features planted by Justice Mudholkar.'],
      oneLineSummary: 'Reaffirmed Shankari Prasad while Justice Mudholkar seeded the concept of basic features.',
      detailedSummary: '5-judge bench upheld 17th Amendment, but dissenting notes sowed intellectual groundwork for Basic Structure doctrine.',
      citations: const ['AIR 1965 SC 845'],
    ),

    // ------------------------------------------------------------------------
    // 5. Berubari Union, In re (1960)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-BERUBARI-UNION',
      caseId: 'BERUBARI_UNION',
      caseName: 'Re: Berubari Union and Exchange of Enclaves',
      citation: 'AIR 1960 SC 845',
      year: 1960,
      court: 'Supreme Court of India',
      bench: '9-Judge Constitution Bench',
      judges: const ['B.P. Sinha C.J.', 'K. Subba Rao J.', 'P.B. Gajendragadkar J.', 'S.K. Das J.', 'J.C. Shah J.'],
      status: CaseStatus.partiallyOverruled,
      keywords: const ['Berubari Union', 'Indo-Pakistan Agreement 1958', 'Article 3', 'Article 368', 'Preamble not part of Constitution', 'Cession of Territory'],
      aliases: const ['Berubari Case', 'Presidential Reference on Berubari'],
      historicalContext: 'Presidential Reference under Article 143 regarding transfer of Berubari Union No. 12 to Pakistan under Nehru-Noon Agreement 1958.',
      facts: 'Nehru-Noon Agreement (1958) agreed to divide Berubari Union between India and East Pakistan. Question arose whether GoI could cede territory under Art 3 legislative power or required Art 368 amendment.',
      issues: ['Can Indian territory be ceded to a foreign country under Article 3?', 'Is Preamble a part of the Constitution?'],
      decision: 'Territory CANNOT be ceded under Article 3. Cession requires Article 368 Constitutional Amendment. Preamble is key to mind of makers, but NOT part of Constitution.',
      ratioDecidendi: const [
        'Article 3 deals with internal reorganisation of States, not ceding territory to foreign nations.',
        'Cession of territory requires Constitutional Amendment under Article 368.',
        'Preamble is NOT an integral part of the Constitution.'
      ],
      constitutionalSignificance: 'Led to 9th Constitutional Amendment Act 1960. Preamble holding was overruled in Kesavananda (1973).',
      relatedArticles: const ['1', '3', '143', '368'],
      relatedParts: const ['KO-PART-I'],
      relatedAmendments: const ['9th Amendment', '100th Amendment'],
      pyqIds: const ['PYQ_UPSC_2020_08', 'PYQ_CAPF_2019_02'],
      judgmentDate: DateTime(1960, 3, 14),
      presentStatus: 'Preamble ruling overruled by Kesavananda (1973); Cession ruling remains Good Law',
      examImportance: 'High',
      timesAsked: 26,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'Berubari Union (1960) ruled that Art 3 does NOT allow ceding Indian territory to foreign nations (requires Art 368 amendment). It famously held Preamble is NOT part of Constitution (overruled in 1973).',
      commonMistakes: const ['Mistake: Thinking Berubari is good law for Preamble status. Reality: Kesavananda reversed it, holding Preamble IS part of Constitution.'],
      memoryTricks: const ['Berubari = Border territory cession needs Art 368 amendment.'],
      oneLineSummary: 'Cession of territory requires Art 368 amendment; Preamble held not part of Constitution (later overruled).',
      detailedSummary: '9-judge bench under CJI B.P. Sinha answered Presidential Reference, holding foreign territory cession requires constitutional amendment.',
      citations: const ['AIR 1960 SC 845'],
    ),

    // ------------------------------------------------------------------------
    // 6. Minerva Mills Ltd. v. Union of India (1980)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-MINERVA-MILLS',
      caseId: 'MINERVA_MILLS',
      caseName: 'Minerva Mills Ltd. v. Union of India',
      citation: 'AIR 1980 SC 1789',
      year: 1980,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['Y.V. Chandrachud C.J.', 'P.N. Bhagwati J.', 'A.C. Gupta J.', 'N.L. Untwalia J.', 'P.S. Kailasam J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Minerva Mills', '42nd Amendment', 'Section 55 Art 368(4)(5)', 'Section 4 Art 31C', 'Harmonious Balance FR DPSP', 'Limited Amending Power'],
      aliases: const ['Minerva Mills Case'],
      historicalContext: 'Challenged Sections 4 and 55 of 42nd Amendment Act 1976 passed during Emergency to make amending power unlimited and give all DPSPs primacy over FRs.',
      facts: 'Minerva Mills, a textile mill in Karnataka, was nationalised under Sick Textile Undertakings Act 1974. Owners challenged 42nd Amendment provisions.',
      issues: ['Validity of Section 55 (inserting Art 368(4)&(5) removing all limits on amending power) and Section 4 (amending Art 31C) of 42nd Amendment.'],
      decision: 'Unanimously struck down Section 55 & Section 4 of 42nd Amendment. Held limited amending power is itself a Basic Feature.',
      ratioDecidendi: const [
        'A limited amending power is itself a basic feature of the Constitution; Parliament cannot expand limited power into absolute power.',
        'Judicial review is a basic feature of the Constitution.',
        'Harmony and balance between Fundamental Rights (Part III) and DPSPs (Part IV) is a basic feature.'
      ],
      constitutionalSignificance: 'Saved Basic Structure Doctrine from 42nd Amendment legislative nullification.',
      relatedArticles: const ['14', '19', '31C', '32', '368'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV', 'KO-PART-XX'],
      relatedAmendments: const ['42nd Amendment'],
      pyqIds: const ['PYQ_UPSC_2020_02', 'PYQ_UPSC_2017_06'],
      judgmentDate: DateTime(1980, 7, 31),
      presentStatus: 'Good Law / Landmark Precedent',
      examImportance: 'Critical',
      timesAsked: 34,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      garudaExplanation:
          'Minerva Mills (1980) struck down 42nd Amendment clauses that tried to give Parliament unlimited amending power and override all FRs for DPSPs. Established that balance between FRs and DPSPs is a Basic Structure.',
      commonMistakes: const ['Mistake: Thinking 42nd Amendment completely destroyed Basic Structure. Reality: Minerva Mills struck down those clauses in 1980.'],
      memoryTricks: const ['Minerva = Twin pillars of FR and DPSP balanced in harmony.'],
      oneLineSummary: 'Struck down 42nd Amendment clauses attempting unlimited amending power and total DPSP supremacy.',
      detailedSummary: '5-judge bench led by CJI Y.V. Chandrachud invalidated Sections 4 and 55 of 42nd Amendment Act 1976, restoring judicial review.',
      citations: const ['AIR 1980 SC 1789', '(1980) 3 SCC 625'],
    ),

    // ------------------------------------------------------------------------
    // 7. Maneka Gandhi v. Union of India (1978)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-MANEKA-GANDHI',
      caseId: 'MANEKA_GANDHI',
      caseName: 'Maneka Gandhi v. Union of India',
      citation: 'AIR 1978 SC 597',
      year: 1978,
      court: 'Supreme Court of India',
      bench: '7-Judge Constitution Bench',
      judges: const ['M.H. Beg C.J.', 'Y.V. Chandrachud J.', 'P.N. Bhagwati J.', 'V.R. Krishna Iyer J.', 'N.L. Untwalia J.', 'P.S. Kailasam J.', 'S. Murtaza Fazal Ali J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Maneka Gandhi', 'Article 21', 'Procedure established by law', 'Due Process of law', 'Golden Triangle 14 19 21', 'Passport impounding', 'Natural Justice'],
      aliases: const ['Maneka Gandhi Case', 'Passport Case'],
      historicalContext: 'Post-Emergency expansion of personal liberty and procedural fairness under Article 21.',
      facts: 'Janata Party government impounded Maneka Gandhi’s passport under Passports Act 1967 "in public interest" without giving reasons or hearing.',
      issues: ['Whether impounding passport without hearing violates Art 19(1)(a), 19(1)(g), and 21.', 'Meaning of "procedure established by law" under Art 21.'],
      decision: 'Held procedure under Art 21 must be "just, fair, and reasonable", not arbitrary, fanciful, or oppressive. Read American "Due Process" into Art 21.',
      ratioDecidendi: const [
        'Procedure established by law under Art 21 must conform to Principles of Natural Justice (Audi Alteram Partem).',
        'Articles 14, 19, and 21 are not mutually exclusive but form an interconnected "Golden Triangle".',
        'Right to travel abroad is part of personal liberty under Art 21.'
      ],
      constitutionalSignificance: 'Transformed Article 21 from passive protection against executive illegal action to active guarantee of substantive human dignity.',
      relatedArticles: const ['14', '19', '21', '32'],
      relatedParts: const ['KO-PART-III'],
      relatedActs: const ['Passports Act 1967'],
      pyqIds: const ['PYQ_UPSC_2021_01', 'PYQ_UPSC_2018_07', 'PYQ_NDA_2020_03'],
      judgmentDate: DateTime(1978, 1, 25),
      presentStatus: 'Good Law / Pillar Precedent',
      examImportance: 'Critical',
      timesAsked: 42,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      garudaExplanation:
          'Maneka Gandhi (1978) fundamentally transformed Article 21. It overruled A.K. Gopalan (1950), reading Natural Justice and "due process" into "procedure established by law" and creating the Golden Triangle of Articles 14, 19, and 21.',
      commonMistakes: const ['Mistake: Assuming "procedure established by law" means any enacted procedure is valid. Reality: Maneka Gandhi requires procedure to be just, fair, and reasonable.'],
      memoryTricks: const ['Maneka = Golden Triangle (14 + 19 + 21) + Just, Fair & Reasonable.'],
      oneLineSummary: 'Expanded Article 21 to mandate that procedure depriving liberty must be just, fair, and reasonable.',
      detailedSummary: '7-judge bench led by CJI Beg and Justice Bhagwati overruled Gopalan, establishing substantive due process and natural justice under Article 21.',
      citations: const ['AIR 1978 SC 597', '(1978) 1 SCC 248'],
    ),

    // ------------------------------------------------------------------------
    // 8. ADM Jabalpur v. Shivkant Shukla (1976)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-ADM-JABALPUR',
      caseId: 'ADM_JABALPUR',
      caseName: 'ADM Jabalpur v. Shivkant Shukla',
      citation: 'AIR 1976 SC 1207',
      year: 1976,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['A.N. Ray C.J.', 'H.R. Khanna J.', 'M.H. Beg J.', 'Y.V. Chandrachud J.', 'P.N. Bhagwati J.'],
      status: CaseStatus.overruled,
      keywords: const ['ADM Jabalpur', 'Habeas Corpus Case', 'Emergency Art 359', 'Article 21 suspension', 'Justice H.R. Khanna Dissent'],
      aliases: const ['Habeas Corpus Case'],
      historicalContext: 'Decided during National Emergency declared in June 1975 under Article 352.',
      facts: 'Political dissidents detained under MISA filed habeas corpus petitions. President issued order under Art 359 suspending right to move court for enforcement of Art 14, 21, 22.',
      issues: ['Can habeas corpus writ petition under Art 226 be maintained during Emergency when Art 21 enforcement is suspended?'],
      decision: '4:1 Majority held no person has locus standi to move court for habeas corpus during Emergency if Art 21 is suspended. Justice H.R. Khanna famously dissented.',
      ratioDecidendi: const ['Suspension of Art 21 enforcement under Art 359 bars all judicial remedies against illegal detention during Emergency.'],
      obiterDicta: const ['Justice H.R. Khanna: "Life and personal liberty are not creations of the Constitution; law of nature precedes constitutional text."'],
      constitutionalSignificance: 'Darkest hour of Indian judiciary. Led to 44th Amendment Act 1978 making Art 20 and 21 non-suspendable even during Emergency.',
      relatedArticles: const ['20', '21', '226', '352', '359'],
      relatedParts: const ['KO-PART-III', 'KO-PART-XVIII'],
      relatedAmendments: const ['44th Amendment'],
      pyqIds: const ['PYQ_UPSC_2019_06'],
      judgmentDate: DateTime(1976, 4, 28),
      presentStatus: 'Overruled explicitly in K.S. Puttaswamy (2017)',
      examImportance: 'High',
      timesAsked: 22,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'ADM Jabalpur (1976) held that during Emergency, citizens could not approach court even if detained illegally. Justice H.R. Khanna’s sole dissent cost him CJI post. Formally overruled in Puttaswamy (2017).',
      commonMistakes: const ['Mistake: Thinking ADM Jabalpur is active precedent. Reality: Formally buried by 9-judge bench in Puttaswamy (2017).'],
      memoryTricks: const ['ADM Jabalpur = Dark Emergency case; Khanna’s courageous dissent.'],
      oneLineSummary: 'Held Art 21 enforcement suspended during Emergency; overruled in Puttaswamy (2017).',
      detailedSummary: '5-judge bench 4:1 decision barred habeas corpus during Emergency. Justice Khanna dissented, upholding natural right to life.',
      citations: const ['AIR 1976 SC 1207'],
    ),

    // ------------------------------------------------------------------------
    // 9. S.R. Bommai v. Union of India (1994)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SR-BOMMAI',
      caseId: 'SR_BOMMAI',
      caseName: 'S.R. Bommai v. Union of India',
      citation: 'AIR 1994 SC 1918',
      year: 1994,
      court: 'Supreme Court of India',
      bench: '9-Judge Constitution Bench',
      judges: const ['S.R. Pandian J.', 'A.M. Ahmadi J.', 'K. Ramaswamy J.', 'P.B. Sawant J.', 'K. Ramaswamy J.', 'S.C. Agrawal J.', 'B.P. Jeevan Reddy J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['S.R. Bommai', 'Article 356', 'President Rule', 'Federalism Basic Structure', 'Secularism Basic Structure', 'Floor Test', 'Judicial Review of Proclamation'],
      aliases: const ['S.R. Bommai Case', 'President’s Rule Case'],
      historicalContext: 'Arbitrary dismissal of state governments under Article 356 by central government in Karnataka, Meghalaya, Nagaland, MP, Rajasthan, UP.',
      facts: 'S.R. Bommai ministry in Karnataka dismissed under Art 356 without floor test. Similar dismissals challenged across multiple states.',
      issues: ['Is Presidential Proclamation under Article 356 subject to judicial review?', 'What is the scope and limitations of Article 356 power?'],
      decision: '9-judge bench held Presidential Proclamation under Art 356 is subject to judicial review. Federalism and Secularism are part of Basic Structure.',
      ratioDecidendi: const [
        'Presidential power under Art 356 is conditional, not absolute; subject to judicial review.',
        'Floor Test in the Legislative Assembly is the ONLY legal method to test majority of ministry.',
        'Federalism and Secularism are basic features of the Constitution.'
      ],
      constitutionalSignificance: 'Drastically reduced misuse of Article 356 by central governments against opposition-ruled states.',
      relatedArticles: const ['14', '25', '356', '365'],
      relatedParts: const ['KO-PART-XVIII'],
      relatedReports: const ['Sarkaria Commission Report 1988'],
      pyqIds: const ['PYQ_UPSC_2021_04', 'PYQ_UPSC_2017_02'],
      judgmentDate: DateTime(1994, 3, 11),
      presentStatus: 'Good Law / Federalism Anchor Precedent',
      examImportance: 'Critical',
      timesAsked: 36,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      garudaExplanation:
          'S.R. Bommai (1994) stopped arbitrary misuse of Article 356 (President’s Rule). Established floor test as mandatory, made Art 356 subject to judicial review, and affirmed Federalism & Secularism as Basic Structure.',
      commonMistakes: const ['Mistake: Thinking President’s subjective satisfaction under Art 356 cannot be questioned in court. Reality: Bommai permits judicial review of material facts.'],
      memoryTricks: const ['Bommai = Floor test mandatory + Federalism & Secularism Basic Structure.'],
      oneLineSummary: 'Subjected President’s Rule under Art 356 to judicial review and mandated Assembly floor test.',
      detailedSummary: '9-judge Constitution Bench laid down strict guidelines for Article 356 invocation and affirmed core basic structure tenets.',
      citations: const ['AIR 1994 SC 1918', '(1994) 3 SCC 1'],
    ),

    // ------------------------------------------------------------------------
    // 10. Indra Sawhney v. Union of India (1992)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-INDRA-SAWHNEY',
      caseId: 'INDRA_SAWHNEY',
      caseName: 'Indra Sawhney v. Union of India',
      citation: 'AIR 1993 SC 477',
      year: 1992,
      court: 'Supreme Court of India',
      bench: '9-Judge Constitution Bench',
      judges: const ['M.H. Kania C.J.', 'M.N. Venkatachaliah J.', 'S.R. Pandian J.', 'T.K. Thommen J.', 'A.M. Ahmadi J.', 'K. Ramaswamy J.', 'P.B. Sawant J.', 'R.M. Sahai J.', 'B.P. Jeevan Reddy J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Indra Sawhney', 'Mandal Case', 'Article 16(4)', 'OBC Reservation 27%', 'Creamy Layer', '50% Ceiling Cap', 'No Reservation in Promotions'],
      aliases: const ['Mandal Case', 'Mandal Commission Case'],
      historicalContext: 'Implementation of Mandal Commission recommendations reserving 27% central government jobs for Other Backward Classes (OBCs) in 1990.',
      facts: 'V.P. Singh government issued executive orders providing 27% reservation for OBCs in civil services. Challenged by Indra Sawhney and advocates.',
      issues: ['Validity of 27% OBC reservation in public employment.', 'Whether backward class can be identified based on caste.', 'Cap on total reservation percentage.'],
      decision: '6:3 Majority upheld 27% OBC reservation subject to exclusion of "Creamy Layer", 50% overall cap, and exclusion of reservations in promotions.',
      ratioDecidendi: const [
        'Article 16(4) permits reservation for backward classes; caste can be a primary identifier of backwardness.',
        'Creamy layer among backward classes must be excluded from reservation benefits.',
        'Total reservation must not exceed 50% ceiling except under extraordinary circumstances.',
        'No reservation in promotions under Art 16(4) (later overridden in part by 77th Amendment Art 16(4A)).'
      ],
      constitutionalSignificance: 'Established definitive framework for affirmative action, OBC reservation, and creamy layer exclusion in India.',
      relatedArticles: const ['14', '15', '16', '335', '340'],
      relatedParts: const ['KO-PART-III'],
      relatedAmendments: const ['77th Amendment', '81st Amendment', '85th Amendment', '103rd Amendment'],
      relatedReports: const ['Mandal Commission Report 1980'],
      pyqIds: const ['PYQ_UPSC_2020_05', 'PYQ_UPSC_2018_09', 'PYQ_CAPF_2021_04'],
      judgmentDate: DateTime(1992, 11, 16),
      presentStatus: 'Good Law / Reservation Framework Precedent',
      examImportance: 'Critical',
      timesAsked: 40,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      garudaExplanation:
          'Indra Sawhney (1992) (Mandal Case) upheld 27% OBC reservation in public jobs, instituted the Creamy Layer exclusion, enforced 50% ceiling cap, and barred reservation in promotions.',
      commonMistakes: const ['Mistake: Believing 50% cap is in constitutional text. Reality: It is a judicial limit created in Indra Sawhney.'],
      memoryTricks: const ['Indra Sawhney = 27% OBC + Creamy Layer out + 50% Cap.'],
      oneLineSummary: 'Upheld 27% OBC reservation subject to Creamy Layer exclusion and 50% overall ceiling cap.',
      detailedSummary: '9-judge bench under CJI Kania laid down comprehensive legal framework governing reservation, equality of opportunity under Art 16.',
      citations: const ['AIR 1993 SC 477', '1992 Supp (3) SCC 217'],
    ),

    // ------------------------------------------------------------------------
    // 11. Vishaka v. State of Rajasthan (1997)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-VISHAKA',
      caseId: 'VISHAKA',
      caseName: 'Vishaka v. State of Rajasthan',
      citation: 'AIR 1997 SC 3011',
      year: 1997,
      court: 'Supreme Court of India',
      bench: '3-Judge Constitution Bench',
      judges: const ['J.S. Verma C.J.', 'Sujata V. Manohar J.', 'B.N. Kirpal J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Vishaka', 'Sexual Harassment at Workplace', 'Article 14 19 21', 'CEDAW Convention', 'Vishaka Guidelines', 'POSH Act 2013'],
      aliases: const ['Vishaka Guidelines Case'],
      historicalContext: 'Gang rape of social worker Bhanwari Devi in Rajasthan while opposing child marriage, revealing total absence of workplace sexual harassment laws.',
      facts: 'Women’s rights NGOs under banner "Vishaka" filed PIL seeking judicial guidelines to protect working women from sexual harassment.',
      issues: ['Does sexual harassment of working women violate Articles 14, 15, 19(1)(g), and 21?', 'Can court lay down binding guidelines in legislative vacuum using international conventions?'],
      decision: 'Laid down binding "Vishaka Guidelines" governing workplace sexual harassment until enactment of legislation, drawing from CEDAW international convention.',
      ratioDecidendi: const [
        'Sexual harassment at workplace violates fundamental rights under Articles 14, 15, 19(1)(g), and 21.',
        'In absence of domestic law, international conventions (CEDAW) ratified by India can be read into Fundamental Rights under Art 51(c).'
      ],
      constitutionalSignificance: 'Pioneered judicial law-making in legislative vacuum and led directly to POSH Act 2013.',
      relatedArticles: const ['14', '15', '19', '21', '51'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IVA'],
      relatedActs: const ['Sexual Harassment of Women at Workplace (POSH) Act 2013'],
      pyqIds: const ['PYQ_UPSC_2019_08', 'PYQ_CDS_2020_02'],
      judgmentDate: DateTime(1997, 8, 13),
      presentStatus: 'Good Law / Codified into POSH Act 2013',
      examImportance: 'High',
      timesAsked: 24,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'Vishaka (1997) established binding guidelines against workplace sexual harassment under Art 14, 19, 21 and international CEDAW framework. Codified into POSH Act 2013.',
      commonMistakes: const ['Mistake: Thinking POSH Act existed in 1997. Reality: POSH Act was passed in 2013 based on 1997 Vishaka Guidelines.'],
      memoryTricks: const ['Vishaka = Virtual law made by SC for workplace sexual harassment until POSH 2013.'],
      oneLineSummary: 'Formulated binding workplace sexual harassment guidelines using CEDAW international law.',
      detailedSummary: '3-judge bench led by CJI J.S. Verma used constitutional power to issue binding workplace safety norms for women.',
      citations: const ['AIR 1997 SC 3011', '(1997) 6 SCC 241'],
    ),

    // ------------------------------------------------------------------------
    // 12. Olga Tellis v. Bombay Municipal Corporation (1985)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-OLGA-TELLIS',
      caseId: 'OLGA_TELLIS',
      caseName: 'Olga Tellis v. Bombay Municipal Corporation',
      citation: 'AIR 1986 SC 180',
      year: 1985,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['Y.V. Chandrachud C.J.', 'S. Murtaza Fazal Ali J.', 'V.D. Tulzapurkar J.', 'O. Chinnappa Reddy J.', 'A. Varadarajan J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Olga Tellis', 'Pavement Dwellers Case', 'Article 21 Right to Livelihood', 'Natural Justice', 'Bombay Municipal Corporation Act'],
      aliases: const ['Pavement Dwellers Case'],
      historicalContext: 'Mass eviction of pavement and slum dwellers in Bombay in 1981 without alternative shelter or hearing.',
      facts: 'Journalist Olga Tellis and slum dwellers filed writ petition against BMC’s decision to evict pavement dwellers under Sec 314 of BMC Act.',
      issues: ['Does Right to Life under Article 21 include Right to Livelihood?', 'Are evictions without prior hearing unconstitutional?'],
      decision: 'Held Right to Life under Article 21 INCLUDES Right to Livelihood. Eviction must follow natural justice and fair procedure.',
      ratioDecidendi: const [
        'Deprivation of livelihood leads to deprivation of life under Article 21.',
        'Procedure for eviction under municipal laws must conform to natural justice (notice and hearing).'
      ],
      constitutionalSignificance: 'Expanded Article 21 to include socio-economic right to livelihood and shelter.',
      relatedArticles: const ['14', '19', '21', '39'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      pyqIds: const ['PYQ_UPSC_2018_04'],
      judgmentDate: DateTime(1985, 7, 10),
      presentStatus: 'Good Law / Socio-Economic Rights Anchor',
      examImportance: 'High',
      timesAsked: 16,
      lastAskedYear: 2022,
      trend: 'Medium Frequency',
      garudaExplanation:
          'Olga Tellis (1985) established that Right to Life under Art 21 includes Right to Livelihood, protecting pavement dwellers from arbitrary eviction without natural justice.',
      commonMistakes: const ['Mistake: Believing SC granted absolute right to squat on public roads. Reality: SC held eviction is permitted but requires fair procedure and notice.'],
      memoryTricks: const ['Olga Tellis = Occupants on pavement -> Livelihood is Life under Art 21.'],
      oneLineSummary: 'Ruled that Right to Life under Article 21 includes Right to Livelihood.',
      detailedSummary: '5-judge bench under CJI Chandrachud integrated socio-economic rights under DPSP into enforceable Art 21 fundamental rights.',
      citations: const ['AIR 1986 SC 180', '(1985) 3 SCC 545'],
    ),

    // ------------------------------------------------------------------------
    // 13. Unni Krishnan, J.P. v. State of Andhra Pradesh (1993)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-UNNIKRISHNAN',
      caseId: 'UNNIKRISHNAN',
      caseName: 'Unni Krishnan, J.P. v. State of Andhra Pradesh',
      citation: 'AIR 1993 SC 2178',
      year: 1993,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['L.M. Sharma C.J.', 'S.R. Pandian J.', 'B.P. Jeevan Reddy J.', 'S.C. Agrawal J.', 'S. Mohan J.'],
      status: CaseStatus.partiallyOverruled,
      keywords: const ['Unnikrishnan', 'Right to Education', 'Article 21', 'Article 45', 'Capitation Fee Scheme', '86th Amendment Art 21A'],
      aliases: const ['Unni Krishnan Case', 'Capitation Fee Case'],
      historicalContext: 'Commercialisation of professional medical and engineering education through exorbitant capitation fees in private colleges.',
      facts: 'Private educational institutions challenged state laws regulating admissions and capitation fees.',
      issues: ['Is Right to Education a Fundamental Right under Article 21?', 'Validity of capitation fee in private educational institutions.'],
      decision: 'Held Right to Education up to 14 years of age is a Fundamental Right under Art 21 (read with Art 45). Formulated scheme regulating private college admissions.',
      ratioDecidendi: const [
        'Every child has a fundamental right to free and compulsory education until age of 14 under Article 21.',
        'Beyond 14 years, right to education is subject to economic capacity of the State.'
      ],
      constitutionalSignificance: 'Direct catalyst for the 86th Constitutional Amendment Act 2002 inserting Article 21A.',
      relatedArticles: const ['14', '19', '21', '21A', '41', '45'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedAmendments: const ['86th Amendment'],
      pyqIds: const ['PYQ_UPSC_2019_03'],
      judgmentDate: DateTime(1993, 2, 4),
      presentStatus: 'Right to Education affirmed (Art 21A); Private college regulatory scheme modified in TMA Pai (2002)',
      examImportance: 'High',
      timesAsked: 20,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'Unnikrishnan (1993) declared free education up to age 14 a Fundamental Right under Art 21, inspiring 86th Amendment (Art 21A). Scheme regulating private colleges was modified in TMA Pai (2002).',
      commonMistakes: const ['Mistake: Thinking Art 21A created right to education first. Reality: Unnikrishnan recognised it under Art 21 in 1993 before 2002 amendment.'],
      memoryTricks: const ['Unnikrishnan = Under 14 Education is Fundamental Right.'],
      oneLineSummary: 'Declared right to free education up to 14 years a Fundamental Right under Article 21.',
      detailedSummary: '5-judge bench under CJI Sharma elevated DPSP Article 45 into enforceable Fundamental Right under Article 21.',
      citations: const ['AIR 1993 SC 2178', '(1993) 1 SCC 645'],
    ),

    // ------------------------------------------------------------------------
    // 14. I.R. Coelho v. State of Tamil Nadu (2007)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-IR-COELHO',
      caseId: 'IR_COELHO',
      caseName: 'I.R. Coelho v. State of Tamil Nadu',
      citation: 'AIR 2007 SC 861',
      year: 2007,
      court: 'Supreme Court of India',
      bench: '9-Judge Constitution Bench',
      judges: const ['Y.K. Sabharwal C.J.', 'K.G. Balakrishnan J.', 'S.H. Kapadia J.', 'C.K. Thakker J.', 'P.K. Balasubramanyan J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['I.R. Coelho', 'Ninth Schedule Immunity', 'Article 31B', 'Basic Structure Test', 'Post-April 24 1973 Cutoff', 'Rights Test vs Essence of Rights Test'],
      aliases: const ['9th Schedule Case'],
      historicalContext: 'Blanket immunity granted to laws placed in Ninth Schedule under Art 31B, avoiding judicial review even if violating Fundamental Rights.',
      facts: '9-judge bench constituted following 5-judge bench reference in Waman Rao (1981) to decide extent of judicial review over Ninth Schedule laws passed after April 24, 1973.',
      issues: ['Are laws placed in Ninth Schedule after April 24, 1973 subject to judicial review on grounds of violating Basic Structure?'],
      decision: 'Unanimous 9-judge decision holding NO law placed in Ninth Schedule after April 24, 1973 enjoys immunity from judicial review if it violates Basic Structure.',
      ratioDecidendi: const [
        'Ninth Schedule laws inserted post April 24, 1973 (Kesavananda judgment date) are open to judicial challenge.',
        'If a law in Ninth Schedule violates Fundamental Rights that form part of Basic Structure (e.g. Art 14, 19, 21), it will be struck down.',
        'Judicial review is a Basic Feature that cannot be abrogated via Ninth Schedule insertion.'
      ],
      constitutionalSignificance: 'Closed the Ninth Schedule loophole used by legislatures to bypass judicial review and basic structure limits.',
      relatedArticles: const ['14', '19', '21', '31B', '32', '368'],
      relatedParts: const ['KO-PART-III', 'KO-PART-XX'],
      relatedSchedules: const ['KO-SCHED-9'],
      pyqIds: const ['PYQ_UPSC_2021_02', 'PYQ_UPSC_2019_01'],
      judgmentDate: DateTime(2007, 1, 11),
      presentStatus: 'Good Law / Ninth Schedule Benchmark',
      examImportance: 'Critical',
      timesAsked: 32,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      garudaExplanation:
          'I.R. Coelho (2007) ended Ninth Schedule safe-haven status. Held that any law added to 9th Schedule after April 24, 1973 can be invalidated if it violates the Basic Structure of the Constitution.',
      commonMistakes: const ['Mistake: Thinking ALL Ninth Schedule laws are open to challenge. Reality: Only laws added AFTER April 24, 1973 cut-off date.'],
      memoryTricks: const ['Coelho = Cutoff date April 24, 1973 for 9th Schedule immunity.'],
      oneLineSummary: 'Subjected post-April 24, 1973 Ninth Schedule laws to Basic Structure judicial review.',
      detailedSummary: '9-judge Constitution Bench led by CJI Sabharwal established that Ninth Schedule is not a vault immune from judicial scrutiny.',
      citations: const ['AIR 2007 SC 861', '(2007) 2 SCC 1'],
    ),

    // ------------------------------------------------------------------------
    // 15. K.S. Puttaswamy v. Union of India (2017)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-PUTTASWAMY',
      caseId: 'PUTTASWAMY',
      caseName: 'Justice K.S. Puttaswamy (Retd.) v. Union of India',
      citation: 'AIR 2017 SC 4161',
      year: 2017,
      court: 'Supreme Court of India',
      bench: '9-Judge Constitution Bench',
      judges: const ['J.S. Khehar C.J.', 'J. Chelameswar J.', 'S.A. Bobde J.', 'R.F. Nariman J.', 'A.M. Sapre J.', 'D.Y. Chandrachud J.', 'S.K. Kaul J.', 'A.N. Sen J.', 'S.A. Nazeer J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Puttaswamy', 'Right to Privacy', 'Article 21', 'Informational Privacy', 'Proportionality Test', 'Overruled MP Sharma & Kharak Singh', 'Overruled ADM Jabalpur'],
      aliases: const ['Privacy Case', 'Aadhaar Privacy Case'],
      historicalContext: 'Challenged biometric Aadhaar scheme on ground that right to privacy is a Fundamental Right under Article 21.',
      facts: 'Retired High Court Judge K.S. Puttaswamy challenged mandatory Aadhaar enrolment. Government argued privacy was not a guaranteed fundamental right based on M.P. Sharma (1954) and Kharak Singh (1962).',
      issues: ['Is Right to Privacy a Fundamental Right guaranteed under Part III of Constitution?'],
      decision: 'Unanimous 9-judge decision holding Right to Privacy is a fundamental right intrinsically linked to Article 21 life and liberty and Part III freedoms.',
      ratioDecidendi: const [
        'Right to Privacy is an integral part of Right to Life and Personal Liberty under Article 21.',
        'Privacy includes spatial privacy, informational privacy, and individual autonomy.',
        'Restriction on privacy must satisfy 3-fold Proportionality Test: 1) Legitimate State Aim, 2) Lawful basis, 3) Proportionality.'
      ],
      obiterDicta: const ['Formally overruled ADM Jabalpur (1976), calling it flawed and erroneous.'],
      constitutionalSignificance: 'Pillar judgment founding modern digital rights, data protection framework, and bodily autonomy jurisprudence in India.',
      relatedArticles: const ['14', '19', '21'],
      relatedParts: const ['KO-PART-III'],
      relatedActs: const ['Aadhaar Act 2016', 'Digital Personal Data Protection Act 2023'],
      pyqIds: const ['PYQ_UPSC_2021_03', 'PYQ_UPSC_2020_03', 'PYQ_UPSC_2018_01'],
      judgmentDate: DateTime(2017, 8, 24),
      presentStatus: 'Good Law / Modern Constitutional Pillar',
      examImportance: 'Critical',
      timesAsked: 52,
      lastAskedYear: 2024,
      trend: 'High Frequency',
      garudaExplanation:
          'Puttaswamy (2017) unanimously declared Right to Privacy a Fundamental Right under Art 21. Overruled M.P. Sharma, Kharak Singh, and ADM Jabalpur, establishing the 3-fold Proportionality Test for privacy restrictions.',
      commonMistakes: const ['Mistake: Believing privacy is an absolute right. Reality: Puttaswamy allows reasonable restrictions under 3-fold Proportionality Test.'],
      memoryTricks: const ['Puttaswamy = Privacy is Paramount under Art 21 (9-0 decision).'],
      oneLineSummary: 'Unanimously declared Right to Privacy a Fundamental Right under Article 21.',
      detailedSummary: '9-judge bench led by CJI Khehar delivered historic unanimous verdict elevating privacy to intrinsic constitutional right.',
      citations: const ['AIR 2017 SC 4161', '(2017) 10 SCC 1'],
    ),

    // ------------------------------------------------------------------------
    // 16. Navtej Singh Johar v. Union of India (2018)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-NAVTEJ-JOHAR',
      caseId: 'NAVTEJ_JOHAR',
      caseName: 'Navtej Singh Johar v. Union of India',
      citation: 'AIR 2018 SC 4321',
      year: 2018,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['Dipak Misra C.J.', 'R.F. Nariman J.', 'A.M. Khanwilkar J.', 'D.Y. Chandrachud J.', 'Indu Malhotra J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Navtej Singh Johar', 'Section 377 IPC', 'Decriminalisation of Homosexuality', 'Article 14 15 19 21', 'Constitutional Morality', 'Transformative Constitutionalism'],
      aliases: const ['Section 377 Case', 'LGBTQ+ Rights Case'],
      historicalContext: 'Challenge to Section 377 IPC criminalising consensual same-sex adult relationships following Suresh Koushal (2013) reversal.',
      facts: 'Dancer Navtej Singh Johar and others filed writ petition seeking decriminalisation of consensual adult same-sex relations under Sec 377 IPC.',
      issues: ['Does Section 377 IPC violate Articles 14, 15, 19, and 21 for consensual adult same-sex acts?'],
      decision: 'Unanimously struck down Section 377 IPC to extent it criminalised consensual sexual acts between adults in private.',
      ratioDecidendi: const [
        'Sexual orientation is an intrinsic component of personal identity, privacy, and dignity under Art 21.',
        'Article 15 prohibition against discrimination based on "sex" includes "sexual orientation".',
        'Constitutional Morality overrides social morality.'
      ],
      constitutionalSignificance: 'Benchmark for Transformative Constitutionalism and LGBTQ+ fundamental rights in India.',
      relatedArticles: const ['14', '15', '19', '21'],
      relatedParts: const ['KO-PART-III'],
      relatedActs: const ['Indian Penal Code 1860 (Sec 377)'],
      pyqIds: const ['PYQ_UPSC_2020_07', 'PYQ_CDS_2021_02'],
      judgmentDate: DateTime(2018, 9, 6),
      presentStatus: 'Good Law / LGBTQ+ Equality Anchor',
      examImportance: 'High',
      timesAsked: 22,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'Navtej Singh Johar (2018) decriminalised consensual same-sex acts under Sec 377 IPC, holding that Constitutional Morality prevails over public morality and sexual orientation is protected under Art 14, 15, 21.',
      commonMistakes: const ['Mistake: Thinking Sec 377 IPC was completely struck down. Reality: Struck down only regarding consensual adult acts; non-consensual acts remain offences.'],
      memoryTricks: const ['Navtej Johar = Natural identity & sexual orientation protected under Art 21.'],
      oneLineSummary: 'Decriminalised consensual same-sex adult relationships under Section 377 IPC.',
      detailedSummary: '5-judge bench led by CJI Dipak Misra affirmed transformative constitutionalism and equal citizenship for LGBTQ+ individuals.',
      citations: const ['AIR 2018 SC 4321', '(2018) 10 SCC 1'],
    ),

    // ------------------------------------------------------------------------
    // 17. Shayara Bano v. Union of India (2017)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-SHAYARA-BANO',
      caseId: 'SHAYARA_BANO',
      caseName: 'Shayara Bano v. Union of India',
      citation: 'AIR 2017 SC 4609',
      year: 2017,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['J.S. Khehar C.J.', 'Kurian Joseph J.', 'R.F. Nariman J.', 'U.U. Lalit J.', 'S. Abdul Nazeer J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Shayara Bano', 'Triple Talaq', 'Talaq-e-Biddat', 'Article 14 15 21 25', 'Manifest Arbitrariness Test', 'Muslim Women Act 2019'],
      aliases: const ['Triple Talaq Case'],
      historicalContext: 'Practice of instantaneous un-revocable Triple Talaq (Talaq-e-Biddat) dissolving Muslim marriages without reconciliation.',
      facts: 'Shayara Bano subjected to instantaneous Triple Talaq filed petition challenging Triple Talaq, polygamy, and nikah halala as unconstitutional.',
      issues: ['Is instant Triple Talaq (Talaq-e-Biddat) protected under Article 25 religious freedom?', 'Does Triple Talaq violate Article 14 equal protection?'],
      decision: '3:2 Majority declared instantaneous Triple Talaq (Talaq-e-Biddat) unconstitutional and void.',
      ratioDecidendi: const [
        'Triple Talaq is manifestly arbitrary and violates Article 14 equality.',
        'Practice not essential to Islamic religious faith, hence not protected by Article 25.',
        'Manifest Arbitrariness Test formulated by Justice Nariman to strike down statutory/customary laws.'
      ],
      constitutionalSignificance: 'Formulated Manifest Arbitrariness Test under Article 14 and led to Muslim Women (Protection of Rights on Marriage) Act 2019.',
      relatedArticles: const ['14', '15', '21', '25', '44'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedActs: const ['Muslim Women (Protection of Rights on Marriage) Act 2019'],
      pyqIds: const ['PYQ_UPSC_2019_05', 'PYQ_CAPF_2020_01'],
      judgmentDate: DateTime(2017, 8, 22),
      presentStatus: 'Good Law / Codified into Criminal Act 2019',
      examImportance: 'High',
      timesAsked: 25,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'Shayara Bano (2017) struck down instant Triple Talaq as unconstitutional under Art 14 for being manifestly arbitrary, affirming gender justice over discriminatory religious customs.',
      commonMistakes: const ['Mistake: Assuming all forms of talaq were banned. Reality: Only instant Talaq-e-Biddat was declared void.'],
      memoryTricks: const ['Shayara Bano = Struck down Triple Talaq using Manifest Arbitrariness.'],
      oneLineSummary: 'Declared instantaneous Triple Talaq (Talaq-e-Biddat) unconstitutional under Article 14.',
      detailedSummary: '5-judge multi-faith bench 3:2 decision invalidated instant Triple Talaq, promoting women’s equality and dignity.',
      citations: const ['AIR 2017 SC 4609', '(2017) 9 SCC 1'],
    ),

    // ------------------------------------------------------------------------
    // 18. Romesh Thappar v. State of Madras (1950)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-ROMESH-THAPPAR',
      caseId: 'ROMESH_THAPPAR',
      caseName: 'Romesh Thappar v. State of Madras',
      citation: 'AIR 1950 SC 124',
      year: 1950,
      court: 'Supreme Court of India',
      bench: '5-Judge Constitution Bench',
      judges: const ['H.J. Kania C.J.', 'Paitanjali Sastri J.', 'B.K. Mukherjea J.', 'S.R. Das J.', 'N. Chandrasekhara Aiyar J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Romesh Thappar', 'Freedom of Press', 'Article 19(1)(a)', 'Cross Roads Journal', 'Public Order vs Public Safety', '1st Amendment 1951'],
      aliases: const ['Cross Roads Case', 'Freedom of Press Case'],
      historicalContext: 'Madras government banned circulation of weekly journal "Cross Roads" under Madras Maintenance of Public Order Act 1949.',
      facts: 'Romesh Thappar, printer and publisher of left-leaning journal "Cross Roads", challenged entry ban imposed by Madras government.',
      issues: ['Does freedom of speech under Art 19(1)(a) include freedom of circulation/press?', 'Can speech be banned for general "public safety"?'],
      decision: 'Held Freedom of Speech & Expression under Art 19(1)(a) INCLUDES Freedom of Press and circulation. Banning journal violated Art 19(1)(a).',
      ratioDecidendi: const [
        'Freedom of Speech and Expression includes freedom of propagation of ideas, guaranteed by freedom of circulation.',
        '"Public safety" is broader than "security of State"; speech cannot be restricted outside grounds listed in Art 19(2).'
      ],
      constitutionalSignificance: 'Foundational precedent establishing Freedom of Press in India. Prompted 1st Amendment 1951 adding "public order" to Art 19(2).',
      relatedArticles: const ['19', '32'],
      relatedParts: const ['KO-PART-III'],
      relatedAmendments: const ['1st Amendment'],
      pyqIds: const ['PYQ_UPSC_2018_03', 'PYQ_NDA_2021_01'],
      judgmentDate: DateTime(1950, 5, 26),
      presentStatus: 'Good Law / Freedom of Press Anchor',
      examImportance: 'High',
      timesAsked: 21,
      lastAskedYear: 2022,
      trend: 'High Frequency',
      garudaExplanation:
          'Romesh Thappar (1950) ruled that Art 19(1)(a) protects Freedom of the Press and circulation. Led directly to 1st Amendment 1951 introducing "public order" in Art 19(2).',
      commonMistakes: const ['Mistake: Believing "Freedom of Press" is explicitly written in Art 19(1)(a). Reality: It was read into Art 19(1)(a) by judicial interpretation in Romesh Thappar.'],
      memoryTricks: const ['Romesh Thappar = Freedom of Press & Circulation under 19(1)(a).'],
      oneLineSummary: 'Established that Freedom of Speech under Article 19(1)(a) includes Freedom of the Press.',
      detailedSummary: '5-judge bench led by Justice Patanjali Sastri held that freedom of speech covers circulation of newspapers and journals.',
      citations: const ['AIR 1950 SC 124', '1950 SCR 594'],
    ),

    // ------------------------------------------------------------------------
    // 19. A.K. Gopalan v. State of Madras (1950)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-AK-GOPALAN',
      caseId: 'AK_GOPALAN',
      caseName: 'A.K. Gopalan v. State of Madras',
      citation: 'AIR 1950 SC 27',
      year: 1950,
      court: 'Supreme Court of India',
      bench: '6-Judge Constitution Bench',
      judges: const ['H.J. Kania C.J.', 'S. Fazl Ali J.', 'Patanjali Sastri J.', 'B.K. Mukherjea J.', 'S.R. Das J.', 'N. Chandrasekhara Aiyar J.'],
      status: CaseStatus.overruled,
      keywords: const ['A.K. Gopalan', 'Preventive Detention Act 1950', 'Article 21', 'Literal Interpretation', 'Procedure Established by Law vs Due Process', 'Silowed View of FRs'],
      aliases: const ['A.K. Gopalan Case'],
      historicalContext: 'Communist leader A.K. Gopalan detained under Preventive Detention Act 1950 shortly after Constitution came into force.',
      facts: 'Gopalan challenged detention arguing procedure under Preventive Detention Act was unfair and violated Art 19, 21, and 22.',
      issues: ['Does "procedure established by law" in Art 21 mean American "Due Process of Law"?', 'Are Fundamental Rights in Part III mutually exclusive silos?'],
      decision: 'Narrow literal interpretation: Held "procedure established by law" means any procedure enacted by Parliament. Rejected Due Process. Held FRs are separate silos.',
      ratioDecidendi: const [
        'Article 21 protects against executive illegality only, not arbitrary legislation.',
        'Articles 19, 21, and 22 are independent, mutually exclusive provisions.'
      ],
      constitutionalSignificance: 'Narrow early constitutional interpretation later completely discarded by Maneka Gandhi (1978).',
      relatedArticles: const ['14', '19', '21', '22'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2017_05'],
      judgmentDate: DateTime(1950, 5, 19),
      presentStatus: 'Overruled by Maneka Gandhi (1978)',
      examImportance: 'High',
      timesAsked: 27,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'A.K. Gopalan (1950) gave a rigid literal interpretation to Art 21, holding law need not be just or fair. Overruled in 1978 by Maneka Gandhi.',
      commonMistakes: const ['Mistake: Thinking Gopalan protected personal liberty broadly. Reality: Gopalan gave maximum power to legislature over personal liberty.'],
      memoryTricks: const ['Gopalan = Guarded literal interpretation (overruled by Maneka).'],
      oneLineSummary: 'Narrowly interpreted Article 21 procedure as mere state-enacted law (overruled in 1978).',
      detailedSummary: '6-judge bench 5:1 decision adopted strict textualist approach to fundamental rights under Article 21.',
      citations: const ['AIR 1950 SC 27', '1950 SCR 88'],
    ),

    // ------------------------------------------------------------------------
    // 20. State of Madras v. Champakam Dorairajan (1951)
    // ------------------------------------------------------------------------
    CaseKnowledgeObject(
      objectId: 'KO-CASE-CHAMPAKAM',
      caseId: 'CHAMPAKAM_DORAIRAJAN',
      caseName: 'State of Madras v. Champakam Dorairajan',
      citation: 'AIR 1951 SC 226',
      year: 1951,
      court: 'Supreme Court of India',
      bench: '7-Judge Constitution Bench',
      judges: const ['H.J. Kania C.J.', 'S. Fazl Ali J.', 'Patanjali Sastri J.', 'B.K. Mukherjea J.', 'S.R. Das J.', 'N. Chandrasekhara Aiyar J.', 'V. Bose J.'],
      status: CaseStatus.landmarkPrecedent,
      keywords: const ['Champakam Dorairajan', 'Communal G.O.', 'Article 15(1)', 'Article 29(2)', 'Fundamental Rights vs DPSP', '1st Amendment 1951 Art 15(4)'],
      aliases: const ['Communal G.O. Case', 'Champakam Case'],
      historicalContext: 'Madras government Communal G.O. (1927) allocated medical/engineering college seats based strictly on caste proportion.',
      facts: 'Brahmin candidates Champakam Dorairajan and C.R. Srinivasan denied medical/engineering college admission despite high marks due to Communal G.O. quota.',
      issues: ['Does Communal G.O. assigning college seats based on caste violate Art 15(1) and 29(2)?', 'Do DPSPs override Fundamental Rights?'],
      decision: 'Unanimously struck down Communal G.O. as unconstitutional under Art 29(2). Held Fundamental Rights are sacrosanct and override DPSPs.',
      ratioDecidendi: const [
        'Denying admission to educational institutions based on caste violates Article 29(2).',
        'DPSPs under Part IV cannot override Fundamental Rights under Part III; DPSPs must run as subsidiary to Part III.'
      ],
      constitutionalSignificance: 'First case on reservation in educational institutions; prompted 1st Constitutional Amendment Act 1951 inserting Article 15(4).',
      relatedArticles: const ['14', '15', '29', '46'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedAmendments: const ['1st Amendment'],
      pyqIds: const ['PYQ_UPSC_2020_04', 'PYQ_CAPF_2018_01'],
      judgmentDate: DateTime(1951, 4, 9),
      presentStatus: 'Good Law / Triggered 1st Amendment Art 15(4)',
      examImportance: 'High',
      timesAsked: 30,
      lastAskedYear: 2023,
      trend: 'High Frequency',
      garudaExplanation:
          'Champakam Dorairajan (1951) invalidated caste-based communal quotas in medical/engineering colleges under Art 29(2) and established FR superiority over DPSP. Led directly to 1st Amendment adding Art 15(4).',
      commonMistakes: const ['Mistake: Believing Art 15(4) existed in original 1950 Constitution. Reality: Added by 1st Amendment 1951 to undo Champakam ruling.'],
      memoryTricks: const ['Champakam = Caste quota struck down -> 1st Amendment Art 15(4) born.'],
      oneLineSummary: 'Struck down caste-based college quota under Art 29(2), leading to 1st Amendment inserting Art 15(4).',
      detailedSummary: '7-judge bench led by CJI Kania ruled that DPSPs cannot override fundamental rights, necessitating constitutional amendment.',
      citations: const ['AIR 1951 SC 226', '1951 SCR 525'],
    ),
  ];
}
