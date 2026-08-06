library;

import 'constitution_articles_part3.dart';
import 'constitution_articles_part4_to_5.dart';
import 'constitution_articles_part6_to_10.dart';
import 'constitution_articles_part11_to_15.dart';
import 'constitution_articles_part16_to_22.dart';
import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_enums.dart';
import '../domain/entities/constitution_metadata.dart';
import '../domain/entities/part_knowledge_object.dart';
import '../domain/entities/preamble_knowledge_object.dart';
import '../domain/entities/schedule_knowledge_object.dart';
import '../templates/editorial_templates.dart';

/// Permanent Seeded Official Repository Data for the GARUDA Constitution Library.
/// Contains Metadata, Preamble, Parts, Schedules, and Articles across all Constitutional Parts.
class ConstitutionSeedData {
  static final List<ArticleKnowledgeObject> articles = [
    ...ConstitutionArticlesPart3.articles,
    ...ConstitutionArticlesPart4To5.articles,
    ...ConstitutionArticlesPart6To10.articles,
    ...ConstitutionArticlesPart11To15.articles,
    ...ConstitutionArticlesPart16To22.articles,
  ];

  static final ConstitutionMetadata metadata = ConstitutionMetadata(

    title: 'Constitution of India',
    dateAdopted: DateTime(1949, 11, 26),
    dateEnforced: DateTime(1950, 1, 26),
    constituentAssembly:
        'Constituent Assembly of India (Dr. B.R. Ambedkar, Drafting Committee Chairman; Dr. Rajendra Prasad, President)',
    originalArticles: 395,
    currentArticles: 448,
    originalParts: 22,
    currentParts: 25,
    originalSchedules: 8,
    currentSchedules: 12,
    currentAmendments: 106,
    officialSources: const [
      'Legislative Department, Ministry of Law and Justice, Government of India',
      'Gazette of India Extraordinary',
      'Constituent Assembly Debates (Official Report, Lok Sabha Secretariat)',
      'Supreme Court Reports (SCR) & All India Reporter (AIR)',
    ],
  );

  static final PreambleKnowledgeObject preamble = PreambleKnowledgeObject(
    objectId: 'KO_CONST_PREAMBLE',
    title: 'Preamble to the Constitution of India',
    officialName: 'Preamble',
    description:
        'WE, THE PEOPLE OF INDIA, having solemnly resolved to constitute India into a SOVEREIGN SOCIALIST SECULAR DEMOCRATIC REPUBLIC and to secure to all its citizens: JUSTICE, social, economic and political; LIBERTY of thought, expression, belief, faith and worship; EQUALITY of status and of opportunity; and to promote among them all FRATERNITY assuring the dignity of the individual and the unity and integrity of the Nation; IN OUR CONSTITUENT ASSEMBLY this twenty-sixth day of November, 1949, do HEREBY ADOPT, ENACT AND GIVE TO OURSELVES THIS CONSTITUTION.',
    officialText:
        'WE, THE PEOPLE OF INDIA, having solemnly resolved to constitute India into a SOVEREIGN SOCIALIST SECULAR DEMOCRATIC REPUBLIC and to secure to all its citizens: JUSTICE, social, economic and political; LIBERTY of thought, expression, belief, faith and worship; EQUALITY of status and of opportunity; and to promote among them all FRATERNITY assuring the dignity of the individual and the unity and integrity of the Nation; IN OUR CONSTITUENT ASSEMBLY this twenty-sixth day of November, 1949, do HEREBY ADOPT, ENACT AND GIVE TO OURSELVES THIS CONSTITUTION.',
    objectives: const [
      'JUSTICE (Social, Economic, and Political)',
      'LIBERTY (of Thought, Expression, Belief, Faith, and Worship)',
      'EQUALITY (of Status and of Opportunity)',
      'FRATERNITY (Assuring Dignity of Individual and Unity and Integrity of Nation)',
    ],
    historicalBackground:
        'The Preamble is based on the "Objectives Resolution", drafted and moved by Pandit Jawaharlal Nehru on December 13, 1946, and unanimously adopted by the Constituent Assembly on January 22, 1947.',
    constituentAssemblyReferences: const [
      'CAD Vol. X (October 17, 1949) - Motion on Preamble by Hasrat Mohani and Acharya Kripalani',
      'CAD Vol. XI (November 26, 1949) - Adoption of Constitution by Constituent Assembly',
      'Dr. B.R. Ambedkar speech on the tripartite principles of Liberty, Equality, and Fraternity',
      'K.M. Munshi statement describing Preamble as the "Political Horoscope of the Sovereign Democratic Republic"',
    ],
    fortySecondAmendmentChanges: const [
      'The Constitution (Forty-second Amendment) Act, 1976 amended the Preamble for the first and only time.',
      'Added words "SOCIALIST" and "SECULAR" between "SOVEREIGN" and "DEMOCRATIC".',
      'Substituted "unity of the Nation" with "unity and integrity of the Nation".',
    ],
    relevantJudgments: const [
      'Berubari Union Case (1960): SC held Preamble key to open the mind of makers but NOT part of Constitution.',
      'Kesavananda Bharati v. State of Kerala (1973): SC reversed Berubari, ruling Preamble IS part of Constitution and subject to Art 368 amendment provided Basic Structure is maintained.',
      'SR Bommai v. Union of India (1994): SC ruled Secularism is part of Basic Structure as enshrined in Preamble.',
      'LIC of India v. Consumer Education & Research Centre (1995): SC reaffirmed Preamble is an integral part of Constitution.',
    ],
    editorialNotes:
        'The Preamble embodies the fundamental values and philosophy upon which the Constitution is based. It is neither a source of power to legislature nor a prohibition upon powers. It is non-justiciable (not enforceable in court of law).',
    officialSource:
        'Legislative Department, Ministry of Law and Justice / Constituent Assembly Debates',
    status: ConstitutionStatus.active,
    version: 1,
    effectiveDate: DateTime(1950, 1, 26),
    keywords: const [
      'Preamble',
      'Sovereign',
      'Socialist',
      'Secular',
      'Democratic',
      'Republic',
      'Justice',
      'Liberty',
      'Equality',
      'Fraternity',
      'Objectives Resolution',
      'Basic Structure',
    ],
    aliases: const [
      'Preamble',
      'Identity Card of the Constitution',
      'Political Horoscope of India',
      'Key to the Constitution',
    ],
    timeline: const [
      '1946-12-13: Objectives Resolution moved by Jawaharlal Nehru',
      '1947-01-22: Objectives Resolution adopted by Constituent Assembly',
      '1949-11-26: Preamble enacted alongside Constitution',
      '1950-01-26: Constitution and Preamble came into force',
      '1960-03-14: Berubari Union judgment',
      '1973-04-24: Kesavananda Bharati judgment',
      '1976-12-18: 42nd Constitutional Amendment Act passed',
      '1994-03-11: SR Bommai judgment',
    ],
    crossReferences: const [
      'KO-PART-III',
      'KO-PART-IV',
      'KO-PART-IVA',
      'KO-PART-XX',
    ],
    relatedParts: const [
      'KO-PART-III',
      'KO-PART-IV',
      'KO-PART-IVA',
      'KO-PART-XX',
    ],
    relatedSchedules: const [],
    relatedArticles: const [
      'Art 14',
      'Art 15',
      'Art 19',
      'Art 21',
      'Art 25',
      'Art 38',
      'Art 39',
      'Art 51A',
      'Art 368',
    ],
    relatedAmendments: const ['42nd Amendment Act 1976'],
    relatedCases: const [
      'Berubari Union Case 1960',
      'Kesavananda Bharati v. State of Kerala 1973',
      'SR Bommai v. Union of India 1994',
      'LIC of India Case 1995',
    ],
    relatedActs: const ['The Constitution (Forty-second Amendment) Act, 1976'],
    relatedPYQs: const [
      'UPSC-CSE-2017-POLITY-PRE-Q12',
      'UPSC-CSE-2020-POLITY-PRE-Q05',
      'UPSC-CSE-2021-POLITY-PRE-Q18',
    ],
    relatedCurrentAffairs: const [
      'Debates on secularism and welfare state in Supreme Court constitutional benches.',
    ],
    editorialStatus: 'APPROVED',
    evidenceReferences: const [
      'Constituent Assembly Debates (Official Report, Vol. X & XI)',
      'AIR 1973 SC 1461 (Kesavananda Bharati)',
      'AIR 1994 SC 1918 (SR Bommai)',
    ],
    knowledgeGraphLinks: const [
      'KG_NODE_PREAMBLE',
      'KG_NODE_SOVEREIGNTY',
      'KG_NODE_SECULARISM',
      'KG_NODE_BASIC_STRUCTURE',
    ],
  );

  static final List<PartKnowledgeObject> parts = [
    PartTemplate.create(
      partNumber: 'I',
      title: 'The Union and its Territory',
      officialName: 'PART I - THE UNION AND ITS TERRITORY',
      description:
          'Covers the name and territory of the Union, admission or establishment of new States, and alteration of areas, boundaries or names of existing States.',
      articlesRange: const ['Art 1', 'Art 2', 'Art 3', 'Art 4'],
      relatedSchedules: const ['KO-SCHED-1'],
      relatedActs: const ['States Reorganisation Act 1956', 'Andhra Pradesh Reorganisation Act 2014'],
      relatedCases: const ['Berubari Union Case 1960', 'Maganbhai Ishwarbhai Patel 1969'],
      relatedAmendments: const ['100th Amendment Act 2015'],
      knowledgeGraphLinks: const ['KG_PART_I', 'KG_SCHED_1'],
    ),
    PartTemplate.create(
      partNumber: 'II',
      title: 'Citizenship',
      officialName: 'PART II - CITIZENSHIP',
      description:
          'Defines citizenship at the commencement of the Constitution, rights of citizenship of certain persons who migrated from/to Pakistan, and continuation of rights of citizenship.',
      articlesRange: const ['Art 5', 'Art 6', 'Art 7', 'Art 8', 'Art 9', 'Art 10', 'Art 11'],
      keywords: const ['Citizenship Act 1955', 'NRI', 'PIO', 'OCI', 'CAA 2019'],
      relatedActs: const ['Citizenship Act 1955', 'Citizenship (Amendment) Act 2019'],
      relatedCases: const ['State of Bihar v. Kumar Amar Singh 1955', 'Izhar Ahmad Khan 1962'],
      knowledgeGraphLinks: const ['KG_PART_II', 'KG_CITIZENSHIP_ACT'],
    ),
    PartTemplate.create(
      partNumber: 'III',
      title: 'Fundamental Rights',
      officialName: 'PART III - FUNDAMENTAL RIGHTS',
      description:
          'Guarantees fundamental rights including Right to Equality, Right to Freedom, Right against Exploitation, Right to Freedom of Religion, Cultural and Educational Rights, and Right to Constitutional Remedies.',
      articlesRange: const [
        'Art 12', 'Art 13', 'Art 14', 'Art 15', 'Art 16', 'Art 17', 'Art 18',
        'Art 19', 'Art 20', 'Art 21', 'Art 21A', 'Art 22', 'Art 23', 'Art 24',
        'Art 25', 'Art 26', 'Art 27', 'Art 28', 'Art 29', 'Art 30', 'Art 32'
      ],
      relatedCases: const [
        'AK Gopalan 1950', 'Golaknath 1967', 'Kesavananda Bharati 1973',
        'Maneka Gandhi 1978', 'Minerva Mills 1980', 'KS Puttaswamy 2017'
      ],
      relatedAmendments: const ['44th Amendment Act 1978', '86th Amendment Act 2002', '103rd Amendment Act 2019'],
      knowledgeGraphLinks: const ['KG_PART_III', 'KG_BASIC_STRUCTURE', 'KG_WRITS'],
    ),
    PartTemplate.create(
      partNumber: 'IV',
      title: 'Directive Principles of State Policy',
      officialName: 'PART IV - DIRECTIVE PRINCIPLES OF STATE POLICY',
      description:
          'Non-justiciable guidelines for governance aimed at establishing a social and economic democracy and a welfare state.',
      articlesRange: const [
        'Art 36', 'Art 37', 'Art 38', 'Art 39', 'Art 39A', 'Art 40', 'Art 41',
        'Art 42', 'Art 43', 'Art 43A', 'Art 43B', 'Art 44', 'Art 45', 'Art 46',
        'Art 47', 'Art 48', 'Art 48A', 'Art 49', 'Art 50', 'Art 51'
      ],
      keywords: const ['DPSP', 'Welfare State', 'Uniform Civil Code', 'Gram Panchayats', 'Socialist', 'Gandhian', 'Liberal Intellectual'],
      relatedCases: const ['Champakam Dorairajan 1951', 'Minerva Mills 1980', 'Unni Krishnan 1993'],
      relatedAmendments: const ['42nd Amendment Act 1976', '44th Amendment Act 1978', '86th Amendment Act 2002', '97th Amendment Act 2011'],
      knowledgeGraphLinks: const ['KG_PART_IV', 'KG_WELFARE_STATE'],
    ),
    PartTemplate.create(
      partNumber: 'IVA',
      title: 'Fundamental Duties',
      officialName: 'PART IVA - FUNDAMENTAL DUTIES',
      description:
          'Set of 11 moral obligations of all citizens to promote patriotism and uphold the unity and integrity of India.',
      articlesRange: const ['Art 51A'],
      type: PartType.amendedPart,
      relatedAmendments: const ['42nd Amendment Act 1976', '86th Amendment Act 2002'],
      relatedCases: const ['Bijoe Emmanuel 1986', 'Verma Committee 1999', 'Ranganath Mishra 2003'],
      knowledgeGraphLinks: const ['KG_PART_IVA', 'KG_CITIZEN_DUTIES'],
    ),
    PartTemplate.create(
      partNumber: 'V',
      title: 'The Union',
      officialName: 'PART V - THE UNION',
      description:
          'Deals with the Executive (President, Vice-President, Council of Ministers, Attorney-General), Parliament, Legislative Powers of President, the Union Judiciary (Supreme Court), and CAG.',
      articlesRange: const ['Art 52', 'Art 72', 'Art 74', 'Art 75', 'Art 110', 'Art 123', 'Art 124', 'Art 143', 'Art 148'],
      relatedSchedules: const ['KO-SCHED-2', 'KO-SCHED-3', 'KO-SCHED-4'],
      relatedCases: const ['Shamsher Singh 1974', 'UNR Rao 1971', 'Second Judges Case 1993', 'NJAC Case 2015'],
      knowledgeGraphLinks: const ['KG_PART_V', 'KG_PRESIDENT', 'KG_SUPREME_COURT', 'KG_CAG'],
    ),
    PartTemplate.create(
      partNumber: 'VI',
      title: 'The States',
      officialName: 'PART VI - THE STATES',
      description:
          'Deals with the State Executive (Governor, Council of Ministers, Advocate-General), State Legislature, Legislative Power of Governor, High Courts, and Subordinate Courts.',
      articlesRange: const ['Art 152', 'Art 161', 'Art 163', 'Art 164', 'Art 213', 'Art 214', 'Art 226', 'Art 233'],
      relatedSchedules: const ['KO-SCHED-2', 'KO-SCHED-3'],
      relatedCases: const ['SR Bommai 1994', 'BP Singhal 2010', 'Nabam Rebia 2016'],
      knowledgeGraphLinks: const ['KG_PART_VI', 'KG_GOVERNOR', 'KG_HIGH_COURTS'],
    ),
    PartTemplate.create(
      partNumber: 'VII',
      title: 'The States in Part B of the First Schedule',
      officialName: 'PART VII - THE STATES IN PART B OF THE FIRST SCHEDULE (REPEALED)',
      description: 'Repealed by the Constitution (Seventh Amendment) Act, 1956 following reorganization of States.',
      articlesRange: const ['Art 238'],
      status: ConstitutionStatus.repealed,
      type: PartType.repealedPart,
      relatedAmendments: const ['7th Amendment Act 1956'],
      knowledgeGraphLinks: const ['KG_PART_VII_REPEALED'],
    ),
    PartTemplate.create(
      partNumber: 'VIII',
      title: 'The Union Territories',
      officialName: 'PART VIII - THE UNION TERRITORIES',
      description:
          'Administration of Union Territories, creation of local legislatures/Council of Ministers, and special provisions for National Capital Territory of Delhi.',
      articlesRange: const ['Art 239', 'Art 239AA', 'Art 239AB', 'Art 240', 'Art 241'],
      relatedAmendments: const ['69th Amendment Act 1991', '70th Amendment Act 1992'],
      relatedCases: const ['NCT of Delhi v. Union of India 2018', 'NCT of Delhi v. Union of India 2023'],
      knowledgeGraphLinks: const ['KG_PART_VIII', 'KG_DELHI_NCT'],
    ),
    PartTemplate.create(
      partNumber: 'IX',
      title: 'The Panchayats',
      officialName: 'PART IX - THE PANCHAYATS',
      description:
          'Constitutional status and provisions for Gram Panchayats, 3-tier system, reservations, duration, and State Finance / Election Commissions.',
      articlesRange: const ['Art 243', 'Art 243A', 'Art 243B', 'Art 243C', 'Art 243D', 'Art 243G', 'Art 243K', 'Art 243O'],
      type: PartType.amendedPart,
      relatedSchedules: const ['KO-SCHED-11'],
      relatedAmendments: const ['73rd Amendment Act 1992'],
      relatedActs: const ['PESA Act 1996'],
      knowledgeGraphLinks: const ['KG_PART_IX', 'KG_SCHED_11', 'KG_PANCHAYATI_RAJ'],
    ),
    PartTemplate.create(
      partNumber: 'IXA',
      title: 'The Municipalities',
      officialName: 'PART IXA - THE MUNICIPALITIES',
      description:
          'Constitutional provisions for urban local governance including Nagar Panchayats, Municipal Councils, Municipal Corporations, Wards Committees, and District Planning Committees.',
      articlesRange: const ['Art 243P', 'Art 243Q', 'Art 243R', 'Art 243S', 'Art 243W', 'Art 243ZD', 'Art 243ZE', 'Art 243ZG'],
      type: PartType.amendedPart,
      relatedSchedules: const ['KO-SCHED-12'],
      relatedAmendments: const ['74th Amendment Act 1992'],
      knowledgeGraphLinks: const ['KG_PART_IXA', 'KG_SCHED_12', 'KG_URBAN_LOCAL_BODY'],
    ),
    PartTemplate.create(
      partNumber: 'IXB',
      title: 'The Co-operative Societies',
      officialName: 'PART IXB - THE CO-OPERATIVE SOCIETIES',
      description:
          'Provisions for democratic control, autonomous functioning, professional management, and regulation of co-operative societies.',
      articlesRange: const ['Art 243ZH', 'Art 243ZI', 'Art 243ZJ', 'Art 243ZT'],
      type: PartType.amendedPart,
      relatedAmendments: const ['97th Amendment Act 2011'],
      relatedCases: const ['Union of India v. Rajendra N. Shah 2021'],
      knowledgeGraphLinks: const ['KG_PART_IXB', 'KG_COOPERATIVES'],
    ),
    PartTemplate.create(
      partNumber: 'X',
      title: 'The Scheduled and Tribal Areas',
      officialName: 'PART X - THE SCHEDULED AND TRIBAL AREAS',
      description: 'Administration of Scheduled Areas and Tribal Areas under Fifth and Sixth Schedules.',
      articlesRange: const ['Art 244', 'Art 244A'],
      relatedSchedules: const ['KO-SCHED-5', 'KO-SCHED-6'],
      relatedCases: const ['Samatha v. State of Andhra Pradesh 1997'],
      knowledgeGraphLinks: const ['KG_PART_X', 'KG_SCHED_5', 'KG_SCHED_6'],
    ),
    PartTemplate.create(
      partNumber: 'XI',
      title: 'Relations between the Union and the States',
      officialName: 'PART XI - RELATIONS BETWEEN THE UNION AND THE STATES',
      description:
          'Legislative relations (distribution of legislative powers under List I, II, III) and administrative relations between Centre and States.',
      articlesRange: const ['Art 245', 'Art 246', 'Art 248', 'Art 249', 'Art 250', 'Art 256', 'Art 262', 'Art 263'],
      relatedSchedules: const ['KO-SCHED-7'],
      relatedCases: const ['SR Bommai Case 1994', 'Cauvery Water Disputes 1993', 'State of West Bengal v. Union of India 1963'],
      knowledgeGraphLinks: const ['KG_PART_XI', 'KG_SCHED_7', 'KG_FEDERALISM'],
    ),
    PartTemplate.create(
      partNumber: 'XII',
      title: 'Finance, Property, Contracts and Suits',
      officialName: 'PART XII - FINANCE, PROPERTY, CONTRACTS AND SUITS',
      description:
          'Distribution of revenues, Finance Commission, borrowing, property rights, and Constitutional Right to Property under Article 300A.',
      articlesRange: const ['Art 264', 'Art 265', 'Art 275', 'Art 279A', 'Art 280', 'Art 300', 'Art 300A'],
      relatedAmendments: const ['44th Amendment Act 1978', '101st Amendment Act 2016'],
      relatedCases: const ['K.T. Plantation 2011', 'Jindal Stainless 2017'],
      knowledgeGraphLinks: const ['KG_PART_XII', 'KG_FINANCE_COMMISSION', 'KG_GST_COUNCIL', 'KG_ART_300A'],
    ),
    PartTemplate.create(
      partNumber: 'XIII',
      title: 'Trade, Commerce and Intercourse within Territory of India',
      officialName: 'PART XIII - TRADE, COMMERCE AND INTERCOURSE WITHIN THE TERRITORY OF INDIA',
      description: 'Freedom of trade, commerce and intercourse throughout India and restrictions imposed in public interest.',
      articlesRange: const ['Art 301', 'Art 302', 'Art 303', 'Art 304', 'Art 307'],
      relatedCases: const ['Atiabari Tea Co. 1961', 'Automobile Transport Rajasthan 1962', 'Jindal Stainless 2017'],
      knowledgeGraphLinks: const ['KG_PART_XIII', 'KG_INTERSTATE_TRADE'],
    ),
    PartTemplate.create(
      partNumber: 'XIV',
      title: 'Services Under the Union and the States',
      officialName: 'PART XIV - SERVICES UNDER THE UNION AND THE STATES',
      description:
          'All India Services, tenure of office, constitutional safeguards for civil servants under Art 311, UPSC and State Public Service Commissions.',
      articlesRange: const ['Art 308', 'Art 309', 'Art 310', 'Art 311', 'Art 312', 'Art 315', 'Art 320'],
      keywords: const ['IAS', 'IPS', 'UPSC', 'SPSC', 'Civil Services Safeguards'],
      relatedCases: const ['Parshotam Lal Dhingra 1958', 'T.N. Seshayee 1985', 'Ajay Hasia 1981'],
      knowledgeGraphLinks: const ['KG_PART_XIV', 'KG_UPSC', 'KG_CIVIL_SERVICES'],
    ),
    PartTemplate.create(
      partNumber: 'XIVA',
      title: 'Tribunals',
      officialName: 'PART XIVA - TRIBUNALS',
      description: 'Administrative Tribunals (CAT) and Tribunals for other matters (taxation, foreign exchange, land reforms).',
      articlesRange: const ['Art 323A', 'Art 323B'],
      type: PartType.amendedPart,
      relatedAmendments: const ['42nd Amendment Act 1976'],
      relatedCases: const ['L. Chandra Kumar v. Union of India 1997', 'Madras Bar Association 2014'],
      knowledgeGraphLinks: const ['KG_PART_XIVA', 'KG_CAT_TRIBUNAL'],
    ),
    PartTemplate.create(
      partNumber: 'XV',
      title: 'Elections',
      officialName: 'PART XV - ELECTIONS',
      description:
          'Superintendence, direction and control of elections vested in Election Commission, adult suffrage, and non-interference by courts in electoral matters.',
      articlesRange: const ['Art 324', 'Art 325', 'Art 326', 'Art 327', 'Art 328', 'Art 329'],
      relatedAmendments: const ['61st Amendment Act 1988'],
      relatedCases: const ['Mohinder Singh Gill 1978', 'TN Seshan 1995', 'Anoop Baranwal v. Union of India 2023'],
      knowledgeGraphLinks: const ['KG_PART_XV', 'KG_ELECTION_COMMISSION', 'KG_ADULT_SUFFRAGE'],
    ),
    PartTemplate.create(
      partNumber: 'XVI',
      title: 'Special Provisions Relating to Certain Classes',
      officialName: 'PART XVI - SPECIAL PROVISIONS RELATING TO CERTAIN CLASSES',
      description:
          'Reservation of seats for SCs, STs, OBCs, Anglo-Indians, and National Commissions for SCs, STs, and NCBC.',
      articlesRange: const ['Art 330', 'Art 332', 'Art 335', 'Art 338', 'Art 338A', 'Art 338B', 'Art 340', 'Art 341', 'Art 342'],
      relatedAmendments: const ['89th Amendment Act 2003', '102nd Amendment Act 2018', '104th Amendment Act 2019'],
      relatedCases: const ['Indra Sawhney 1992', 'M. Nagaraj 2006', 'Jarnail Singh 2018'],
      knowledgeGraphLinks: const ['KG_PART_XVI', 'KG_NCSC', 'KG_NCST', 'KG_NCBC'],
    ),
    PartTemplate.create(
      partNumber: 'XVII',
      title: 'Official Language',
      officialName: 'PART XVII - OFFICIAL LANGUAGE',
      description:
          'Official language of the Union, Regional languages, Language of Supreme Court & High Courts, and Special Directives for Hindi language development.',
      articlesRange: const ['Art 343', 'Art 344', 'Art 345', 'Art 348', 'Art 350A', 'Art 351'],
      relatedSchedules: const ['KO-SCHED-8'],
      relatedActs: const ['Official Languages Act 1963'],
      knowledgeGraphLinks: const ['KG_PART_XVII', 'KG_SCHED_8', 'KG_OFFICIAL_LANGUAGES'],
    ),
    PartTemplate.create(
      partNumber: 'XVIII',
      title: 'Emergency Provisions',
      officialName: 'PART XVIII - EMERGENCY PROVISIONS',
      description:
          'National Emergency (Art 352), President’s Rule / Constitutional Emergency (Art 356), and Financial Emergency (Art 360).',
      articlesRange: const ['Art 352', 'Art 355', 'Art 356', 'Art 358', 'Art 359', 'Art 360'],
      type: PartType.specialProvisionPart,
      relatedAmendments: const ['38th Amendment Act 1975', '44th Amendment Act 1978'],
      relatedCases: const ['ADM Jabalpur 1976', 'SR Bommai 1994', 'Rameshwar Prasad 2006'],
      knowledgeGraphLinks: const ['KG_PART_XVIII', 'KG_NATIONAL_EMERGENCY', 'KG_PRESIDENTS_RULE'],
    ),
    PartTemplate.create(
      partNumber: 'XIX',
      title: 'Miscellaneous',
      officialName: 'PART XIX - MISCELLANEOUS',
      description:
          'Protection of President and Governors, immunity from legal proceedings, bar to interference by courts in treaties/agreements, and definitions.',
      articlesRange: const ['Art 361', 'Art 361A', 'Art 363', 'Art 365', 'Art 366', 'Art 367'],
      relatedCases: const ['Rameshwar Prasad 2006', 'Madhav Rao Scindia (Privy Purse) 1971'],
      knowledgeGraphLinks: const ['KG_PART_XIX', 'KG_IMMUNITIES'],
    ),
    PartTemplate.create(
      partNumber: 'XX',
      title: 'Amendment of the Constitution',
      officialName: 'PART XX - AMENDMENT OF THE CONSTITUTION',
      description: 'Power of Parliament to amend the Constitution and procedure therefor under Article 368.',
      articlesRange: const ['Art 368'],
      type: PartType.corePart,
      relatedCases: const [
        'Shankari Prasad 1951', 'Sajjan Singh 1965', 'Golaknath 1967',
        'Kesavananda Bharati 1973', 'Minerva Mills 1980', 'I.R. Coelho 2007'
      ],
      relatedAmendments: const ['24th Amendment Act 1971', '42nd Amendment Act 1976', '44th Amendment Act 1978'],
      knowledgeGraphLinks: const ['KG_PART_XX', 'KG_AMENDMENT_PROCEDURE', 'KG_BASIC_STRUCTURE'],
    ),
    PartTemplate.create(
      partNumber: 'XXI',
      title: 'Temporary, Transitional and Special Provisions',
      officialName: 'PART XXI - TEMPORARY, TRANSITIONAL AND SPECIAL PROVISIONS',
      description:
          'Special provisions for various States including Maharashtra, Gujarat, Nagaland, Assam, Manipur, Andhra Pradesh, Sikkim, Mizoram, Arunachal Pradesh, Goa, and Karnataka.',
      articlesRange: const ['Art 369', 'Art 370', 'Art 371', 'Art 371A', 'Art 371B', 'Art 371C', 'Art 371D', 'Art 371F', 'Art 371J'],
      type: PartType.specialProvisionPart,
      relatedCases: const ['Prem Nath Kaul 1959', 'Sampat Prakash 1969', 'In re Article 370 of Constitution 2023'],
      knowledgeGraphLinks: const ['KG_PART_XXI', 'KG_SPECIAL_PROVISIONS_STATES'],
    ),
    PartTemplate.create(
      partNumber: 'XXII',
      title: 'Short Title, Commencement, Authoritative Text in Hindi and Repeals',
      officialName: 'PART XXII - SHORT TITLE, COMMENCEMENT, AUTHORITATIVE TEXT IN HINDI AND REPEALS',
      description:
          'Short title ("Constitution of India"), date of commencement, Hindi translation provisions, and repeals of Indian Independence Act 1947 & Government of India Act 1935.',
      articlesRange: const ['Art 393', 'Art 394', 'Art 394A', 'Art 395'],
      relatedActs: const ['Indian Independence Act 1947', 'Government of India Act 1935'],
      knowledgeGraphLinks: const ['KG_PART_XXII', 'KG_COMMENCEMENT'],
    ),
  ];

  static final List<ScheduleKnowledgeObject> schedules = [
    ScheduleTemplate.create(
      scheduleNumber: '1',
      title: 'States and Union Territories',
      officialName: 'FIRST SCHEDULE - STATES AND UNION TERRITORIES',
      description: 'Lists the 28 States and 8 Union Territories of India, specifying their names and territorial extents.',
      type: ScheduleType.territorial,
      relatedParts: const ['KO-PART-I'],
      relatedArticles: const ['Art 1', 'Art 4'],
      relatedActs: const ['States Reorganisation Act 1956', 'Jammu and Kashmir Reorganisation Act 2019'],
      relatedCases: const ['Berubari Union Case 1960'],
      knowledgeGraphLinks: const ['KG_SCHED_1', 'KG_PART_I'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '2',
      title: 'Emoluments and Salaries',
      officialName: 'SECOND SCHEDULE - EMOLUMENTS, ALLOWANCES AND PRIVILEGES',
      description:
          'Provisions regarding salaries, allowances and privileges of President, Governors, Speaker/Deputy Speaker, Chairman/Deputy Chairman, Judges of SC/HCs, and Comptroller and Auditor-General of India.',
      type: ScheduleType.emoluments,
      relatedParts: const ['KO-PART-V', 'KO-PART-VI'],
      relatedArticles: const ['Art 59', 'Art 65', 'Art 75', 'Art 97', 'Art 125', 'Art 148', 'Art 158', 'Art 164', 'Art 186', 'Art 221'],
      knowledgeGraphLinks: const ['KG_SCHED_2', 'KG_EMOLUMENTS'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '3',
      title: 'Forms of Oaths or Affirmations',
      officialName: 'THIRD SCHEDULE - FORMS OF OATHS OR AFFIRMATIONS',
      description:
          'Contains 8 standard forms of oaths/affirmations for Union Ministers, Parliamentary Election Candidates, MPs, Supreme Court Judges, CAG, State Ministers, State Legislature Candidates, MLAs/MLCs, and High Court Judges.',
      type: ScheduleType.oaths,
      relatedParts: const ['KO-PART-V', 'KO-PART-VI'],
      relatedArticles: const ['Art 75', 'Art 84', 'Art 99', 'Art 124', 'Art 148', 'Art 164', 'Art 173', 'Art 188', 'Art 219'],
      knowledgeGraphLinks: const ['KG_SCHED_3', 'KG_OATHS'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '4',
      title: 'Allocation of Seats in Rajya Sabha',
      officialName: 'FOURTH SCHEDULE - ALLOCATION OF SEATS IN THE COUNCIL OF STATES',
      description: 'Specifies the allocation of Rajya Sabha (Council of States) seats to each State and Union Territory.',
      type: ScheduleType.representation,
      relatedParts: const ['KO-PART-V'],
      relatedArticles: const ['Art 4', 'Art 80'],
      relatedCases: const ['Kuldip Nayar v. Union of India 2006'],
      knowledgeGraphLinks: const ['KG_SCHED_4', 'KG_RAJYA_SABHA'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '5',
      title: 'Administration of Scheduled Areas and Scheduled Tribes',
      officialName: 'FIFTH SCHEDULE - PROVISIONS AS TO THE ADMINISTRATION AND CONTROL OF SCHEDULED AREAS AND SCHEDULED TRIBES',
      description:
          'Special provisions for administration and governance of Scheduled Areas and Scheduled Tribes in 10 states (other than Assam, Meghalaya, Tripura, and Mizoram). Establishes Tribes Advisory Councils.',
      type: ScheduleType.tribalAdministration,
      relatedParts: const ['KO-PART-X'],
      relatedArticles: const ['Art 244'],
      relatedCases: const ['Samatha v. State of Andhra Pradesh 1997'],
      knowledgeGraphLinks: const ['KG_SCHED_5', 'KG_PART_X', 'KG_TRIBAL_ADVISORY_COUNCIL'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '6',
      title: 'Administration of Tribal Areas in North-Eastern States',
      officialName: 'SIXTH SCHEDULE - PROVISIONS AS TO THE ADMINISTRATION OF TRIBAL AREAS IN THE STATES OF ASSAM, MEGHALAYA, TRIPURA AND MIZORAM',
      description:
          'Establishes Autonomous District Councils (ADCs) and Regional Councils with legislative, judicial, executive, and financial powers in tribal areas of Assam, Meghalaya, Tripura, and Mizoram.',
      type: ScheduleType.tribalAdministration,
      relatedParts: const ['KO-PART-X'],
      relatedArticles: const ['Art 244', 'Art 275'],
      relatedCases: const ['Pu Myat Hla v. State of Mizoram 2007'],
      knowledgeGraphLinks: const ['KG_SCHED_6', 'KG_AUTONOMOUS_DISTRICT_COUNCILS'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '7',
      title: 'Legislative Lists (Union, State, Concurrent)',
      officialName: 'SEVENTH SCHEDULE - LEGISLATIVE LISTS',
      description:
          'Delineates legislative power between Parliament and State Assemblies under List I (Union List: 100 items), List II (State List: 61 items), and List III (Concurrent List: 52 items).',
      type: ScheduleType.legislativeLists,
      relatedParts: const ['KO-PART-XI'],
      relatedArticles: const ['Art 246'],
      relatedAmendments: const ['42nd Amendment Act 1976', '101st Amendment Act 2016'],
      relatedCases: const ['State of Bombay v. F.N. Balsara 1951', 'Hoechst Pharmaceuticals 1983', 'Jindal Stainless 2017'],
      knowledgeGraphLinks: const ['KG_SCHED_7', 'KG_PART_XI', 'KG_LEGISLATIVE_COMPETENCE'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '8',
      title: 'Official Languages',
      officialName: 'EIGHTH SCHEDULE - LANGUAGES',
      description:
          'Lists the 22 official languages recognized by the Constitution of India (originally 14; 8 added via 21st, 71st, and 92nd Amendments).',
      type: ScheduleType.officialLanguages,
      relatedParts: const ['KO-PART-XVII'],
      relatedArticles: const ['Art 344', 'Art 351'],
      relatedAmendments: const ['21st Amendment Act 1967', '71st Amendment Act 1992', '92nd Amendment Act 2003', '96th Amendment Act 2011'],
      knowledgeGraphLinks: const ['KG_SCHED_8', 'KG_PART_XVII', 'KG_22_LANGUAGES'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '9',
      title: 'Validation of certain Acts and Regulations (Land Reforms)',
      officialName: 'NINTH SCHEDULE - VALIDATION OF CERTAIN ACTS AND REGULATIONS',
      description:
          'Created by 1st Amendment Act 1951 to protect land reform and agrarian laws from judicial review; subject to basic structure review post-April 24, 1973 per I.R. Coelho Case.',
      type: ScheduleType.landReforms,
      relatedArticles: const ['Art 31B'],
      relatedAmendments: const ['1st Amendment Act 1951', '17th Amendment Act 1964', '29th Amendment Act 1972', '34th Amendment Act 1974'],
      relatedCases: const ['Shankari Prasad 1951', 'Kesavananda Bharati 1973', 'I.R. Coelho v. State of Tamil Nadu 2007'],
      knowledgeGraphLinks: const ['KG_SCHED_9', 'KG_ART_31B', 'KG_IR_COELHO'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '10',
      title: 'Anti-Defection Law',
      officialName: 'TENTH SCHEDULE - PROVISIONS AS TO DISQUALIFICATION ON GROUND OF DEFECTION',
      description:
          'Added by 52nd Amendment Act 1985 to disqualify legislators for defecting from political parties. Presiding Officer decisions subject to judicial review.',
      type: ScheduleType.antiDefection,
      relatedArticles: const ['Art 102', 'Art 191'],
      relatedAmendments: const ['52nd Amendment Act 1985', '91st Amendment Act 2003'],
      relatedCases: const ['Kihoto Hollohan v. Zachillhu 1992', 'Ravi S. Naik 1994', 'Nabam Rebia 2016', 'Subhash Desai 2023'],
      knowledgeGraphLinks: const ['KG_SCHED_10', 'KG_ANTI_DEFECTION'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '11',
      title: 'Powers and Responsibilities of Panchayats',
      officialName: 'ELEVENTH SCHEDULE - MATTERS ENTRUSTED TO PANCHAYATS',
      description: 'Contains 29 functional items under the purview of Panchayats following the 73rd Amendment Act 1992.',
      type: ScheduleType.localGovernance,
      relatedParts: const ['KO-PART-IX'],
      relatedArticles: const ['Art 243G'],
      relatedAmendments: const ['73rd Amendment Act 1992'],
      knowledgeGraphLinks: const ['KG_SCHED_11', 'KG_PART_IX', 'KG_29_MATTERS'],
    ),
    ScheduleTemplate.create(
      scheduleNumber: '12',
      title: 'Powers and Responsibilities of Municipalities',
      officialName: 'TWELFTH SCHEDULE - MATTERS ENTRUSTED TO MUNICIPALITIES',
      description: 'Contains 18 functional items under the purview of Municipalities following the 74th Amendment Act 1992.',
      type: ScheduleType.localGovernance,
      relatedParts: const ['KO-PART-IXA'],
      relatedArticles: const ['Art 243W'],
      relatedAmendments: const ['74th Amendment Act 1992'],
      knowledgeGraphLinks: const ['KG_SCHED_12', 'KG_PART_IXA', 'KG_18_MATTERS'],
    ),
  ];
}
