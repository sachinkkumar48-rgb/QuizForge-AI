library;

import '../domain/entities/article_knowledge_object.dart';

/// Permanent Production Knowledge Objects for Constitutional Parts XVI, XVII, XVIII, XIX, XX, XXI, and XXII.
class ConstitutionArticlesPart16To22 {
  static final List<ArticleKnowledgeObject> articles = [
    // PART XVI - SPECIAL PROVISIONS RELATING TO CERTAIN CLASSES (Art. 330 - 342A)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-330',
      articleNumber: '330',
      officialTitle: 'Reservation of seats for Scheduled Castes and Scheduled Tribes in House of the People',
      part: 'Part XVI',
      chapter: 'Special Provisions',
      originalNumber: '330',
      currentNumber: '330',
      title: 'Article 330: Reservation of seats for SCs and STs in Lok Sabha',
      officialName: 'ARTICLE 330',
      description: 'Seats shall be reserved in Lok Sabha for Scheduled Castes and Scheduled Tribes in proportion to their population.',
      officialConstitutionalText:
          '(1) Seats shall be reserved in the House of the People for—\n(a) the Scheduled Castes;\n(b) the Scheduled Tribes except the Scheduled Tribes in the autonomous districts of Assam; and\n(c) the Scheduled Tribes in the autonomous districts of Assam.',
      originalGarudaExplanation:
          'Mandates population-proportionate parliamentary seat reservation for SCs and STs in Lok Sabha (extended to 2030 by 104th Amendment Act 2019 while Anglo-Indian nomination was discontinued).',
      historicalBackground:
          '104th Amendment 2019 extended SC/ST reservation for 10 years (until 2030) and discontinued Anglo-Indian nomination under 331.',
      searchKeywords: const ['Article 330', 'Lok Sabha SC ST Reservation', '104th Amendment 2019', 'Special Provisions'],
      keyTakeaways: const [
        'Proportionate SC/ST reservation in Lok Sabha based on population census.',
        '104th Amendment 2019 extended SC/ST reservation to 2030.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '104th Constitutional Amendment Act 2019',
          beforeText: 'SC/ST reservation in Lok Sabha and Anglo-Indian nomination expired in 2020.',
          afterText: 'SC/ST reservation extended until 2030; Anglo-Indian nomination discontinued.',
          reason: 'To continue affirmative political representation for SCs/STs.',
          effectiveDate: DateTime(2020, 1, 25),
        ),
      ],
      pyqIds: const ['UPSC-CSE-2020-GS2-Q09'],
      citations: const ['104th Amendment Act 2019', 'Delimitation Act 2002'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-338',
      articleNumber: '338',
      officialTitle: 'National Commission for Scheduled Castes',
      part: 'Part XVI',
      chapter: 'Special Provisions',
      originalNumber: '338',
      currentNumber: '338',
      title: 'Article 338: National Commission for Scheduled Castes',
      officialName: 'ARTICLE 338',
      description: 'There shall be a Commission for Scheduled Castes to investigate and monitor all matters relating to safeguards provided for SCs.',
      officialConstitutionalText:
          '(1) There shall be a Commission for the Scheduled Castes to be known as the National Commission for the Scheduled Castes.\n(2) Subject to the provisions of any law made in this behalf by Parliament, the Commission shall consist of a Chairperson, Vice-Chairperson and three other Members...',
      originalGarudaExplanation:
          'Constitutional body for monitoring SC rights safeguards, vested with powers of a Civil Court while investigating complaints (split into NCSC Art 338 & NCST Art 338A by 89th Amendment 2003).',
      historicalBackground:
          '89th Amendment 2003 bifurcated original combined commission into separate NCSC (338) and NCST (338A).',
      searchKeywords: const ['Article 338', 'National Commission Scheduled Castes', 'NCSC', '89th Amendment 2003', 'Civil Court Powers'],
      keyTakeaways: const [
        'Constitutional body investigating SC rights violations.',
        'Has powers of a Civil Court trying a suit during investigations.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '89th Constitutional Amendment Act 2003',
          beforeText: 'Single National Commission for SCs and STs under Article 338.',
          afterText: 'Bifurcated into NCSC (338) and NCST (338A).',
          reason: 'To provide focused protection to Scheduled Tribes.',
          effectiveDate: DateTime(2004, 2, 19),
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q08', 'UPSC-CSE-2022-GS2-Q15'],
      citations: const ['89th Amendment Act 2003'],
    ),

    // PART XVII - OFFICIAL LANGUAGE (Art. 343 - 351)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-343',
      articleNumber: '343',
      officialTitle: 'Official language of the Union',
      part: 'Part XVII',
      chapter: 'Official Language of the Union',
      originalNumber: '343',
      currentNumber: '343',
      title: 'Article 343: Official language of the Union',
      officialName: 'ARTICLE 343',
      description: 'The official language of the Union shall be Hindi in Devanagari script, with international form of Indian numerals.',
      officialConstitutionalText:
          '(1) The official language of the Union shall be Hindi in Devanagari script. The form of numerals to be used for the official purposes of the Union shall be the international form of Indian numerals.\n(2) Notwithstanding anything in clause (1), for a period of fifteen years from the commencement of this Constitution, the English language shall continue to be used...',
      originalGarudaExplanation:
          'Declares Hindi in Devanagari script as official language of Union, with English continued beyond 15 years via Official Languages Act 1963.',
      historicalBackground:
          'Munshi-Ayyangar Formula resolved language debate in Constituent Assembly.',
      searchKeywords: const ['Article 343', 'Official Language Union', 'Hindi Devanagari', 'Official Languages Act 1963', 'Munshi Ayyangar Formula'],
      keyTakeaways: const [
        'Hindi is Official Language of the Union (NOT National Language).',
        'English continued for official purposes under Official Languages Act 1963.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2016-GS1-Q22'],
      citations: const ['Official Languages Act 1963', 'CAD Vol. IX'],
    ),

    // PART XVIII - EMERGENCY PROVISIONS (Art. 352 - 360)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-352',
      articleNumber: '352',
      officialTitle: 'Proclamation of Emergency',
      part: 'Part XVIII',
      chapter: 'Emergency Provisions',
      originalNumber: '352',
      currentNumber: '352',
      title: 'Article 352: Proclamation of Emergency',
      officialName: 'ARTICLE 352',
      description: 'If President is satisfied security of India is threatened by war, external aggression, or armed rebellion, he may proclaim National Emergency.',
      officialConstitutionalText:
          '(1) If the President is satisfied that a grave emergency exists whereby the security of India or of any part of the territory thereof is threatened, whether by war or external aggression or armed rebellion, he may, by Proclamation, make a declaration to that effect in respect of the whole of India or of such part of the territory thereof as may be specified in the Proclamation...\n(3) The President shall not issue a Proclamation... unless the decision of the Union Cabinet... has been communicated to him in writing.',
      originalGarudaExplanation:
          'Governs National Emergency on grounds of War, External Aggression, or Armed Rebellion (replacing "internal disturbance" under 44th Amendment 1978). Requires written Cabinet advice and 1-month parliamentary approval by special majority.',
      historicalBackground:
          '44th Amendment 1978 substituted "armed rebellion" for "internal disturbance" and required written Cabinet decision following 1975 National Emergency abuses.',
      searchKeywords: const ['Article 352', 'National Emergency', 'Armed Rebellion', '44th Amendment 1978', 'Special Majority Emergency'],
      keyTakeaways: const [
        'Grounds: War, External Aggression, or Armed Rebellion (44th Amendment).',
        'Requires WRITTEN advice of Cabinet (only place word "Cabinet" is used in Constitution).',
        'Requires Parliamentary approval within 1 month by Special Majority in both Houses.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act 1978',
          beforeText: 'Grounds included "internal disturbance"; approval by simple majority within 2 months.',
          afterText: 'Ground "internal disturbance" replaced by "armed rebellion"; written Cabinet decision mandated; approval required within 1 month by special majority.',
          reason: 'To prevent misuse of emergency powers as experienced during 1975-77.',
          effectiveDate: DateTime(1979, 6, 20),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Minerva Mills Ltd v. Union of India',
          year: 1980,
          bench: '5-Judge Bench',
          legalPrinciple: 'Proclamation of National Emergency under Article 352 is subject to judicial review on grounds of mala fides.',
          importance: 'Established judicial review over National Emergency.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS2-Q05', 'UPSC-CSE-2019-GS2-Q02', 'UPSC-CSE-2022-GS2-Q04'],
      citations: const ['44th Amendment Act 1978', 'Minerva Mills 1980'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-356',
      articleNumber: '356',
      officialTitle: 'Provisions in case of failure of constitutional machinery in States',
      part: 'Part XVIII',
      chapter: 'Emergency Provisions',
      originalNumber: '356',
      currentNumber: '356',
      title: 'Article 356: Provisions in case of failure of constitutional machinery in States',
      officialName: 'ARTICLE 356',
      description: 'If President is satisfied government of State cannot be carried on in accordance with Constitution, he may issue Proclamation of President\'s Rule.',
      officialConstitutionalText:
          '(1) If the President, on receipt of a report from the Governor of a State or otherwise, is satisfied that a situation has arisen in which the government of the State cannot be carried on in accordance with the provisions of this Constitution, the President may by Proclamation—\n(a) assume to himself all or any of the functions of the Government of the State...',
      originalGarudaExplanation:
          'Governs President\'s Rule / State Emergency when constitutional machinery fails in a State, subject to SR Bommai 1994 safeguards restricting arbitrary dismissal of State governments.',
      historicalBackground:
          'SR Bommai 1994 established floor test as mandatory proof of majority and subjected Art 356 proclamation to strict judicial review.',
      searchKeywords: const ['Article 356', 'Presidents Rule', 'State Emergency', 'SR Bommai Case', 'Constitutional Machinery Breakdown'],
      keyTakeaways: const [
        'Requires parliamentary approval within 2 months by Simple Majority.',
        'Floor test is the only constitutional test for majority (SR Bommai 1994).',
        'State Assembly cannot be dissolved until Parliament approves the Proclamation.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'SR Bommai v. Union of India',
          year: 1994,
          bench: '9-Judge Bench',
          legalPrinciple: 'Secularism is basic structure; Presidential proclamation under 356 is subject to judicial review; floor test is mandatory.',
          importance: 'Watermark judgment protecting federalism from Article 356 abuse.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS2-Q15', 'UPSC-CSE-2021-GS2-Q10'],
      citations: const ['SR Bommai 1994', 'Sarkaria Commission Report 1988'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-360',
      articleNumber: '360',
      officialTitle: 'Provisions as to financial emergency',
      part: 'Part XVIII',
      chapter: 'Emergency Provisions',
      originalNumber: '360',
      currentNumber: '360',
      title: 'Article 360: Provisions as to financial emergency',
      officialName: 'ARTICLE 360',
      description: 'If President is satisfied financial stability or credit of India is threatened, he may proclaim Financial Emergency.',
      officialConstitutionalText:
          '(1) If the President is satisfied that a situation has arisen whereby the financial stability or credit of India or of any part of the territory thereof is threatened, he may by a Proclamation make a declaration to that effect.',
      originalGarudaExplanation:
          'Authorizes Financial Emergency empowering Union to reduce salaries of public servants including High Court and Supreme Court Judges (never declared in India).',
      historicalBackground:
          'Never invoked in the history of independent India, even during 1991 balance of payments crisis.',
      searchKeywords: const ['Article 360', 'Financial Emergency', 'Salary Reduction Judges', 'Never Incurred'],
      keyTakeaways: const [
        'Empowers reduction of salaries of SC/HC Judges and Union/State civil servants.',
        'Has NEVER been declared in India.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2018-GS2-Q06'],
      citations: const ['Constituent Assembly Debates Vol. IX'],
    ),

    // PART XX - AMENDMENT OF THE CONSTITUTION (Art. 368)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-368',
      articleNumber: '368',
      officialTitle: 'Power of Parliament to amend the Constitution and procedure therefor',
      part: 'Part XX',
      chapter: 'Amendment of the Constitution',
      originalNumber: '368',
      currentNumber: '368',
      title: 'Article 368: Power of Parliament to amend Constitution and procedure',
      officialName: 'ARTICLE 368',
      description: 'Parliament may in exercise of constituent power amend by addition, variation or repeal any provision of Constitution per procedure laid down.',
      officialConstitutionalText:
          '(1) Notwithstanding anything in this Constitution, Parliament may in exercise of its constituent power amend by way of addition, variation or repeal any provision of this Constitution in accordance with the procedure laid down in this article...\n(2) ...requires special majority of 2/3rd present and voting + majority of total membership in each House, and for federal provisions, ratification by at least 50% of State Legislatures...',
      originalGarudaExplanation:
          'Establishes constituent power and procedure for Constitutional Amendments (Special Majority, and State ratification for federal provisions under 368(2)), subject to the Basic Structure Doctrine (Kesavananda Bharati 1973).',
      historicalBackground:
          'Kesavananda Bharati 1973 ruled that constituent power under Art 368 cannot alter or destroy the Basic Structure of the Constitution.',
      searchKeywords: const ['Article 368', 'Constitutional Amendment', 'Basic Structure Doctrine', 'Kesavananda Bharati', 'Special Majority', 'State Ratification'],
      keyTakeaways: const [
        'Constituent power of Parliament is limited by the Basic Structure Doctrine.',
        'Federal amendments require ratification by not less than half of State Legislatures.',
        'No joint sitting permitted for Constitutional Amendment Bills.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '24th Constitutional Amendment Act 1971',
          beforeText: 'Article 368 titled "Procedure for Amendment of the Constitution".',
          afterText: 'Title changed to "Power of Parliament to amend the Constitution and procedure therefor"; Clause (1) inserted affirming constituent power.',
          reason: 'To overcome Golaknath 1967 ruling restricting amendment of Fundamental Rights.',
          effectiveDate: DateTime(1971, 11, 5),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Kesavananda Bharati v. State of Kerala',
          year: 1973,
          bench: '13-Judge Bench',
          legalPrinciple: 'Parliament has wide power to amend any part of the Constitution including Fundamental Rights, but cannot alter its Basic Structure.',
          importance: 'Established Basic Structure Doctrine as cornerstone of Indian constitutional law.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Minerva Mills Ltd v. Union of India',
          year: 1980,
          bench: '5-Judge Bench',
          legalPrinciple: 'Clauses (4) and (5) of Article 368 inserted by 42nd Amendment attempting unlimited amendment power declared unconstitutional.',
          importance: 'Reaffirmed that limited amending power is itself a basic feature.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS2-Q01', 'UPSC-CSE-2019-GS2-Q01', 'UPSC-CSE-2023-GS2-Q10'],
      citations: const ['Kesavananda Bharati 1973', 'Minerva Mills 1980'],
    ),

    // PART XXI - TEMPORARY, TRANSITIONAL AND SPECIAL PROVISIONS (Art. 369 - 392)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-370',
      articleNumber: '370',
      officialTitle: 'Temporary provisions with respect to the State of Jammu and Kashmir',
      part: 'Part XXI',
      chapter: 'Temporary Provisions',
      originalNumber: '370',
      currentNumber: '370',
      title: 'Article 370: Temporary provisions with respect to Jammu and Kashmir',
      officialName: 'ARTICLE 370',
      description: 'Temporary special autonomous status for J&K (declared inoperative per Presidential Orders C.O. 272 and C.O. 273 in August 2019).',
      officialConstitutionalText:
          'Temporary provisions with respect to the State of Jammu and Kashmir [Inoperative per Constitution (Application to Jammu and Kashmir) Order, 2019 C.O. 272 & C.O. 273].',
      originalGarudaExplanation:
          'Granted temporary special autonomous status to Jammu & Kashmir. Declared inoperative by Presidential Orders C.O. 272 and C.O. 273 on August 5-6, 2019, upheld by Supreme Court Constitution Bench in 2023.',
      historicalBackground:
          'In re Article 370 (2023) 5-judge bench unanimously upheld the abrogation of Article 370 as a valid exercise of executive power.',
      searchKeywords: const ['Article 370', 'Jammu and Kashmir Abrogation', 'C.O. 272', 'In re Article 370 2023', 'Asymmetrical Federalism'],
      keyTakeaways: const [
        'Declared inoperative in August 2019 via C.O. 272 & 273.',
        'Abrogation unanimously upheld by 5-judge Supreme Court bench in December 2023.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'In re Article 370 of the Constitution of India',
          year: 2023,
          bench: '5-Judge Bench',
          legalPrinciple: 'Article 370 was a temporary feature; President possessed power to declare it inoperative under 370(3).',
          importance: 'Upheld full integration of J&K into Indian Union.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2020-GS2-Q02', 'UPSC-CSE-2024-GS2-Q01'],
      citations: const ['C.O. 272 & C.O. 273', 'In re Article 370 Judgment 2023'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-371A',
      articleNumber: '371A',
      officialTitle: 'Special provision with respect to the State of Nagaland',
      part: 'Part XXI',
      chapter: 'Special Provisions for States',
      originalNumber: '371A',
      currentNumber: '371A',
      title: 'Article 371A: Special provision with respect to Nagaland',
      officialName: 'ARTICLE 371A',
      description: 'No Act of Parliament respecting Naga religious/social practices, customary law, or land ownership applies unless Nagaland Assembly resolves so.',
      officialConstitutionalText:
          'Notwithstanding anything in this Constitution, no Act of Parliament in respect of— (i) religious or social practices of the Nagas, (ii) Naga customary law and procedure, (iii) administration of civil and criminal justice involving decisions according to Naga customary law, (iv) ownership and transfer of land and its resources, shall apply to the State of Nagaland unless the Legislative Assembly of Nagaland by resolution so decides...',
      originalGarudaExplanation:
          'Inserted by 13th Amendment Act 1962 granting special constitutional autonomy protecting Naga customary law, social practices, and land rights from Parliamentary laws.',
      historicalBackground:
          'Followed 16-Point Agreement 1960 between Nagaland People\'s Convention and Government of India.',
      searchKeywords: const ['Article 371A', 'Nagaland Special Provision', 'Naga Customary Law', '13th Amendment 1962'],
      keyTakeaways: const [
        'Protects Naga religious/social practices, customary law, and land ownership.',
        'Parliamentary laws on these subjects apply ONLY if Nagaland Assembly resolves so.'
      ],
      effectiveDate: DateTime(1963, 12, 1),
      pyqIds: const ['UPSC-CSE-2018-GS2-Q16'],
      citations: const ['13th Amendment Act 1962', '16-Point Agreement 1960'],
    ),

    // PART XXII - SHORT TITLE, COMMENCEMENT AND REPEALS (Art. 393 - 395)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-393',
      articleNumber: '393',
      officialTitle: 'Short title',
      part: 'Part XXII',
      chapter: 'Short Title and Commencement',
      originalNumber: '393',
      currentNumber: '393',
      title: 'Article 393: Short title',
      officialName: 'ARTICLE 393',
      description: 'This Constitution may be cited as the Constitution of India.',
      officialConstitutionalText: 'This Constitution may be cited as the Constitution of India.',
      originalGarudaExplanation:
          'Gives the official short title of the supreme document as "The Constitution of India".',
      historicalBackground:
          'Adopted on November 26, 1949 by the Constituent Assembly.',
      searchKeywords: const ['Article 393', 'Short Title', 'Constitution of India'],
      keyTakeaways: const ['Official nomenclature: Constitution of India.'],
      effectiveDate: DateTime(1949, 11, 26),
      citations: const ['CAD Vol. XI'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-395',
      articleNumber: '395',
      officialTitle: 'Repeals',
      part: 'Part XXII',
      chapter: 'Repeals',
      originalNumber: '395',
      currentNumber: '395',
      title: 'Article 395: Repeals',
      officialName: 'ARTICLE 395',
      description: 'Repeals the Indian Independence Act 1947 and Government of India Act 1935.',
      officialConstitutionalText:
          'The Indian Independence Act, 1947, and the Government of India Act, 1935, together with all enactments amending or supplementing the latter Act, but not including the Abolition of Privy Council Jurisdiction Act, 1949, are hereby repealed.',
      originalGarudaExplanation:
          'Formally repeals the Indian Independence Act 1947 and Government of India Act 1935, establishing the sovereign independence of the Constitution of India.',
      historicalBackground:
          'Severed legal continuity with British colonial parliamentary enactments.',
      searchKeywords: const ['Article 395', 'Repeals', 'Indian Independence Act 1947 Repealed', 'Government of India Act 1935 Repealed'],
      keyTakeaways: const [
        'Repealed GOI Act 1935 and Indian Independence Act 1947.',
        'Established autonomous constitutional sovereignty.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      citations: const ['CAD Vol. XI'],
    ),
  ];
}
