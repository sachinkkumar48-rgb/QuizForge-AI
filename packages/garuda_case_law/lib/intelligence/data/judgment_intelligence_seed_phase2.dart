/// Curated Judgment Intelligence for the 29 Phase-II landmark cases
/// (TITAN-KO-015.0 P4).
///
/// Holdings, outcome, significance and timeline carry verified evidence
/// references (traceable to the official judgment record). UPSC intelligence
/// and interpretive characterizations are editorial analysis grounded in those
/// verified facts. Where a fact cannot be established it is left empty.
library;

import '../domain/intelligence_enums.dart';
import '../domain/judgment_intelligence.dart';
import 'judgment_intelligence_seed.dart';

/// Phase-II curated intelligence seeds keyed by caseId.
class JudgmentIntelligenceSeedPhase2 {
  static final Map<String, JudgmentIntelligenceSeed> seeds = {
    // -----------------------------------------------------------------------
    // 1. L. Chandra Kumar v. Union of India (1997)
    // -----------------------------------------------------------------------
    'L_CHANDRA_KUMAR': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_chandra_kumar_1',
          holding:
              'Judicial review under Articles 32 and 226 is a basic feature of '
              'the Constitution; clauses in Articles 323A and 323B excluding '
              'High Court jurisdiction are unconstitutional.',
          legalPrinciple: 'Judicial review is a basic feature; tribunals are subject to HC/Supreme Court review.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('L_CHANDRA_KUMAR'),
        ),
        JudgmentHolding(
          holdingId: 'hol_chandra_kumar_2',
          holding:
              'Tribunals created under Articles 323A and 323B remain valid and '
              'are subject to the writ jurisdiction of the High Courts.',
          legalPrinciple: 'Tribunal decisions reviewable by High Courts under Article 226.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('L_CHANDRA_KUMAR'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The 7-judge bench affirmed that the power of judicial review vested '
            'in the Supreme Court and High Courts is part of the basic structure, '
            'so no tribunal can wholly oust the writ jurisdiction of the High '
            'Courts.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Judicial review as the backbone of constitutional governance',
        ],
        doctrinalReasoning: const ['Basic Structure Doctrine', 'Tribunal jurisprudence'],
        reasoningTools: const ['structural interpretation'],
        evidence: edr('L_CHANDRA_KUMAR'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'The exclusion of High Court jurisdiction under Articles 323A(2)(d) '
            'and 323B(3)(d) held unconstitutional; tribunals upheld subject to '
            'High Court review.',
        majorityOutcome: 'Judicial review preserved; tribunals remain valid.',
        evidence: evr('L_CHANDRA_KUMAR'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The definitive authority on tribunals and judicial review, making '
            'the High Courts\' supervisory role over tribunals inviolable.',
        legalSignificance:
            'Laid down that tribunal orders are appealable/reviewable under '
            'Articles 226 and 32.',
        upscSignificance:
            'Asked on tribunal reforms, Articles 323A/323B and the basic '
            'structure doctrine.',
        historicalSignificance:
            'Decided 1997; shaped the framework for the later Tribunal '
            'Reforms Act and the National Tribunals Commission debate.',
        significanceScore: 87,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1997 by a 7-judge bench.',
          'Judicial review under Articles 32 and 226 is a basic feature.',
          'Tribunals under Articles 323A/323B cannot oust High Court jurisdiction.',
        ],
        prelimsTraps: [
          'L. Chandra Kumar did NOT abolish tribunals — it made their orders '
          'reviewable by High Courts.',
        ],
        mainsThemes: [
          'Tribunals and the basic structure doctrine',
          'Access to justice and judicial review',
        ],
        mainsArguments: [
          'A tribunal cannot substitute for the High Court\'s constitutional '
          'judicial review.',
        ],
        answerKeywords: [
          'L. Chandra Kumar', 'Article 323A', 'Tribunals', 'Judicial Review',
          'Basic Structure', 'Article 226',
        ],
        essayThemes: [
          'Specialised justice without losing constitutional oversight',
        ],
        interviewAreas: [
          'Why have tribunal reforms struggled in India?',
        ],
        answerEnrichmentPoints: [
          'The judgment responded to the tribunalisation trend of the 1980s-90s.',
        ],
        contemporaryRelevance: [
          'Central to the debate on Tribunal Reforms and the "search for a '
          'sure foundation" in institutional adjudication.',
        ],
        likelyInterviewQuestions: [
          'Should tribunals be insulated from government control?',
        ],
        conclusionIdeas: [
          'L. Chandra Kumar lets tribunals specialise while keeping the High '
          'Courts as the constitutional backstop.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1997,
          event: 'L. Chandra Kumar decided.',
          significance: 'Judicial review over tribunals affirmed.',
          evidence: evr('L_CHANDRA_KUMAR'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 2. Supreme Court Advocates-on-Record Assn. v. Union of India (1993)
    // -----------------------------------------------------------------------
    'SC_OR_1993': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_scor93_1',
          holding:
              'In appointment of judges, the opinion of the Chief Justice of '
              'India has primacy, formed in consultation with a collegium of '
              'the senior-most judges of the Supreme Court.',
          legalPrinciple: 'Collegium system; primacy of the CJI in judicial appointments.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SC_OR_1993'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 9-judge bench construed "consultation" in Articles 124(2) and '
            '217(1) as requiring concurrence of the CJI acting with a collegium, '
            'overruling the First Judges Case.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Independence of the judiciary as a basic feature',
        ],
        doctrinalReasoning: const ['Collegium Doctrine', 'Basic Structure Doctrine'],
        reasoningTools: const ['purposive construction of "consultation"'],
        evidence: edr('SC_OR_1993'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'The Second Judges Case: "consultation" means the opinion of the '
            'CJI formed in consultation with the collegium; the executive\'s role '
            'in appointments confined.',
        majorityOutcome: 'Collegium primacy in judicial appointments.',
        evidence: evr('SC_OR_1993'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established the collegium method for judicial appointments, a '
            'linchpin of judicial independence.',
        legalSignificance:
            'Overruled S.P. Gupta (First Judges Case, 1981) and set the primacy '
            'of the CJI-led collegium.',
        upscSignificance:
            'High-frequency on judicial appointments, the collegium and the '
            'later NJAC controversy.',
        historicalSignificance:
            'Decided 1993; followed by the 1998 (Third Judges Case) and the '
            '2015 NJAC ruling.',
        significanceScore: 90,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1993 by a 9-judge bench.',
          'Established the collegium for judicial appointments.',
          '"Consultation" under Article 124(2) means concurrence of the CJI-led collegium.',
        ],
        prelimsTraps: [
          'SC_OR 1993 is the Second Judges Case; S.P. Gupta (1981) was the First.',
          'The collegium appoints judges, but appointments need the President\'s warrant.',
        ],
        mainsThemes: [
          'Judicial appointments and independence',
          'Collegium vs NJAC debate',
        ],
        answerKeywords: [
          'Collegium', 'Article 124(2)', 'Second Judges Case', 'CJI',
          'Judicial Appointments', 'Basic Structure',
        ],
        essayThemes: [
          'Who should appoint the guardians of the Constitution?',
        ],
        interviewAreas: [
          'Is the collegium system compatible with accountability?',
        ],
        answerEnrichmentPoints: [
          'The 99th Amendment (NJAC) was struck down in 2015, restoring the '
          'collegium.',
        ],
        contemporaryRelevance: [
          'The collegium-vs-executive tussle over appointments continues.',
        ],
        likelyInterviewQuestions: [
          'Why was the NJAC struck down?',
        ],
        conclusionIdeas: [
          'The Second Judges Case entrenched judicial primacy in appointments '
          'as the price of independence.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1993,
          event: 'Second Judges Case decided.',
          significance: 'Collegium system established.',
          evidence: evr('SC_OR_1993'),
        ),
        JudgmentTimelineEvent(
          year: 2015,
          event: 'NJAC struck down.',
          significance: 'Collegium restored.',
          evidence: evr('SC_OR_1993'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 3. Supreme Court Advocates-on-Record Assn. v. Union of India (NJAC, 2015)
    // -----------------------------------------------------------------------
    'NJAC_2015': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_njac_1',
          holding:
              'The 99th Constitutional Amendment and the NJAC Act are '
              'unconstitutional for violating the basic structure of judicial '
              'independence.',
          legalPrinciple: 'Judicial independence is a basic feature; the NJAC diluted it.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('NJAC_2015'),
        ),
        JudgmentHolding(
          holdingId: 'hol_njac_2',
          holding:
              'The primacy of the judiciary in judicial appointments is part of '
              'the basic structure.',
          legalPrinciple: 'Judicial primacy in appointments is constitutionally entrenched.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('NJAC_2015'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The 5-judge bench held that the NJAC, with two lay members and a '
            'Union Minister, compromised the primacy of the judiciary and thus '
            'the independence of the judiciary, a basic feature.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Independence of the judiciary as inseparable from democracy',
        ],
        doctrinalReasoning: const ['Basic Structure Doctrine', 'Collegium Doctrine'],
        reasoningTools: const ['structural interpretation'],
        evidence: edr('NJAC_2015'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            '99th Amendment and NJAC Act struck down; the collegium system '
            'restored.',
        majorityOutcome: 'NJAC unconstitutional; collegium continues.',
        evidence: evr('NJAC_2015'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Confirmed that judicial independence — including primacy in '
            'appointments — is part of the basic structure.',
        legalSignificance:
            'Invalidated a constitutional amendment through basic-structure '
            'review (a direct application of Kesavananda and Minerva Mills).',
        upscSignificance:
            'Asked on the NJAC, collegium, and basic structure application to '
            'appointments.',
        historicalSignificance:
            'Decided 2015; the most recent major use of the basic structure '
            'doctrine to strike down an amendment.',
        significanceScore: 91,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2015 by a 5-judge bench (4:1).',
          '99th Amendment and NJAC Act struck down.',
          'Judicial independence and primacy held part of the basic structure.',
          'Collegium system restored.',
        ],
        prelimsTraps: [
          'NJAC was struck down for diluting judicial primacy, not for '
          'being a commission per se.',
          'The 99th Amendment was the first successful basic-structure '
          'invalidation in decades.',
        ],
        mainsThemes: [
          'Judicial appointments and the basic structure',
          'Balance of powers in judicial selection',
        ],
        mainsArguments: [
          'An appointments body with executive and lay members undermines '
          'judicial independence.',
        ],
        mainsCounterarguments: [
          'A purely judicial collegium lacks accountability and transparency.',
        ],
        answerKeywords: [
          'NJAC', '99th Amendment', 'Collegium', 'Basic Structure',
          'Judicial Independence', 'Appointments',
        ],
        essayThemes: [
          'Accountability vs independence in institutional design',
        ],
        interviewAreas: [
          'How should judicial appointments balance independence and '
          'accountability?',
        ],
        answerEnrichmentPoints: [
          'Four judges held the amendment unconstitutional; Justice Chelameswar '
          'dissented.',
          'The judgment applied the basic structure doctrine to appointment '
          'architecture.',
        ],
        contemporaryRelevance: [
          'Ongoing debate over the Memorandum of Procedure and appointment '
          'reform.',
        ],
        likelyInterviewQuestions: [
          'Can a future amendment design a valid alternative to the collegium?',
        ],
        conclusionIdeas: [
          'NJAC reaffirmed that the judiciary must have the final word in '
          'guarding its own independence.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2015,
          event: 'NJAC struck down.',
          significance: 'Collegium restored; basic structure applied to appointments.',
          evidence: evr('NJAC_2015'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 4. Shreya Singhal v. Union of India (2015)
    // -----------------------------------------------------------------------
    'SHREYA_SINGHAL': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_shreya_1',
          holding:
              'Section 66A of the Information Technology Act, 2000 is '
              'unconstitutional for being vague and disproportionately restricting '
              'freedom of speech under Article 19(1)(a).',
          legalPrinciple: 'Vague and overbroad speech restrictions are void under Article 19(2).',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SHREYA_SINGHAL'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court applied the three-fold test under Article 19(2) and held '
            'that Section 66A\'s terms such as "annoyance" and "inconvenience" '
            'were not saved by the grounds of reasonable restriction, and that '
            'intermediary liability under Section 79 was upheld subject to '
            'safeguards.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Online speech enjoys the same protection as offline speech',
        ],
        doctrinalReasoning: const ['Reasonable restriction doctrine', 'Vagueness doctrine'],
        reasoningTools: const ['overbreadth', 'chilling effect', 'reasonableness'],
        evidence: edr('SHREYA_SINGHAL'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 66A struck down; Sections 69A and 79 (intermediary liability) '
            'upheld with safeguards.',
        majorityOutcome: '66A void; other provisions upheld.',
        evidence: evr('SHREYA_SINGHAL'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established that the Constitution protects online speech equally '
            'and that vague internet speech offences are void.',
        legalSignificance:
            'Struck down Section 66A; clarified the scope of Article 19(2) '
            'grounds for digital speech.',
        upscSignificance:
            'Asked for Section 66A, online speech, and the IT Act framework.',
        historicalSignificance:
            'Decided 2015 after widespread misuse of Section 66A; a watershed '
            'for internet freedom.',
        significanceScore: 88,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2015 by a 2-judge bench.',
          'Section 66A IT Act struck down for vagueness.',
          'Article 19(1)(a) protects online speech.',
          'Section 69A (blocking) and 79 (intermediary liability) upheld.',
        ],
        prelimsTraps: [
          'Only Section 66A was struck down — not the whole IT Act.',
          'Intermediary liability under Section 79 remains valid.',
        ],
        mainsThemes: [
          'Free speech and the internet',
          'Vagueness and reasonable restrictions',
        ],
        answerKeywords: [
          'Shreya Singhal', 'Section 66A', 'IT Act 2000', 'Free Speech',
          'Article 19(1)(a)', 'Vagueness',
        ],
        essayThemes: [
          'The digital public square and the rule of law',
        ],
        interviewAreas: [
          'How should the state balance online speech and misinformation?',
        ],
        answerEnrichmentPoints: [
          'The judgment rejected overbreadth and the chilling effect.',
          'Digital data protection and intermediary rules now build on its '
          'logic.',
        ],
        contemporaryRelevance: [
          'Central to debates on IT Rules, online censorship and platform '
          'accountability.',
        ],
        likelyInterviewQuestions: [
          'Are today\'s IT intermediary rules consistent with Shreya Singhal?',
        ],
        conclusionIdeas: [
          'Shreya Singhal keeps the internet tethered to the same '
          'constitutional freedoms as the street.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2015,
          event: 'Shreya Singhal decided.',
          significance: 'Section 66A struck down.',
          evidence: evr('SHREYA_SINGHAL'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 5. State of Rajasthan v. Union of India (1977)
    // -----------------------------------------------------------------------
    'STATE_RAJASTHAN_V_UNION': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_rajasthan_1',
          holding:
              'A proclamation under Article 356 is not wholly immune from '
              'judicial review, though the Court will exercise restraint.',
          legalPrinciple: 'Article 356 is justiciable in limited circumstances.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('STATE_RAJASTHAN_V_UNION'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 7-judge bench held that while the satisfaction of the President '
            'under Article 356 is subjective, malafides, extraneous '
            'considerations and absence of material can be examined by the Court.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Limited judicial review of presidential discretion',
        ],
        doctrinalReasoning: const ['Justiciability of Article 356'],
        reasoningTools: const ['judicial restraint', 'mala fides review'],
        evidence: edr('STATE_RAJASTHAN_V_UNION'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.dismissed,
        operativeResult:
            'Challenges to the 1977 Assembly dissolutions dismissed, but the '
            'reviewability of Article 356 was accepted in principle.',
        majorityOutcome: 'Article 356 justiciable in principle; restraint exercised.',
        evidence: evr('STATE_RAJASTHAN_V_UNION'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established the justiciability of Article 356, paving the way for '
            'the fuller doctrine in S.R. Bommai (1994).',
        legalSignificance:
            'First authoritative statement that the President\'s satisfaction is '
            'reviewable.',
        upscSignificance:
            'Asked in the Article 356 / President\'s Rule sequence before Bommai.',
        historicalSignificance:
            'Decided 1977, testing the post-Emergency dissolutions.',
        significanceScore: 74,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1977 by a 7-judge bench.',
          'Held Article 356 is subject to limited judicial review.',
          'Predecessor of S.R. Bommai (1994).',
        ],
        prelimsTraps: [
          'State of Rajasthan upheld the proclamations; it only accepted '
          'reviewability in principle.',
        ],
        mainsThemes: [
          'Article 356 and federalism',
          'Judicial review of presidential discretion',
        ],
        answerKeywords: [
          'Article 356', 'President\'s Rule', 'Judicial Review',
          'State of Rajasthan v UoI', 'Federalism',
        ],
        essayThemes: [
          'Emergency powers and constitutional restraint',
        ],
        interviewAreas: [
          'How did State of Rajasthan set up the Bommai doctrine?',
        ],
        answerEnrichmentPoints: [
          'The Court accepted review for malafides and extraneous material.',
        ],
        contemporaryRelevance: [
          'Cited whenever Article 356 misuse is alleged.',
        ],
        likelyInterviewQuestions: [
          'When can a court strike down a President\'s Rule proclamation?',
        ],
        conclusionIdeas: [
          'State of Rajasthan opened the door that Bommai later walked through.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1977,
          event: 'State of Rajasthan decided.',
          significance: 'Article 356 reviewability accepted.',
          evidence: evr('STATE_RAJASTHAN_V_UNION'),
        ),
        JudgmentTimelineEvent(
          year: 1994,
          event: 'S.R. Bommai expanded the doctrine.',
          significance: 'Article 356 made fully justiciable with floor test.',
          evidence: evr('STATE_RAJASTHAN_V_UNION'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 6. Nabam Rebia v. Deputy Speaker (2016)
    // -----------------------------------------------------------------------
    'NABAM_REBIA': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_nabam_1',
          holding:
              'The Governor cannot summon or dissolve an Assembly in a manner '
              'that defeats a pending disqualification petition; a majority is to '
              'be tested on the floor of the House.',
          legalPrinciple: 'Floor test; Governor\'s discretion cannot bypass Article 174 safeguards.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('NABAM_REBIA'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The 5-judge bench laid down that while a floor test is ordered, '
            'the Governor acts on aid and advice and cannot act to frustrate the '
            'constitutional process of deciding disqualification.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Parliamentary democracy and the floor test',
        ],
        doctrinalReasoning: const ['Floor Test Doctrine'],
        reasoningTools: const ['constitutional balancing'],
        evidence: edr('NABAM_REBIA'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Held the Governor\'s actions to convene the Assembly without '
            'resolving the disqualification issue as unconstitutional; the '
            'Assembly was directed to be convened properly.',
        majorityOutcome: 'Floor test preserved; Governor\'s discretion constrained.',
        evidence: evr('NABAM_REBIA'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Defined the constitutional limits on the Governor\'s powers to '
            'summon and dissolve an Assembly.',
        legalSignificance:
            'Clarified the interplay of Articles 163, 174, 175 and 356 with '
            'disqualification proceedings.',
        upscSignificance:
            'Asked in federalism and Governor-discretion questions; the '
            'Arunachal case.',
        historicalSignificance:
            'Decided 2016 in the Arunachal Pradesh political crisis.',
        significanceScore: 84,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2016 by a 5-judge bench.',
          'Governor cannot use summoning/dissolution powers to defeat '
          'disqualification proceedings.',
          'Majority must be tested on the floor of the House.',
        ],
        prelimsTraps: [
          'Nabam Rebia is about the Governor and floor test, not about '
          'reservation or appointments.',
        ],
        mainsThemes: [
          'Governor\'s discretionary powers and federalism',
          'Floor test and parliamentary democracy',
        ],
        answerKeywords: [
          'Nabam Rebia', 'Floor Test', 'Governor', 'Article 174',
          'Disqualification', 'Federalism',
        ],
        essayThemes: [
          'When the head of state and the legislature collide',
        ],
        interviewAreas: [
          'Should Governors act as neutral umpires?',
        ],
        answerEnrichmentPoints: [
          'Built on S.R. Bommai\'s floor-test doctrine.',
          'Later applied in the 2018 Karnataka and 2020 MP/Manipur floor-test '
          'orders.',
        ],
        contemporaryRelevance: [
          'Constantly cited in coalition and defection disputes.',
        ],
        likelyInterviewQuestions: [
          'What limits does the Constitution place on a Governor?',
        ],
        conclusionIdeas: [
          'Nabam Rebia ensures that no Governor\'s action can substitute the '
          'constitutional verdict of the floor.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2016,
          event: 'Nabam Rebia decided.',
          significance: 'Governor\'s powers constrained by the floor test.',
          evidence: evr('NABAM_REBIA'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 7. M. Nagaraj v. Union of India (2006)
    // -----------------------------------------------------------------------
    'M_NAGARAJ': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_nagaraj_1',
          holding:
              'Reservation in promotions under Article 16(4A) is valid only if '
              'the State demonstrates backwardness, inadequacy of representation '
              'and overall administrative efficiency, applying the creamy layer '
              'test.',
          legalPrinciple: 'Compelling-reasons data test for promotion reservations.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('M_NAGARAJ'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench upheld Article 16(4A) but made promotion '
            'reservation contingent on quantifiable data of backwardness and '
            'inadequacy, together with the creamy layer exclusion.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Efficiency of administration balanced against equality',
        ],
        doctrinalReasoning: const ['Creamy layer doctrine', 'Reservation in promotions'],
        reasoningTools: const ['proportionality', 'quantifiable data test'],
        evidence: edr('M_NAGARAJ'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheldWithDirections,
        operativeResult:
            'Article 16(4A) upheld; States must show quantifiable data of '
            'backwardness, inadequacy and efficiency before granting promotion '
            'reservation.',
        majorityOutcome: 'Promotion reservation conditional on data and creamy-layer test.',
        evidence: evr('M_NAGARAJ'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Reconciled the 77th/81st/85th Amendments with the basic structure '
            'and the equality jurisprudence of Indra Sawhney.',
        legalSignificance:
            'Set the "compelling reasons" and quantifiable-data test for '
            'Article 16(4A).',
        upscSignificance:
            'Asked on promotion reservations, creamy layer and the '
            'reservation-amendment framework.',
        historicalSignificance:
            'Decided 2006; central to the prolonged promotion-reservation '
            'litigation.',
        significanceScore: 85,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2006 by a 5-judge bench.',
          'Article 16(4A) promotion reservation upheld with conditions.',
          'State must show backwardness, inadequacy and efficiency data.',
          'Creamy layer test applies.',
        ],
        prelimsTraps: [
          'M. Nagaraj did not make promotion reservation unconditional.',
        ],
        mainsThemes: [
          'Reservation in promotions and Article 16(4A)',
          'Equality and efficiency in public employment',
        ],
        answerKeywords: [
          'M. Nagaraj', 'Article 16(4A)', 'Promotion Reservation',
          'Creamy Layer', 'Quantifiable Data', 'Efficiency',
        ],
        essayThemes: [
          'Merit, representation and the state',
        ],
        interviewAreas: [
          'Why did the Court require data before promotion reservation?',
        ],
        answerEnrichmentPoints: [
          'The 77th, 81st and 85th Amendments inserted/expanded 16(4A).',
          'Jarnail Singh (2018) clarified the creamy layer for SC/STs.',
        ],
        contemporaryRelevance: [
          'Ongoing SC/ST promotion disputes apply the Nagaraj test.',
        ],
        likelyInterviewQuestions: [
          'Can the State relax the Nagaraj data conditions by law?',
        ],
        conclusionIdeas: [
          'M. Nagaraj makes promotion reservation a data-driven exception to '
          'equality, not a blank cheque.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2006,
          event: 'M. Nagaraj decided.',
          significance: 'Data and creamy-layer conditions on promotion reservation.',
          evidence: evr('M_NAGARAJ'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 8. Jarnail Singh v. Lachhmi Narain Gupta (2018)
    // -----------------------------------------------------------------------
    'JARNAIL_SINGH': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_jarnail_1',
          holding:
              'The creamy layer test applies to reservation in promotions for '
              'Scheduled Castes and Scheduled Tribes as well; the M. Nagaraj '
              'framework was not overruled.',
          legalPrinciple: 'Creamy layer applies to SC/ST promotion reservations.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('JARNAIL_SINGH'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench clarified that the creamy layer principle is not '
            'confined to OBCs and extends to SC/STs in the promotion-reservation '
            'framework, without disturbing the conditions in M. Nagaraj.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Equality within affirmative action',
        ],
        doctrinalReasoning: const ['Creamy layer doctrine', 'Article 16(4A)'],
        reasoningTools: const ['proportionality'],
        evidence: edr('JARNAIL_SINGH'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Held that creamy layer applies to SC/ST promotions; reference to '
            'a larger bench on other questions rejected.',
        majorityOutcome: 'Creamy layer extended to SC/ST promotion reservation.',
        evidence: evr('JARNAIL_SINGH'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Extended the creamy layer doctrine to SC/ST promotion '
            'reservations, refining Nagaraj.',
        legalSignificance:
            'Clarified that the State cannot ignore creamy layer for SC/STs '
            'in Article 16(4A).',
        upscSignificance:
            'Asked to update the Nagaraj and creamy-layer position.',
        historicalSignificance:
            'Decided 2018 after prolonged SC/ST promotion litigation.',
        significanceScore: 82,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2018 by a 5-judge bench.',
          'Creamy layer applies to SC/ST promotion reservations.',
          'M. Nagaraj conditions remain valid.',
        ],
        prelimsTraps: [
          'Jarnail Singh did not overrule M. Nagaraj.',
        ],
        mainsThemes: [
          'Creamy layer and SC/ST reservation',
          'Affirmative action jurisprudence',
        ],
        answerKeywords: [
          'Jarnail Singh', 'Creamy Layer', 'Article 16(4A)', 'SC/ST',
          'Promotion Reservation',
        ],
        essayThemes: [
          'Does equality within reservation advance or dilute affirmative '
          'action?',
        ],
        interviewAreas: [
          'Why should creamy layer matter for SC/STs?',
        ],
        answerEnrichmentPoints: [
          'The judgment flagged the need for a separate creamy layer test for '
          'SCs/STs given their social disadvantage.',
        ],
        contemporaryRelevance: [
          'Relevant to the pending sub-classification and promotion cases.',
        ],
        likelyInterviewQuestions: [
          'How is the creamy layer defined for SCs/STs today?',
        ],
        conclusionIdeas: [
          'Jarnail Singh ensures the benefits of promotion reservation reach '
          'the genuinely disadvantaged.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2018,
          event: 'Jarnail Singh decided.',
          significance: 'Creamy layer extended to SC/ST promotions.',
          evidence: evr('JARNAIL_SINGH'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 9. Janhit Abhiyan v. Union of India (2022)
    // -----------------------------------------------------------------------
    'JANHIT_ABHIYAN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_janhit_1',
          holding:
              'The 103rd Amendment providing 10% reservation for Economically '
              'Weaker Sections is constitutional and does not violate the basic '
              'structure.',
          legalPrinciple: 'EWS reservation valid; 50% cap is not an absolute rule.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('JANHIT_ABHIYAN'),
        ),
        JudgmentHolding(
          holdingId: 'hol_janhit_2',
          holding:
              'The 50% ceiling on reservations is not a basic feature and can be '
              'exceeded; exclusion of OBC/SC/ST from EWS does not violate '
              'equality.',
          legalPrinciple: 'Basis of identification for EWS is economic; reservation cap not sacrosanct.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('JANHIT_ABHIYAN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench upheld the EWS amendment by 3:2, holding that '
            'economic criteria can be a valid basis for reservation and that '
            'the 50% cap is not an immutable rule of the basic structure.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Economic criteria as a valid axis of affirmative action',
        ],
        doctrinalReasoning: const ['EWS doctrine', 'Basic Structure Doctrine'],
        reasoningTools: const ['reasonable classification', '50% cap analysis'],
        evidence: edr('JANHIT_ABHIYAN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheldWithDirections,
        operativeResult:
            '103rd Amendment upheld; EWS reservation of 10% valid; separate '
            'EWS ceiling beyond the general cap permitted.',
        majorityOutcome: 'EWS reservation upheld (3:2).',
        minorityOutcome:
            'Dissenters held that economic criterion alone cannot justify '
            'reservation and that breaching the 50% cap violates the basic '
            'structure.',
        evidence: evr('JANHIT_ABHIYAN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The first judicial examination of an economic-criteria '
            'reservation and a re-interpretation of the 50% cap.',
        legalSignificance:
            'Held the 50% ceiling not to be a basic feature; economic '
            'backwardness valid under Article 15(6).',
        upscSignificance:
            'The most contemporary reservation case — asked on EWS, the 103rd '
            'Amendment and the 50% cap.',
        historicalSignificance:
            'Decided 2022, resolving the challenge to the 2019 EWS amendment.',
        significanceScore: 92,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2022 by a 5-judge bench (3:2).',
          '103rd Amendment (Article 15(6)) EWS reservation upheld.',
          '10% EWS quota valid beyond the general 50% cap.',
          'Held the 50% cap is not a basic feature.',
        ],
        prelimsTraps: [
          'EWS is based on economic criteria, not caste; SC/ST/OBC are excluded.',
          'The judgment was 3:2, not unanimous.',
        ],
        mainsThemes: [
          'Reservation beyond the 50% cap',
          'Economic criteria and the EWS debate',
          'Basic structure and reservation limits',
        ],
        mainsArguments: [
          'Economic disadvantage can be a valid basis for affirmative action.',
          'The 50% cap in Indra Sawhney was a general rule, not a basic feature.',
        ],
        mainsCounterarguments: [
          'Excluding OBC/SC/ST from EWS and breaching the cap dilutes the '
          'reservation scheme.',
        ],
        answerKeywords: [
          'EWS', '103rd Amendment', 'Article 15(6)', 'Janhit Abhiyan',
          '50% Cap', 'Reservation', 'Basic Structure',
        ],
        essayThemes: [
          'Reservation as a mirror of social and economic inequality',
        ],
        interviewAreas: [
          'Should reservation be made income-based or caste-based?',
        ],
        answerEnrichmentPoints: [
          'The EWS income and asset limits are set by the Centre.',
          'The dissent relied on the basic-structure reading of Indra Sawhney.',
        ],
        contemporaryRelevance: [
          'Directly governs the EWS quota in education and jobs.',
        ],
        likelyInterviewQuestions: [
          'Is the 50% cap truly dead after Janhit Abhiyan?',
        ],
        conclusionIdeas: [
          'Janhit Abhiyan made economic disadvantage a constitutional basis '
          'for reservation, reshaping the equality debate.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2019,
          event: '103rd Amendment enacted.',
          significance: '10% EWS reservation added via Article 15(6).',
          evidence: evr('JANHIT_ABHIYAN'),
        ),
        JudgmentTimelineEvent(
          year: 2022,
          event: 'Janhit Abhiyan decided.',
          significance: 'EWS amendment upheld (3:2).',
          evidence: evr('JANHIT_ABHIYAN'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 10. D.K. Basu v. State of West Bengal (1997)
    // -----------------------------------------------------------------------
    'DK_BASU': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_dkbasu_1',
          holding:
              'The right against custodial violence and torture is part of '
              'Article 21; detailed arrest guidelines were issued to prevent '
              'custodial abuse.',
          legalPrinciple: 'Dignity in custody; binding arrest guidelines.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('DK_BASU'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court issued a comprehensive set of requirements — including '
            'identification, intimation to family, legal aid and custody '
            'registers — to give effect to the constitutional prohibition on '
            'torture.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Dignity and liberty inside custody',
        ],
        doctrinalReasoning: const ['Custodial jurisprudence'],
        reasoningTools: const ['guidelines to fill legislative gaps'],
        evidence: edr('DK_BASU'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.guidelinesIssued,
        operativeResult:
            'Eleven procedural requirements laid down for arrest and custody; '
            'failure attracts departmental and contempt liability.',
        majorityOutcome: 'Binding custodial-justice guidelines issued.',
        evidence: evr('DK_BASU'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established that no custodial violence can be justified under '
            'Article 21 and operationalised the right through guidelines.',
        legalSignificance:
            'The D.K. Basu guidelines remain the standard for lawful arrest and '
            'custody.',
        upscSignificance:
            'Asked on custodial violence, arrest procedure and Article 21.',
        historicalSignificance:
            'Decided 1997 after custodial-death revelations; a landmark in '
            'criminal-justice reform.',
        significanceScore: 89,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1997 by a 2-judge bench.',
          'Issued guidelines for arrest and custody to prevent custodial violence.',
          'Right against torture is part of Article 21.',
        ],
        prelimsTraps: [
          'D.K. Basu guidelines govern arrest procedure, not the death penalty.',
        ],
        mainsThemes: [
          'Custodial justice and Article 21',
          'Police accountability and arrest procedure',
        ],
        answerKeywords: [
          'D.K. Basu', 'Custodial Violence', 'Arrest Guidelines', 'Article 21',
          'Torture', 'Criminal Justice',
        ],
        essayThemes: [
          'The state\'s hands and the rights of the arrested',
        ],
        interviewAreas: [
          'Have the D.K. Basu guidelines reduced custodial violence?',
        ],
        answerEnrichmentPoints: [
          'The guidelines require informing the family, legal aid, and a '
          'custody register.',
          'Section 41A CrPC and the police reforms agenda build on this.',
        ],
        contemporaryRelevance: [
          'Cited in every custodial-violence and arrest-procedure case.',
        ],
        likelyInterviewQuestions: [
          'Why did the Court have to legislate arrest procedure?',
        ],
        conclusionIdeas: [
          'D.K. Basu converted the right to life into a code of conduct for '
          'the custodial state.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1997,
          event: 'D.K. Basu decided.',
          significance: 'Arrest and custody guidelines issued.',
          evidence: evr('DK_BASU'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 11. Hussainara Khatoon v. State of Bihar (1979)
    // -----------------------------------------------------------------------
    'HUSSAINARA_KHATOON': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_hussainara_1',
          holding:
              'The right to a speedy trial is implicit in Article 21; '
              'undertrials cannot be kept in custody beyond the maximum '
              'punishment for the alleged offence.',
          legalPrinciple: 'Speedy trial as part of Article 21.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('HUSSAINARA_KHATOON'),
        ),
        JudgmentHolding(
          holdingId: 'hol_hussainara_2',
          holding:
              'Legal aid is a right of the accused and a necessary part of fair '
              'trial.',
          legalPrinciple: 'Right to free legal aid for the accused.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('HUSSAINARA_KHATOON'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court exposed the plight of undertrials, holding that '
            'prolonged pre-trial detention without trial violates Article 21, '
            'and that the State must provide legal aid.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Criminal justice must not be punishment before trial',
        ],
        doctrinalReasoning: const ['Speedy trial doctrine', 'Right to legal aid'],
        reasoningTools: const ['reasonableness', 'dignity'],
        evidence: edr('HUSSAINARA_KHATOON'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.ordersIssued,
        operativeResult:
            'Directions issued for release of undertrials, legal aid and '
            'expeditious trial.',
        majorityOutcome: 'Speedy trial and legal aid affirmed.',
        evidence: evr('HUSSAINARA_KHATOON'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Read the right to speedy trial and legal aid into Article 21, '
            'reshaping criminal procedure toward fairness.',
        legalSignificance:
            'Foundation for Section 304 CrPC legal-aid jurisprudence and '
            'speedy-trial guarantees.',
        upscSignificance:
            'Asked on speedy trial, undertrials and legal aid under Article 21.',
        historicalSignificance:
            'Decided 1979 by P.N. Bhagwati J.; sparked prison reform and '
            'underserved-acquitted movements.',
        significanceScore: 87,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1979 by a 2-judge bench (Bhagwati J.).',
          'Right to speedy trial is part of Article 21.',
          'Legal aid is a right of the accused.',
          'Undertrials cannot be held beyond maximum punishment.',
        ],
        prelimsTraps: [
          'Hussainara Khatoon is about undertrials and speedy trial, not about '
          'arrest guidelines (that is D.K. Basu).',
        ],
        mainsThemes: [
          'Speedy trial and access to justice',
          'Legal aid and the criminal-justice system',
        ],
        answerKeywords: [
          'Hussainara Khatoon', 'Speedy Trial', 'Article 21', 'Legal Aid',
          'Undertrial', 'Criminal Justice',
        ],
        essayThemes: [
          'Justice delayed is justice denied',
        ],
        interviewAreas: [
          'How has the undertrial problem changed since 1979?',
        ],
        answerEnrichmentPoints: [
          'Led to the Legal Services Authorities Act, 1987.',
          'Pre-trial detention reform remains a live concern.',
        ],
        contemporaryRelevance: [
          'Central to undertrial-release orders during the pandemic and the '
          'bail-reform debate.',
        ],
        likelyInterviewQuestions: [
          'Is the right to a speedy trial an absolute right?',
        ],
        conclusionIdeas: [
          'Hussainara Khatoon made the State\'s delay a constitutional '
          'wrong against the accused.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1979,
          event: 'Hussainara Khatoon decided.',
          significance: 'Speedy trial and legal aid read into Article 21.',
          evidence: evr('HUSSAINARA_KHATOON'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 12. Common Cause v. Union of India (2018)
    // -----------------------------------------------------------------------
    'COMMON_CAUSE_EUTHANASIA': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_euthanasia_1',
          holding:
              'Passive euthanasia (withdrawal of life support) is permissible '
              'under Article 21 in cases of terminal illness, subject to a '
              'High Court or Medical Board safeguard.',
          legalPrinciple: 'Right to die with dignity within Article 21.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('COMMON_CAUSE_EUTHANASIA'),
        ),
        JudgmentHolding(
          holdingId: 'hol_euthanasia_2',
          holding:
              'Advance medical directives (living wills) are valid and '
              'operational, allowing a person to decline futile treatment.',
          legalPrinciple: 'Advance directives recognised under Article 21.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('COMMON_CAUSE_EUTHANASIA'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The 5-judge bench held that dignity includes the right to a '
            'dignified end of life, permitting passive euthanasia and advance '
            'directives under strict safeguards.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Dignity at the end of life',
        ],
        doctrinalReasoning: const ['Right to die with dignity', 'Advance directives'],
        reasoningTools: const ['proportionality', 'dignity'],
        evidence: edr('COMMON_CAUSE_EUTHANASIA'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.guidelinesIssued,
        operativeResult:
            'Passive euthanasia permitted with judicial/medical safeguards; '
            'living wills validated subject to procedural formalities.',
        majorityOutcome: 'Right to die with dignity affirmed; safeguards imposed.',
        evidence: evr('COMMON_CAUSE_EUTHANASIA'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Recognised the right to a dignified end of life under Article 21 '
            'and legalised advance directives.',
        legalSignificance:
            'Built on Aruna Shanbaug (2011) and clarified the law on passive '
            'euthanasia.',
        upscSignificance:
            'Asked on euthanasia, living wills and Article 21.',
        historicalSignificance:
            'Decided 2018 after the Aruna Shanbaug debate.',
        significanceScore: 86,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2018 by a 5-judge bench.',
          'Passive euthanasia permitted under Article 21.',
          'Advance medical directives (living wills) recognised.',
          'Active euthanasia remains impermissible.',
        ],
        prelimsTraps: [
          'The Court allowed passive, NOT active, euthanasia.',
        ],
        mainsThemes: [
          'Right to life and the right to die with dignity',
          'Medical ethics and constitutional law',
        ],
        answerKeywords: [
          'Common Cause', 'Euthanasia', 'Living Will', 'Article 21',
          'Right to Die with Dignity', 'Advance Directive',
        ],
        essayThemes: [
          'Life, autonomy and the limits of medical prolongation',
        ],
        interviewAreas: [
          'Should India permit active euthanasia?',
        ],
        answerEnrichmentPoints: [
          'Aruna Shanbaug (2011) first permitted passive euthanasia.',
          'The judgment grounded the right in dignity, following Puttaswamy.',
        ],
        contemporaryRelevance: [
          'The Medical Termination / end-of-life care debates continue.',
        ],
        likelyInterviewQuestions: [
          'How does the law balance autonomy and protection of life?',
        ],
        conclusionIdeas: [
          'Common Cause extends the right to dignity to the last breath of '
          'life.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2011,
          event: 'Aruna Shanbaug permitted passive euthanasia.',
          significance: 'Precursor to Common Cause.',
          evidence: evr('COMMON_CAUSE_EUTHANASIA'),
        ),
        JudgmentTimelineEvent(
          year: 2018,
          event: 'Common Cause decided.',
          significance: 'Living wills and passive euthanasia formalised.',
          evidence: evr('COMMON_CAUSE_EUTHANASIA'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 13. M.C. Mehta v. Union of India (Taj Trapezium, 1997)
    // -----------------------------------------------------------------------
    'MC_MEHTA_TAJ': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_taj_1',
          holding:
              'The Taj Mahal requires protection from industrial pollution; '
              'directions were issued to shift polluting units from the Taj '
              'Trapezium Zone.',
          legalPrinciple: 'Right to environment as part of Article 21; sustainable development.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MC_MEHTA_TAJ'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court applied the precautionary principle and Articles 21, 48A '
            'and 51A(g) to protect the Taj from industrial emissions, ordering '
            'cleaner fuels and relocation of polluting units.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Environmental protection as part of the right to life',
        ],
        doctrinalReasoning: const ['Public trust doctrine', 'Sustainable development'],
        reasoningTools: const ['precautionary principle'],
        evidence: edr('MC_MEHTA_TAJ'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.ordersIssued,
        operativeResult:
            'Polluting industries ordered to shift; use of cleaner fuel '
            'directed in the Taj Trapezium Zone.',
        majorityOutcome: 'Taj protected via environmental directions.',
        evidence: evr('MC_MEHTA_TAJ'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Placed environmental protection squarely within Article 21 and '
            'the constitutional duty framework.',
        legalSignificance:
            'Applied precautionary principle and issued continuing mandamus '
            'for heritage protection.',
        upscSignificance:
            'Asked on environment and heritage, Article 48A/51A(g) and '
            'sustainable development.',
        historicalSignificance:
            'Decided 1997 in the long-running Taj pollution litigation.',
        significanceScore: 83,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1997 by a 2-judge bench.',
          'Protects the Taj Mahal from industrial pollution.',
          'Applied Articles 21, 48A and 51A(g).',
          'Ordered polluting units out of the Taj Trapezium Zone.',
        ],
        prelimsTraps: [
          'MC_Mehta is the Taj Trapezium case — there are several MC_Mehta '
          'cases.',
        ],
        mainsThemes: [
          'Environment, heritage and Article 21',
          'Sustainable development and the precautionary principle',
        ],
        answerKeywords: [
          'Taj Trapezium', 'MC Mehta', 'Article 48A', 'Precautionary Principle',
          'Sustainable Development', 'Environment',
        ],
        essayThemes: [
          'Development and the monument: the cost of neglect',
        ],
        interviewAreas: [
          'How should heritage protection be balanced with industry?',
        ],
        answerEnrichmentPoints: [
          'The Court ordered natural gas conversion and relocation.',
        ],
        contemporaryRelevance: [
          'Pollution-control directions for the Taj region continue.',
        ],
        likelyInterviewQuestions: [
          'What does the Taj case teach about environmental litigation?',
        ],
        conclusionIdeas: [
          'The Taj case showed the judiciary protecting heritage as a '
          'constitutional right.',
        ],
        relatedSyllabusAreas: [
          UpscSyllabusArea.gs2,
          UpscSyllabusArea.gs3,
          UpscSyllabusArea.prelimsEnvironment,
        ],
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1997,
          event: 'Taj Trapezium directions issued.',
          significance: 'Heritage and environment protected via Article 21.',
          evidence: evr('MC_MEHTA_TAJ'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 14. Vellore Citizens Welfare Forum v. Union of India (1996)
    // -----------------------------------------------------------------------
    'VELLORE_CITIZENS': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_vellore_1',
          holding:
              'The precautionary principle and the polluter-pays principle are '
              'part of the law of the land under Articles 21, 48A and 51A(g).',
          legalPrinciple: 'Precautionary principle and polluter-pays as constitutional norms.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('VELLORE_CITIZENS'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court read sustainable development and its twin principles '
            'into Articles 21, 48A and 51A(g), and directed polluting tanneries '
            'to compensate affected parties.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Environmental justice and sustainable development',
        ],
        doctrinalReasoning: const ['Polluter-pays principle', 'Precautionary principle'],
        reasoningTools: const ['precautionary principle', 'polluter pays'],
        evidence: edr('VELLORE_CITIZENS'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.ordersIssued,
        operativeResult:
            'Tanneries directed to install effluent treatment and pay '
            'compensation; the polluter-pays principle applied.',
        majorityOutcome: 'Environment principles enforced with compensation.',
        evidence: evr('VELLORE_CITIZENS'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Definitively incorporated sustainable-development principles '
            'into Indian environmental law.',
        legalSignificance:
            'First clear articulation that precautionary and polluter-pays '
            'principles are part of Article 21 jurisprudence.',
        upscSignificance:
            'Asked for the precautionary principle, polluter-pays and '
            'sustainable development.',
        historicalSignificance:
            'Decided 1996; a turning point in environmental-justice litigation.',
        significanceScore: 88,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1996 by a 2-judge bench.',
          'Precautionary principle and polluter-pays are part of Indian law.',
          'Grounded in Articles 21, 48A and 51A(g).',
        ],
        prelimsTraps: [
          'Vellore Citizens is the tannery pollution case, not the Taj case.',
        ],
        mainsThemes: [
          'Sustainable development and constitutional rights',
          'Polluter-pays and precautionary principles',
        ],
        answerKeywords: [
          'Vellore Citizens', 'Precautionary Principle', 'Polluter Pays',
          'Sustainable Development', 'Article 48A', 'Environment',
        ],
        essayThemes: [
          'Who pays for the environment the economy consumes?',
        ],
        interviewAreas: [
          'How effective is the polluter-pays principle in India?',
        ],
        answerEnrichmentPoints: [
          'The principles were borrowed from the Rio Declaration (1992).',
        ],
        contemporaryRelevance: [
          'Foundational to the environmental-justice framework under NGT.',
        ],
        likelyInterviewQuestions: [
          'What is the difference between precautionary and polluter-pays '
          'principles?',
        ],
        conclusionIdeas: [
          'Vellore Citizens made environmental prudence a constitutional '
          'command.',
        ],
        relatedSyllabusAreas: [
          UpscSyllabusArea.gs2,
          UpscSyllabusArea.gs3,
          UpscSyllabusArea.prelimsEnvironment,
        ],
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1996,
          event: 'Vellore Citizens decided.',
          significance: 'Sustainable-development principles constitutionalised.',
          evidence: evr('VELLORE_CITIZENS'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 15. Indian Council for Enviro-Legal Action v. Union of India (1996)
    // -----------------------------------------------------------------------
    'ICELA_BICHHRI': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_bichhri_1',
          holding:
              'The polluter-pays principle applies — the hazardous chemical '
              'industry at Bichhri must compensate and remediate environmental '
              'damage.',
          legalPrinciple: 'Polluter-pays principle for hazardous industries.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('ICELA_BICHHRI'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court held that industries generating hazardous waste are '
            'absolutely liable for resulting damage and must bear the cost of '
            'remediation.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Absolute liability of hazardous industries',
        ],
        doctrinalReasoning: const ['Polluter-pays principle', 'Absolute liability'],
        reasoningTools: const ['polluter pays', 'precaution'],
        evidence: edr('ICELA_BICHHRI'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.ordersIssued,
        operativeResult:
            'Chemical units at Bichhri held liable to pay compensation and '
            'remediation costs for the damage caused.',
        majorityOutcome: 'Hazardous industries must remediate and compensate.',
        evidence: evr('ICELA_BICHHRI'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Applied the polluter-pays principle to industrial pollution, '
            'affirming the State\'s duty to protect the environment.',
        legalSignificance:
            'Linked Articles 21 and 48A to absolute liability and remediation.',
        upscSignificance:
            'Asked on polluter-pays and hazardous-industry liability.',
        historicalSignificance:
            'Decided 1996 in the Bichhri acid-pollution litigation.',
        significanceScore: 81,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1996 by a 2-judge bench.',
          'Polluter-pays principle applied to hazardous chemical units.',
          'Industries absolutely liable for environmental damage.',
        ],
        prelimsTraps: [
          'ICELA Bichhri and Vellore Citizens are different cases, both 1996.',
        ],
        mainsThemes: [
          'Absolute liability and the polluter-pays principle',
          'Hazardous industries and Article 21',
        ],
        answerKeywords: [
          'ICELA', 'Bichhri', 'Polluter Pays', 'Absolute Liability',
          'Hazardous Waste', 'Environment',
        ],
        essayThemes: [
          'Industrial progress and the price of pollution',
        ],
        interviewAreas: [
          'How is polluter-pays enforced against industries?',
        ],
        answerEnrichmentPoints: [
          'The judgment operationalised the principle of absolute liability '
          'from MC_Mehta (Oleum Gas).',
        ],
        contemporaryRelevance: [
          'Applied by the NGT in remediation orders.',
        ],
        likelyInterviewQuestions: [
          'Who bears the burden of cleaning industrial pollution?',
        ],
        conclusionIdeas: [
          'ICELA made polluters pay for the environment they damage.',
        ],
        relatedSyllabusAreas: [
          UpscSyllabusArea.gs2,
          UpscSyllabusArea.gs3,
          UpscSyllabusArea.prelimsEnvironment,
        ],
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1996,
          event: 'ICELA (Bichhri) decided.',
          significance: 'Polluter-pays applied to hazardous industry.',
          evidence: evr('ICELA_BICHHRI'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 16. T.N. Godavarman Thirumulpad v. Union of India (1997)
    // -----------------------------------------------------------------------
    'TN_GODAVARMAN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_godavarman_1',
          holding:
              'Forests must be protected from deforestation; a ban on '
              'unsustainable felling was imposed and the Forest Conservation Act '
              'enforced across all forest types.',
          legalPrinciple: 'Forest protection under Articles 21 and 48A.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('TN_GODAVARMAN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court issued wide-ranging directions to curb deforestation, '
            'define "forest" broadly and regulate sawmills and forest use in '
            'furtherance of Article 48A.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Forests as part of the constitutional environmental trust',
        ],
        doctrinalReasoning: const ['Public trust doctrine', 'Forest jurisprudence'],
        reasoningTools: const ['continuing mandamus', 'precaution'],
        evidence: edr('TN_GODAVARMAN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.ordersIssued,
        operativeResult:
            'Ban on felling imposed; all forest land brought under the Forest '
            'Conservation Act; ongoing supervision via a monitoring committee.',
        majorityOutcome: 'Deforestation curbed via continuing mandamus.',
        evidence: evr('TN_GODAVARMAN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The most expansive forest-protection jurisdiction, making forest '
            'conservation a judicially monitored obligation.',
        legalSignificance:
            'Defined "forest" expansively and enforced the Forest Conservation '
            'Act through continuing mandamus.',
        upscSignificance:
            'Asked on forest policy, deforestation and Article 48A.',
        historicalSignificance:
            'Decided 1997; the start of a decades-long forest-protection '
            'monitoring regime.',
        significanceScore: 84,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1997 by a 2-judge bench.',
          'Ban on unsustainable felling; broad definition of "forest".',
          'Enforced the Forest Conservation Act, 1980.',
          'Continuing mandamus for forest protection.',
        ],
        prelimsTraps: [
          'Godavarman is the forest-protection case; it is ongoing via '
          'monitoring committees.',
        ],
        mainsThemes: [
          'Forest conservation and Article 48A',
          'Judicial monitoring and environmental governance',
        ],
        answerKeywords: [
          'Godavarman', 'Forest Conservation Act', 'Deforestation',
          'Article 48A', 'Continuing Mandamus', 'Environment',
        ],
        essayThemes: [
          'The forest and the polity: can law hold back the axe?',
        ],
        interviewAreas: [
          'Should courts micro-manage forest governance?',
        ],
        answerEnrichmentPoints: [
          'The case created the Compensatory Afforestation Fund (CAMPA) '
          'framework.',
        ],
        contemporaryRelevance: [
          'Guides the green-credit and afforestation debates.',
        ],
        likelyInterviewQuestions: [
          'What has the Godavarman regime achieved for forests?',
        ],
        conclusionIdeas: [
          'Godavarman turned forest protection into a continuous judicial '
          'trusteeship.',
        ],
        relatedSyllabusAreas: [
          UpscSyllabusArea.gs2,
          UpscSyllabusArea.gs3,
          UpscSyllabusArea.prelimsEnvironment,
        ],
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1997,
          event: 'Godavarman directions issued.',
          significance: 'Forest felling banned; FCA enforced.',
          evidence: evr('TN_GODAVARMAN'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 17. Narmada Bachao Andolan v. Union of India (2000)
    // -----------------------------------------------------------------------
    'NARMADA_BACHAO': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_nba_1',
          holding:
              'Large dams are not unconstitutional per se; the right to life '
              'under Article 21 does not bar the displacement inherent in '
              'development, provided rehabilitation is carried out.',
          legalPrinciple: 'Balancing development and Article 21 rehabilitation.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('NARMADA_BACHAO'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court balanced environmental and displacement concerns '
            'against developmental necessity, allowing the Sardar Sarovar '
            'project to proceed subject to completion of rehabilitation.',
        approach: InterpretiveApproach.pragmatic,
        constitutionalPhilosophy: const [
          'Development and rehabilitation as two sides of Article 21',
        ],
        doctrinalReasoning: const ['Sustainable development'],
        reasoningTools: const ['balancing', 'rehabilitation safeguards'],
        evidence: edr('NARMADA_BACHAO'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.dismissed,
        operativeResult:
            'Challenges to the Sardar Sarovar dam dismissed; directions for '
            'rehabilitation and environmental safeguards issued.',
        majorityOutcome: 'Dam construction permitted with safeguards.',
        evidence: evr('NARMADA_BACHAO'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Framed the development-vs-displacement debate under Article 21, '
            'requiring humane rehabilitation.',
        legalSignificance:
            'Clarified that displacement alone does not violate Article 21 if '
            'rehabilitation is ensured.',
        upscSignificance:
            'Asked on dams, displacement, rehabilitation and Article 21.',
        historicalSignificance:
            'Decided 2000 in the long Narmada agitation.',
        significanceScore: 80,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2000 by a 3-judge bench.',
          'Sardar Sarovar dam allowed with rehabilitation safeguards.',
          'Displacement alone does not violate Article 21.',
        ],
        prelimsTraps: [
          'NBA did not ban large dams; it regulated their displacement.',
        ],
        mainsThemes: [
          'Development projects and displacement',
          'Rehabilitation and Article 21',
        ],
        answerKeywords: [
          'Narmada Bachao', 'Sardar Sarovar', 'Displacement', 'Article 21',
          'Rehabilitation', 'Sustainable Development',
        ],
        essayThemes: [
          'Development for whom?',
        ],
        interviewAreas: [
          'How should big infrastructure reconcile with displacement?',
        ],
        answerEnrichmentPoints: [
          'Rehabilitation and Resettlement policy evolved after this case.',
        ],
        contemporaryRelevance: [
          'Relevant to the Land Acquisition Act and rehabilitation debates.',
        ],
        likelyInterviewQuestions: [
          'What safeguards make displacement constitutional?',
        ],
        conclusionIdeas: [
          'Narmada Bachao insists that development must carry its displaced '
          'people along.',
        ],
        relatedSyllabusAreas: [
          UpscSyllabusArea.gs2,
          UpscSyllabusArea.gs3,
          UpscSyllabusArea.prelimsEnvironment,
        ],
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2000,
          event: 'Narmada Bachao decided.',
          significance: 'Dam allowed subject to rehabilitation.',
          evidence: evr('NARMADA_BACHAO'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 18. Association for Democratic Reforms v. Union of India (2002)
    // -----------------------------------------------------------------------
    'ADR_ASSOCIATION': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_adr_1',
          holding:
              'Voters have a fundamental right to information about '
              'candidates\' criminal background, education and assets; '
              'candidates must disclose these details.',
          legalPrinciple: 'Right to information about candidates under Article 19(1)(a).',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('ADR_ASSOCIATION'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court held that informed choice is the essence of democracy, '
            'and Article 19(1)(a) entitles voters to know the antecedents of '
            'candidates.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Informed electoral choice as the essence of democracy',
        ],
        doctrinalReasoning: const ['Right to information in elections'],
        reasoningTools: const ['purposive construction'],
        evidence: edr('ADR_ASSOCIATION'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Directions issued requiring disclosure of criminal cases, '
            'education and assets in election affidavits.',
        majorityOutcome: 'Mandatory disclosure for all candidates.',
        evidence: evr('ADR_ASSOCIATION'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established the voter\'s right to information as the foundation '
            'of free and fair elections.',
        legalSignificance:
            'Led to the electoral-affidavit regime under the RPA and '
            'subsequent election-law reforms.',
        upscSignificance:
            'Asked on electoral transparency, candidates\' disclosures and '
            'Article 19(1)(a).',
        historicalSignificance:
            'Decided 2002; a turning point for electoral accountability.',
        significanceScore: 88,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2002 by a 2-judge bench.',
          'Voters have a right to know candidates\' criminal, education and '
          'asset details.',
          'Disclosure mandated in election affidavits.',
        ],
        prelimsTraps: [
          'ADR is the criminal-disclosure case; Lily Thomas (2013) is the '
          'disqualification case.',
        ],
        mainsThemes: [
          'Electoral transparency and free and fair elections',
          'Right to information and democracy',
        ],
        answerKeywords: [
          'ADR', 'Criminal Record Disclosure', 'Article 19(1)(a)',
          'Election Affidavit', 'Electoral Reforms', 'RPA',
        ],
        essayThemes: [
          'Can transparency cure the criminalisation of politics?',
        ],
        interviewAreas: [
          'Does disclosure actually change voter behaviour?',
        ],
        answerEnrichmentPoints: [
          'The 2003 RPA amendment required disclosure in Form 26.',
          'Extended by the PUCL and NOTA line of cases.',
        ],
        contemporaryRelevance: [
          'Central to the criminalisation-of-politics debate and pending '
          'reform proposals.',
        ],
        likelyInterviewQuestions: [
          'Should candidates with criminal cases be barred outright?',
        ],
        conclusionIdeas: [
          'ADR gave the voter the weapon of information against '
          'unaccountable candidature.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2002,
          event: 'ADR decided.',
          significance: 'Mandatory candidate disclosure.',
          evidence: evr('ADR_ASSOCIATION'),
        ),
        JudgmentTimelineEvent(
          year: 2003,
          event: 'RPA amended for Form 26 disclosure.',
          significance: 'Statutory effect given to ADR.',
          evidence: evr('ADR_ASSOCIATION'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 19. Lily Thomas v. Union of India (2013)
    // -----------------------------------------------------------------------
    'LILY_THOMAS': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_lily_1',
          holding:
              'Section 8(4) of the Representation of the People Act, 1951 — '
              'which allowed convicted MPs/MLAs to continue in office pending '
              'appeal — is unconstitutional.',
          legalPrinciple: 'Disqualification on conviction is immediate.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('LILY_THOMAS'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court held that Parliament lacked the power to defer '
            'disqualification through Section 8(4), which created an arbitrary '
            'exception for sitting legislators.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Purity of the legislature',
        ],
        doctrinalReasoning: const ['Article 102/191 disqualification'],
        reasoningTools: const ['textual construction'],
        evidence: edr('LILY_THOMAS'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 8(4) RPA struck down; conviction immediately disqualifies '
            'a sitting member under Articles 102(1)(e) and 191(1)(e).',
        majorityOutcome: 'Immediate disqualification on conviction.',
        evidence: evr('LILY_THOMAS'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Ended the immunity of convicted legislators from immediate '
            'disqualification.',
        legalSignificance:
            'Struck down Section 8(4) RPA as beyond legislative competence.',
        upscSignificance:
            'Asked on disqualification, criminalisation of politics and '
            'Article 102/191.',
        historicalSignificance:
            'Decided 2013; a major anti-criminalisation-of-politics ruling.',
        significanceScore: 87,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2013 by a 2-judge bench.',
          'Section 8(4) RPA struck down.',
          'Conviction immediately disqualifies a legislator.',
          'Grounds: Articles 102(1)(e) and 191(1)(e).',
        ],
        prelimsTraps: [
          'Lily Thomas is about disqualification on conviction, not candidate '
          'disclosure (ADR).',
        ],
        mainsThemes: [
          'Criminalisation of politics and disqualification',
          'Legislative competence under the RPA',
        ],
        answerKeywords: [
          'Lily Thomas', 'Section 8(4) RPA', 'Disqualification',
          'Article 102', 'Conviction', 'Criminalisation of Politics',
        ],
        essayThemes: [
          'Can the law filter criminals from the legislature?',
        ],
        interviewAreas: [
          'Should even the appeal period bar a convicted legislator?',
        ],
        answerEnrichmentPoints: [
          'A subsequent 2013 order also nullified the 2013 ordinance that '
          'sought to reverse Lily Thomas.',
        ],
        contemporaryRelevance: [
          'Central to the criminalisation-of-politics data and reforms debate.',
        ],
        likelyInterviewQuestions: [
          'Does immediate disqualification conflict with the presumption of '
          'innocence?',
        ],
        conclusionIdeas: [
          'Lily Thomas cleaned the legislative chamber of convicted '
          'members at the point of conviction.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2013,
          event: 'Lily Thomas decided.',
          significance: 'Immediate disqualification on conviction.',
          evidence: evr('LILY_THOMAS'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 20. PUCL v. Union of India (NOTA, 2013)
    // -----------------------------------------------------------------------
    'PUCL_NOTA': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_nota_1',
          holding:
              'Voters have the right to register a negative vote through the '
              'NOTA (None of the Above) option under Article 19(1)(a).',
          legalPrinciple: 'Right to negative voting as part of free expression.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('PUCL_NOTA'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court held that the right to vote includes the right to reject, '
            'grounded in Article 19(1)(a), and directed the introduction of '
            'NOTA on EVMs.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Free choice includes the choice to reject',
        ],
        doctrinalReasoning: const ['Right to vote and negative voting'],
        reasoningTools: const ['purposive construction'],
        evidence: edr('PUCL_NOTA'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'NOTA option directed to be provided on EVMs; it has no effect on '
            'the electoral result if it garners a plurality.',
        majorityOutcome: 'NOTA introduced; no electoral consequence when it wins.',
        evidence: evr('PUCL_NOTA'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Recognised negative voting as part of electoral expression.',
        legalSignificance:
            'Introduced NOTA in Indian elections while clarifying it does not '
            'trigger a fresh poll.',
        upscSignificance:
            'Asked on NOTA, negative voting and electoral reform.',
        historicalSignificance:
            'Decided 2013; NOTA operationalised from the 2014 general election.',
        significanceScore: 82,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2013 by a 2-judge bench.',
          'NOTA introduced as an option on EVMs.',
          'Right to negative voting flows from Article 19(1)(a).',
          'NOTA does not trigger re-election if it wins the plurality.',
        ],
        prelimsTraps: [
          'NOTA does NOT lead to a fresh election.',
        ],
        mainsThemes: [
          'Electoral reforms and the right to vote',
          'Negative voting and democratic expression',
        ],
        answerKeywords: [
          'NOTA', 'PUCL', 'Negative Voting', 'Article 19(1)(a)',
          'Electoral Reform', 'EVM',
        ],
        essayThemes: [
          'The power of saying no in a democracy',
        ],
        interviewAreas: [
          'Is NOTA a meaningful democratic tool?',
        ],
        answerEnrichmentPoints: [
          'NOTA appeared on EVMs from the 2014 general election.',
          'The right to vote was recognised as a constitutional right in the '
          'PUCL (2013) context.',
        ],
        contemporaryRelevance: [
          'Debates on compulsory voting and NOTA\'s electoral effect continue.',
        ],
        likelyInterviewQuestions: [
          'Should a NOTA plurality trigger a re-poll?',
        ],
        conclusionIdeas: [
          'NOTA gave the voter a constitutional right to reject without '
          'converting it into an electoral veto.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2013,
          event: 'PUCL (NOTA) decided.',
          significance: 'NOTA introduced on EVMs.',
          evidence: evr('PUCL_NOTA'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 21. Bachan Singh v. State of Punjab (1980)
    // -----------------------------------------------------------------------
    'BACHAN_SINGH': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_bachan_1',
          holding:
              'The death penalty for murder is constitutional, but must be '
              'imposed only in the "rarest of rare" cases where the '
              'alternative sentence is unquestionably foreclosed.',
          legalPrinciple: 'Rarest of rare doctrine for capital punishment.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('BACHAN_SINGH'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The 5-judge bench upheld the constitutional validity of the death '
            'penalty but confined it to the rarest of rare cases, requiring '
            'special reasons and consideration of mitigating circumstances.',
        approach: InterpretiveApproach.pragmatic,
        constitutionalPhilosophy: const [
          'Life and death between Articles 21 and the penological aims of '
          'deterrence',
        ],
        doctrinalReasoning: const ['Rarest of rare doctrine'],
        reasoningTools: const ['proportionality', 'mitigating circumstances'],
        evidence: edr('BACHAN_SINGH'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheldWithDirections,
        operativeResult:
            'Death penalty upheld; "rarest of rare" test laid down; mitigating '
            'circumstances must be weighed.',
        majorityOutcome: 'Capital punishment constitutional, narrowly confined.',
        evidence: evr('BACHAN_SINGH'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The governing authority on the death penalty and the rarest-of-'
            'rare doctrine.',
        legalSignificance:
            'Limited the death sentence to exceptional cases with special '
            'reasons and mitigation.',
        upscSignificance:
            'Asked for the rarest-of-rare doctrine, capital punishment and '
            'Article 21.',
        historicalSignificance:
            'Decided 1980, following the Jagmohan reference.',
        significanceScore: 90,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1980 by a 5-judge bench.',
          'Death penalty held constitutional.',
          '"Rarest of rare" doctrine laid down.',
          'Mitigating circumstances must be considered.',
        ],
        prelimsTraps: [
          'Bachan Singh upheld the death penalty; it did not abolish it.',
        ],
        mainsThemes: [
          'Capital punishment and Article 21',
          'The rarest-of-rare doctrine',
        ],
        answerKeywords: [
          'Bachan Singh', 'Rarest of Rare', 'Death Penalty', 'Article 21',
          'Capital Punishment', 'Mitigating Circumstances',
        ],
        essayThemes: [
          'The state and the taking of life',
        ],
        interviewAreas: [
          'Should India abolish the death penalty?',
        ],
        answerEnrichmentPoints: [
          'Followed in Machhi Singh (1983) which elaborated the rarest-of-rare '
          'categories.',
        ],
        contemporaryRelevance: [
          'Central to the death-penalty debate and the reform of capital '
          'sentencing.',
        ],
        likelyInterviewQuestions: [
          'Why is the rarest-of-rare test difficult to apply?',
        ],
        conclusionIdeas: [
          'Bachan Singh keeps the death penalty alive but insists it be a '
          'constitutional exception, not a rule.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1980,
          event: 'Bachan Singh decided.',
          significance: 'Rarest-of-rare doctrine laid down.',
          evidence: evr('BACHAN_SINGH'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 22. Mithu v. State of Punjab (1983)
    // -----------------------------------------------------------------------
    'MITHU': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_mithu_1',
          holding:
              'Section 303 IPC — imposing mandatory death sentence for murder '
              'by a life-convict — is unconstitutional for violating Articles 14 '
              'and 21.',
          legalPrinciple: 'No mandatory death penalty; individualised sentencing required.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MITHU'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court held that treating all life-convicts uniformly for '
            'mandatory death was arbitrary and offended the guarantee of '
            'individualised sentencing.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Individualised justice over blanket mandatory sentencing',
        ],
        doctrinalReasoning: const ['Arbitrariness under Article 14'],
        reasoningTools: const ['non-arbitrariness', 'proportionality'],
        evidence: edr('MITHU'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 303 IPC struck down; mandatory death for murder by a '
            'life-convict abolished.',
        majorityOutcome: 'Mandatory death penalty held unconstitutional.',
        evidence: evr('MITHU'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Reinforced that the death penalty must be individualised and '
            'never mandatory.',
        legalSignificance:
            'Invalidated Section 303 IPC under Articles 14 and 21.',
        upscSignificance:
            'Asked on mandatory death, Section 303 IPC and Article 14.',
        historicalSignificance:
            'Decided 1983 in the shadow of Bachan Singh.',
        significanceScore: 82,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1983 by a 5-judge bench.',
          'Section 303 IPC (mandatory death for life-convicts) struck down.',
          'Violates Articles 14 and 21.',
        ],
        prelimsTraps: [
          'Mithu is about mandatory death for life-convicts, not about '
          'abolishing the death penalty.',
        ],
        mainsThemes: [
          'Mandatory sentencing and Article 14',
          'Death penalty and individualised justice',
        ],
        answerKeywords: [
          'Mithu', 'Section 303 IPC', 'Mandatory Death Penalty',
          'Article 14', 'Article 21', 'Sentencing',
        ],
        essayThemes: [
          'Why one-size-fits-all punishment fails justice',
        ],
        interviewAreas: [
          'What remains of Section 303 IPC after Mithu?',
        ],
        answerEnrichmentPoints: [
          'The judgment built on the non-arbitrariness reading of Article 14.',
        ],
        contemporaryRelevance: [
          'Central to the ongoing debate on mandatory minimum sentences.',
        ],
        likelyInterviewQuestions: [
          'Why does mandatory death violate Article 14?',
        ],
        conclusionIdeas: [
          'Mithu abolished the last mandatory death sentence, reaffirming '
          'that punishment must fit the individual.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1983,
          event: 'Mithu decided.',
          significance: 'Section 303 IPC struck down.',
          evidence: evr('MITHU'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 23. Vineet Narain v. Union of India (1998)
    // -----------------------------------------------------------------------
    'VINEET_NARAIN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_vineet_1',
          holding:
              'The CBI must function independently and free from political '
              'influence; directions were issued for its institutional '
              'restructuring and for the Central Vigilance Commission.',
          legalPrinciple: 'Institutional independence of investigative agencies.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('VINEET_NARAIN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'In the hawala case, the Court held that good governance requires '
            'independent investigation, and issued directions to restructure '
            'the CBI and grant statutory status to the CVC.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Independence of investigative agencies as part of the rule of law',
        ],
        doctrinalReasoning: const ['Institutional independence'],
        reasoningTools: const ['structural interpretation', 'continuing mandamus'],
        evidence: edr('VINEET_NARAIN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.ordersIssued,
        operativeResult:
            'Directions issued for CBI restructuring, CVC statutory status '
            'and insulation of the investigation process.',
        majorityOutcome: 'Investigative independence institutionalised.',
        evidence: evr('VINEET_NARAIN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established that investigative independence is integral to the '
            'rule of law and good governance.',
        legalSignificance:
            'Led to the CVC Act, 2003 and the DSPE Act amendment granting '
            'statutory status to the CVC.',
        upscSignificance:
            'Asked on CBI/CVC independence and anti-corruption '
            'institutions.',
        historicalSignificance:
            'Decided 1998 during the hawala scam; a landmark in '
            'anti-corruption governance.',
        significanceScore: 85,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1998 by a 3-judge bench.',
          'CBI made independent of political influence.',
          'CVC granted statutory status.',
          'Directions under Article 32.',
        ],
        prelimsTraps: [
          'Vineet Narain is the CBI/CVC independence case (hawala), not a '
          'police-arrest case.',
        ],
        mainsThemes: [
          'Investigative agencies and the rule of law',
          'Anti-corruption institutions and good governance',
        ],
        answerKeywords: [
          'Vineet Narain', 'CBI', 'CVC', 'Hawala', 'Article 32',
          'Anti-Corruption', 'Good Governance',
        ],
        essayThemes: [
          'The institutional architecture of anti-corruption',
        ],
        interviewAreas: [
          'Is the CBI truly independent today?',
        ],
        answerEnrichmentPoints: [
          'The CVC Act, 2003 operationalised the directions.',
          'The case kept the investigation process insulated from executive '
          'pressure.',
        ],
        contemporaryRelevance: [
          'Central to the debates on the Lokpal, CBI and ED independence.',
        ],
        likelyInterviewQuestions: [
          'How can investigative agencies be made structurally independent?',
        ],
        conclusionIdeas: [
          'Vineet Narain institutionalised the independence that '
          'investigation needs to be credible.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1998,
          event: 'Vineet Narain decided.',
          significance: 'CBI independence and CVC status ordered.',
          evidence: evr('VINEET_NARAIN'),
        ),
        JudgmentTimelineEvent(
          year: 2003,
          event: 'CVC Act enacted.',
          significance: 'Statutory effect given to the directions.',
          evidence: evr('VINEET_NARAIN'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 24. Lalita Kumari v. Government of U.P. (2014)
    // -----------------------------------------------------------------------
    'LALITA_KUMARI': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_lalita_1',
          holding:
              'Registration of an FIR under Section 154 CrPC is mandatory where '
              'a complaint discloses a cognizable offence; preliminary inquiry '
              'is permissible only in narrow, specified cases.',
          legalPrinciple: 'Mandatory FIR registration for cognizable offences.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('LALITA_KUMARI'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench held that the police have no discretion to refuse '
            'an FIR for a cognizable offence, and confined preliminary inquiry '
            'to exceptional situations.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Access to criminal justice begins with the FIR',
        ],
        doctrinalReasoning: const ['FIR registration doctrine'],
        reasoningTools: const ['textual construction of Section 154'],
        evidence: edr('LALITA_KUMARI'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'FIR registration mandatory for cognizable offences; preliminary '
            'inquiry allowed only in limited categories with time limits.',
        majorityOutcome: 'Mandatory FIR; limited preliminary inquiry.',
        evidence: evr('LALITA_KUMARI'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Clarified the police\'s duty to register FIRs, strengthening '
            'access to justice.',
        legalSignificance:
            'Settled the law on Section 154 CrPC and preliminary inquiry.',
        upscSignificance:
            'Asked on FIR, Section 154 CrPC and criminal procedure.',
        historicalSignificance:
            'Decided 2014, following the Shakti Mills and missing-children '
            'contexts.',
        significanceScore: 81,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2014 by a 5-judge bench.',
          'FIR registration is mandatory for cognizable offences.',
          'Preliminary inquiry only in exceptional categories.',
          'Section 154 CrPC governs.',
        ],
        prelimsTraps: [
          'Preliminary inquiry is the exception, not the rule.',
        ],
        mainsThemes: [
          'FIR registration and police accountability',
          'Criminal procedure and access to justice',
        ],
        answerKeywords: [
          'Lalita Kumari', 'Section 154 CrPC', 'FIR', 'Preliminary Inquiry',
          'Cognizable Offence', 'Criminal Procedure',
        ],
        essayThemes: [
          'The first page of criminal justice: the FIR',
        ],
        interviewAreas: [
          'When can the police refuse to register an FIR?',
        ],
        answerEnrichmentPoints: [
          'The judgment protects complainants from police inaction.',
        ],
        contemporaryRelevance: [
          'Relevant to police-reform and complaint-handling debates.',
        ],
        likelyInterviewQuestions: [
          'What categories allow a preliminary inquiry?',
        ],
        conclusionIdeas: [
          'Lalita Kumari makes the FIR a right, not a favour.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2014,
          event: 'Lalita Kumari decided.',
          significance: 'Mandatory FIR for cognizable offences.',
          evidence: evr('LALITA_KUMARI'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 25. Arnesh Kumar v. State of Bihar (2014)
    // -----------------------------------------------------------------------
    'ARNESH_KUMAR': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_arnesh_1',
          holding:
              'Arrest is not automatic for offences punishable up to seven '
              'years; Section 41A CrPC requires notice and the satisfaction of '
              'the police must be recorded.',
          legalPrinciple: 'No automatic arrest; anti-arrest guidelines.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('ARNESH_KUMAR'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court laid down guidelines to prevent mechanical arrests, '
            'especially in dowry cases, requiring the police to comply with '
            'Section 41A CrPC and record reasons.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Liberty until the state justifies custody',
        ],
        doctrinalReasoning: const ['Anti-arrest doctrine', 'Section 41A CrPC'],
        reasoningTools: const ['proportionality', 'reasoned satisfaction'],
        evidence: edr('ARNESH_KUMAR'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.guidelinesIssued,
        operativeResult:
            'Guidelines issued against automatic arrest; police must comply '
            'with Section 41A and record reasons before arrest.',
        majorityOutcome: 'Arrest confined to necessity, not convenience.',
        evidence: evr('ARNESH_KUMAR'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Embedded the presumption of liberty into the arrest process '
            'under Article 21.',
        legalSignificance:
            'Clarified Section 41A CrPC and the conditions for lawful arrest.',
        upscSignificance:
            'Asked on arrest procedure, Section 41A and police guidelines.',
        historicalSignificance:
            'Decided 2014, responding to the misuse of Section 498A IPC.',
        significanceScore: 84,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2014 by a 2-judge bench.',
          'No automatic arrest for offences up to seven years.',
          'Section 41A CrPC requires notice and recorded satisfaction.',
          'Guidelines issued, including for dowry cases.',
        ],
        prelimsTraps: [
          'Arnesh Kumar is about arrest, not about striking down Section 498A.',
        ],
        mainsThemes: [
          'Arrest and the right to liberty',
          'Police power and Section 41A CrPC',
        ],
        answerKeywords: [
          'Arnesh Kumar', 'Section 41A', 'Arrest Guidelines', 'Article 21',
          'Section 498A', 'Bail',
        ],
        essayThemes: [
          'Presumption of innocence until the state proves otherwise',
        ],
        interviewAreas: [
          'Have the Arnesh Kumar guidelines curbed arbitrary arrest?',
        ],
        answerEnrichmentPoints: [
          'The judgment mandates non-arrest compliance reports.',
        ],
        contemporaryRelevance: [
          'Cited in every arrest-avoidance and bail argument.',
        ],
        likelyInterviewQuestions: [
          'What distinguishes lawful from arbitrary arrest?',
        ],
        conclusionIdeas: [
          'Arnesh Kumar treats arrest as the exception that liberty '
          'presumes against.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2014,
          event: 'Arnesh Kumar decided.',
          significance: 'Anti-automatic-arrest guidelines issued.',
          evidence: evr('ARNESH_KUMAR'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 26. Mohini Jain v. State of Karnataka (1992)
    // -----------------------------------------------------------------------
    'MOHINI_JAIN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_mohini_1',
          holding:
              'The right to education is a fundamental right flowing from '
              'Article 21; capitation fees in private medical colleges are '
              'unconstitutional.',
          legalPrinciple: 'Right to education as part of Article 21.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MOHINI_JAIN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 2-judge bench located the right to education in Article 21 and '
            'declared capitation fees arbitrary and exploitative.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Education as a gateway to dignity',
        ],
        doctrinalReasoning: const ['Right to education', 'Capitation fee'],
        reasoningTools: const ['purposive construction'],
        evidence: edr('MOHINI_JAIN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Capitation fee regime struck down; right to education affirmed.',
        majorityOutcome: 'Education read into Article 21.',
        evidence: evr('MOHINI_JAIN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'First step toward recognising education as a fundamental right, '
            'culminating in Article 21A.',
        legalSignificance:
            'Declared capitation fees unconstitutional and education '
            'part of Article 21.',
        upscSignificance:
            'Asked in the right-to-education sequence leading to Unni '
            'Krishnan and Article 21A.',
        historicalSignificance:
            'Decided 1992, triggering the Unni Krishnan reconsideration.',
        significanceScore: 80,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1992 by a 2-judge bench.',
          'Right to education part of Article 21.',
          'Capitation fees unconstitutional.',
        ],
        prelimsTraps: [
          'Mohini Jain was partly reconsidered by Unni Krishnan (1993) which '
          'limited the right to 6-14 years.',
        ],
        mainsThemes: [
          'Right to education and Article 21',
          'Regulation of private medical education',
        ],
        answerKeywords: [
          'Mohini Jain', 'Right to Education', 'Capitation Fee', 'Article 21',
          'Medical Education', 'Unni Krishnan',
        ],
        essayThemes: [
          'The cost of education and the right to learn',
        ],
        interviewAreas: [
          'Why was Mohini Jain reconsidered?',
        ],
        answerEnrichmentPoints: [
          'Unni Krishnan (1993) refined the holding and the 86th Amendment '
          'added Article 21A.',
        ],
        contemporaryRelevance: [
          'Fee-regulation and private-institution admission debates continue.',
        ],
        likelyInterviewQuestions: [
          'How did Mohini Jain lead to Article 21A?',
        ],
        conclusionIdeas: [
          'Mohini Jain planted the seed that grew into the constitutional '
          'right to education.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1992,
          event: 'Mohini Jain decided.',
          significance: 'Education read into Article 21.',
          evidence: evr('MOHINI_JAIN'),
        ),
        JudgmentTimelineEvent(
          year: 1993,
          event: 'Unni Krishnan refined the right.',
          significance: 'Fundamental right confined to 6-14 years.',
          evidence: evr('MOHINI_JAIN'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 27. Suchita Srivastava v. Chandigarh Administration (2009)
    // -----------------------------------------------------------------------
    'SUCHITA_SRIVASTAVA': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_suchita_1',
          holding:
              'Reproductive autonomy is part of the right to life under '
              'Article 21; the State cannot force a woman, including one with '
              'mental illness, to terminate a pregnancy.',
          legalPrinciple: 'Reproductive autonomy within Article 21.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SUCHITA_SRIVASTAVA'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court affirmed that the decision to bear a child rests with '
            'the woman, and set aside the directive to terminate the pregnancy '
            'of a woman with schizophrenia.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Bodily autonomy and dignity of the woman',
        ],
        doctrinalReasoning: const ['Reproductive rights'],
        reasoningTools: const ['dignity', 'autonomy'],
        evidence: edr('SUCHITA_SRIVASTAVA'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'The termination directive set aside; the woman\'s reproductive '
            'autonomy affirmed.',
        majorityOutcome: 'No forced termination; reproductive autonomy upheld.',
        evidence: evr('SUCHITA_SRIVASTAVA'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Rooted reproductive autonomy in Article 21, protecting women '
            'from state coercion in pregnancy decisions.',
        legalSignificance:
            'Clarified that mental illness does not justify forced '
            'termination.',
        upscSignificance:
            'Asked on reproductive rights, abortion law and Article 21.',
        historicalSignificance:
            'Decided 2009, a foundational reproductive-rights judgment.',
        significanceScore: 84,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2009 by a 2-judge bench.',
          'Reproductive autonomy part of Article 21.',
          'State cannot force termination, even for a woman with mental '
          'illness.',
        ],
        prelimsTraps: [
          'Suchita Srivastava is about forced termination, not about '
          'legalising abortion generally.',
        ],
        mainsThemes: [
          'Reproductive rights and Article 21',
          'Women\'s bodily autonomy',
        ],
        answerKeywords: [
          'Suchita Srivastava', 'Reproductive Autonomy', 'Article 21',
          'Abortion', 'Bodily Autonomy', 'MTP',
        ],
        essayThemes: [
          'Who owns the decision to bear a child?',
        ],
        interviewAreas: [
          'How does the MTP Act balance autonomy and state interest?',
        ],
        answerEnrichmentPoints: [
          'The 2021 MTP Amendment extended gestational limits and access.',
          'The judgment influenced X v. Union of India (2022) on '
          'unwed-pregnancy abortion.',
        ],
        contemporaryRelevance: [
          'Central to the MTP reform and reproductive-health debates.',
        ],
        likelyInterviewQuestions: [
          'Should a third party ever override a woman\'s pregnancy decision?',
        ],
        conclusionIdeas: [
          'Suchita Srivastava placed the pregnancy decision firmly in the '
          'woman\'s constitutional autonomy.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2009,
          event: 'Suchita Srivastava decided.',
          significance: 'Reproductive autonomy affirmed.',
          evidence: evr('SUCHITA_SRIVASTAVA'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 28. Independent Thought v. Union of India (2017)
    // -----------------------------------------------------------------------
    'INDEPENDENT_THOUGHT': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_independent_1',
          holding:
              'The Exception to Section 375 IPC permitting intercourse with a '
              'wife aged 15-18 is read down: sexual intercourse with a girl '
              'below 18 is rape.',
          legalPrinciple: 'Child-marriage exception to rape struck down; child rights prevail.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('INDEPENDENT_THOUGHT'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 2-judge bench read down the marital exception under Section 375 '
            'IPC for girls aged 15-18, in consonance with the POCSO Act and '
            'Articles 14, 15 and 21.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'The best interests of the child override archaic marital '
          'exceptions',
        ],
        doctrinalReasoning: const ['Child rights', 'Reading down'],
        reasoningTools: const ['harmonious construction with POCSO', 'best interests'],
        evidence: edr('INDEPENDENT_THOUGHT'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Exception 2 to Section 375 IPC read down for wives aged 15-18; '
            'such intercourse constitutes rape.',
        majorityOutcome: 'Marital rape exception for minors removed.',
        evidence: evr('INDEPENDENT_THOUGHT'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Protected girls aged 15-18 from marital sexual abuse, aligning '
            'IPC with the POCSO Act.',
        legalSignificance:
            'Read down Exception 2 to Section 375 IPC through constitutional '
            'harmonisation.',
        upscSignificance:
            'Asked on the marital-rape exception, child rights and Section '
            '375 IPC.',
        historicalSignificance:
            'Decided 2017, a milestone in the child-protection and '
            'criminal-law reform debate.',
        significanceScore: 86,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2017 by a 2-judge bench.',
          'Exception 2 to Section 375 IPC read down for girls aged 15-18.',
          'Intercourse with a wife below 18 is rape.',
          'Harmonised with the POCSO Act.',
        ],
        prelimsTraps: [
          'Independent Thought addressed wives aged 15-18, NOT the marital '
          'exception for adult wives.',
        ],
        mainsThemes: [
          'Marital rape exception and child rights',
          'Reading down penal provisions',
        ],
        answerKeywords: [
          'Independent Thought', 'Section 375 IPC', 'Marital Rape',
          'POCSO', 'Child Rights', 'Reading Down',
        ],
        essayThemes: [
          'The law\'s protection of the child inside the marriage',
        ],
        interviewAreas: [
          'Should the marital exception survive for adults?',
        ],
        answerEnrichmentPoints: [
          'The judgment followed the best-interests principle under Article 15(3).',
        ],
        contemporaryRelevance: [
          'Central to the ongoing marital-rape debate after Joseph Shine.',
        ],
        likelyInterviewQuestions: [
          'How does Independent Thought interact with the POCSO Act?',
        ],
        conclusionIdeas: [
          'Independent Thought removed the law\'s tolerance for the sexual '
          'abuse of child wives.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2017,
          event: 'Independent Thought decided.',
          significance: 'Marital exception read down for minors.',
          evidence: evr('INDEPENDENT_THOUGHT'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 29. Joseph Shine v. Union of India (2018)
    // -----------------------------------------------------------------------
    'JOSEPH_SHINE': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_joseph_1',
          holding:
              'Section 497 IPC criminalising adultery is unconstitutional; '
              'adultery is no longer a criminal offence.',
          legalPrinciple: 'Adultery decriminalised; gender equality under Articles 14 and 21.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('JOSEPH_SHINE'),
        ),
        JudgmentHolding(
          holdingId: 'hol_joseph_2',
          holding:
              'Section 497 treated women as property of the husband and '
              'violated the equal protection of Articles 14, 15 and 21.',
          legalPrinciple: 'Criminal adultery provision void for gender discrimination.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('JOSEPH_SHINE'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench struck down Section 497 IPC (and Section 198(2) '
            'CrPC) as archaic and discriminatory, holding that adultery is a '
            'civil matter, not a crime.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Equality of women and the privacy of marriage',
        ],
        doctrinalReasoning: const ['Gender equality', 'Privacy'],
        reasoningTools: const ['non-arbitrariness', 'dignity', 'privacy'],
        evidence: edr('JOSEPH_SHINE'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 497 IPC and Section 198(2) CrPC struck down; adultery '
            'decriminalised.',
        majorityOutcome: 'Adultery no longer a crime; women\'s equality affirmed.',
        evidence: evr('JOSEPH_SHINE'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Decriminalised adultery and affirmed the equality and autonomy '
            'of women within marriage.',
        legalSignificance:
            'Overruled Yusuf Aziz (1954); invalidated a gender-discriminatory '
            'criminal provision.',
        upscSignificance:
            'Asked on adultery, Section 497 IPC and gender equality.',
        historicalSignificance:
            'Decided 2018, following Navtej Johar and Independent Thought in '
            'the privacy-based reform wave.',
        significanceScore: 88,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2018 by a 5-judge bench.',
          'Section 497 IPC struck down.',
          'Adultery decriminalised.',
          'Violates Articles 14, 15 and 21.',
        ],
        prelimsTraps: [
          'Adultery remains a ground for civil divorce, but is no longer a '
          'crime.',
        ],
        mainsThemes: [
          'Decriminalisation and gender equality',
          'Privacy and the criminal law',
        ],
        answerKeywords: [
          'Joseph Shine', 'Section 497 IPC', 'Adultery', 'Article 14',
          'Gender Equality', 'Decriminalisation',
        ],
        essayThemes: [
          'When the state must stay out of the bedroom',
        ],
        interviewAreas: [
          'Does decriminalising adultery weaken the institution of marriage?',
        ],
        answerEnrichmentPoints: [
          'The judgment relied on Puttaswamy\'s privacy and dignity holdings.',
        ],
        contemporaryRelevance: [
          'The adultery and marital-rape debates continue after Joseph Shine.',
        ],
        likelyInterviewQuestions: [
          'Why did the Court treat adultery as a civil wrong?',
        ],
        conclusionIdeas: [
          'Joseph Shine removed the criminal law from a private failing, '
          'restoring the woman as an equal citizen.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2018,
          event: 'Joseph Shine decided.',
          significance: 'Adultery decriminalised.',
          evidence: evr('JOSEPH_SHINE'),
        ),
      ],
    ),
  };
}
