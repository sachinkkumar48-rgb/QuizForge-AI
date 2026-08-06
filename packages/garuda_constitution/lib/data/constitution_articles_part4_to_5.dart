library;

import '../domain/entities/article_knowledge_object.dart';

/// Permanent Production Knowledge Objects for Constitutional Parts IV, IVA, and V.
class ConstitutionArticlesPart4To5 {
  static final List<ArticleKnowledgeObject> articles = [
    // PART IV - DIRECTIVE PRINCIPLES OF STATE POLICY (Art. 36 - 51)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-36',
      articleNumber: '36',
      officialTitle: 'Definition of State for Part IV',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '36',
      currentNumber: '36',
      title: 'Article 36: Definition of State',
      officialName: 'ARTICLE 36',
      description: 'In this Part, unless the context otherwise requires, "the State" has the same meaning as in Part III.',
      officialConstitutionalText:
          'In this Part, unless the context otherwise requires, "the State" has the same meaning as in Part III.',
      originalGarudaExplanation:
          'Article 36 extends the comprehensive definition of "State" from Article 12 to the Directive Principles of State Policy, binding the executive, legislature, local authorities, and statutory bodies to strive towards fulfilling DPSPs.',
      historicalBackground:
          'Adopted from the Constitution of Ireland 1937, ensuring continuity between rights enforceable against the State and policy obligations directed at the State.',
      searchKeywords: const ['Article 36', 'Definition of State', 'DPSP State Definition', 'Part IV Definition'],
      keyTakeaways: const [
        'State in Part IV has identical scope to State in Article 12 (Part III).',
        'Includes Government of India, Parliament, State Governments, State Legislatures, Local and other authorities.'
      ],
      commonMisconceptions: const [
        'Misconception: DPSP definition of State excludes local Gram Panchayats. Fact: Local bodies are explicitly part of the State definition.'
      ],
      memoryAids: const ['36 = Mirror of 12 (State Definition).'],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'RD Shetty v. International Airport Authority',
          year: 1979,
          bench: 'Supreme Court',
          legalPrinciple: 'Instrumentalities of State bound by Part IV guidelines as well as Part III fundamental rights.',
          importance: 'Extended DPSP obligations to statutory corporations.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS1-Q36', 'UPSC-CSE-2020-GS2-Q12'],
      learningObjectives: const [
        'Understand the scope of State for Directive Principles.',
        'Compare Article 36 state definition with Article 12.'
      ],
      citations: const ['Constituent Assembly Debates Vol. VII', 'Legislative Dept, Ministry of Law & Justice'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-37',
      articleNumber: '37',
      officialTitle: 'Application of the principles contained in Part IV',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '37',
      currentNumber: '37',
      title: 'Article 37: Application of principles contained in Part IV',
      officialName: 'ARTICLE 37',
      description: 'The provisions contained in this Part shall not be enforceable by any court, but the principles therein laid down are nevertheless fundamental in the governance of the country.',
      officialConstitutionalText:
          'The provisions contained in this Part shall not be enforceable by any court, but the principles therein laid down are nevertheless fundamental in the governance of the country and it shall be the duty of the State to apply these principles in making laws.',
      originalGarudaExplanation:
          'Article 37 establishes the dual nature of DPSPs: they are non-justiciable (cannot be directly enforced in courts like Fundamental Rights), yet legally binding as fundamental directives for governance and law-making by the State.',
      historicalBackground:
          'Dr. B.R. Ambedkar described DPSPs as novel features of the Constitution aimed at establishing Economic Democracy alongside Political Democracy.',
      searchKeywords: const ['Article 37', 'Non-justiciable', 'Fundamental in Governance', 'Enforceability of DPSP'],
      keyTakeaways: const [
        'DPSPs are non-justiciable: No writ lies for their non-implementation.',
        'DPSPs are fundamental in governance and impose a constitutional moral duty on legislatures.'
      ],
      commonMisconceptions: const [
        'Misconception: Non-justiciable means DPSPs have zero legal validity. Fact: Courts use DPSPs to interpret statutory ambiguity and test reasonableness under Article 19.'
      ],
      memoryAids: const ['Art 37 = Non-enforceable by courts, Fundamental in governance.'],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of Madras v. Champakam Dorairajan',
          year: 1951,
          bench: '7-Judge Bench',
          legalPrinciple: 'DPSPs cannot override Fundamental Rights in case of conflict.',
          importance: 'Initial primacy of Fundamental Rights over DPSPs.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Minerva Mills Ltd v. Union of India',
          year: 1980,
          bench: '5-Judge Bench',
          legalPrinciple: 'Harmony and balance between Part III and Part IV is an essential feature of basic structure.',
          importance: 'Established bedrock balance between FRs and DPSPs.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS1-Q37', 'UPSC-CSE-2020-GS1-Q44'],
      learningObjectives: const [
        'Analyze non-justiciability versus fundamental nature of DPSPs.',
        'Explain the evolving judicial balance between Part III and Part IV.'
      ],
      citations: const ['CAD Vol. VII', 'Minerva Mills Judgment 1980'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-38',
      articleNumber: '38',
      officialTitle: 'State to secure a social order for the promotion of welfare of the people',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '38',
      currentNumber: '38',
      title: 'Article 38: State to secure a social order for welfare of the people',
      officialName: 'ARTICLE 38',
      description: 'The State shall strive to promote the welfare of the people by securing and protecting a social order in which justice, social, economic and political, shall inform all institutions of national life.',
      officialConstitutionalText:
          '(1) The State shall strive to promote the welfare of the people by securing and protecting as effectively as it may a social order in which justice, social, economic and political, shall inform all the institutions of the national life.\n(2) The State shall, in particular, strive to minimise the inequalities in income, and endeavour to eliminate inequalities in status, facilities and opportunities, not only amongst individuals but also amongst groups of people residing in different areas or engaged in different vocations.',
      originalGarudaExplanation:
          'Article 38 is the foundational directive for establishing a Welfare State in India, directing the government to minimize economic inequalities and secure social, economic, and political justice.',
      historicalBackground:
          'Clause (2) was added by the 44th Constitutional Amendment Act, 1978 to explicitly direct the reduction of income and opportunity inequalities.',
      searchKeywords: const ['Article 38', 'Welfare State', 'Social Order', 'Minimise Inequalities', '44th Amendment'],
      keyTakeaways: const [
        'Core directive for Welfare State concept.',
        'Clause (2) added by 44th Amendment Act 1978 focusing on income and status equality.'
      ],
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act 1978',
          beforeText: 'Article 38 consisted of a single paragraph.',
          afterText: 'Article 38 renumbered as clause (1) and clause (2) inserted.',
          reason: 'To direct State action specifically against income disparity and positional inequality.',
          effectiveDate: DateTime(1979, 6, 20),
        ),
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q05', 'UPSC-CSE-2021-GS1-Q22'],
      citations: const ['44th Amendment Act Gazette', 'Ministry of Law and Justice'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-39',
      articleNumber: '39',
      officialTitle: 'Certain principles of policy to be followed by the State',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '39',
      currentNumber: '39',
      title: 'Article 39: Certain principles of policy to be followed by the State',
      officialName: 'ARTICLE 39',
      description: 'The State shall direct its policy towards securing adequate livelihood, distribution of material resources for common good, and equal pay for equal work.',
      officialConstitutionalText:
          'The State shall, in particular, direct its policy towards securing—\n(a) that the citizens, men and women equally, have the right to an adequate means of livelihood;\n(b) that the ownership and control of the material resources of the community are so distributed as best to subserve the common good;\n(c) that the operation of the economic system does not result in the concentration of wealth and means of production to the common detriment;\n(d) that there is equal pay for equal work for both men and women;\n(e) that the health and strength of workers, men and women, and the tender age of children are not abused;\n(f) that children are given opportunities and facilities to develop in a healthy manner and in conditions of freedom and dignity.',
      originalGarudaExplanation:
          'Article 39 lays down economic sub-directives focusing on adequate livelihood, equitable material resource distribution (39b), prevention of wealth concentration (39c), equal pay for equal work (39d), and protection of worker/child health.',
      historicalBackground:
          'Clause (f) was modified by the 42nd Amendment Act 1976 to emphasize healthy development and dignity for children.',
      searchKeywords: const ['Article 39', 'Equal Pay for Equal Work', 'Material Resources Common Good', '39b and 39c', 'Wealth Concentration'],
      keyTakeaways: const [
        'Articles 39(b) and 39(c) form the socialist core of DPSPs, protected under Article 31C.',
        'Article 39(d) mandates Equal Pay for Equal Work for men and women.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Sanjeev Coke Mfg Co v. Bharat Coking Coal Ltd',
          year: 1983,
          bench: 'Supreme Court',
          legalPrinciple: 'Laws enacted to give effect to Article 39(b) and 39(c) override Articles 14 and 19.',
          importance: 'Affirmed immunity under Article 31C for nationalisation laws.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Randhir Singh v. Union of India',
          year: 1982,
          bench: 'Supreme Court',
          legalPrinciple: 'Equal pay for equal work is a constitutional goal enforceable through Article 32 read with Article 14.',
          importance: 'Elevated 39(d) to enforceable constitutional status.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q11', 'UPSC-CSE-2022-GS1-Q30'],
      citations: const ['42nd Amendment Act 1976', 'Sanjeev Coke Case 1983'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-39A',
      articleNumber: '39A',
      officialTitle: 'Equal justice and free legal aid',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '39A',
      currentNumber: '39A',
      title: 'Article 39A: Equal justice and free legal aid',
      officialName: 'ARTICLE 39A',
      description: 'The State shall secure that the operation of the legal system promotes justice on a basis of equal opportunity and provide free legal aid.',
      officialConstitutionalText:
          'The State shall secure that the operation of the legal system promotes justice, on a basis of equal opportunity, and shall, in particular, provide free legal aid, by suitable legislation or schemes or in any other way, to ensure that opportunities for securing justice are not denied to any citizen by reason of economic or other disabilities.',
      originalGarudaExplanation:
          'Inserted by the 42nd Amendment Act 1976, Article 39A guarantees equal access to justice and mandates free legal aid for indigent citizens, laying the foundation for NALSA and Legal Services Authorities Act 1987.',
      historicalBackground:
          'Enacted following recommendations of the Krishna Iyer Committee and Bhagwati Committee on legal aid.',
      searchKeywords: const ['Article 39A', 'Free Legal Aid', 'Equal Justice', 'NALSA', '42nd Amendment'],
      keyTakeaways: const [
        'Inserted by 42nd Amendment Act 1976.',
        'Led to enactment of Legal Services Authorities Act 1987 and establishment of NALSA/SALSA.'
      ],
      effectiveDate: DateTime(1977, 1, 3),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'MH Hoskot v. State of Maharashtra',
          year: 1978,
          bench: 'Supreme Court',
          legalPrinciple: 'Right to free legal aid is an integral component of fair procedure under Article 21.',
          importance: 'Linked Article 39A free legal aid directly to Article 21 fundamental right.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2019-GS2-Q04', 'UPSC-CSE-2023-GS2-Q08'],
      citations: const ['42nd Amendment Act 1976', 'NALSA Act 1987'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-40',
      articleNumber: '40',
      officialTitle: 'Organisation of village panchayats',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '40',
      currentNumber: '40',
      title: 'Article 40: Organisation of village panchayats',
      officialName: 'ARTICLE 40',
      description: 'The State shall take steps to organise village panchayats and endow them with such powers and authority as may be necessary to enable them to function as units of self-government.',
      officialConstitutionalText:
          'The State shall take steps to organise village panchayats and endow them with such powers and authority as may be necessary to enable them to function as units of self-government.',
      originalGarudaExplanation:
          'Article 40 embodies Gandhian constitutional vision by directing the organization of Village Panchayats as units of local self-government, eventually constitutionalized via the 73rd Amendment Act 1992 (Part IX).',
      historicalBackground:
          'Drafted following intense debate in Constituent Assembly led by K.S. Santhanam advocating Gandhian Gram Swaraj.',
      searchKeywords: const ['Article 40', 'Village Panchayats', 'Gandhian Principle', 'Local Self Government', '73rd Amendment'],
      keyTakeaways: const [
        'Primary Gandhian DPSP in Part IV.',
        'Operationalized nationwide by 73rd Constitutional Amendment Act 1992.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2016-GS1-Q15', 'UPSC-CSE-2021-GS2-Q02'],
      citations: const ['CAD Vol. VII', 'Balwant Rai Mehta Committee 1957'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-44',
      articleNumber: '44',
      officialTitle: 'Uniform civil code for the citizens',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '44',
      currentNumber: '44',
      title: 'Article 44: Uniform civil code for the citizens',
      officialName: 'ARTICLE 44',
      description: 'The State shall endeavour to secure for the citizens a Uniform Civil Code throughout the territory of India.',
      officialConstitutionalText:
          'The State shall endeavour to secure for the citizens a Uniform Civil Code throughout the territory of India.',
      originalGarudaExplanation:
          'Article 44 directs the State to secure a Uniform Civil Code (UCC) replacing personal religious laws governing marriage, divorce, succession, and adoption with a common civil law across India.',
      historicalBackground:
          'Vigorous debates in Constituent Assembly with K.M. Munshi and Dr. Ambedkar supporting UCC for national integration and gender justice.',
      searchKeywords: const ['Article 44', 'Uniform Civil Code', 'UCC', 'Personal Laws', 'Gender Justice'],
      keyTakeaways: const [
        'Liberal-Intellectual principle aimed at national consolidation and gender parity.',
        'Goa is currently the only Indian State with a uniform civil code (Portuguese Civil Code 1867).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Mohd. Ahmed Khan v. Shah Bano Begum',
          year: 1985,
          bench: '5-Judge Bench',
          legalPrinciple: 'Supreme Court urged Government to enact Uniform Civil Code for national integrity.',
          importance: 'Landmark judicial call for Article 44 implementation.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Sarla Mudgal v. Union of India',
          year: 1995,
          bench: 'Supreme Court',
          legalPrinciple: 'Solemnization of second marriage after converting to Islam without dissolving first marriage is void.',
          importance: 'Reiterated urgent need for UCC under Article 44.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS2-Q14', 'UPSC-CSE-2023-GS2-Q19'],
      citations: const ['CAD Vol. VII', 'Shah Bano Judgment 1985'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-45',
      articleNumber: '45',
      officialTitle: 'Provision for early childhood care and education to children below six years',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '45',
      currentNumber: '45',
      title: 'Article 45: Early childhood care and education below six years',
      officialName: 'ARTICLE 45',
      description: 'The State shall endeavour to provide early childhood care and education for all children until they complete the age of six years.',
      officialConstitutionalText:
          'The State shall endeavour to provide early childhood care and education for all children until they complete the age of six years.',
      originalGarudaExplanation:
          'Substituted by the 86th Amendment Act 2002 when free education for ages 6-14 was moved to Fundamental Right Article 21A, leaving Article 45 to focus on early childhood care (0-6 years).',
      historicalBackground:
          'Originally mandated free education for 6-14 years within 10 years of Constitution commencement.',
      searchKeywords: const ['Article 45', 'Early Childhood Care', '86th Amendment', 'Pre-school Education', 'Anganwadi'],
      keyTakeaways: const [
        'Substituted by 86th Constitutional Amendment Act 2002.',
        'Complements Article 21A (Rights 6-14 years) by covering early childhood development (0-6 years).'
      ],
      effectiveDate: DateTime(2002, 12, 12),
      pyqIds: const ['UPSC-CSE-2019-GS1-Q29'],
      citations: const ['86th Amendment Act 2002', 'RTE Act 2009'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-50',
      articleNumber: '50',
      officialTitle: 'Separation of judiciary from executive',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '50',
      currentNumber: '50',
      title: 'Article 50: Separation of judiciary from executive',
      officialName: 'ARTICLE 50',
      description: 'The State shall take steps to separate the judiciary from the executive in the public services of the State.',
      officialConstitutionalText:
          'The State shall take steps to separate the judiciary from the executive in the public services of the State.',
      originalGarudaExplanation:
          'Article 50 directs the structural separation of judicial functions from executive magistrate control to safeguard judicial independence and impartiality in administration of justice.',
      historicalBackground:
          'Achieved across India through the Criminal Procedure Code (CrPC) 1973 separating Judicial Magistrates from Executive Magistrates.',
      searchKeywords: const ['Article 50', 'Separation of Powers', 'Judiciary Executive Separation', 'CrPC 1973'],
      keyTakeaways: const [
        'Liberal-Intellectual directive establishing separation of judicial functions.',
        'Fully operationalized via CrPC 1973 creating independent judicial magistrate cadre.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2020-GS2-Q01'],
      citations: const ['CrPC 1973', 'Law Commission 14th Report'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-51',
      articleNumber: '51',
      officialTitle: 'Promotion of international peace and security',
      part: 'Part IV',
      chapter: 'Directive Principles of State Policy',
      originalNumber: '51',
      currentNumber: '51',
      title: 'Article 51: Promotion of international peace and security',
      officialName: 'ARTICLE 51',
      description: 'The State shall endeavour to promote international peace, foster respect for international law, and encourage settlement of disputes by arbitration.',
      officialConstitutionalText:
          'The State shall endeavour to—\n(a) promote international peace and security;\n(b) maintain just and honourable relations between nations;\n(c) foster respect for international law and treaty obligations in the dealings of organised peoples with one another; and\n(d) encourage settlement of international disputes by arbitration.',
      originalGarudaExplanation:
          'Article 51 serves as the constitutional anchor for India\'s foreign policy, directing international peace, treaty adherence, and peaceful dispute resolution.',
      historicalBackground:
          'Reflects Panchsheel and non-alignment principles championed by Jawaharlal Nehru.',
      searchKeywords: const ['Article 51', 'International Peace', 'Treaty Obligations', 'Foreign Policy DPSP', 'Arbitration'],
      keyTakeaways: const [
        'Constitutional basis of Indian Foreign Policy.',
        'Promotes international treaty respect and arbitration.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q18'],
      citations: const ['CAD Vol. VII', 'MEA Treaty Series'],
    ),

    // PART IVA - FUNDAMENTAL DUTIES (Art. 51A)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-51A',
      articleNumber: '51A',
      officialTitle: 'Fundamental duties',
      part: 'Part IVA',
      chapter: 'Fundamental Duties',
      originalNumber: '51A',
      currentNumber: '51A',
      title: 'Article 51A: Fundamental duties of citizens',
      officialName: 'ARTICLE 51A',
      description: 'It shall be the duty of every citizen of India to abide by the Constitution, cherish freedom ideals, protect sovereignty, and promote harmony.',
      officialConstitutionalText:
          'It shall be the duty of every citizen of India—\n(a) to abide by the Constitution and respect its ideals and institutions, the National Flag and the National Anthem;\n(b) to cherish and follow the noble ideals which inspired our national struggle for freedom;\n(c) to uphold and protect the sovereignty, unity and integrity of India;\n(d) to defend the country and render national service when called upon to do so;\n(e) to promote harmony and the spirit of common brotherhood amongst all the people of India transcending religious, linguistic and regional or sectional diversities; to renounce practices derogatory to the dignity of women;\n(f) to value and preserve the rich heritage of our composite culture;\n(g) to protect and improve the natural environment including forests, lakes, rivers and wild life, and to have compassion for living creatures;\n(h) to develop the scientific temper, humanism and the spirit of inquiry and reform;\n(i) to safeguard public property and to abjure violence;\n(j) to strive towards excellence in all spheres of individual and collective activity so that the nation constantly rises to higher levels of endeavour and achievement;\n(k) who is a parent or guardian to provide opportunities for education to his child or, as the case may be, ward between the age of six and fourteen years.',
      originalGarudaExplanation:
          'Inserted by the 42nd Amendment Act 1976 on recommendations of Swaran Singh Committee (10 duties, clause k added by 86th Amendment Act 2002), setting 11 statutory duties for Indian citizens.',
      historicalBackground:
          'Inspired by the USSR Constitution. JS Verma Committee (1999) identified existing legal provisions enforcing fundamental duties.',
      searchKeywords: const ['Article 51A', 'Fundamental Duties', 'Swaran Singh Committee', '42nd Amendment', '86th Amendment', 'Scientific Temper'],
      keyTakeaways: const [
        'Non-justiciable moral obligations applicable exclusively to citizens of India.',
        '10 duties added by 42nd Amendment 1976; 11th duty (k) added by 86th Amendment 2002.'
      ],
      effectiveDate: DateTime(1977, 1, 3),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '42nd Constitutional Amendment Act 1976',
          beforeText: 'Part IVA did not exist in the Constitution.',
          afterText: 'Part IVA inserted containing Article 51A (clauses a to j).',
          reason: 'To introduce civic duties alongside fundamental rights.',
          effectiveDate: DateTime(1977, 1, 3),
        ),
        ArticleAmendmentRecord(
          amendmentName: '86th Constitutional Amendment Act 2002',
          beforeText: 'Article 51A contained 10 duties (a to j).',
          afterText: 'Clause (k) added regarding duty of parent/guardian to provide education (6-14 years).',
          reason: 'To complement Fundamental Right Article 21A.',
          effectiveDate: DateTime(2002, 12, 12),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Bijoe Emmanuel v. State of Kerala',
          year: 1986,
          bench: 'Supreme Court',
          legalPrinciple: 'Standing respectfully during National Anthem fulfills Duty 51A(a); singing is not compulsory if religious conscience forbids under 25.',
          importance: 'Balanced 51A duties with Article 19(1)(a) and 25 rights.',
        ),
        ArticleCaseLawRecord(
          caseName: 'AIIMS Students Union v. AIIMS',
          year: 2002,
          bench: 'Supreme Court',
          legalPrinciple: 'Fundamental duties are equally important as Fundamental Rights for constitutional interpretation.',
          importance: 'Reiterated high constitutional value of Part IVA.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS1-Q21', 'UPSC-CSE-2017-GS1-Q40', 'UPSC-CSE-2021-GS2-Q11'],
      citations: const ['Swaran Singh Committee Report 1976', 'JS Verma Committee Report 1999'],
    ),

    // PART V - THE UNION (Art. 52 - 151)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-52',
      articleNumber: '52',
      officialTitle: 'The President of India',
      part: 'Part V',
      chapter: 'The Executive',
      originalNumber: '52',
      currentNumber: '52',
      title: 'Article 52: The President of India',
      officialName: 'ARTICLE 52',
      description: 'There shall be a President of India.',
      officialConstitutionalText: 'There shall be a President of India.',
      originalGarudaExplanation:
          'Article 52 creates the office of the President of India as the constitutional Head of State and supreme commander of armed forces.',
      historicalBackground:
          'Constituent Assembly selected parliamentary form of executive where President functions as de jure head while Prime Minister acts as de facto head.',
      searchKeywords: const ['Article 52', 'President of India', 'Head of State', 'Executive Head'],
      keyTakeaways: const [
        'Establishes the permanent office of the President of India.',
        'De jure executive head of the Union.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2018-GS2-Q01'],
      citations: const ['CAD Vol. VII', 'Rashtrapati Bhavan Official Record'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-53',
      articleNumber: '53',
      officialTitle: 'Executive power of the Union',
      part: 'Part V',
      chapter: 'The Executive',
      originalNumber: '53',
      currentNumber: '53',
      title: 'Article 53: Executive power of the Union',
      officialName: 'ARTICLE 53',
      description: 'The executive power of the Union shall be vested in the President and exercised directly or through officers subordinate to him.',
      officialConstitutionalText:
          '(1) The executive power of the Union shall be vested in the President and shall be exercised by him either directly or through officers subordinate to him in accordance with this Constitution.\n(2) Without prejudice to the generality of the foregoing provision, the supreme command of the Defence Forces of the Union shall be vested in the President and the exercise thereof shall be regulated by law.',
      originalGarudaExplanation:
          'Vests Union executive authority and Supreme Command of Armed Forces in the President, to be exercised per constitutional advice (Article 74).',
      historicalBackground:
          'Affirmed in Shamsher Singh 1974 that President acts on Council of Ministers aid and advice.',
      searchKeywords: const ['Article 53', 'Executive Power Union', 'Supreme Commander Armed Forces', 'Aid and Advice'],
      keyTakeaways: const [
        'Vests supreme command of Defence Forces in President.',
        'Executive power exercised through subordinate officers per Constitution.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Shamsher Singh v. State of Punjab',
          year: 1974,
          bench: '7-Judge Bench',
          legalPrinciple: 'President and Governors are constitutional heads acting on advice of Council of Ministers.',
          importance: 'Settled constitutional position of Presidential executive power.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2019-GS2-Q05'],
      citations: const ['Shamsher Singh Judgment 1974'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-54',
      articleNumber: '54',
      officialTitle: 'Election of President',
      part: 'Part V',
      chapter: 'The Executive',
      originalNumber: '54',
      currentNumber: '54',
      title: 'Article 54: Election of President',
      officialName: 'ARTICLE 54',
      description: 'The President shall be elected by an electoral college consisting of elected members of both Houses of Parliament and elected members of State Legislative Assemblies.',
      officialConstitutionalText:
          'The President shall be elected by the members of an electoral college consisting of—\n(a) the elected members of both Houses of Parliament; and\n(b) the elected members of the Legislative Assemblies of the States.',
      originalGarudaExplanation:
          'Defines the Electoral College for Presidential election comprising elected MPs and elected MLAs (including NCT Delhi and Puducherry added by 70th Amendment 1992). Nominated members are excluded.',
      historicalBackground:
          'Explanation added by 70th Amendment Act 1992 clarifying State includes NCT Delhi and Union Territory of Puducherry.',
      searchKeywords: const ['Article 54', 'President Electoral College', 'Elected MPs MLAs', '70th Amendment', 'President Election'],
      keyTakeaways: const [
        'Only ELECTED members vote (Nominated MPs/MLAs & MLCs excluded).',
        'Includes elected MLAs of Delhi & Puducherry (70th Amendment 1992).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q02', 'UPSC-CSE-2022-GS2-Q01'],
      citations: const ['Presidential and Vice-Presidential Elections Act 1952'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-72',
      articleNumber: '72',
      officialTitle: 'Power of President to grant pardons, etc.',
      part: 'Part V',
      chapter: 'The Executive',
      originalNumber: '72',
      currentNumber: '72',
      title: 'Article 72: Power of President to grant pardons',
      officialName: 'ARTICLE 72',
      description: 'The President shall have power to grant pardons, reprieves, respites or remissions of punishment or to suspend, remit or commute sentences.',
      officialConstitutionalText:
          '(1) The President shall have the power to grant pardons, reprieves, respites or remissions of punishment or to suspend, remit or commute the sentence of any person convicted of any offence—\n(a) in all cases where the punishment or sentence is by a Court Martial;\n(b) in all cases where the punishment or sentence is for an offence against any law relating to a matter to which the executive power of the Union extends;\n(c) in all cases where the sentence is a sentence of death.',
      originalGarudaExplanation:
          'Grants the President executive clemency power (pardon, reprieve, respite, remission, commutation) over court-martial sentences, Union law offenses, and all death sentences.',
      historicalBackground:
          'Kehar Singh 1989 established that mercy power is an executive function subject to limited judicial review against arbitrariness.',
      searchKeywords: const ['Article 72', 'Pardoning Power President', 'Pardon Reprieve Respite Remission Commutation', 'Court Martial Clemency'],
      keyTakeaways: const [
        'Covers 5 clemency types: Pardon, Reprieve, Respite, Remission, Commutation.',
        'Presidential power extends to Court Martial sentences and all Death sentences (unlike Governor under 161).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Kehar Singh v. Union of India',
          year: 1989,
          bench: '5-Judge Bench',
          legalPrinciple: 'Presidential pardon is an executive act; President can scrutinize evidence afresh.',
          importance: 'Defined scope of judicial review over Article 72.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Shatrughan Chauhan v. Union of India',
          year: 2014,
          bench: '3-Judge Bench',
          legalPrinciple: 'Inordinate and unexplained delay in deciding mercy petition is a ground for commuting death sentence to life imprisonment.',
          importance: 'Established protection against delay in mercy decisions.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2016-GS2-Q10', 'UPSC-CSE-2021-GS2-Q09'],
      citations: const ['Kehar Singh Case 1989', 'Shatrughan Chauhan Case 2014'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-74',
      articleNumber: '74',
      officialTitle: 'Council of Ministers to aid and advise President',
      part: 'Part V',
      chapter: 'The Executive',
      originalNumber: '74',
      currentNumber: '74',
      title: 'Article 74: Council of Ministers to aid and advise President',
      officialName: 'ARTICLE 74',
      description: 'There shall be a Council of Ministers with the Prime Minister at the head to aid and advise the President who shall act in accordance with such advice.',
      officialConstitutionalText:
          '(1) There shall be a Council of Ministers with the Prime Minister at the head to aid and advise the President who shall, in the exercise of his functions, act in accordance with such advice:\nProvided that the President may require the Council of Ministers to reconsider such advice... and the President shall act in accordance with the advice tendered after such reconsideration.\n(2) The question whether any, and if so what, advice was tendered by Ministers to the President shall not be inquired into in any court.',
      originalGarudaExplanation:
          'Article 74 forms the core of parliamentary democracy, making Cabinet advice binding on the President (42nd & 44th Amendments) and barring judicial scrutiny of advice tendered.',
      historicalBackground:
          '42nd Amendment 1976 made advice strictly binding; 44th Amendment 1978 added proviso allowing President one reconsiderative option.',
      searchKeywords: const ['Article 74', 'Aid and Advice', 'Council of Ministers', '42nd Amendment', '44th Amendment', 'Cabinet Advice Binding'],
      keyTakeaways: const [
        'Advice of Council of Ministers led by PM is legally binding on President.',
        'President has one-time power of reconsideration under 44th Amendment 1978.',
        'Advice tendered by ministers is exempt from judicial inquiry (Art 74(2)).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '42nd Amendment Act 1976',
          beforeText: 'President shall exercise functions with aid and advice of Council of Ministers.',
          afterText: 'President shall act in accordance with such advice.',
          reason: 'To explicitly bind President to Cabinet advice.',
          effectiveDate: DateTime(1977, 1, 3),
        ),
        ArticleAmendmentRecord(
          amendmentName: '44th Amendment Act 1978',
          beforeText: 'President had to accept advice immediately.',
          afterText: 'Proviso added enabling President to send advice back once for reconsideration.',
          reason: 'To provide constitutional check against hasty executive action.',
          effectiveDate: DateTime(1979, 6, 20),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'SR Bommai v. Union of India',
          year: 1994,
          bench: '9-Judge Bench',
          legalPrinciple: 'Article 74(2) bars inquiry into advice itself, but courts can examine material basis on which advice was formed.',
          importance: 'Clarified scope of judicial review under Article 74(2).',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS2-Q03', 'UPSC-CSE-2020-GS2-Q14'],
      citations: const ['44th Amendment Act 1978', 'SR Bommai Judgment 1994'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-75',
      articleNumber: '75',
      officialTitle: 'Other provisions as to Ministers',
      part: 'Part V',
      chapter: 'The Executive',
      originalNumber: '75',
      currentNumber: '75',
      title: 'Article 75: Other provisions as to Ministers',
      officialName: 'ARTICLE 75',
      description: 'The Prime Minister shall be appointed by the President and Council of Ministers shall be collectively responsible to Lok Sabha.',
      officialConstitutionalText:
          '(1) The Prime Minister shall be appointed by the President and the other Ministers shall be appointed by the President on the advice of the Prime Minister.\n(1A) The total number of Ministers, including the Prime Minister, in the Council of Ministers shall not exceed fifteen per cent. of the total number of members of the House of the People.\n(3) The Council of Ministers shall be collectively responsible to the House of the People.',
      originalGarudaExplanation:
          'Article 75 stipulates PM appointment, minister appointments, 15% ceiling on Council size (91st Amendment 2003), individual pleasure of President (75(2)), and collective responsibility to Lok Sabha (75(3)).',
      historicalBackground:
          'Clause (1A) cap of 15% added by 91st Amendment Act 2003 to curb jumbo cabinets.',
      searchKeywords: const ['Article 75', 'Collective Responsibility', 'Prime Minister Appointment', '15 Percent Ceiling', '91st Amendment'],
      keyTakeaways: const [
        'Council of Ministers is collectively responsible to Lok Sabha (Art 75(3)).',
        'Cabinet size capped at 15% of Lok Sabha strength by 91st Amendment 2003.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q07', 'UPSC-CSE-2022-GS2-Q11'],
      citations: const ['91st Amendment Act 2003'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-110',
      articleNumber: '110',
      officialTitle: 'Definition of "Money Bills"',
      part: 'Part V',
      chapter: 'Parliament',
      originalNumber: '110',
      currentNumber: '110',
      title: 'Article 110: Definition of Money Bills',
      officialName: 'ARTICLE 110',
      description: 'A bill shall be deemed to be a Money Bill if it contains only provisions dealing with tax imposition, borrowing, or Consolidated Fund custody.',
      officialConstitutionalText:
          '(1) For the purposes of this Chapter, a bill shall be deemed to be a Money Bill if it contains only provisions dealing with all or any of the following matters, namely:—\n(a) the imposition, abolition, remission, alteration or regulation of any tax;\n(b) the regulation of the borrowing of money or the giving of any guarantee by the Government of India;\n(c) the custody of the Consolidated Fund or the Contingency Fund of India...\n(3) If any question arises whether a Bill is a Money Bill or not, the decision of the Speaker of the House of the People thereon shall be final.',
      originalGarudaExplanation:
          'Defines Money Bills exclusively covering financial tax/borrowing/Consolidated Fund matters and confers final certification authority on Lok Sabha Speaker.',
      historicalBackground:
          'Aadhaar case 2018 examined Speaker\'s certification under Article 110(3).',
      searchKeywords: const ['Article 110', 'Money Bill', 'Speaker Certification Final', 'Taxation Financial Bill', 'Consolidated Fund'],
      keyTakeaways: const [
        'Money Bill introduced ONLY in Lok Sabha with prior recommendation of President.',
        'Speaker\'s decision under 110(3) is final (subject to judicial review for colorable exercise).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'KS Puttaswamy (Aadhaar-5J) v. Union of India',
          year: 2018,
          bench: '5-Judge Bench',
          legalPrinciple: 'Speaker\'s decision certifying Money Bill under 110(3) is subject to judicial review.',
          importance: 'Tested Money Bill certification standards.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q04', 'UPSC-CSE-2023-GS2-Q15'],
      citations: const ['Aadhaar Judgment 2018', 'Rules of Procedure Lok Sabha'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-123',
      articleNumber: '123',
      officialTitle: 'Power of President to promulgate Ordinances during recess of Parliament',
      part: 'Part V',
      chapter: 'Legislative Powers of the President',
      originalNumber: '123',
      currentNumber: '123',
      title: 'Article 123: Power of President to promulgate Ordinances',
      officialName: 'ARTICLE 123',
      description: 'If at any time except when both Houses of Parliament are in session, President is satisfied of immediate action, he may promulgate Ordinances.',
      officialConstitutionalText:
          '(1) If at any time, except when both Houses of Parliament are in session, the President is satisfied that circumstances exist which render it necessary for him to take immediate action, he may promulgate such Ordinances as the circumstances appear to him to require.\n(2) An Ordinance promulgated under this article shall have the same force and effect as an Act of Parliament, but every such Ordinance—\n(a) shall be laid before both Houses of Parliament and shall cease to operate at the expiration of six weeks from the reassembly of Parliament...',
      originalGarudaExplanation:
          'Vests temporary emergency legislative power in the President to issue Ordinances during parliamentary recess, valid for maximum 6 months and 6 weeks unless approved.',
      historicalBackground:
          'DC Wadhwa 1987 and Krishna Kumar Singh 2017 declared repromulgation of Ordinances without legislative placement a fraud on Constitution.',
      searchKeywords: const ['Article 123', 'Ordinance Making Power', 'President Ordinance', 'Recess of Parliament', '6 Weeks Expiry'],
      keyTakeaways: const [
        'Can only be issued when at least one House of Parliament is not in session.',
        'Maximum life: 6 months + 6 weeks.',
        'Repromulgation without parliamentary approval is unconstitutional.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'DC Wadhwa v. State of Bihar',
          year: 1987,
          bench: '5-Judge Bench',
          legalPrinciple: 'Repromulgation of ordinances without placing them before legislature is a fraud on the Constitution.',
          importance: 'Banned routine re-promulgation of ordinances.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Krishna Kumar Singh v. State of Bihar',
          year: 2017,
          bench: '7-Judge Bench',
          legalPrinciple: 'Presidential satisfaction under Article 123 is subject to judicial review for bad faith.',
          importance: 'Referred ordinance-making to strict judicial review.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS2-Q08', 'UPSC-CSE-2020-GS2-Q07'],
      citations: const ['DC Wadhwa 1987', 'Krishna Kumar Singh 2017'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-124',
      articleNumber: '124',
      officialTitle: 'Establishment and constitution of Supreme Court',
      part: 'Part V',
      chapter: 'The Union Judiciary',
      originalNumber: '124',
      currentNumber: '124',
      title: 'Article 124: Establishment and constitution of Supreme Court',
      officialName: 'ARTICLE 124',
      description: 'There shall be a Supreme Court of India consisting of a Chief Justice of India and other Judges prescribed by Parliament.',
      officialConstitutionalText:
          '(1) There shall be a Supreme Court of India consisting of a Chief Justice of India and, until Parliament by law prescribes a larger number, of not more than seven other Judges.\n(2) Every Judge of the Supreme Court shall be appointed by the President by warrant under his hand and seal after consultation with such of the Judges of the Supreme Court and of the High Courts in the States as the President may deem necessary...',
      originalGarudaExplanation:
          'Establishes Supreme Court of India, judicial qualifications, Collegium consultation process, and removal by Parliamentary impeachment under 124(4).',
      historicalBackground:
          'Evolved from 1950 (8 judges) to 34 judges today. NJAC 99th Amendment struck down in 2015 restoring Collegium system.',
      searchKeywords: const ['Article 124', 'Supreme Court Establishment', 'CJI Appointment', 'Collegium System', 'NJAC Struck Down', 'Impeachment Judge'],
      keyTakeaways: const [
        'Supreme Court judge sanctioned strength determined by Parliament (currently 34).',
        'Removal under 124(4) requires special majority of both Houses on grounds of proved misbehaviour or incapacity.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Supreme Court Advocates-on-Record Association (NJAC)',
          year: 2015,
          bench: '5-Judge Bench',
          legalPrinciple: '99th Constitutional Amendment and NJAC Act declared unconstitutional as violating judicial independence (basic structure).',
          importance: 'Restored Collegium system for judicial appointments.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS2-Q12', 'UPSC-CSE-2021-GS2-Q05'],
      citations: const ['Judges Transfer Cases I-IV', 'Supreme Court (Number of Judges) Amendment Act 2019'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-148',
      articleNumber: '148',
      officialTitle: 'Comptroller and Auditor-General of India',
      part: 'Part V',
      chapter: 'Comptroller and Auditor-General of India',
      originalNumber: '148',
      currentNumber: '148',
      title: 'Article 148: Comptroller and Auditor-General of India',
      officialName: 'ARTICLE 148',
      description: 'There shall be a Comptroller and Auditor-General of India appointed by the President and removable only like a Judge of the Supreme Court.',
      officialConstitutionalText:
          '(1) There shall be a Comptroller and Auditor-General of India who shall be appointed by the President by warrant under his hand and seal and shall only be removed from office in like manner and on the like grounds as a Judge of the Supreme Court.',
      originalGarudaExplanation:
          'Establishes CAG as guardian of public purse, independent constitutional authority removable only like SC judge, auditing Union and State accounts.',
      historicalBackground:
          'Dr. B.R. Ambedkar stated CAG is the most important officer in the Constitution of India.',
      searchKeywords: const ['Article 148', 'CAG', 'Comptroller Auditor General', 'Guardian Public Purse', 'Audit Authority'],
      keyTakeaways: const [
        'Independent constitutional authority appointed by President.',
        'Removed like SC Judge (proven misbehaviour/incapacity via special majority).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2016-GS2-Q04', 'UPSC-CSE-2022-GS2-Q18'],
      citations: const ['CAG (Duties, Powers and Conditions of Service) Act 1971'],
    ),
  ];
}
