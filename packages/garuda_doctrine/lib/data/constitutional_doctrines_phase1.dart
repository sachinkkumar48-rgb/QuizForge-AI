library;

import '../domain/entities/doctrine_enums.dart';
import '../domain/entities/doctrine_knowledge_object.dart';

/// Seeded Data for Phase I Constitutional Doctrines (20 Doctrines).
/// Every Doctrine is an independent, permanent Knowledge Object formatted for GARUDA engine.
class ConstitutionalDoctrinesPhase1 {
  static final List<DoctrineKnowledgeObject> doctrines = [
    // ------------------------------------------------------------------------
    // 1. Basic Structure Doctrine
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-BASIC-STRUCTURE',
      doctrineId: 'BASIC_STRUCTURE',
      name: 'Basic Structure Doctrine',
      aliases: const ['Basic Features Doctrine', 'Unalterable Core'],
      category: DoctrineCategory.amendingPower,
      origin: 'Judicially Evolved by Supreme Court in Kesavananda Bharati (1973)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional principle providing that while Parliament has broad constituent powers under Article 368 to amend any part of the Constitution, it cannot alter, damage, or destroy the core framework, identity, or basic features of the Constitution.',
      plainLanguageExplanation:
          'Parliament can change parts of the Constitution, but it cannot destroy its foundation (like democracy, secularism, federalism, independence of judiciary, or judicial review).',
      purpose:
          'To prevent a parliamentary majority from legally converting India’s constitutional democracy into a totalitarian or dictatorial regime.',
      scope:
          'Applies to all Constitutional Amendment Acts passed under Article 368, including laws placed in the Ninth Schedule post-April 24, 1973.',
      limitations: const [
        'Does not apply to ordinary legislative statutes (which are judged on fundamental rights and legislative competence).',
        'Not explicitly enumerated or defined in the text of the Constitution.'
      ],
      originatingCase: 'Kesavananda Bharati v. State of Kerala (1973)',
      historicalContext:
          'Evolved amidst a long constitutional struggle between Judiciary and Parliament regarding the extent of amending power under Article 368 following Shankari Prasad (1951), Sajjan Singh (1965), and Golaknath (1967).',
      evolution:
          'First hinted at by Justice Mudholkar in Sajjan Singh (1965), formally established in Kesavananda Bharati (1973), expanded in Indira Gandhi (1975), Minerva Mills (1980), S.R. Bommai (1994), and I.R. Coelho (2007).',
      importantMilestones: const [
        '1965: Justice Mudholkar hints at "basic features" in Sajjan Singh.',
        '1973: 13-Judge Bench formulates doctrine in Kesavananda Bharati (7-6 majority).',
        '1975: Applied to strike down 39th Amendment in Indira Gandhi v. Raj Narain.',
        '1980: Reaffirmed limited amending power as basic feature in Minerva Mills.',
        '2007: Applied to Ninth Schedule laws post-1973 in I.R. Coelho.'
      ],
      landmarkCases: const [
        'Kesavananda Bharati v. State of Kerala (1973)',
        'Indira Gandhi v. Raj Narain (1975)',
        'Minerva Mills Ltd. v. Union of India (1980)',
        'S.R. Bommai v. Union of India (1994)',
        'I.R. Coelho v. State of Tamil Nadu (2007)'
      ],
      subsequentCases: const ['NJAC Case (Supreme Court Advocates-on-Record Assn. v. UOI 2015)'],
      expandedBy: const ['I.R. Coelho (extended to 9th Schedule laws)'],
      currentPosition:
          'Settled constitutional law. Judicial review, secularism, federalism, rule of law, independence of judiciary, and free/fair elections are recognized basic features.',
      relatedArticles: const ['13', '14', '19', '21', '32', '226', '368'],
      relatedParts: const ['KO-PART-III', 'KO-PART-XX'],
      relatedSchedules: const ['KO-SCHED-9'],
      relatedAmendments: const ['24th Amendment', '39th Amendment', '42nd Amendment', '99th Amendment'],
      pyqIds: const ['PYQ_UPSC_2020_01', 'PYQ_UPSC_2019_04', 'PYQ_UPSC_2017_09'],
      examImportance: 'Critical',
      timesAsked: 54,
      trend: 'High Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Severability', 'Doctrine of Eclipse'],
      oneLineSummary: 'Parliament cannot use Article 368 to alter or destroy the Basic Structure of the Constitution.',
      detailedExplanation:
          'The Basic Structure Doctrine balances legislative amending power with constitutional supremacy. It ensures that constitutional identity remains intact despite majoritarian amendments.',
      primarySource: 'Kesavananda Bharati v. State of Kerala, AIR 1973 SC 1461',
      citations: const ['AIR 1973 SC 1461', '(1973) 4 SCC 225'],
    ),

    // ------------------------------------------------------------------------
    // 2. Doctrine of Eclipse
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-ECLIPSE',
      doctrineId: 'ECLIPSE',
      name: 'Doctrine of Eclipse',
      aliases: const ['Principle of Dormancy', 'Eclipse Doctrine'],
      category: DoctrineCategory.fundamentalRights,
      origin: 'Judicially Evolved in Bhikaji Narain Dhakras v. State of M.P. (1955)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A principle providing that a pre-constitutional law violating a Fundamental Right under Article 13(1) is not dead ab initio, but remains dormant or shadowed by the fundamental right, becoming active again if the shadow is removed by constitutional amendment.',
      plainLanguageExplanation:
          'Inconsistent pre-1950 laws don’t vanish completely; they are eclipsed (covered like an eclipse). If the constitutional obstacle is removed later, the law becomes fully functional again without needing to be re-enacted.',
      purpose:
          'To preserve pre-constitutional legislation and prevent unnecessary legislative re-enactment when constitutional provisions change.',
      scope:
          'Applies primarily to pre-constitutional laws under Article 13(1). (Does NOT apply to post-constitutional laws which are void ab initio against citizens - Deep Chand case).',
      limitations: const [
        'Does not make post-constitutional laws valid against citizens if passed in violation of Part III.',
        'Applies only while the fundamental right inconsistency persists.'
      ],
      originatingCase: 'Bhikaji Narain Dhakras v. State of Madhya Pradesh (1955)',
      historicalContext:
          'Addressed C.P. & Berar Motor Vehicles Amendment Act 1947 which created motor transport monopoly. Inconsistent with Art 19(1)(g) in 1950, but 1st Amendment 1951 added Art 19(6) allowing state monopolies.',
      evolution:
          'Formulated in Bhikaji Narain (1955), clarified in Deep Chand (1959) and State of Gujarat v. Ambica Mills (1974).',
      landmarkCases: const [
        'Bhikaji Narain Dhakras v. State of M.P. (1955)',
        'Deep Chand v. State of U.P. (1959)',
        'State of Gujarat v. Ambica Mills (1974)'
      ],
      currentPosition: 'Settled law. Pre-constitutional laws remain dormant under eclipse; post-constitutional laws violating Part III are void ab initio regarding citizens.',
      relatedArticles: const ['13', '19'],
      relatedParts: const ['KO-PART-III'],
      relatedAmendments: const ['1st Amendment'],
      pyqIds: const ['PYQ_UPSC_2018_08', 'PYQ_CAPF_2020_05'],
      examImportance: 'High',
      timesAsked: 22,
      trend: 'High Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Severability', 'Doctrine of Waiver'],
      oneLineSummary: 'Pre-constitutional laws violating Part III are eclipsed and become active if the inconsistency is cured.',
      detailedExplanation:
          'Under Article 13(1), pre-1950 laws violating Fundamental Rights are not void from birth (ab initio). They remain dormant like a solar eclipse. Once constitutional amendments remove the conflict, the shadow lifts and the law operates fully.',
      citations: const ['AIR 1955 SC 781'],
    ),

    // ------------------------------------------------------------------------
    // 3. Doctrine of Severability
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-SEVERABILITY',
      doctrineId: 'SEVERABILITY',
      name: 'Doctrine of Severability',
      aliases: const ['Doctrine of Separability', 'Blue Pencil Test'],
      category: DoctrineCategory.fundamentalRights,
      origin: 'Derived from Article 13(1) and 13(2) text & Common Law',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional rule that if a statute contains unconstitutional provisions alongside valid provisions, the court will strike down ONLY the unconstitutional portion if it can be cleanly severed without affecting the surviving text or purpose.',
      plainLanguageExplanation:
          'Courts cut away only the bad part of a law with a scalpel, saving the good parts, as long as the remaining law makes sense on its own.',
      purpose:
          'To preserve valid legislative enactments and avoid invalidating entire statutes when only specific clauses are unconstitutional.',
      scope:
          'Applies to both pre-constitutional and post-constitutional laws under Article 13.',
      limitations: const [
        'If the valid and invalid parts are inextricably linked, the ENTIRE statute must be struck down.',
        'If removing invalid parts alters the core object/scheme of the Act, severability fails.'
      ],
      originatingCase: 'A.K. Gopalan v. State of Madras (1950)',
      historicalContext:
          'Applied in A.K. Gopalan where Section 14 of Preventive Detention Act 1950 was severed while upholding the rest of the Act.',
      evolution:
          'Definitive rules laid down by SC in R.M.D. Chamarbaugwalla v. Union of India (1957).',
      landmarkCases: const [
        'A.K. Gopalan v. State of Madras (1950)',
        'R.M.D. Chamarbaugwalla v. Union of India (1957)',
        'Kihoto Hollohan v. Zachillhu (1992)'
      ],
      currentPosition: 'Settled law. Standard Blue Pencil Test applied in constitutional litigation.',
      relatedArticles: const ['13', '254'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2019_07'],
      examImportance: 'High',
      timesAsked: 26,
      trend: 'High Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Eclipse'],
      oneLineSummary: 'Only the unconstitutional portion of a law is invalidated if it can be severed cleanly from valid parts.',
      detailedExplanation:
          'Article 13 states laws are void "to the extent of inconsistency". Under R.M.D. Chamarbaugwalla, if valid and invalid provisions can be separated, courts strike down only the bad clauses.',
      citations: const ['AIR 1957 SC 628'],
    ),

    // ------------------------------------------------------------------------
    // 4. Doctrine of Waiver
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-WAIVER',
      doctrineId: 'WAIVER',
      name: 'Doctrine of Waiver',
      aliases: const ['Waiver of Rights'],
      category: DoctrineCategory.fundamentalRights,
      origin: 'Judicially Evolved in Basheshar Nath v. CIT (1959)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional principle holding that an individual citizen CANNOT voluntarily waive or give up any Fundamental Right guaranteed under Part III of the Constitution.',
      plainLanguageExplanation:
          'A citizen cannot sign away or give up their Fundamental Rights, even if they agree to do so in writing or contract.',
      purpose:
          'To protect vulnerable individuals from coerced agreements and maintain fundamental rights as public policy protections.',
      scope:
          'Applies strictly to Part III Fundamental Rights in India (unlike American constitutional law where rights can be waived).',
      limitations: const ['Applies to Fundamental Rights; statutory rights or contractual rights can generally be waived.'],
      originatingCase: 'Basheshar Nath v. Commissioner of Income Tax (1959)',
      historicalContext:
          'Taxpayer entered settlement under Income Tax Investigation Commission Act. Section 5(1) was later declared unconstitutional under Art 14. IT department argued taxpayer waived his right by settling.',
      evolution:
          '5-judge SC bench held unanimously that Fundamental Rights are public obligations that cannot be waived.',
      landmarkCases: const ['Basheshar Nath v. CIT (1959)', 'Behram Khurshed Pesikaka v. State of Bombay (1955)'],
      currentPosition: 'Settled law. Fundamental Rights in India cannot be waived by individuals.',
      relatedArticles: const ['13', '14', '19', '21'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2017_08'],
      examImportance: 'Medium',
      timesAsked: 16,
      trend: 'Medium Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Estoppel'],
      oneLineSummary: 'Citizens cannot waive or contract out of Fundamental Rights guaranteed by Part III.',
      detailedExplanation:
          'In Basheshar Nath (1959), SC held FRs are built into the Constitution not just for individual benefit but as a matter of public policy. No person can relinquish them.',
      citations: const ['AIR 1959 SC 149'],
    ),

    // ------------------------------------------------------------------------
    // 5. Doctrine of Colourable Legislation
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-COLOURABLE-LEGISLATION',
      doctrineId: 'COLOURABLE_LEGISLATION',
      name: 'Doctrine of Colourable Legislation',
      aliases: const ['Indirect Legislative Overreach', 'What cannot be done directly cannot be done indirectly'],
      category: DoctrineCategory.legislativeRelations,
      origin: 'Maxim: Quando aliquid prohibetur ex directo, prohibetur et per obliquum',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A doctrine testing legislative competence, holding that the legislature cannot under the guise of an apparent power pass a law on a subject outside its constitutional competence ("what cannot be done directly cannot be done indirectly").',
      plainLanguageExplanation:
          'If Parliament or State Legislature does not have the power to make a law, it cannot trick the system by disguising the law under a different name.',
      purpose:
          'To prevent legislative trespass beyond constitutional distribution of powers under Seventh Schedule.',
      scope:
          'Applies strictly to legislative competence and distribution of legislative powers (Art 246 / Schedule 7). Does NOT relate to legislative motives or bona fides.',
      limitations: const [
        'Does not concern legislative motive or bad faith; courts look ONLY at constitutional power/competence.',
        'If legislature has power, motive is irrelevant.'
      ],
      originatingCase: 'Kameshwar Singh v. State of Bihar (1952)',
      historicalContext:
          'Bihar Land Reforms Act 1950 provided compensation formula resulting in near-zero compensation for big zamindars under guise of compensation rules.',
      evolution:
          'Elaborated in K.C. Gajapati Narayan Deo v. State of Orissa (1953).',
      landmarkCases: const [
        'State of Bihar v. Kameshwar Singh (1952)',
        'K.C. Gajapati Narayan Deo v. State of Orissa (1953)',
        'R.S. Joshi v. Ajit Mills (1977)'
      ],
      currentPosition: 'Settled law. Core principle of legislative distribution of powers under 7th Schedule.',
      relatedArticles: const ['245', '246'],
      relatedParts: const ['KO-PART-XI'],
      relatedSchedules: const ['KO-SCHED-7'],
      pyqIds: const ['PYQ_UPSC_2021_06', 'PYQ_CAPF_2019_04'],
      examImportance: 'High',
      timesAsked: 28,
      trend: 'High Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Pith and Substance'],
      oneLineSummary: 'Legislature cannot indirectly enact a law on a subject outside its constitutional competence.',
      detailedExplanation: 'Colourable legislation is about legislative power, not motive. If power is lacking, disguised enactment is unconstitutional.',
      citations: const ['AIR 1953 SC 375'],
    ),

    // ------------------------------------------------------------------------
    // 6. Doctrine of Pith and Substance
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-PITH-AND-SUBSTANCE',
      doctrineId: 'PITH_AND_SUBSTANCE',
      name: 'Doctrine of Pith and Substance',
      aliases: const ['True Nature and Character', 'Dominant Purpose Test'],
      category: DoctrineCategory.legislativeRelations,
      origin: 'Privy Council Jurisprudence (Canadian Constitution precedents)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional doctrine used to examine the true nature, character, and dominant purpose of a law when it encroaches incidentally on a legislative list belonging to another legislature under the Seventh Schedule.',
      plainLanguageExplanation:
          'When looking at a law, courts examine its core purpose ("pith and substance"). If its main topic falls within the legislature’s allowed list, minor incidental overlap into another list does not make it invalid.',
      purpose:
          'To ensure flexible federalism and prevent rigid invalidation of laws due to minor overlapping of legislative subjects.',
      scope:
          'Used to resolve conflicts between Union List, State List, and Concurrent List entries under Article 246.',
      limitations: const [
        'Applies only when encroachment is incidental. If encroachment is substantial, law is invalid.'
      ],
      originatingCase: 'Prafulla Kumar Mukherjee v. Bank of Commerce, Khulna (Privy Council 1947)',
      historicalContext:
          'Bengal Money Lenders Act 1940 enacted by provincial legislature affected promissory notes (central subject). Privy Council upheld Act examining its true pith and substance (money lending).',
      evolution:
          'Adopted by Indian Supreme Court in State of Bombay v. F.N. Balsara (1951).',
      landmarkCases: const [
        'Prafulla Kumar Mukherjee v. Bank of Commerce (1947)',
        'State of Bombay v. F.N. Balsara (1951)',
        'State of Rajasthan v. G. Chawla (1959)'
      ],
      currentPosition: 'Settled law. Primary doctrine for Seventh Schedule legislative entry disputes.',
      relatedArticles: const ['246'],
      relatedParts: const ['KO-PART-XI'],
      relatedSchedules: const ['KO-SCHED-7'],
      pyqIds: const ['PYQ_UPSC_2020_06', 'PYQ_CDS_2022_01'],
      examImportance: 'High',
      timesAsked: 32,
      trend: 'High Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Colourable Legislation', 'Doctrine of Incidental Powers'],
      oneLineSummary: 'Examines the true nature and core purpose of a law to determine legislative competence despite incidental overlap.',
      detailedExplanation: 'In State of Bombay v. F.N. Balsara (1951), SC held Bombay Prohibition Act was in pith and substance about intoxicating liquors (State List), despite incidental impact on import of liquor (Union List).',
      citations: const ['AIR 1951 SC 318'],
    ),

    // ------------------------------------------------------------------------
    // 7. Doctrine of Incidental Powers
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-INCIDENTAL-POWERS',
      doctrineId: 'INCIDENTAL_POWERS',
      name: 'Doctrine of Incidental and Ancillary Powers',
      aliases: const ['Ancillary Powers', 'Implied Powers'],
      category: DoctrineCategory.legislativeRelations,
      origin: 'Common Law Constitutional Interpretation',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A rule of interpretation providing that express grant of legislative power on a subject includes all implied, incidental, and ancillary powers necessary to make that legislative power effective.',
      plainLanguageExplanation:
          'If the Constitution gives a government the power to legislate on a main subject (e.g. Banking), it automatically includes all necessary side-powers needed to implement that main law effectively.',
      purpose:
          'To ensure legislative entries in Seventh Schedule are given liberal, wide interpretation rather than narrow textual restriction.',
      scope:
          'Applies to all legislative heads in List I, List II, List III of 7th Schedule.',
      limitations: const ['Ancillary power cannot be extended to cover a completely independent primary subject.'],
      originatingCase: 'State of Rajasthan v. G. Chawla (1959)',
      historicalContext:
          'Ajmer Sound Amplifiers Control Act restricted amplifiers (State List). Claimed to touch post & telegraphs (Union List).',
      evolution:
          'Reaffirmed in Express Newspapers v. Union of India (1958).',
      landmarkCases: const ['State of Rajasthan v. G. Chawla (1959)', 'State of Haryana v. Chanan Mal (1976)'],
      currentPosition: 'Settled law.',
      relatedArticles: const ['246'],
      relatedSchedules: const ['KO-SCHED-7'],
      pyqIds: const ['PYQ_UPSC_2017_10'],
      examImportance: 'Medium',
      timesAsked: 14,
      trend: 'Medium Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Pith and Substance'],
      oneLineSummary: 'Grant of main legislative power includes all ancillary powers necessary to make the law effective.',
      detailedExplanation: 'Express power includes implied power to enforce and implement the law effectively.',
      citations: const ['AIR 1959 SC 544'],
    ),

    // ------------------------------------------------------------------------
    // 8. Doctrine of Occupied Field
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-OCCUPIED-FIELD',
      doctrineId: 'OCCUPIED_FIELD',
      name: 'Doctrine of Occupied Field',
      aliases: const ['Occupied Field Test', 'Legislative Preemption'],
      category: DoctrineCategory.legislativeRelations,
      origin: 'Article 254 Jurisprudence',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A doctrine under Article 254 providing that when Parliament enacts a comprehensive law covering an entire field in the Concurrent List (List III), the state legislature is ousted from enacting conflicting laws on that same occupied field.',
      plainLanguageExplanation:
          'If the Central Government passes a complete law covering a topic in the Concurrent List, that "field" is occupied, and State laws on that same field become invalid to the extent of conflict.',
      purpose:
          'To resolve federal conflicts between Central and State laws under Concurrent List.',
      scope:
          'Applies primarily to Concurrent List (List III) under Article 254.',
      limitations: const ['State law can prevail if reserved for President’s Assent under Art 254(2).'],
      originatingCase: 'Deep Chand v. State of Uttar Pradesh (1959)',
      historicalContext:
          'UP Transport Service Development Act 1955 vs Central Motor Vehicles Amendment Act 1956.',
      evolution:
          'Elaborated in M. Karunanidhi v. Union of India (1979).',
      landmarkCases: const ['Deep Chand v. State of U.P. (1959)', 'M. Karunanidhi v. Union of India (1979)'],
      currentPosition: 'Settled law under Article 254.',
      relatedArticles: const ['254'],
      relatedParts: const ['KO-PART-XI'],
      relatedSchedules: const ['KO-SCHED-7'],
      pyqIds: const ['PYQ_UPSC_2021_07'],
      examImportance: 'High',
      timesAsked: 20,
      trend: 'High Frequency',
      frequentlyConfusedDoctrines: const ['Doctrine of Repugnancy'],
      oneLineSummary: 'When Parliament occupies a Concurrent List field, state laws on that field yield to central law under Art 254.',
      detailedExplanation: 'M. Karunanidhi (1979) laid down 3 conditions for repugnancy and occupied field under Art 254.',
      citations: const ['AIR 1979 SC 898'],
    ),

    // ------------------------------------------------------------------------
    // 9. Doctrine of Territorial Nexus
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-TERRITORIAL-NEXUS',
      doctrineId: 'TERRITORIAL_NEXUS',
      name: 'Doctrine of Territorial Nexus',
      aliases: const ['Nexus Principle', 'Extra-Territorial Operation'],
      category: DoctrineCategory.legislativeRelations,
      origin: 'Article 245 Jurisprudence',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional principle under Article 245 establishing that a state law can operate extra-territorially outside the state’s borders if there is a real and sufficient nexus (connection) between the state and the subject matter of the law.',
      plainLanguageExplanation:
          'A state legislature can tax or regulate something outside its borders only if there is a real, genuine connection between that outside entity and the state.',
      purpose:
          'To determine valid extra-territorial application of State laws under Article 245(1).',
      scope:
          'Applies to State legislative powers under Art 245(1). (Parliament has explicit extra-territorial power under Art 245(2)).',
      limitations: const ['Nexus must be real, not illusory or weak.'],
      originatingCase: 'State of Bombay v. R.M.D. Chamarbaugwala (1957)',
      historicalContext:
          'Bombay Lotteries & Prize Competitions Act taxed prize competitions in Bombay. Respondent ran crossword competition from Bangalore via newspapers circulated in Bombay.',
      evolution:
          'Upheld in State of Bihar v. Charusila Dasi (1959).',
      landmarkCases: const ['State of Bombay v. R.M.D. Chamarbaugwala (1957)', 'State of Bihar v. Charusila Dasi (1959)'],
      currentPosition: 'Settled law under Article 245.',
      relatedArticles: const ['245'],
      relatedParts: const ['KO-PART-XI'],
      pyqIds: const ['PYQ_UPSC_2020_09'],
      examImportance: 'High',
      timesAsked: 18,
      lastAskedYear: 2022,
      trend: 'High Frequency',
      garudaExplanation:
          'Territorial Nexus allows a state law extra-territorial reach provided nexus is real and pertinent (R.M.D. Chamarbaugwala 1957).',
      oneLineSummary: 'State law can have extra-territorial operation if a real and sufficient territorial nexus exists.',
      detailedExplanation: 'R.M.D. Chamarbaugwala (1957) established that substantial prize competition income generated in Bombay provided sufficient nexus for Bombay tax law.',
      citations: const ['AIR 1957 SC 699'],
    ),

    // ------------------------------------------------------------------------
    // 10. Doctrine of Harmonious Construction
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-HARMONIOUS-CONSTRUCTION',
      doctrineId: 'HARMONIOUS_CONSTRUCTION',
      name: 'Doctrine of Harmonious Construction',
      aliases: const ['Rule of Harmonious Construction', 'Avoiding Conflict'],
      category: DoctrineCategory.constitutionalInterpretation,
      origin: 'Judicial Rule of Statutory & Constitutional Interpretation',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A cardinal rule of constitutional interpretation requiring courts to read conflicting provisions of a statute or Constitution in a manner that gives effect to both, avoiding head-on clash or rendering any provision redundant.',
      plainLanguageExplanation:
          'When two articles or provisions seem to contradict each other, courts interpret them harmoniously so both survive together rather than destroying one.',
      purpose:
          'To preserve the overall coherence of the Constitution and give effect to legislative intent across all provisions.',
      scope:
          'Applies to interpreting conflicting articles of Constitution (e.g. Part III vs Part IV, Art 19 vs Art 105 parliamentary privileges).',
      limitations: const ['Cannot be used to destroy clear textual mandate when provisions are entirely irreconcilable.'],
      originatingCase: 'MSM Sharma v. Sri Krishna Sinha (Searchlight Case 1959)',
      historicalContext:
          'Conflict between Freedom of Speech (Art 19(1)(a)) and Legislative Privilege (Art 194).',
      evolution:
          'Applied in Venkataramana Devaru (1958), Shankari Prasad (1951), and Minerva Mills (1980).',
      landmarkCases: const [
        'Sri Venkataramana Devaru v. State of Mysore (1958)',
        'MSM Sharma v. Sri Krishna Sinha (1959)',
        'Minerva Mills Ltd. v. Union of India (1980)'
      ],
      currentPosition: 'Settled cornerstone rule of constitutional interpretation.',
      relatedArticles: const ['14', '19', '25', '26', '105', '194', '368'],
      pyqIds: const ['PYQ_UPSC_2021_05', 'PYQ_CDS_2020_04'],
      examImportance: 'Critical',
      timesAsked: 38,
      trend: 'High Frequency',
      garudaExplanation:
          'Harmonious Construction ensures no part of the Constitution is rendered useless. In Venkataramana Devaru (1958), SC harmonised Art 25(2)(b) public temple access with Art 26(b) denominational management.',
      oneLineSummary: 'Conflicting provisions must be interpreted harmoniously to give maximum effect to both.',
      detailedExplanation: 'SC consistently applies this doctrine to balance fundamental rights with parliamentary privileges and DPSPs.',
      citations: const ['AIR 1958 SC 255'],
    ),

    // ------------------------------------------------------------------------
    // 11. Doctrine of Prospective Overruling
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-PROSPECTIVE-OVERRULING',
      doctrineId: 'PROSPECTIVE_OVERRULING',
      name: 'Doctrine of Prospective Overruling',
      aliases: const ['Prospective Application'],
      category: DoctrineCategory.constitutionalInterpretation,
      origin: 'American Jurisprudence, adopted in Golaknath (1967)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A judicial doctrine providing that a newly declared constitutional ruling invalidating a law applies ONLY to future cases and transactions, preserving past transactions and settled actions taken under the old law.',
      plainLanguageExplanation:
          'When the Supreme Court changes a legal rule, the new rule applies from that day forward, without reopening past decided cases or settled actions.',
      purpose:
          'To prevent chaos, economic dislocation, and mass invalidation of historical actions when precedents are changed.',
      scope:
          'Can be invoked ONLY by the Supreme Court of India under its constitutional discretion.',
      limitations: const ['High Courts cannot invoke prospective overruling.'],
      originatingCase: 'I.C. Golaknath v. State of Punjab (1967)',
      historicalContext:
          'CJI Subba Rao invoked doctrine in Golaknath to hold FRs unamendable prospectively, leaving earlier 1st, 4th, 17th Amendments intact.',
      evolution:
          'Reaffirmed in India Cement (1990) and Orissa Cement (1991).',
      landmarkCases: const ['I.C. Golaknath v. State of Punjab (1967)', 'India Cement Ltd. v. State of Tamil Nadu (1990)'],
      currentPosition: 'Settled law, exclusively exercised by Supreme Court.',
      relatedArticles: const ['141', '142'],
      relatedParts: const ['KO-PART-V'],
      pyqIds: const ['PYQ_UPSC_2018_05'],
      examImportance: 'High',
      timesAsked: 20,
      trend: 'High Frequency',
      oneLineSummary: 'New judicial ruling applies prospectively to future transactions without invalidating past actions.',
      detailedExplanation: 'Golaknath (1967) introduced prospective overruling into Indian constitutional jurisprudence to save past land reform amendments.',
      citations: const ['AIR 1967 SC 1643'],
    ),

    // ------------------------------------------------------------------------
    // 12. Doctrine of Pleasure
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-PLEASURE',
      doctrineId: 'PLEASURE_DOCTRINE',
      name: 'Doctrine of Pleasure',
      aliases: const ['Durante Bene Placito', 'Servants of Crown'],
      category: DoctrineCategory.executivePower,
      origin: 'English Common Law, modified under Article 310 & 311',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional principle under Article 310 providing that civil servants hold office during the pleasure of the President or Governor, subject to explicit safeguards under Article 311.',
      plainLanguageExplanation:
          'Government servants hold their post at the pleasure of the President/Governor, but cannot be arbitrarily dismissed without inquiry and hearing under Art 311.',
      purpose:
          'To balance executive control over civil services with tenure security for civil servants.',
      scope:
          'Applies to Defense services and Civil services of Union and States under Art 310.',
      limitations: const ['Subject to procedural safeguards under Article 311(2) (inquiry and opportunity of being heard).'],
      originatingCase: 'Parshotam Lal Dhingra v. Union of India (1958)',
      historicalContext: 'Adaptation of Crown Pleasure doctrine into Indian Constitutional framework.',
      evolution:
          'Elaborated in Parshotam Lal Dhingra (1958) and Union of India v. Tulsiram Patel (1985).',
      landmarkCases: const ['Parshotam Lal Dhingra v. Union of India (1958)', 'Union of India v. Tulsiram Patel (1985)'],
      currentPosition: 'Settled law under Articles 310 and 311.',
      relatedArticles: const ['309', '310', '311'],
      relatedParts: const ['KO-PART-XIV'],
      pyqIds: const ['PYQ_UPSC_2020_10', 'PYQ_CAPF_2021_03'],
      examImportance: 'High',
      timesAsked: 24,
      trend: 'High Frequency',
      oneLineSummary: 'Civil servants hold office during pleasure of President/Governor subject to Article 311 safeguards.',
      detailedExplanation: 'Tulsiram Patel (1985) clarified exceptions to Art 311 inquiry requirement under second proviso.',
      citations: const ['AIR 1958 SC 36', 'AIR 1985 SC 1416'],
    ),

    // ------------------------------------------------------------------------
    // 13. Doctrine of Proportionality
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-PROPORTIONALITY',
      doctrineId: 'PROPORTIONALITY',
      name: 'Doctrine of Proportionality',
      aliases: const ['Proportionality Test', 'Wednesbury Unreasonableness Replacement'],
      category: DoctrineCategory.administrativeLaw,
      origin: 'European & German Jurisprudence, adopted in Om Kumar (2001) & Puttaswamy (2017)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A judicial review principle holding that state action restricting fundamental rights must choose the least restrictive means to achieve a legitimate state goal, ensuring a rational connection and balance between goal and restriction.',
      plainLanguageExplanation:
          'The government cannot use a sledgehammer to crack a nut. Restrictions on rights must be strictly proportional and minimal.',
      purpose:
          'To prevent excessive state intrusion into fundamental freedoms and individual privacy.',
      scope:
          'Applies to administrative action and legislative restrictions affecting Articles 14, 19, and 21.',
      limitations: const ['Courts evaluate proportionality of means, not wisdom of policy.'],
      originatingCase: 'Om Kumar v. Union of India (2001)',
      historicalContext: 'Shift from English Wednesbury unreasonableness test to European Proportionality standard in fundamental rights adjudication.',
      evolution:
          'Adopted in Om Kumar (2001), fully integrated into Article 21 privacy in K.S. Puttaswamy (2017) (4-prong test).',
      landmarkCases: const ['Om Kumar v. Union of India (2001)', 'K.S. Puttaswamy v. Union of India (2017)'],
      currentPosition: 'Settled law. Standard test for fundamental rights violation.',
      relatedArticles: const ['14', '19', '21'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2021_08'],
      examImportance: 'Critical',
      timesAsked: 30,
      trend: 'High Frequency',
      oneLineSummary: 'State restrictions on fundamental rights must be the least restrictive, rational, and proportional means.',
      detailedExplanation: 'Puttaswamy (2017) established 4-prong test: Legitimate goal, suitability, necessity (least restrictive), and balance.',
      citations: const ['AIR 2001 SC 295', 'AIR 2017 SC 4161'],
    ),

    // ------------------------------------------------------------------------
    // 14. Doctrine of Reasonable Classification
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-REASONABLE-CLASSIFICATION',
      doctrineId: 'REASONABLE_CLASSIFICATION',
      name: 'Doctrine of Reasonable Classification',
      aliases: const ['Classification Test', 'Article 14 Permissible Classification'],
      category: DoctrineCategory.fundamentalRights,
      origin: 'State of West Bengal v. Anwar Ali Sarkar (1952) & Ram Krishna Dalmia (1958)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional test under Article 14 providing that while class legislation is forbidden, reasonable classification of persons or objects is permissible if based on an intelligible differentia having a rational nexus to the object sought to be achieved.',
      plainLanguageExplanation:
          'Equal protection under Article 14 does not mean identical treatment for everyone, but equal treatment for equals. The government can divide people into groups if the grouping is logical and connected to the law’s goal.',
      purpose:
          'To permit affirmative action and practical legislation tailored to different classes of citizens.',
      scope:
          'Applies to all legislative and administrative classifications under Article 14.',
      limitations: const [
        'Classification cannot be arbitrary, artificial, or evasive.',
        'Intelligible differentia MUST have a rational nexus to the statutory object.'
      ],
      originatingCase: 'State of West Bengal v. Anwar Ali Sarkar (1952)',
      historicalContext: 'Special courts created under West Bengal Special Courts Act 1950 to try "speedier trial" cases without clear objective criteria.',
      evolution:
          'Twin-test formulated by Chief Justice S.R. Das in Ram Krishna Dalmia v. S.R. Tendolkar (1958).',
      landmarkCases: const [
        'State of West Bengal v. Anwar Ali Sarkar (1952)',
        'Ram Krishna Dalmia v. S.R. Tendolkar (1958)',
        'E.P. Royappa v. State of Tamil Nadu (1974)'
      ],
      currentPosition: 'Settled twin-test under Article 14.',
      relatedArticles: const ['14', '15', '16'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2020_11', 'PYQ_CDS_2021_06'],
      examImportance: 'Critical',
      timesAsked: 44,
      trend: 'High Frequency',
      garudaExplanation:
          'Reasonable Classification requires two conditions (Ram Krishna Dalmia 1958): 1) Intelligible Differentia (distinguishable group) and 2) Rational Nexus to object of law.',
      oneLineSummary: 'Article 14 allows classification if based on intelligible differentia with rational nexus to law’s object.',
      detailedExplanation: 'Ram Krishna Dalmia (1958) established classic twin-test for Article 14 equality analysis.',
      citations: const ['AIR 1958 SC 538'],
    ),

    // ------------------------------------------------------------------------
    // 15. Doctrine of Manifest Arbitrariness
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-MANIFEST-ARBITRARINESS',
      doctrineId: 'MANIFEST_ARBITRARINESS',
      name: 'Doctrine of Manifest Arbitrariness',
      aliases: const ['New Doctrine of Equality', 'Arbitrariness Test'],
      category: DoctrineCategory.fundamentalRights,
      origin: 'E.P. Royappa (1974), revived & formalised in Shayara Bano (2017)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A constitutional test under Article 14 holding that a law or state action is unconstitutional if it is manifestly arbitrary, i.e., done capriciously, without adequate determining principle, or disproportionate.',
      plainLanguageExplanation:
          'Any government law or action that is unreasonable, senseless, or capricious violates Article 14 because equality and arbitrariness are sworn enemies.',
      purpose:
          'To strike down legislation or executive actions under Article 14 beyond traditional classification test.',
      scope:
          'Applies to invalidate statutory legislation, delegated legislation, and executive action under Article 14.',
      limitations: const ['Arbitrariness must be "manifest" (clear, evident, caprice without principle).'],
      originatingCase: 'E.P. Royappa v. State of Tamil Nadu (1974)',
      historicalContext: 'Justice P.N. Bhagwati introduced new dimension of Article 14: "Equality is a dynamic concept; equality and arbitrariness are sworn enemies."',
      evolution:
          'Formalised as a test to invalidate parliamentary statutes by Justice Nariman in Shayara Bano (2017) and Navtej Johar (2018).',
      landmarkCases: const [
        'E.P. Royappa v. State of Tamil Nadu (1974)',
        'Maneka Gandhi v. Union of India (1978)',
        'Shayara Bano v. Union of India (2017)',
        'Navtej Singh Johar v. Union of India (2018)'
      ],
      currentPosition: 'Settled law. Key ground for striking down statutes under Article 14.',
      relatedArticles: const ['14', '19', '21'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2021_09'],
      examImportance: 'Critical',
      timesAsked: 36,
      trend: 'High Frequency',
      oneLineSummary: 'State action or legislation that is manifestly arbitrary violates Article 14 equality.',
      detailedExplanation: 'Shayara Bano (2017) used Manifest Arbitrariness to invalidate instant Triple Talaq.',
      citations: const ['AIR 1974 SC 555', 'AIR 2017 SC 4609'],
    ),

    // ------------------------------------------------------------------------
    // 16. Doctrine of Legitimate Expectation
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-LEGITIMATE-EXPECTATION',
      doctrineId: 'LEGITIMATE_EXPECTATION',
      name: 'Doctrine of Legitimate Expectation',
      aliases: const ['Legitimate Expectation'],
      category: DoctrineCategory.administrativeLaw,
      origin: 'English Administrative Law (Lord Denning), adopted in Food Corporation of India (1993)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A principle of administrative fairness providing that when public authority policy or past practice creates a reasonable expectation in a citizen, the authority cannot arbitrarily alter policy without fair opportunity or public interest justification.',
      plainLanguageExplanation:
          'If government long-standing practice leads you to expect a benefit, the government cannot suddenly change rules to your detriment without fair notice or public reason.',
      purpose:
          'To enforce procedural fairness and prevent administrative caprice.',
      scope:
          'Applies to administrative action; creates procedural rights, not an absolute enforceable substantive right.',
      limitations: const ['Yields to overriding public interest.'],
      originatingCase: 'Food Corporation of India v. Kamdhenu Cattle Feed Industries (1993)',
      historicalContext: 'FCI tender process rejection despite highest bid.',
      evolution:
          'Expanded in National Buildings Construction Corpn. v. S. Raghunathan (1998).',
      landmarkCases: const [
        'Food Corporation of India v. Kamdhenu Cattle Feed (1993)',
        'Navjyoti Coop. Group Housing Society v. UOI (1992)'
      ],
      currentPosition: 'Settled administrative law doctrine under Article 14.',
      relatedArticles: const ['14'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2019_09'],
      examImportance: 'Medium',
      timesAsked: 16,
      trend: 'Medium Frequency',
      oneLineSummary: 'Public authorities must respect reasonable expectations generated by past practices unless overridden by public interest.',
      detailedExplanation: 'FCI (1993) held public authorities are bound by Article 14 fairness in administrative expectations.',
      citations: const ['AIR 1993 SC 1601'],
    ),

    // ------------------------------------------------------------------------
    // 17. Doctrine of Public Trust
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-PUBLIC-TRUST',
      doctrineId: 'PUBLIC_TRUST',
      name: 'Doctrine of Public Trust',
      aliases: const ['Public Trust Principle', 'Trustee of Natural Resources'],
      category: DoctrineCategory.environmentalJurisprudence,
      origin: 'Roman Law & Joseph Sax treatise, adopted in M.C. Mehta v. Kamal Nath (1997)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'A legal principle holding that natural resources (rivers, forests, seashores, air) are held by the State in trust for the general public and cannot be converted into private ownership or commercial exploitation damaging the environment.',
      plainLanguageExplanation:
          'The Government is not the owner of natural resources; it is only a trustee holding air, water, and forests for the public and future generations.',
      purpose:
          'To protect natural environment and public ecological resources from commercial privatization.',
      scope:
          'Applies to all natural resources and environmental management under Article 21 and Article 48A.',
      limitations: const ['Does not bar all development, but requires sustainable environmental protection.'],
      originatingCase: 'M.C. Mehta v. Kamal Nath (Span Motel Case 1997)',
      historicalContext: 'Motel owned by former Environment Minister Kamal Nath diverted Beas River flow in Himachal Pradesh for commercial resort.',
      evolution:
          'Reaffirmed in 2G Spectrum Case (Subramanian Swamy 2012) for spectrum and natural resource allocation.',
      landmarkCases: const [
        'M.C. Mehta v. Kamal Nath (1997)',
        'Centre for Public Interest Litigation v. Union of India (2G Case 2012)'
      ],
      currentPosition: 'Settled law. Core pillar of Indian environmental jurisprudence.',
      relatedArticles: const ['21', '48A', '51A'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV', 'KO-PART-IVA'],
      relatedActs: const ['Environment Protection Act 1986', 'National Green Tribunal Act 2010'],
      pyqIds: const ['PYQ_UPSC_2020_12', 'PYQ_CAPF_2021_05'],
      examImportance: 'High',
      timesAsked: 25,
      trend: 'High Frequency',
      oneLineSummary: 'State holds natural resources in trust for the public and cannot alienate them for private commercial gain.',
      detailedExplanation: 'Kamal Nath case (1997) established State as trustee of natural resources under Art 21.',
      citations: const ['(1997) 1 SCC 388'],
    ),

    // ------------------------------------------------------------------------
    // 18. Polluter Pays Principle
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-POLLUTER-PAYS',
      doctrineId: 'POLLUTER_PAYS',
      name: 'Polluter Pays Principle',
      aliases: const ['Absolute Liability for Pollution', 'Cost of Restoration'],
      category: DoctrineCategory.environmentalJurisprudence,
      origin: 'OECD 1972 guidelines, adopted in Indian Council for Enviro-Legal Action (1996)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'An environmental law principle holding that the absolute financial liability for repairing environmental damage and compensating affected victims rests upon the party responsible for causing the pollution.',
      plainLanguageExplanation:
          'Whoever causes environmental pollution must pay the full cost of cleaning up the damage and compensating victims.',
      purpose:
          'To internalize environmental costs and deter industrial pollution.',
      scope:
          'Applies to all polluting industries under Article 21 and Environment Protection Act 1986.',
      limitations: const ['Liability is absolute and non-delegable.'],
      originatingCase: 'Indian Council for Enviro-Legal Action v. Union of India (Bichhri Case 1996)',
      historicalContext: 'Chemical plants in Bichhri village, Rajasthan discharged toxic sludge polluting groundwater and agriculture.',
      evolution:
          'Applied in Vellore Citizens Welfare Forum (1996) and M.C. Mehta (Taj Trapezium 1997).',
      landmarkCases: const [
        'Indian Council for Enviro-Legal Action v. UOI (1996)',
        'Vellore Citizens Welfare Forum v. Union of India (1996)'
      ],
      currentPosition: 'Settled law under Article 21.',
      relatedArticles: const ['21', '48A'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      relatedActs: const ['Environment Protection Act 1986', 'NGT Act 2010'],
      pyqIds: const ['PYQ_UPSC_2019_10'],
      examImportance: 'High',
      timesAsked: 24,
      trend: 'High Frequency',
      oneLineSummary: 'The financial responsibility for environmental cleanup and victim compensation lies entirely on the polluter.',
      detailedExplanation: 'Bichhri case (1996) made polluter liable for ecological restoration under Art 21.',
      citations: const ['AIR 1996 SC 1446'],
    ),

    // ------------------------------------------------------------------------
    // 19. Precautionary Principle
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-PRECAUTIONARY-PRINCIPLE',
      doctrineId: 'PRECAUTIONARY_PRINCIPLE',
      name: 'Precautionary Principle',
      aliases: const ['Principle of Precaution', 'Onus of Proof on Developer'],
      category: DoctrineCategory.environmentalJurisprudence,
      origin: 'Rio Declaration 1992 (Principle 15), adopted in Vellore Citizens (1996)',
      currentStatus: DoctrineStatus.settledLaw,
      officialDefinition:
          'An environmental principle requiring state authorities to take anticipatory action to prevent environmental degradation even if full scientific certainty is lacking, shifting the onus of proof onto the developer to show the activity is environmentally benign.',
      plainLanguageExplanation:
          'Where there are threats of serious environmental damage, lack of full scientific proof cannot be an excuse for delaying preventive action. The developer must prove their project is safe.',
      purpose:
          'To prevent irreversible damage to fragile ecosystems.',
      scope:
          'Applies to all developmental and industrial projects affecting Article 21 right to clean environment.',
      limitations: const ['Requires threat of serious or irreversible damage.'],
      originatingCase: 'Vellore Citizens Welfare Forum v. Union of India (1996)',
      historicalContext: 'Tanneries in Tamil Nadu discharging untreated effluents into Palar River.',
      evolution:
          'Reaffirmed in Narmada Bachao Andolan (2000) and AP Control Board (1999).',
      landmarkCases: const [
        'Vellore Citizens Welfare Forum v. Union of India (1996)',
        'A.P. Pollution Control Board v. M.V. Nayudu (1999)'
      ],
      currentPosition: 'Settled law. Part of Article 21 law of the land.',
      relatedArticles: const ['21', '48A', '51A'],
      relatedParts: const ['KO-PART-III', 'KO-PART-IV'],
      pyqIds: const ['PYQ_UPSC_2021_10'],
      examImportance: 'High',
      timesAsked: 22,
      trend: 'High Frequency',
      oneLineSummary: 'Anticipatory preventive action must be taken against environmental threats, placing onus of safety proof on developer.',
      detailedExplanation: 'Vellore Citizens (1996) declared Precautionary Principle and Polluter Pays Principle part of Article 21.',
      citations: const ['AIR 1996 SC 2715'],
    ),

    // ------------------------------------------------------------------------
    // 20. Essential Religious Practices Test
    // ------------------------------------------------------------------------
    DoctrineKnowledgeObject(
      objectId: 'KO-DOC-ESSENTIAL-RELIGIOUS-PRACTICES',
      doctrineId: 'ESSENTIAL_RELIGIOUS_PRACTICES',
      name: 'Essential Religious Practices Test',
      aliases: const ['ERP Test', 'Essentiality Test'],
      category: DoctrineCategory.fundamentalRights,
      origin: 'Shirur Mutt Case (1954)',
      currentStatus: DoctrineStatus.evolvingJurisprudence,
      officialDefinition:
          'A judicial test formulated under Article 25 and 26 providing that constitutional protection extends ONLY to religious practices that are essential and integral to that religion, as determined by the court upon historical and scriptural evidence.',
      plainLanguageExplanation:
          'Courts protect under freedom of religion only those practices that are fundamental/core to a religion. Secular, superstitious, or peripheral practices can be regulated by law.',
      purpose:
          'To separate core religious faith from secular socio-economic activities subject to state reform.',
      scope:
          'Applies to freedom of religion claims under Articles 25 and 26.',
      limitations: const ['Judiciary acts as scriptural interpreter, which has faced academic and judicial criticism.'],
      originatingCase: 'Commr., Hindu Religious Endowments, Madras v. Sri Lakshmindra Thirtha Swamiar of Sri Shirur Mutt (1954)',
      historicalContext: 'Madras Hindu Religious and Charitable Endowments Act 1951 regulating administration of Mutt properties.',
      evolution:
          'Applied in Durgah Committee (1961), Shayara Bano (2017), Sabarimala (2018). Currently referred to 9-judge bench in Sabarimala Review.',
      landmarkCases: const [
        'Shirur Mutt Case (1954)',
        'Durgah Committee, Ajmer v. Syed Hussain Ali (1961)',
        'Indian Young Lawyers Association (Sabarimala Case 2018)'
      ],
      currentPosition: 'Evolving jurisprudence, currently under 9-judge bench reference in Sabarimala Review.',
      relatedArticles: const ['25', '26'],
      relatedParts: const ['KO-PART-III'],
      pyqIds: const ['PYQ_UPSC_2020_13', 'PYQ_CAPF_2021_06'],
      examImportance: 'Critical',
      timesAsked: 32,
      trend: 'High Frequency',
      garudaExplanation:
          'Essential Religious Practices Test (Shirur Mutt 1954) determines whether a practice is protected under Art 25/26 by examining if removal of the practice alters the nature of the religion.',
      oneLineSummary: 'Constitutional protection under Art 25/26 extends only to practices essential and integral to a religion.',
      detailedExplanation: 'Shirur Mutt (1954) established that court decides what is essential based on religious tenets.',
      citations: const ['AIR 1954 SC 282'],
    ),
  ];
}
