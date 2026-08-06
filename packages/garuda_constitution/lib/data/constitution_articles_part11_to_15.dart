library;

import '../domain/entities/article_knowledge_object.dart';

/// Permanent Production Knowledge Objects for Constitutional Parts XI, XII, XIII, XIV, XIVA, and XV.
class ConstitutionArticlesPart11To15 {
  static final List<ArticleKnowledgeObject> articles = [
    // PART XI - RELATIONS BETWEEN UNION AND STATES (Art. 245 - 263)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-245',
      articleNumber: '245',
      officialTitle: 'Extent of laws made by Parliament and by the Legislatures of States',
      part: 'Part XI',
      chapter: 'Legislative Relations',
      originalNumber: '245',
      currentNumber: '245',
      title: 'Article 245: Extent of laws made by Parliament and State Legislatures',
      officialName: 'ARTICLE 245',
      description: 'Parliament may make laws for the whole or any part of India with extra-territorial operation; State Legislatures may make laws for the whole or any part of the State.',
      officialConstitutionalText:
          '(1) Subject to the provisions of this Constitution, Parliament may make laws for the whole or any part of the territory of India, and the Legislature of a State may make laws for the whole or any part of the State.\n(2) No law made by Parliament shall be deemed to be invalid on the ground that it would have extra-territorial operation.',
      originalGarudaExplanation:
          'Establishes territorial extent of legislation: Parliament has extra-territorial jurisdiction, whereas State Legislatures are restricted to their state territory unless sufficient territorial nexus exists.',
      historicalBackground:
          'Doctrine of Territorial Nexus applies to test extraterritorial validity of State tax/statutory laws.',
      searchKeywords: const ['Article 245', 'Territorial Extent', 'Extra-territorial Operation', 'Territorial Nexus'],
      keyTakeaways: const [
        'Parliament has extra-territorial legislative power.',
        'State laws require territorial nexus to apply outside state boundaries.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'State of Bombay v. RMDC',
          year: 1957,
          bench: 'Supreme Court',
          legalPrinciple: 'Sufficient territorial nexus justifies state tax on prize competitions conducted from outside state.',
          importance: 'Landmark ruling on Territorial Nexus doctrine.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q15'],
      citations: const ['RMDC Case 1957'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-246',
      articleNumber: '246',
      officialTitle: 'Subject-matter of laws made by Parliament and by the Legislatures of States',
      part: 'Part XI',
      chapter: 'Legislative Relations',
      originalNumber: '246',
      currentNumber: '246',
      title: 'Article 246: Subject-matter of laws made by Parliament and State Legislatures',
      officialName: 'ARTICLE 246',
      description: 'Parliament has exclusive power over Union List I; Parliament and States have concurrent power over List III; States have exclusive power over List II.',
      officialConstitutionalText:
          '(1) Notwithstanding anything in clauses (2) and (3), Parliament has exclusive power to make laws with respect to any of the matters enumerated in List I in the Seventh Schedule (Union List).\n(2) Parliament, and... Legislature of any State also, have power to make laws... List III (Concurrent List).\n(3) Subject to clauses (1) and (2), Legislature of any State has exclusive power... List II (State List).',
      originalGarudaExplanation:
          'Defines the 3-List legislative division of powers under Seventh Schedule (Union, State, Concurrent Lists) with Union List non-obstante dominance.',
      historicalBackground:
          'Doctrine of Pith and Substance used to determine true nature of law overlapping list subjects.',
      searchKeywords: const ['Article 246', 'Seventh Schedule', 'Union List', 'State List', 'Concurrent List', 'Pith and Substance'],
      keyTakeaways: const [
        'Federal division of legislative powers under 7th Schedule.',
        'Union List has non-obstante supremacy over State & Concurrent Lists.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2016-GS2-Q02', 'UPSC-CSE-2021-GS2-Q08'],
      citations: const ['Seventh Schedule Lists I, II, III'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-246A',
      articleNumber: '246A',
      officialTitle: 'Special provision with respect to goods and services tax',
      part: 'Part XI',
      chapter: 'Legislative Relations',
      originalNumber: '246A',
      currentNumber: '246A',
      title: 'Article 246A: Special provision with respect to goods and services tax',
      officialName: 'ARTICLE 246A',
      description: 'Parliament and State Legislatures have simultaneous power to make laws with respect to Goods and Services Tax.',
      officialConstitutionalText:
          '(1) Notwithstanding anything contained in articles 246 and 254, Parliament, and, subject to clause (2), the Legislature of every State, have power to make laws with respect to goods and services tax imposed by the Union or by such State.\n(2) Parliament has exclusive power to make laws with respect to goods and services tax where the supply of goods, or of services, or both takes place in the course of inter-State trade or commerce.',
      originalGarudaExplanation:
          'Inserted by 101st Amendment Act 2016 to introduce dual GST power conferred concurrently on Parliament and State Legislatures, bypassing standard Article 246 scheme.',
      historicalBackground:
          'Mohit Minerals 2022 established that GST Council recommendations under Art 279A are persuasive, not binding, preserving Art 246A legislative autonomy.',
      searchKeywords: const ['Article 246A', 'Goods and Services Tax', 'GST Concurrent Power', '101st Amendment 2016', 'Inter-State GST'],
      keyTakeaways: const [
        'Inserted by 101st Amendment Act 2016.',
        'Gives simultaneous legislative power to Parliament and State Legislatures for intra-state GST.',
        'Exclusive Parliament power over Inter-state GST (IGST).'
      ],
      effectiveDate: DateTime(2016, 9, 16),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '101st Constitutional Amendment Act 2016',
          beforeText: 'Taxation power strictly divided between List I and List II under Article 246.',
          afterText: 'Article 246A inserted conferring dual concurrent GST legislative powers.',
          reason: 'To introduce unified Goods and Services Tax (GST) nation-wide.',
          effectiveDate: DateTime(2016, 9, 16),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Union of India v. Mohit Minerals Pvt Ltd',
          year: 2022,
          bench: '3-Judge Bench',
          legalPrinciple: 'GST Council recommendations are persuasive and not binding on Parliament/States; Article 246A embodies cooperative federalism.',
          importance: 'Upheld state legislative autonomy under Article 246A.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q10', 'UPSC-CSE-2022-GS2-Q12'],
      citations: const ['101st Amendment Act 2016', 'Mohit Minerals Judgment 2022'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-248',
      articleNumber: '248',
      officialTitle: 'Residuary powers of legislation',
      part: 'Part XI',
      chapter: 'Legislative Relations',
      originalNumber: '248',
      currentNumber: '248',
      title: 'Article 248: Residuary powers of legislation',
      officialName: 'ARTICLE 248',
      description: 'Parliament has exclusive power to make any law with respect to any matter not enumerated in Concurrent List or State List.',
      officialConstitutionalText:
          '(1) Subject to article 246A, Parliament has exclusive power to make any law with respect to any matter not enumerated in the Concurrent List or State List.\n(2) Such power shall include the power of making any law imposing a tax not mentioned in either of those Lists.',
      originalGarudaExplanation:
          'Vests residuary legislative and tax powers exclusively in Parliament (unlike USA/Australia where residuary powers lie with States).',
      historicalBackground:
          'Reflects Canadian model (British North America Act 1867) strengthening central authority.',
      searchKeywords: const ['Article 248', 'Residuary Powers', 'Parliament Residuary Authority', 'Unenumerated Subjects'],
      keyTakeaways: const [
        'Residuary legislative & taxation powers belong exclusively to Parliament.',
        'Patterned after Canadian Constitution.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q11'],
      citations: const ['Canadian Constitution Act 1867'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-249',
      articleNumber: '249',
      officialTitle: 'Power of Parliament to legislate with respect to a matter in the State List in the national interest',
      part: 'Part XI',
      chapter: 'Legislative Relations',
      originalNumber: '249',
      currentNumber: '249',
      title: 'Article 249: Power of Parliament to legislate on State List in national interest',
      officialName: 'ARTICLE 249',
      description: 'If Rajya Sabha passes a resolution by 2/3rd majority declaring national interest, Parliament may legislate on State List matters.',
      officialConstitutionalText:
          '(1) If the Council of States has declared by resolution supported by not less than two-thirds of the members present and voting that it is necessary or expedient in the national interest that Parliament should make laws with respect to any matter enumerated in the State List... Parliament may make laws for the whole or any part of the territory of India with respect to that matter...',
      originalGarudaExplanation:
          'Empowers Parliament to enact laws on State List subjects if Rajya Sabha passes a resolution by 2/3rd majority present & voting declaring national interest, valid for 1 year at a time.',
      historicalBackground:
          'Demonstrates federal flexibility where Rajya Sabha represents state interests at Union level.',
      searchKeywords: const ['Article 249', 'Rajya Sabha 2/3rd Resolution', 'State List National Interest', 'Parliament State Legislation'],
      keyTakeaways: const [
        'Exclusive initiative of Rajya Sabha (2/3rd present & voting resolution).',
        'Law remains force for max 1 year per resolution extension.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2016-GS2-Q07', 'UPSC-CSE-2020-GS2-Q03'],
      citations: const ['Rules of Procedure Rajya Sabha'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-254',
      articleNumber: '254',
      officialTitle: 'Inconsistency between laws made by Parliament and laws made by the Legislatures of States',
      part: 'Part XI',
      chapter: 'Legislative Relations',
      originalNumber: '254',
      currentNumber: '254',
      title: 'Article 254: Inconsistency between Union and State laws',
      officialName: 'ARTICLE 254',
      description: 'In case of conflict between Parliamentary law and State law on Concurrent List, Parliamentary law prevails unless State law received Presidential assent.',
      officialConstitutionalText:
          '(1) If any provision of a law made by the Legislature of a State is repugnant to any provision of a law made by Parliament... the law made by Parliament shall prevail...\n(2) Where a law made by the Legislature of a State with respect to one of the matters enumerated in the Concurrent List contains any provision repugnant to... an earlier law made by Parliament... the law so made by the Legislature of such State shall, if it has been reserved for the consideration of the President and has received his assent, prevail in that State.',
      originalGarudaExplanation:
          'Resolves repugnancy between Union and State laws on Concurrent List: Parliamentary law prevails unless State law received Presidential assent under 254(2).',
      historicalBackground:
          'Deep Chand 1959 and M. Karunanidhi 1979 established tests for direct conflict and operational repugnancy.',
      searchKeywords: const ['Article 254', 'Repugnancy', 'Concurrent List Conflict', 'Presidential Assent Exemption 254(2)'],
      keyTakeaways: const [
        'Parliamentary law prevails over State law in Concurrent List repugnancy.',
        'Proviso 254(2): State law prevails in that State if it receives Presidential Assent.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'M. Karunanidhi v. Union of India',
          year: 1979,
          bench: '5-Judge Bench',
          legalPrinciple: 'Repugnancy arises when two statutes are fully irreconcilable or occupy the exact same field.',
          importance: 'Laid down 3-part test for Article 254 repugnancy.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2019-GS2-Q14', 'UPSC-CSE-2023-GS2-Q11'],
      citations: const ['M Karunanidhi Case 1979'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-263',
      articleNumber: '263',
      officialTitle: 'Provisions with respect to an Inter-State Council',
      part: 'Part XI',
      chapter: 'Administrative Relations',
      originalNumber: '263',
      currentNumber: '263',
      title: 'Article 263: Provisions with respect to Inter-State Council',
      officialName: 'ARTICLE 263',
      description: 'The President may establish an Inter-State Council to inquire into disputes and discuss subjects of common interest between Union and States.',
      officialConstitutionalText:
          'If at any time it appears to the President that the public interests would be served by the establishment of a Council charged with the duty of—\n(a) inquiring into and advising upon disputes which may have arisen between States;\n(b) investigating and discussing subjects in which some or all of the States, or the Union and one or more of the States, have a common interest... it shall be lawful for the President by order to establish such a Council...',
      originalGarudaExplanation:
          'Enables President to set up an Inter-State Council for advisory coordination between Union and States, established in 1990 on Sarkaria Commission recommendation.',
      historicalBackground:
          'Established by Presidential Order in 1990 following Sarkaria Commission recommendations on Centre-State Relations.',
      searchKeywords: const ['Article 263', 'Inter-State Council', 'Sarkaria Commission', 'Cooperative Federalism'],
      keyTakeaways: const [
        'Advisory constitutional body for inter-state and centre-state coordination.',
        'Established in 1990 by Presidential Order.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2015-GS2-Q10', 'UPSC-CSE-2021-GS2-Q17'],
      citations: const ['Sarkaria Commission Report 1988', 'Inter-State Council Presidential Order 1990'],
    ),

    // PART XII - FINANCE, PROPERTY, CONTRACTS AND SUITS (Art. 264 - 300A)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-279A',
      articleNumber: '279A',
      officialTitle: 'Goods and Services Tax Council',
      part: 'Part XII',
      chapter: 'Finance',
      originalNumber: '279A',
      currentNumber: '279A',
      title: 'Article 279A: Goods and Services Tax Council',
      officialName: 'ARTICLE 279A',
      description: 'The President shall constitute Goods and Services Tax Council to make recommendations to Union and States on GST taxes, exemptions, and rates.',
      officialConstitutionalText:
          '(1) The President shall, within sixty days from the date of commencement of the Constitution (One Hundred and First Amendment) Act, 2016, by order, constitute a Council to be called the Goods and Services Tax Council...\n(4) The Goods and Services Tax Council shall make recommendations to the Union and the States on— (a) taxes, cesses and surcharges... (b) goods and services exempted...',
      originalGarudaExplanation:
          'Constitutes federal GST Council headed by Union Finance Minister with 1/3rd voting weight for Union and 2/3rd for States combined, requiring 75% weighted majority for decisions.',
      historicalBackground:
          'Inserted by 101st Amendment Act 2016 as apex constitutional forum for cooperative fiscal federalism.',
      searchKeywords: const ['Article 279A', 'GST Council', '101st Amendment', 'Fiscal Federalism', 'Weighted Voting 75 Percent'],
      keyTakeaways: const [
        'Chaired by Union Finance Minister.',
        'Voting weightage: Central Govt = 1/3rd, All State Govts combined = 2/3rd.',
        'Decision threshold: 3/4th (75%) weighted majority.'
      ],
      effectiveDate: DateTime(2016, 9, 12),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '101st Amendment Act 2016',
          beforeText: 'No federal tax council existed in Part XII.',
          afterText: 'Article 279A inserted setting up constitutional GST Council.',
          reason: 'To institutionalize federal consensus for GST rates and policies.',
          effectiveDate: DateTime(2016, 9, 12),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Union of India v. Mohit Minerals Pvt Ltd',
          year: 2022,
          bench: '3-Judge Bench',
          legalPrinciple: 'GST Council recommendations have persuasive value fostering collaborative federalism.',
          importance: 'Defined constitutional force of Art 279A recommendations.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS2-Q14', 'UPSC-CSE-2023-GS2-Q02'],
      citations: const ['101st Amendment Act 2016'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-300A',
      articleNumber: '300A',
      officialTitle: 'Persons not to be deprived of property save by authority of law',
      part: 'Part XII',
      chapter: 'Right to Property',
      originalNumber: '300A',
      currentNumber: '300A',
      title: 'Article 300A: Persons not to be deprived of property save by authority of law',
      officialName: 'ARTICLE 300A',
      description: 'No person shall be deprived of his property save by authority of law.',
      officialConstitutionalText: 'No person shall be deprived of his property save by authority of law.',
      originalGarudaExplanation:
          'Shifted Right to Property from Fundamental Right (Art 31 & 19(1)(f)) to a Constitutional/Legal Right under Part XII via 44th Amendment Act 1978.',
      historicalBackground:
          '44th Amendment 1978 repealed Articles 19(1)(f) & 31, inserting Art 300A. Kolkata Municipal Corp 2024 affirmed property right remains a human right requiring fair compensation procedure.',
      searchKeywords: const ['Article 300A', 'Right to Property', '44th Amendment 1978', 'Constitutional Right Property'],
      keyTakeaways: const [
        'Property is a Constitutional & Human Right, NOT a Fundamental Right.',
        'State cannot acquire private property without authority of law and just procedure (Kolkata Corp 2024).'
      ],
      effectiveDate: DateTime(1979, 6, 20),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '44th Constitutional Amendment Act 1978',
          beforeText: 'Right to Property was a Fundamental Right under Articles 19(1)(f) and 31.',
          afterText: 'Articles 19(1)(f) and 31 omitted; Article 300A inserted in Part XII.',
          reason: 'To prevent fundamental rights litigation blocking land reform and welfare acquisition.',
          effectiveDate: DateTime(1979, 6, 20),
        ),
      ],
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Kolkata Municipal Corporation v. Subhasis Biswas',
          year: 2024,
          bench: '2-Judge Bench',
          legalPrinciple: 'Compulsory acquisition under Article 300A requires 7 sub-rights including notice, hearing, reasoned decision, and fair compensation.',
          importance: 'Strengthened procedural safeguards under Article 300A.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS1-Q12', 'UPSC-CSE-2021-GS1-Q35'],
      citations: const ['44th Amendment Act 1978', 'Kolkata Municipal Corp Case 2024'],
    ),

    // PART XIII - TRADE, COMMERCE AND INTERCOURSE WITHIN INDIA (Art. 301 - 307)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-301',
      articleNumber: '301',
      officialTitle: 'Freedom of trade, commerce and intercourse',
      part: 'Part XIII',
      chapter: 'Trade, Commerce and Intercourse',
      originalNumber: '301',
      currentNumber: '301',
      title: 'Article 301: Freedom of trade, commerce and intercourse',
      officialName: 'ARTICLE 301',
      description: 'Subject to provisions of Part XIII, trade, commerce and intercourse throughout the territory of India shall be free.',
      officialConstitutionalText:
          'Subject to the other provisions of this Part, trade, commerce and intercourse throughout the territory of India shall be free.',
      originalGarudaExplanation:
          'Guarantees free flow of inter-state and intra-state trade, commerce, and intercourse across India, subject to public interest restrictions under Arts 302-304.',
      historicalBackground:
          'Inspired by Section 92 of Australian Constitution to build single economic market.',
      searchKeywords: const ['Article 301', 'Freedom of Trade and Commerce', 'Inter-state Trade', 'Australian Model'],
      keyTakeaways: const [
        'Ensures economic unity and barrier-free trade across state borders.',
        'Compensatory taxes do not violate Article 301 (Jindal Stainless 2016).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Jindal Stainless Ltd v. State of Haryana',
          year: 2016,
          bench: '9-Judge Bench',
          legalPrinciple: 'Taxes on entry of goods into local areas do not violate Article 301 if non-discriminatory.',
          importance: '9-judge benchmark ruling on entry tax & free trade.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q18'],
      citations: const ['Jindal Stainless Case 2016'],
    ),

    // PART XIV - SERVICES UNDER UNION AND STATES (Art. 308 - 323)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-311',
      articleNumber: '311',
      officialTitle: 'Dismissal, removal or reduction in rank of civil servants',
      part: 'Part XIV',
      chapter: 'Services',
      originalNumber: '311',
      currentNumber: '311',
      title: 'Article 311: Dismissal, removal or reduction in rank of civil servants',
      officialName: 'ARTICLE 311',
      description: 'No civil servant shall be dismissed by subordinate authority nor dismissed without an inquiry and reasonable opportunity of being heard.',
      officialConstitutionalText:
          '(1) No person who is a member of a civil service of the Union or an all-India service or a civil service of a State... shall be dismissed or removed by an authority subordinate to that by which he was appointed.\n(2) No such person as aforesaid shall be dismissed or removed or reduced in rank except after an inquiry in which he has been informed of the charges against him and given a reasonable opportunity of being heard...',
      originalGarudaExplanation:
          'Provides constitutional protection to civil servants against arbitrary dismissal, mandating departmental inquiry and opportunity of hearing (principles of natural justice).',
      historicalBackground:
          'Second proviso permits dispensing with inquiry on security of State grounds or conviction on criminal charge.',
      searchKeywords: const ['Article 311', 'Civil Services Protection', 'Natural Justice Inquiry', 'Pleasure Doctrine Safeguard'],
      keyTakeaways: const [
        'Safeguard against subordinate authority dismissal.',
        'Mandatory inquiry and natural justice hearing before dismissal/demotion.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Union of India v. Tulsiram Patel',
          year: 1985,
          bench: '5-Judge Bench',
          legalPrinciple: 'Dispensing with inquiry under second proviso to 311(2) in interest of security of State is valid and subject to limited judicial review.',
          importance: 'Defined exceptions to Article 311 natural justice inquiry.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2016-GS2-Q14', 'UPSC-CSE-2022-GS2-Q16'],
      citations: const ['Tulsiram Patel Case 1985'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-312',
      articleNumber: '312',
      officialTitle: 'All-India services',
      part: 'Part XIV',
      chapter: 'Services',
      originalNumber: '312',
      currentNumber: '312',
      title: 'Article 312: All-India services',
      officialName: 'ARTICLE 312',
      description: 'If Rajya Sabha declares by 2/3rd resolution in national interest, Parliament may by law create one or more All-India Services.',
      officialConstitutionalText:
          '(1) Notwithstanding anything in Chapter VI of Part X or Part XI, if the Council of States has declared by resolution supported by not less than two-thirds of the members present and voting that it is necessary or expedient in the national interest so to do, Parliament may by law provide for the creation of one or more all-India services (including an all-India judicial service) common to the Union and the States...',
      originalGarudaExplanation:
          'Vests exclusive power in Rajya Sabha (2/3rd resolution) to initiate creation of new All-India Services (e.g. IAS, IPS, IFoS created 1966, All India Judicial Service proposed).',
      historicalBackground:
          'Indian Forest Service created under Art 312 in 1966. 42nd Amendment 1976 added All India Judicial Service (AIJS).',
      searchKeywords: const ['Article 312', 'All-India Services', 'Rajya Sabha Exclusive Power', 'IAS IPS IFoS', 'AIJS'],
      keyTakeaways: const [
        'Creation of new All-India Service requires Rajya Sabha 2/3rd resolution.',
        'Current AIS: IAS, IPS, IFoS (Forest Service added 1966).'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      pyqIds: const ['UPSC-CSE-2017-GS2-Q03', 'UPSC-CSE-2020-GS2-Q05'],
      citations: const ['All-India Services Act 1951'],
    ),

    // PART XIVA - TRIBUNALS (Art. 323A - 323B)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-323A',
      articleNumber: '323A',
      officialTitle: 'Administrative tribunals',
      part: 'Part XIVA',
      chapter: 'Tribunals',
      originalNumber: '323A',
      currentNumber: '323A',
      title: 'Article 323A: Administrative tribunals',
      officialName: 'ARTICLE 323A',
      description: 'Parliament may by law provide for administrative tribunals for public service disputes.',
      officialConstitutionalText:
          '(1) Parliament may, by law, provide for the adjudication or trial by administrative tribunals of disputes and complaints with respect to recruitment and conditions of service of persons appointed to public services...',
      originalGarudaExplanation:
          'Inserted by 42nd Amendment Act 1976 authorizing Parliament to set up Administrative Tribunals (CAT & SAT) for public service disputes.',
      historicalBackground:
          'L. Chandra Kumar 1997 ruled tribunals act as courts of first instance, but decisions remain subject to High Court writ review under Art 226/227.',
      searchKeywords: const ['Article 323A', 'Administrative Tribunals', 'CAT SAT', '42nd Amendment 1976', 'L Chandra Kumar'],
      keyTakeaways: const [
        'Inserted by 42nd Amendment Act 1976.',
        'Administrative Tribunals established exclusively by Parliament law (Administrative Tribunals Act 1985).'
      ],
      effectiveDate: DateTime(1977, 1, 3),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'L. Chandra Kumar v. Union of India',
          year: 1997,
          bench: '7-Judge Bench',
          legalPrinciple: 'Tribunals are subject to writ jurisdiction of Division Bench of High Courts under Article 226/227.',
          importance: 'Overruled exclusion of High Court judicial review over tribunals.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2018-GS2-Q12', 'UPSC-CSE-2021-GS2-Q14'],
      citations: const ['Administrative Tribunals Act 1985', 'L Chandra Kumar 1997'],
    ),

    // PART XV - ELECTIONS (Art. 324 - 329A)
    ArticleKnowledgeObject(
      objectId: 'KO-ART-324',
      articleNumber: '324',
      officialTitle: 'Superintendence, direction and control of elections vested in Election Commission',
      part: 'Part XV',
      chapter: 'Elections',
      originalNumber: '324',
      currentNumber: '324',
      title: 'Article 324: Superintendence, direction and control of elections in ECI',
      officialName: 'ARTICLE 324',
      description: 'Superintendence, direction and control of elections to Parliament, State Legislatures, President, and Vice-President shall be vested in Election Commission.',
      officialConstitutionalText:
          '(1) The superintendence, direction and control of the preparation of the electoral rolls for, and the conduct of, all elections to Parliament and to the Legislature of every State and of elections to the offices of President and Vice-President held under this Constitution shall be vested in a Commission (referred to in this Constitution as the Election Commission).\n(2) The Election Commission shall consist of the Chief Election Commissioner and such number of other Election Commissioners...',
      originalGarudaExplanation:
          'Vests plenary powers of superintendence, direction, and conduct of Parliament, State Assembly, President, and Vice-President elections in the Election Commission of India.',
      historicalBackground:
          'Anoop Baranwal 2023 mandated independent selection committee for CEC/EC appointment, leading to Chief Election Commissioner and Other Election Commissioners Act 2023.',
      searchKeywords: const ['Article 324', 'Election Commission of India', 'ECI Plenary Powers', 'CEC Appointment', 'Anoop Baranwal Case'],
      keyTakeaways: const [
        'Plenary powers over conduct of elections to Parliament, State Legislatures, President & Vice-President.',
        'CEC removable like SC Judge; ECs removable on recommendation of CEC.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      caseLaw: const [
        ArticleCaseLawRecord(
          caseName: 'Mohinder Singh Gill v. Chief Election Commissioner',
          year: 1978,
          bench: '5-Judge Bench',
          legalPrinciple: 'Article 324 is a reservoir of power for ECI to ensure free and fair elections where enacted laws are silent.',
          importance: 'Established broad plenary scope of ECI powers.',
        ),
        ArticleCaseLawRecord(
          caseName: 'Anoop Baranwal v. Union of India',
          year: 2023,
          bench: '5-Judge Bench',
          legalPrinciple: 'Independence of ECI requires neutral selection process for appointment of CEC and ECs.',
          importance: 'Triggered new statutory framework for CEC/EC appointments.',
        ),
      ],
      pyqIds: const ['UPSC-CSE-2017-GS2-Q01', 'UPSC-CSE-2023-GS2-Q01'],
      citations: const ['Representation of the People Act 1950 & 1951', 'CEC Act 2023'],
    ),

    ArticleKnowledgeObject(
      objectId: 'KO-ART-326',
      articleNumber: '326',
      officialTitle: 'Elections on the basis of adult suffrage',
      part: 'Part XV',
      chapter: 'Elections',
      originalNumber: '326',
      currentNumber: '326',
      title: 'Article 326: Elections on the basis of adult suffrage',
      officialName: 'ARTICLE 326',
      description: 'Elections to Lok Sabha and State Legislative Assemblies shall be on the basis of universal adult suffrage (age 18 years).',
      officialConstitutionalText:
          'The elections to the House of the People and to the Legislative Assembly of every State shall be on the basis of adult suffrage; that is to say, every person who is a citizen of India and who is not less than eighteen years of age on such date as may be fixed... shall be entitled to be registered as a voter at any such election...',
      originalGarudaExplanation:
          'Guarantees Universal Adult Suffrage for citizens, lowered from 21 years to 18 years by the 61st Constitutional Amendment Act 1988.',
      historicalBackground:
          '61st Amendment 1988 democratized voting rights by extending franchise to 18-year-old youth.',
      searchKeywords: const ['Article 326', 'Universal Adult Suffrage', 'Voting Age 18 Years', '61st Amendment 1988'],
      keyTakeaways: const [
        'Universal Adult Franchise at 18 years.',
        'Voting age lowered from 21 to 18 by 61st Amendment Act 1988.'
      ],
      effectiveDate: DateTime(1950, 1, 26),
      amendmentHistory: [
        ArticleAmendmentRecord(
          amendmentName: '61st Constitutional Amendment Act 1988',
          beforeText: 'Voting age was twenty-one years.',
          afterText: 'Voting age reduced to eighteen years.',
          reason: 'To expand democratic participation among young citizens.',
          effectiveDate: DateTime(1989, 3, 28),
        ),
      ],
      pyqIds: const ['UPSC-CSE-2015-GS1-Q10', 'UPSC-CSE-2021-GS2-Q01'],
      citations: const ['61st Amendment Act 1988'],
    ),
  ];
}
