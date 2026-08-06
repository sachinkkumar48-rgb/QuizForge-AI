library;

import '../domain/entities/article_knowledge_object.dart';

/// Permanent Production Knowledge Objects for Constitutional Parts VI, VIII, IX, IXA, IXB, and X.
class ConstitutionArticlesPart6To10 {
  static final List<ArticleKnowledgeObject> articles = [
    // PART VI - THE STATES (Art. 152 - 237)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-153',
      articleNumber: '153',
      officialTitle: 'Governors of States',
      part: 'Part VI',
      chapter: 'The Executive',
      originalNumber: '153',
      currentNumber: '153',
      title: 'Article 153: Governors of States',
      officialName: 'ARTICLE 153',
      description: 'There shall be a Governor for each State, provided that the same person may be appointed as Governor for two or more States.',
      officialConstitutionalText:
          'There shall be a Governor for each State:\nProvided that nothing in this article shall prevent the appointment of the same person as Governor for two or more States.',
      originalGarudaExplanation:
          'Establishes the office of Governor as constitutional head of state. Proviso added by 7th Amendment Act 1956 allows one person to serve as Governor for two or more States.',
      historicalBackground:
          '7th Amendment 1956 facilitated State Reorganisation by allowing shared Governors.',
      searchKeywords: const ['Article 153', 'Governor of State', '7th Amendment 1956', 'Dual Governor'],
      keyTakeaways: const [
        'Constitutional head of the State executive.',
        '7th Amendment 1956 permits one individual to be Governor for multiple states.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '7th Constitutional Amendment Act 1956',
          beforeText: 'Article 153 mandated a separate Governor for each individual state.',
          afterText: 'Proviso added allowing appointment of same person for two or more states.',
          reason: 'Administrative efficiency following State Reorganisation.',
          effectiveDate: DateTime(1956, 11, 1),
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q03'],
      citations: const ['7th Amendment Act 1956', 'Sarkaria Commission Report 1988'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-161',
      articleNumber: '161',
      officialTitle: 'Power of Governor to grant pardons, etc.',
      part: 'Part VI',
      chapter: 'The Executive',
      originalNumber: '161',
      currentNumber: '161',
      title: 'Article 161: Power of Governor to grant pardons',
      officialName: 'ARTICLE 161',
      description: 'The Governor of a State shall have the power to grant pardons, reprieves, respites or remissions of punishment for offences against State laws.',
      officialConstitutionalText:
          'The Governor of a State shall have the power to grant pardons, reprieves, respites or remissions of punishment or to suspend, remit or commute the sentence of any person convicted of any offence against any law relating to a matter to which the executive power of the State extends.',
      originalGarudaExplanation:
          'Empowers the Governor to grant clemency over offenses relating to State executive power. Note: Governor cannot pardon death sentences (only commute/remit) nor court-martial cases.',
      historicalBackground:
          'Maru Ram 1980 & AG Perarivalan 2022 established that Governor acts on advice of State Cabinet under Article 161.',
      searchKeywords: const ['Article 161', 'Governor Clemency', 'Pardoning Power Governor', 'Death Sentence Commutation'],
      keyTakeaways: const [
        'Governor cannot grant absolute pardon for Death Sentence (only President under Art 72 can pardon death).',
        'Governor cannot handle Court Martial sentences.',
        'Pardoning advice of State Cabinet is binding on Governor (Perarivalan Case 2022).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'AG Perarivalan v. State of Tamil Nadu',
          year: 2022,
          bench: 'Supreme Court',
          legalPrinciple: 'Inordinate delay by Governor in exercising Article 161 power justifies Supreme Court invoking Article 142 to release convict.',
          importance: 'Landmark ruling on Governor clemency delays.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2019-GS2-Q08', 'UPSC-CSE-2022-GS2-Q14'],
      citations: const ['Perarivalan Judgment 2022'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-163',
      articleNumber: '163',
      officialTitle: 'Council of Ministers to aid and advise Governor',
      part: 'Part VI',
      chapter: 'The Executive',
      originalNumber: '163',
      currentNumber: '163',
      title: 'Article 163: Council of Ministers to aid and advise Governor',
      officialName: 'ARTICLE 163',
      description: 'There shall be a Council of Ministers with the Chief Minister at the head to aid and advise the Governor except in discretionary matters.',
      officialConstitutionalText:
          '(1) There shall be a Council of Ministers with the Chief Minister at the head to aid and advise the Governor in the exercise of his functions, except in so far as he is by or under this Constitution required to exercise his functions or any of them in his discretion.\n(2) If any question arises whether any matter is or is not a matter as respects which the Governor is by or under this Constitution required to act in his discretion, the decision of the Governor in his discretion shall be final...',
      originalGarudaExplanation:
          'Establishes state cabinet advice to Governor while recognizing constitutional discretionary powers of the Governor (unlike President who has no explicit constitutional discretion under 74).',
      historicalBackground:
          'Discretionary areas include reservation of Bills (Art 200), recommending President\'s Rule (Art 356), and Sixth Schedule autonomous region functions.',
      searchKeywords: const ['Article 163', 'Governor Discretion', 'Aid and Advice Governor', 'Constitutional Discretion'],
      keyTakeaways: const [
        'Governor has explicit constitutional discretion under Article 163(1) & (2).',
        'Discretion is subject to judicial review against arbitrary or partisan action (Nabam Rebia 2016).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Nabam Rebia v. Deputy Speaker',
          year: 2016,
          bench: '5-Judge Bench',
          legalPrinciple: 'Governor\'s discretionary power under Article 163 is limited and not unbridled.',
          importance: 'Constrained discretionary power of Governor regarding legislative sessions.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS2-Q06', 'UPSC-CSE-2021-GS2-Q15'],
      citations: const ['Nabam Rebia 2016', 'Punchhi Commission 2010'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-200',
      articleNumber: '200',
      officialTitle: 'Assent to Bills by Governor',
      part: 'Part VI',
      chapter: 'Legislative Procedure',
      originalNumber: '200',
      currentNumber: '200',
      title: 'Article 200: Assent to Bills by Governor',
      officialName: 'ARTICLE 200',
      description: 'When a Bill has been passed by State Legislature, it shall be presented to the Governor for assent, withholding assent, return, or reservation.',
      officialConstitutionalText:
          'When a Bill has been passed by the Legislative Assembly of a State or, in the case of a State having a Legislative Council, has been passed by both Houses of the Legislature of the State, it shall be presented to the Governor, and the Governor shall declare either that he assents to the Bill, or that he withheld assent therefrom, or that he reserves the Bill for the consideration of the President...',
      originalGarudaExplanation:
          'Outlines Governor\'s four options on state bills: Assent, Withhold Assent, Return for Reconsideration, or Reserve for President\'s consideration.',
      historicalBackground:
          'State of Punjab v. Principal Secretary to Governor (2023) ruled Governor cannot withhold assent endlessly without returning bill.',
      searchKeywords: const ['Article 200', 'Governor Assent', 'Reserve Bill President', 'Withhold Assent', 'State Bills'],
      keyTakeaways: const [
        'Governor must act "as soon as possible" when returning non-Money bills.',
        'If re-passed by assembly, Governor MUST assent or reserve for President.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of Punjab v. Principal Secretary to Governor',
          year: 2023,
          bench: '3-Judge Bench',
          legalPrinciple: 'Governor cannot veto a bill by withholding assent without returning it to the legislature.',
          importance: 'Re-enforced parliamentary democracy at state level.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q09', 'UPSC-CSE-2024-GS2-Q02'],
      citations: const ['Punjab Governor Case 2023'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-213',
      articleNumber: '213',
      officialTitle: 'Power of Governor to promulgate Ordinances during recess of Legislature',
      part: 'Part VI',
      chapter: 'Legislative Power of Governor',
      originalNumber: '213',
      currentNumber: '213',
      title: 'Article 213: Power of Governor to promulgate Ordinances',
      officialName: 'ARTICLE 213',
      description: 'If at any time except when State Legislature is in session Governor is satisfied of immediate action, he may promulgate Ordinances.',
      officialConstitutionalText:
          'If at any time, except when the Legislative Assembly of a State is in session, or where there is a Legislative Council in a State, except when both Houses of the Legislature are in session, the Governor is satisfied that circumstances exist which render it necessary for him to take immediate action, he may promulgate such Ordinances as the circumstances appear to him to require...',
      originalGarudaExplanation:
          'State equivalent of Article 123 empowering Governor to issue ordinances during legislative recess, requiring legislative approval within 6 weeks of reassembly.',
      historicalBackground:
          'DC Wadhwa 1987 struck down Bihar government practice of repromulgating 256 ordinances over 14 years.',
      searchKeywords: const ['Article 213', 'Governor Ordinance', 'Recess of State Legislature', 'DC Wadhwa Case'],
      keyTakeaways: const [
        'Issued on aid & advice of State Cabinet during legislative recess.',
        'Requires prior Presidential instructions for matters requiring Presidential assent.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2019-GS2-Q07'],
      citations: const ['DC Wadhwa Judgment 1987'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-226',
      articleNumber: '226',
      officialTitle: 'Power of High Courts to issue certain writs',
      part: 'Part VI',
      chapter: 'The High Courts in the States',
      originalNumber: '226',
      currentNumber: '226',
      title: 'Article 226: Power of High Courts to issue certain writs',
      officialName: 'ARTICLE 226',
      description: 'Every High Court shall have power to issue writs for the enforcement of Fundamental Rights and for any other purpose.',
      officialConstitutionalText:
          '(1) Notwithstanding anything in article 32, every High Court shall have power, throughout the territories in relation to which it exercises jurisdiction, to issue to any person or authority, including in appropriate cases, any Government, within those territories directions, orders or writs, including writs in the nature of habeas corpus, mandamus, prohibition, quo warranto and certiorari, or any of them, for the enforcement of any of the rights conferred by Part III and for any other purpose.',
      originalGarudaExplanation:
          'Vests expansive writ jurisdiction in High Courts for enforcement of Fundamental Rights AND "for any other purpose" (legal/statutory rights), making Art 226 remedy wider than Art 32.',
      historicalBackground:
          'L. Chandra Kumar 1997 established that judicial review power under Article 226 is part of the inviolable Basic Structure.',
      searchKeywords: const ['Article 226', 'High Court Writs', 'For Any Other Purpose', 'Legal Rights Writs', 'Basic Structure Judicial Review'],
      keyTakeaways: const [
        'Writ scope under Art 226 is WIDER than Art 32 (covers Fundamental Rights + Ordinary Legal Rights).',
        'Judicial review under 226 is a Basic Structure feature (L. Chandra Kumar 1997).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'L. Chandra Kumar v. Union of India',
          year: 1997,
          bench: '7-Judge Bench',
          legalPrinciple: 'Power of judicial review under Articles 226 and 227 is an essential and integral feature of the Basic Structure.',
          importance: 'Restored High Court writ supervisory jurisdiction over administrative tribunals.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2016-GS2-Q03', 'UPSC-CSE-2020-GS2-Q11'],
      citations: const ['L Chandra Kumar Case 1997'],
    ),

    // PART VIII - THE UNION TERRITORIES (Art. 239 - 242)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-239AA',
      articleNumber: '239AA',
      officialTitle: 'Special provisions with respect to Delhi',
      part: 'Part VIII',
      chapter: 'The Union Territories',
      originalNumber: '239AA',
      currentNumber: '239AA',
      title: 'Article 239AA: Special provisions with respect to Delhi',
      officialName: 'ARTICLE 239AA',
      description: 'The Union territory of Delhi shall be called National Capital Territory of Delhi with a Legislative Assembly and Council of Ministers.',
      officialConstitutionalText:
          'As from the date of commencement of the Constitution (Sixty-ninth Amendment) Act, 1991, the Union territory of Delhi shall be called the National Capital Territory of Delhi... and there shall be a Legislative Assembly for the National Capital Territory and the seats in such Assembly shall be filled by members chosen by direct election from territorial constituencies in the National Capital Territory...',
      originalGarudaExplanation:
          'Inserted by 69th Amendment Act 1991, creating Legislative Assembly and Council of Ministers for NCT Delhi, reserving Public Order, Police, and Land under Central control.',
      historicalBackground:
          'Constitution Bench judgments in 2018 and 2023 clarified executive power of elected Delhi Government over services (excluding Public Order, Police, Land).',
      searchKeywords: const ['Article 239AA', 'NCT Delhi', '69th Amendment 1991', 'Delhi Services Executive Power', 'LG vs Delhi Govt'],
      keyTakeaways: const [
        'Inserted by 69th Amendment Act 1991 creating Delhi Assembly.',
        'Delhi Govt has legislative/executive power over State/Concurrent list EXCEPT Public Order, Police, and Land.'
      ],
      effectiveDate: DateTime(1992, 2, 1),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '69th Constitutional Amendment Act 1991',
          beforeText: 'Delhi was governed directly as a Union Territory under Article 239.',
          afterText: 'Article 239AA inserted establishing NCT Delhi with Legislative Assembly.',
          reason: 'To grant democratic self-governance to citizens of National Capital Territory.',
          effectiveDate: DateTime(1992, 2, 1),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'NCT of Delhi v. Union of India (Services Bench)',
          year: 2023,
          bench: '5-Judge Bench',
          legalPrinciple: 'Elected Delhi Government has executive control over administrative services (IAS/officers) under Entry 41 of State List.',
          importance: 'Reaffirmed representative democracy under Article 239AA.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2019-GS2-Q12', 'UPSC-CSE-2023-GS2-Q05'],
      citations: const ['69th Amendment Act 1991', 'Delhi Services Judgment 2023'],
    ),

    // PART IX - THE PANCHAYATS (Art. 243 - 243O)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-243',
      articleNumber: '243',
      officialTitle: 'Definitions relating to Panchayats',
      part: 'Part IX',
      chapter: 'The Panchayats',
      originalNumber: '243',
      currentNumber: '243',
      title: 'Article 243: Definitions relating to Panchayats',
      officialName: 'ARTICLE 243',
      description: 'Provides constitutional definitions for Gram Sabha, Panchayat, District, and Intermediate levels under Part IX.',
      officialConstitutionalText:
          'In this Part, unless the context otherwise requires,—\n(a) "district" means a district in a State;\n(b) "Gram Sabha" means a body consisting of persons registered in the electoral rolls relating to a village comprised within the area of Panchayat at the village level;\n(c) "Panchayat" means an institution (by whatever name called) of self-government constituted under article 243B, for the rural areas...',
      originalGarudaExplanation:
          'Provides constitutional definitions for Part IX (Gram Sabha, Panchayat, Intermediate level, District), inserted by 73rd Amendment Act 1992.',
      historicalBackground:
          '73rd Amendment 1992 added Part IX and 11th Schedule (29 functional items).',
      searchKeywords: const ['Article 243', 'Panchayats Definition', 'Gram Sabha', '73rd Amendment 1992', 'Part IX'],
      keyTakeaways: const [
        'Gram Sabha consists of all registered voters in village electoral roll.',
        'Institutionalizes 3-tier Panchayati Raj system.'
      ],
      effectiveDate: DateTime(1993, 4, 24),
      pyqIds: const ['UPSC-CSE-2016-GS2-Q11'],
      citations: const ['73rd Amendment Act 1992', '11th Schedule'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-243D',
      articleNumber: '243D',
      officialTitle: 'Reservation of seats in Panchayats',
      part: 'Part IX',
      chapter: 'The Panchayats',
      originalNumber: '243D',
      currentNumber: '243D',
      title: 'Article 243D: Reservation of seats in Panchayats',
      officialName: 'ARTICLE 243D',
      description: 'Seats shall be reserved for SCs/STs in proportion to population and not less than one-third of total seats for women.',
      officialConstitutionalText:
          '(1) Seats shall be reserved for—\n(a) the Scheduled Castes; and\n(b) the Scheduled Tribes...\n(3) Not less than one-third (including the number of seats reserved for women belonging to the Scheduled Castes and the Scheduled Tribes) of the total number of seats to be filled by direct election in every Panchayat shall be reserved for women...',
      originalGarudaExplanation:
          'Mandates population-proportionate reservation for SCs/STs and a minimum 33.3% mandatory reservation for women across all Panchayat tiers and Chairperson offices.',
      historicalBackground:
          'K. Vikas Rao 2021 & Rahul Ramesh Wagh 2022 established the "Triple Test" requirement for OBC reservation in local bodies.',
      searchKeywords: const ['Article 243D', 'Panchayat Reservation', 'Women Reservation 33 Percent', 'SC ST Reservation', 'Triple Test OBC'],
      keyTakeaways: const [
        'Mandatory minimum 1/3rd (33.3%) reservation for women in Panchayats.',
        'OBC reservation permitted subject to Supreme Court Triple Test rule.'
      ],
      effectiveDate: DateTime(1993, 4, 24),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'K. Vikas Rao v. State of Maharashtra (Triple Test)',
          year: 2021,
          bench: 'Supreme Court',
          legalPrinciple: 'OBC reservation in local bodies requires dedicated commission empirical inquiry, specific proportion, and total reservation not exceeding 50%.',
          importance: 'Enforced strict 50% cap and empirical verification for local body OBC quotas.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q14', 'UPSC-CSE-2022-GS2-Q07'],
      citations: const ['73rd Amendment Act 1992', 'Triple Test Judgment 2021'],
    ),

    // PART IXA - THE MUNICIPALITIES (Art. 243P - 243ZG)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-243Q',
      articleNumber: '243Q',
      officialTitle: 'Constitution of Municipalities',
      part: 'Part IXA',
      chapter: 'The Municipalities',
      originalNumber: '243Q',
      currentNumber: '243Q',
      title: 'Article 243Q: Constitution of Municipalities',
      officialName: 'ARTICLE 243Q',
      description: 'There shall be constituted in every State a Nagar Panchayat, Municipal Council, and Municipal Corporation based on urban population size.',
      officialConstitutionalText:
          '(1) There shall be constituted in every State,—\n(a) a Nagar Panchayat... for a transitional area;\n(b) a Municipal Council for a smaller urban area;\n(c) a Municipal Corporation for a larger urban area...',
      originalGarudaExplanation:
          'Establishes 3-tier urban local governance: Nagar Panchayat (transitional), Municipal Council (small urban), Municipal Corporation (large urban), inserted by 74th Amendment Act 1992.',
      historicalBackground:
          '74th Amendment 1992 added Part IXA and 12th Schedule (18 functional items).',
      searchKeywords: const ['Article 243Q', 'Municipalities', 'Nagar Panchayat', 'Municipal Corporation', '74th Amendment 1992'],
      keyTakeaways: const [
        'Categorizes urban bodies into 3 tiers based on population and economic factors.',
        'Backed by 12th Schedule with 18 functional items.'
      ],
      effectiveDate: DateTime(1993, 6, 1),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q16'],
      citations: const ['74th Amendment Act 1992', '12th Schedule'],
    ),

    // PART IXB - THE CO-OPERATIVE SOCIETIES (Art. 243ZH - 243ZT)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-243ZH',
      articleNumber: '243ZH',
      officialTitle: 'Definitions relating to Co-operative Societies',
      part: 'Part IXB',
      chapter: 'The Co-operative Societies',
      originalNumber: '243ZH',
      currentNumber: '243ZH',
      title: 'Article 243ZH: Definitions relating to Co-operative Societies',
      officialName: 'ARTICLE 243ZH',
      description: 'Provides constitutional definitions for board, office bearer, and cooperative society under Part IXB.',
      officialConstitutionalText:
          'In this Part, unless the context otherwise requires,—\n(a) "authorised person" means a person authorised by the State Government...\n(b) "board" means the board of directors or the governing body of a co-operative society...',
      originalGarudaExplanation:
          'Inserted by 97th Amendment Act 2011 to grant constitutional status to Co-operative Societies.',
      historicalBackground:
          'Union of India v. Rajendra N. Shah (2021) struck down Part IXB applicability to intra-state cooperatives for lack of state ratification under Art 368(2), upholding it for multi-state cooperatives.',
      searchKeywords: const ['Article 243ZH', 'Co-operative Societies', '97th Amendment 2011', 'Multi State Cooperatives'],
      keyTakeaways: const [
        'Inserted by 97th Amendment Act 2011.',
        'SC in 2021 held Part IXB valid ONLY for Multi-State Co-operative Societies due to state ratification mandate.'
      ],
      effectiveDate: DateTime(2012, 2, 15),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Union of India v. Rajendra N. Shah',
          year: 2021,
          bench: '3-Judge Bench',
          legalPrinciple: 'Part IXB struck down for state cooperatives due to non-ratification by 50% state legislatures under Article 368(2); sustained for Multi-State Cooperatives.',
          importance: 'Landmark federalism ruling on 97th Amendment.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2022-GS2-Q19'],
      citations: const ['97th Amendment Act 2011', 'Rajendra Shah Judgment 2021'],
    ),

    // PART X - SCHEDULED AND TRIBAL AREAS (Art. 244 - 244A)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-244',
      articleNumber: '244',
      officialTitle: 'Administration of Scheduled Areas and Tribal Areas',
      part: 'Part X',
      chapter: 'Scheduled and Tribal Areas',
      originalNumber: '244',
      currentNumber: '244',
      title: 'Article 244: Administration of Scheduled Areas and Tribal Areas',
      officialName: 'ARTICLE 244',
      description: 'Provisions of Fifth Schedule apply to Scheduled Areas in 10 states; provisions of Sixth Schedule apply to tribal areas in Assam, Meghalaya, Tripura, Mizoram.',
      officialConstitutionalText:
          '(1) The provisions of the Fifth Schedule shall apply to the administration and control of the Scheduled Areas and Scheduled Tribes in any State other than the States of Assam, Meghalaya, Tripura and Mizoram.\n(2) The provisions of the Sixth Schedule shall apply to the administration of the tribal areas in the States of Assam, Meghalaya, Tripura and Mizoram.',
      originalGarudaExplanation:
          'Divides tribal administration into Fifth Schedule (10 states: AP, Telangana, Odisha, Jharkhand, Chhattisgarh, MP, Rajasthan, Gujarat, Maharashtra, HP) and Sixth Schedule (4 NE states: Assam, Meghalaya, Tripura, Mizoram).',
      historicalBackground:
          'Fifth Schedule provides Tribes Advisory Councils (TAC); Sixth Schedule creates Autonomous District Councils (ADCs) with legislative, executive, and judicial powers.',
      searchKeywords: const ['Article 244', 'Fifth Schedule', 'Sixth Schedule', 'Tribal Areas', 'Autonomous District Councils', 'PESA 1996'],
      keyTakeaways: const [
        'Fifth Schedule: 10 States (non-NE tribal areas, Tribes Advisory Council).',
        'Sixth Schedule: 4 States (Assam, Meghalaya, Tripura, Mizoram - Autonomous District Councils).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2015-GS1-Q18', 'UPSC-CSE-2019-GS2-Q15', 'UPSC-CSE-2023-GS1-Q09'],
      citations: const ['Fifth Schedule', 'Sixth Schedule', 'PESA Act 1996'],
    ),
  ];
}
