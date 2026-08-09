/// Curated Judgment Intelligence for the 20 Phase-I landmark cases
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

/// Phase-I curated intelligence seeds keyed by caseId.
class JudgmentIntelligenceSeedPhase1 {
  static final Map<String, JudgmentIntelligenceSeed> seeds = {
    // -----------------------------------------------------------------------
    // 1. Kesavananda Bharati v. State of Kerala (1973)
    // -----------------------------------------------------------------------
    'KESAVANANDA': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_kesavananda_1',
          holding:
              'Parliament\'s power to amend the Constitution under Article 368 '
              'cannot alter the basic structure or essential features of the '
              'Constitution.',
          legalPrinciple: 'Basic Structure Doctrine',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('KESAVANANDA'),
        ),
        JudgmentHolding(
          holdingId: 'hol_kesavananda_2',
          holding:
              'The 24th, 25th and 29th Constitutional Amendment Acts were upheld '
              'in principle, but the amending power was confirmed to be limited, '
              'not plenary.',
          legalPrinciple: 'Amending power is not plenary; judicial review survives.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('KESAVANANDA'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The majority adopted a structural reading of the Constitution: the '
            'amending power in Article 368 operates within, and cannot destroy, '
            'the identity of the Constitution. Khanna J.\'s pivotal opinion '
            'formulated the basic-structure limitation.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Constitutional identity and implied limitations on amending power',
          'Balance between parliamentary sovereignty and judicial review',
        ],
        doctrinalReasoning: const ['Basic Structure Doctrine'],
        reasoningTools: const ['structural interpretation'],
        evidence: edr('KESAVANANDA'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheldWithDirections,
        operativeResult:
            'Petitions dismissed in substantial part; the impugned amendments '
            'upheld subject to the basic-structure limitation on the amending '
            'power (7:6 majority).',
        majorityOutcome:
            'The amending power cannot be exercised so as to destroy the basic '
            'structure; the 24th, 25th and 29th Amendments validly upheld.',
        minorityOutcome:
            'A.N. Ray J., P.J. Reddy J., D.G. Palekar J., K.K. Mathew J., M.H. '
            'Beg J. and S.N. Dwivedi J. dissented on the existence of an implied '
            'limitation.',
        evidence: evr('KESAVANANDA'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Foundational basic-structure judgment; defines the ultimate boundary '
            'of Parliament\'s amending power and entrenches judicial review of '
            'constitutional amendments.',
        legalSignificance:
            'Settles that the amending power under Article 368 is limited and '
            'reviewable; overruled Golaknath\'s absolute bar while rejecting '
            'plenary amendment.',
        upscSignificance:
            'Single most asked constitutional-law case in UPSC; the anchor for '
            'every basic-structure, FR-vs-DPSP and amendment question.',
        historicalSignificance:
            'Decided by the largest bench in Indian constitutional history '
            '(13 judges, 1973); directly responded to the 24th/25th/29th '
            'Amendments enacted after Golaknath.',
        significanceScore: 98,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1973 by a 13-judge bench (largest in Supreme Court history) by 7:6 majority.',
          'Held Parliament cannot alter the basic structure of the Constitution under Article 368.',
          'Upheld the 24th, 25th and 29th Constitutional Amendments, but limited the amending power.',
          'Overruled Golaknath (1967) which had barred all amendments touching Fundamental Rights.',
        ],
        prelimsTraps: [
          'Golaknath is NOT current law — it was overruled by Kesavananda in 1973.',
          'Kesavananda did NOT strike down the 25th Amendment entirely; only the second part of Article 31C beyond Articles 14 and 19 was later held invalid (Minerva Mills).',
          'The bench was 13 judges, not 11 (Golaknath was 11).',
        ],
        mainsThemes: [
          'Basic structure doctrine and the limits of constitutional amendment',
          'Judicial review versus parliamentary sovereignty',
          'Fundamental Rights and Directive Principles balance',
        ],
        mainsArguments: [
          'The amending power under Article 368 is a constituent power subject to implied limitations inherent in the Constitution.',
          'Judicial review of amendments is essential to preserve constitutional identity.',
        ],
        mainsCounterarguments: [
          'The word "amend" imports no express limitation; a plenary reading gives Parliament final authority.',
          'Basic structure is vague and unelected judges could frustrate legitimate constitutional change.',
        ],
        answerKeywords: [
          'Basic Structure Doctrine', 'Article 368', 'Implied Limitation',
          '7:6 majority', '13-judge bench', 'Constitutional Identity',
        ],
        essayThemes: [
          'Constitutionalism: the limits of change without losing identity',
          'The tension between majoritarian amendment and fundamental rights',
        ],
        interviewAreas: [
          'Why does the basic structure doctrine have no textual basis and yet bind Parliament?',
          'Doctrine as a safeguard against authoritarian amendments.',
        ],
        answerEnrichmentPoints: [
          'Khanna J.\'s pivotal swing opinion; the 42nd Amendment (1976) attempted to curtail the doctrine.',
          'The doctrine is applied to the NJAC judgment, Coelho, and later amendments.',
        ],
        contemporaryRelevance: [
          'Applied in IR Coelho (2007), NJAC (2015), and to test the 97th/103rd Amendments.',
          'Central to current debates on electoral bonds and digital-services reforms.',
        ],
        likelyInterviewQuestions: [
          'If Parliament cannot change the basic structure, who defines "basic structure"?',
          'Can a future amendment codify or remove the basic structure doctrine?',
        ],
        conclusionIdeas: [
          'The basic structure doctrine is the constitutional firewall that reconciles a supreme Constitution with a powerful amending legislature.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1973,
          event: 'Kesavananda Bharati v. State of Kerala decided (13-judge bench).',
          significance: 'Basic Structure Doctrine established.',
          evidence: evr('KESAVANANDA'),
        ),
        JudgmentTimelineEvent(
          year: 1976,
          event: '42nd Constitutional Amendment sought to curtail judicial review of amendments.',
          significance: 'Tried to dilute the doctrine; later invalidated in Minerva Mills.',
          evidence: evr('KESAVANANDA'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 2. Golaknath v. State of Punjab (1967)
    // -----------------------------------------------------------------------
    'GOLAKNATH': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_golaknath_1',
          holding:
              'Constitutional amendments are "law" under Article 13(2) and cannot '
              'abridge or take away Fundamental Rights.',
          legalPrinciple: 'Fundamental Rights are transcendental and immutable.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('GOLAKNATH'),
        ),
        JudgmentHolding(
          holdingId: 'hol_golaknath_2',
          holding:
              'Applied the doctrine of prospective overruling so that the 1st, '
              '4th and 17th Amendments already enacted remained valid.',
          legalPrinciple: 'Doctrine of Prospective Overruling.',
          scope: HoldingScope.narrow,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('GOLAKNATH'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 6:5 majority under CJI Subba Rao held that the term "law" in '
            'Article 13(2) includes constitutional amendments, and that '
            'Fundamental Rights occupy a transcendental position. Prospective '
            'overruling was invoked to preserve existing amendments.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Fundamental Rights as transcendental and beyond amendment',
        ],
        doctrinalReasoning: const ['Doctrine of Prospective Overruling'],
        reasoningTools: const ['textual construction of Article 13(2)'],
        evidence: edr('GOLAKNATH'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Held that Parliament cannot amend Part III; earlier amendments '
            'preserved by prospective overruling (6:5 majority).',
        majorityOutcome:
            'Future amendments abridging Fundamental Rights are unconstitutional.',
        minorityOutcome:
            'Five judges held the amending power plenary, following Shankari Prasad and Sajjan Singh.',
        evidence: evr('GOLAKNATH'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established the (later reversed) doctrine that Fundamental Rights '
            'cannot be amended; key link in the pre-Kesavananda evolution.',
        legalSignificance:
            'Introduced prospective overruling into Indian constitutional '
            'jurisprudence; overruled by Kesavananda Bharati (1973).',
        upscSignificance:
            'High-frequency comparison case: candidates must distinguish Golaknath '
            '(absolute bar) from Kesavananda (basic structure).',
        historicalSignificance:
            'Response to the 1st, 4th and 17th Amendments; the case that triggered '
            'the 24th Amendment and the basic-structure debate.',
        significanceScore: 82,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1967 by an 11-judge bench, 6:5 majority.',
          'Held Fundamental Rights are transcendental and amendments cannot abridge them.',
          'Applied prospective overruling to save the 1st, 4th and 17th Amendments.',
          'Overruled by Kesavananda Bharati (1973).',
        ],
        prelimsTraps: [
          'Golaknath is overruled law — do not present it as the current position.',
          'It was 11 judges, not 13 (Kesavananda was 13).',
        ],
        mainsThemes: [
          'Evolution of the basic structure doctrine',
          'Doctrine of prospective overruling',
        ],
        mainsArguments: [
          'Part III is inviolable; the amending power cannot destroy fundamental rights.',
        ],
        mainsCounterarguments: [
          'Kesavananda later rejected the absolute bar as too rigid.',
        ],
        answerKeywords: [
          'Article 13(2)', 'Prospective Overruling', 'Transcendental Rights',
          '11-judge bench', 'Subba Rao C.J.',
        ],
        essayThemes: [
          'When should judicial rulings apply only prospectively?',
        ],
        interviewAreas: [
          'Why did the Court in Golaknath refuse to invalidate the earlier amendments?',
        ],
        answerEnrichmentPoints: [
          'Prospective overruling was borrowed from American jurisprudence.',
          'The 24th Amendment (1971) expressly restored the amending power, setting up Kesavananda.',
        ],
        contemporaryRelevance: [
          'Prospective overruling remains a live technique in Indian constitutional adjudication.',
        ],
        likelyInterviewQuestions: [
          'Compare the Golaknath and Kesavananda positions on amendability.',
        ],
        conclusionIdeas: [
          'Golaknath marks the high-water mark of Fundamental Rights absolutism, corrected but not forgotten by the basic structure doctrine.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1967,
          event: 'Golaknath decided (11-judge bench, prospective overruling).',
          significance: 'Absolute bar on amending Fundamental Rights.',
          evidence: evr('GOLAKNATH'),
        ),
        JudgmentTimelineEvent(
          year: 1973,
          event: 'Kesavananda Bharati overruled Golaknath.',
          significance: 'Absolute bar replaced by the basic structure doctrine.',
          evidence: evr('GOLAKNATH'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 3. Shankari Prasad v. Union of India (1951)
    // -----------------------------------------------------------------------
    'SHANKARI_PRASAD': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_shankari_1',
          holding:
              'A constitutional amendment under Article 368 is not "law" within '
              'the meaning of Article 13(2), and is therefore outside the '
              'prohibition on abridging Fundamental Rights.',
          legalPrinciple:
              'Amendments under Article 368 are constituent acts, not ordinary law.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SHANKARI_PRASAD'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The first amendment case held that the amending power under Article '
            '368 is plenary and "law" in Article 13(2) means ordinary law, not a '
            'constitutional amendment.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Parliamentary supremacy over amendments in the early constitutional era',
        ],
        doctrinalReasoning: const ['Plenary amending power'],
        reasoningTools: const ['textual distinction between law and amendment'],
        evidence: edr('SHANKARI_PRASAD'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.dismissed,
        operativeResult:
            'First Amendment (including the Ninth Schedule) held valid; the '
            'impugned land-reform law was upheld.',
        majorityOutcome: 'Amending power is plenary; Article 13(2) inapplicable.',
        evidence: evr('SHANKARI_PRASAD'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The first authoritative construction of the amending power; the '
            'starting point of the amendment debate.',
        legalSignificance:
            'Established the "law vs amendment" distinction later challenged by '
            'Golaknath and resolved by Kesavananda.',
        upscSignificance:
            'Asked as a sequencing point: Shankari Prasad (1951) → Sajjan Singh '
            '(1965) → Golaknath (1967) → Kesavananda (1973).',
        historicalSignificance:
            'Decided the validity of the First Amendment (1951) soon after the '
            'Constitution came into force.',
        significanceScore: 72,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1951 by a 5-judge bench.',
          'Held constitutional amendments are not "law" under Article 13(2).',
          'Upheld the First Constitutional Amendment and the Ninth Schedule.',
        ],
        prelimsTraps: [
          'Do not confuse: Shankari Prasad upheld the plenary amending power; Golaknath later rejected it.',
        ],
        mainsThemes: [
          'The "law vs amendment" debate under Article 13(2)',
        ],
        mainsArguments: [
          'The constituent power to amend is distinct from ordinary legislative power.',
        ],
        answerKeywords: [
          'Article 368', 'Article 13(2)', 'First Amendment', 'Plenary power',
        ],
        essayThemes: [
          'The limits of first principles in constitutional interpretation',
        ],
        interviewAreas: [
          'Why did the Court change its view on amendability by 1967?',
        ],
        answerEnrichmentPoints: [
          'The First Amendment also added the Ninth Schedule, whose immunity later came under attack in IR Coelho.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1951,
          event: 'Shankari Prasad decided — plenary amending power.',
          significance: 'First amendment case.',
          evidence: evr('SHANKARI_PRASAD'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 4. Sajjan Singh v. State of Rajasthan (1965)
    // -----------------------------------------------------------------------
    'SAJJAN_SINGH': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_sajjan_1',
          holding:
              'Affirmed Shankari Prasad: an amendment under Article 368 is not '
              '"law" under Article 13(2) and can touch Fundamental Rights.',
          legalPrinciple: 'Amending power is plenary and outside Article 13(2).',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SAJJAN_SINGH'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench reaffirmed the plenary view, while some judges '
            'observed that a very wide amending power might still be subject to '
            'limits — a hint of the later basic-structure debate.',
        approach: InterpretiveApproach.literal,
        doctrinalReasoning: const ['Plenary amending power'],
        reasoningTools: const ['textual construction'],
        evidence: edr('SAJJAN_SINGH'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.dismissed,
        operativeResult: 'Challenge to the 17th Amendment rejected.',
        majorityOutcome: 'Amendment power upheld following Shankari Prasad.',
        evidence: evr('SAJJAN_SINGH'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Intermediate authority that kept the plenary reading alive between '
            'Shankari Prasad and Golaknath.',
        legalSignificance: 'Reaffirmed Shankari Prasad on Article 13(2).',
        upscSignificance:
            'Part of the amendment-era chronology; less frequently examined than '
            'the neighbouring cases.',
        historicalSignificance:
            'Decided during the run-up to Golaknath; some judges flagged the '
            'possibility of implied limits.',
        significanceScore: 60,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1965 by a 5-judge bench.',
          'Upheld the 17th Amendment and the plenary amending power.',
        ],
        prelimsTraps: [
          'Sajjan Singh followed Shankari Prasad, not Golaknath.',
        ],
        mainsThemes: [
          'Chronology of the amendment power cases',
        ],
        answerKeywords: [
          'Article 368', '17th Amendment', 'Plenary power',
        ],
        essayThemes: [
          'Stare decisis and the slow correction of doctrine',
        ],
        interviewAreas: [
          'What hints in Sajjan Singh foreshadowed the basic structure doctrine?',
        ],
        answerEnrichmentPoints: [
          'Judges in Sajjan Singh questioned whether the amending power was truly unlimited.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1965,
          event: 'Sajjan Singh decided.',
          significance: 'Plenary view reaffirmed.',
          evidence: evr('SAJJAN_SINGH'),
        ),
        JudgmentTimelineEvent(
          year: 1967,
          event: 'Golaknath overruled the plenary view.',
          significance: 'Turned the amendment debate toward implied limits.',
          evidence: evr('SAJJAN_SINGH'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 5. In re Berubari Union (1960)
    // -----------------------------------------------------------------------
    'BERUBARI_UNION': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_berubari_1',
          holding:
              'Parliament\'s power under Article 3 does not extend to ceding '
              'Indian territory to a foreign state; such cession requires a '
              'constitutional amendment.',
          legalPrinciple: 'Article 3 does not cover cession of territory abroad.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('BERUBARI_UNION'),
        ),
        JudgmentHolding(
          holdingId: 'hol_berubari_2',
          holding:
              'The implementing law under Article 3 is not "law" under Article '
              '13(2), but cession of territory needs an amendment under '
              'Article 368.',
          legalPrinciple: 'Territorial cession needs an amendment, not ordinary legislation.',
          scope: HoldingScope.narrow,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('BERUBARI_UNION'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court drew a distinction between alteration of internal '
            'boundaries (Article 3) and cession of territory to a foreign state, '
            'which changes the sovereignty of the Republic and therefore requires '
            'a constitutional amendment.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Territorial integrity and national sovereignty',
        ],
        doctrinalReasoning: const ['Law vs amendment distinction'],
        reasoningTools: const ['textual and structural construction'],
        evidence: edr('BERUBARI_UNION'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Advisory opinion: Berubari could be ceded only by amending the '
            'Constitution; the 9th Amendment (1960) was then enacted for the '
            'purpose.',
        majorityOutcome: 'Cession requires a constitutional amendment.',
        evidence: evr('BERUBARI_UNION'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'First major advisory opinion on territorial cession; defined the '
            'reach of Article 3.',
        legalSignificance:
            'Confirmed the law/amendment distinction and the need for amendment '
            'to cede territory.',
        upscSignificance:
            'Tested in federalism and Article 3 questions; medium frequency.',
        historicalSignificance:
            'Led to the Constitution (Ninth Amendment) Act, 1960 transferring '
            'Berubari to Pakistan.',
        significanceScore: 63,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1960 (advisory opinion, 5-judge bench).',
          'Held Article 3 does not permit cession of Indian territory to a foreign state.',
          'Led to the 9th Constitutional Amendment (1960).',
        ],
        prelimsTraps: [
          'Berubari (1960) is the 9th Amendment case, not the "Basic Structure" case.',
        ],
        mainsThemes: [
          'Article 3 and the constitutional method for territorial change',
        ],
        answerKeywords: [
          'Article 3', 'Cession of Territory', '9th Amendment', 'Advisory opinion',
        ],
        essayThemes: [
          'Territory, sovereignty and the rule of law',
        ],
        interviewAreas: [
          'Can India cede territory today without an amendment?',
        ],
        answerEnrichmentPoints: [
          'The advisory jurisdiction is under Article 143(1).',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1960,
          event: 'Advisory opinion — cession needs an amendment.',
          significance: 'Triggered the 9th Amendment.',
          evidence: evr('BERUBARI_UNION'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 6. Minerva Mills v. Union of India (1980)
    // -----------------------------------------------------------------------
    'MINERVA_MILLS': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_minerva_1',
          holding:
              'Clauses (4) and (5) of Article 368 (inserted by the 42nd Amendment) '
              'ousting judicial review of amendments are unconstitutional.',
          legalPrinciple: 'Judicial review is a basic feature; the amending power is limited.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MINERVA_MILLS'),
        ),
        JudgmentHolding(
          holdingId: 'hol_minerva_2',
          holding:
              'The widened Article 31C (protection for laws giving effect to all '
              'Directive Principles) is unconstitutional; it must remain confined '
              'to Articles 39(b) and 39(c).',
          legalPrinciple:
              'Directive Principles cannot override Fundamental Rights wholesale.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MINERVA_MILLS'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'Bhagwati J. and Chandrachud J. held that the harmony between '
            'Fundamental Rights and Directive Principles is part of the basic '
            'structure; an unlimited power to abridge Part III would destroy that '
            'harmony.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Fundamental Rights and DPSPs as complementary, not subordinate',
        ],
        doctrinalReasoning: const ['Basic Structure Doctrine'],
        reasoningTools: const ['harmonious construction', 'proportionality of the amending power'],
        evidence: edr('MINERVA_MILLS'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 4 of the 42nd Amendment (Articles 368(4)-(5)) and the '
            'widened Article 31C struck down as unconstitutional.',
        majorityOutcome: 'Limited amendment + judicial review + FR-DPSP balance preserved.',
        evidence: evr('MINERVA_MILLS'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Reaffirmed and applied the basic structure doctrine after the '
            'Emergency; struck down key parts of the 42nd Amendment.',
        legalSignificance:
            'Held that the FR-DPSP balance and judicial review are basic features; '
            'limited Article 31C to Articles 39(b) and 39(c).',
        upscSignificance:
            'Asked as the case that invalidated parts of the 42nd Amendment and '
            'limited Article 31C.',
        historicalSignificance:
            'One of the first major post-Emergency checks on constitutional '
            'amendment excess.',
        significanceScore: 90,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1980 by a 5-judge bench.',
          'Struck down Articles 368(4)-(5) and the widened Article 31C of the 42nd Amendment.',
          'Held the limited amending power, judicial review and FR-DPSP harmony are basic features.',
        ],
        prelimsTraps: [
          'Minerva Mills struck down part of the 42nd Amendment, but the 42nd Amendment as a whole was not void.',
          'Article 31C survives only for laws under Articles 39(b) and 39(c).',
        ],
        mainsThemes: [
          'Basic structure and the 42nd Amendment',
          'Fundamental Rights vs Directive Principles under Article 31C',
        ],
        mainsArguments: [
          'An unlimited power to abridge Part III would make Fundamental Rights meaningless.',
          'Judicial review is integral to the constitutional scheme.',
        ],
        mainsCounterarguments: [
          'A contrary view holds DPSPs should be able to override FRs to advance social justice.',
        ],
        answerKeywords: [
          'Minerva Mills', 'Article 31C', '42nd Amendment', 'Judicial review',
          'Basic Structure', 'FR-DPSP harmony',
        ],
        essayThemes: [
          'The constitutional balance between rights and social justice',
        ],
        interviewAreas: [
          'Why did the Court preserve Article 31C only for 39(b) and 39(c)?',
        ],
        answerEnrichmentPoints: [
          'The judgment is a joint product of Bhagwati J. and Chandrachud C.J.',
          'Later reaffirmed in Waman Rao and IR Coelho.',
        ],
        contemporaryRelevance: [
          'The 42nd Amendment remains the largest constitutional change; Minerva Mills frames its limits.',
        ],
        likelyInterviewQuestions: [
          'If Parliament re-enacts a widened Article 31C, would it pass muster?',
        ],
        conclusionIdeas: [
          'Minerva Mills completes the basic structure doctrine by protecting the rights-directives equilibrium from amendment.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1976,
          event: '42nd Amendment enacted.',
          significance: 'Sought to curb judicial review and widen Article 31C.',
          evidence: evr('MINERVA_MILLS'),
        ),
        JudgmentTimelineEvent(
          year: 1980,
          event: 'Minerva Mills struck down the impugned clauses.',
          significance: 'Basic structure doctrine applied to the 42nd Amendment.',
          evidence: evr('MINERVA_MILLS'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 7. Maneka Gandhi v. Union of India (1978)
    // -----------------------------------------------------------------------
    'MANEKA_GANDHI': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_maneka_1',
          holding:
              'The procedure contemplated by Article 21 must be fair, just and '
              'reasonable; Articles 19 and 21 are not mutually exclusive and must '
              'be read together.',
          legalPrinciple:
              'Procedure under Article 21 must be fair, just and reasonable (due process).',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MANEKA_GANDHI'),
        ),
        JudgmentHolding(
          holdingId: 'hol_maneka_2',
          holding:
              'Section 10(3)(c) of the Passports Act, 1967 — impounding a passport '
              'without reasons — is unconstitutional for offending natural justice.',
          legalPrinciple: 'Natural justice applies to administrative action affecting rights.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('MANEKA_GANDHI'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 7-judge bench overruled A.K. Gopalan\'s "self-contained rights" '
            'approach, holding that Articles 14, 19 and 21 overlap and inform '
            'each other, and that the procedure under Article 21 must be '
            'reasonable.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Rights overlap and interact; substantive due process',
        ],
        doctrinalReasoning: const ['Due process', 'Natural justice'],
        reasoningTools: const ['reasonableness', 'procedural fairness'],
        evidence: edr('MANEKA_GANDHI'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 10(3)(c) of the Passports Act held unconstitutional; '
            'impounding without opportunity of hearing invalid.',
        majorityOutcome: 'Right to travel and the doctrine of fair procedure affirmed.',
        evidence: evr('MANEKA_GANDHI'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Transformed Article 21 into the most potent fundamental right by '
            'importing due process and linking Articles 14, 19 and 21.',
        legalSignificance:
            'Overruled Gopalan; made natural justice a constitutional requirement.',
        upscSignificance:
            'One of the most frequently cited rights cases; the bridge between '
            'Gopalan and modern substantive rights jurisprudence.',
        historicalSignificance:
            'Decided shortly after the Emergency, marking the Court\'s turn '
            'toward rights protection.',
        significanceScore: 95,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1978 by a 7-judge bench.',
          'Article 21 procedure must be fair, just and reasonable.',
          'Struck down Section 10(3)(c) of the Passports Act, 1967.',
          'Overruled A.K. Gopalan\'s narrow reading of Article 21.',
        ],
        prelimsTraps: [
          'Maneka Gandhi introduced due process into Article 21; Gopalan (1950) did not.',
          'The right to travel abroad is a right, but not an absolute one.',
        ],
        mainsThemes: [
          'Procedural due process under Article 21',
          'Overlap of Articles 14, 19 and 21',
          'Natural justice in administrative law',
        ],
        mainsArguments: [
          'Liberty under Article 21 is not confined to physical freedom; it requires a fair procedure.',
          'Reading Articles 14, 19 and 21 together makes rights mutually reinforcing.',
        ],
        mainsCounterarguments: [
          'The original drafters rejected an explicit "due process" clause in Article 21.',
        ],
        answerKeywords: [
          'Maneka Gandhi', 'Due Process', 'Natural Justice', 'Article 21',
          'Passports Act 1967', 'Fair Just Reasonable',
        ],
        essayThemes: [
          'Due process as the soul of liberty',
          'How procedural fairness protects substantive rights',
        ],
        interviewAreas: [
          'Why did the Court read "procedure established by law" to mean "fair procedure"?',
        ],
        answerEnrichmentPoints: [
          'Later used to ground privacy (Puttaswamy), environment (Olga Tellis), and dignity rights.',
          'The "golden triangle" of Articles 14, 19, 21.',
        ],
        contemporaryRelevance: [
          'Underpins procedural fairness in every modern liberty question — from data protection to arrest procedures.',
        ],
        likelyInterviewQuestions: [
          'How does Maneka Gandhi\'s reading of Article 21 shape the right to privacy?',
        ],
        conclusionIdeas: [
          'Maneka Gandhi constitutionalised fairness, making procedure the guardian of liberty.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1950,
          event: 'A.K. Gopalan decided — narrow reading of Article 21.',
          significance: 'The view Maneka Gandhi would overrule.',
          evidence: evr('MANEKA_GANDHI'),
        ),
        JudgmentTimelineEvent(
          year: 1978,
          event: 'Maneka Gandhi decided.',
          significance: 'Due process and rights-overlap introduced.',
          evidence: evr('MANEKA_GANDHI'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 8. ADM Jabalpur v. Shivkant Shukla (1976)
    // -----------------------------------------------------------------------
    'ADM_JABALPUR': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_adm_1',
          holding:
              'During the Emergency, the enforcement of the right to life and '
              'personal liberty under Article 21 remained suspended, and a '
              'detainee could not maintain a habeas corpus petition.',
          legalPrinciple:
              'Emergency suspends enforcement of Articles 21 and 22 (majority view, later overruled).',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('ADM_JABALPUR'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 5-judge bench (Khanna J. dissenting) held that the only source of '
            'the right to life was Article 21, and with its suspension during '
            'the Emergency no enforceable right remained for habeas corpus.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Positivist reading of rights as solely constitutional',
        ],
        doctrinalReasoning: const ['Emergency powers'],
        reasoningTools: const ['literal construction of Article 359'],
        evidence: edr('ADM_JABALPUR'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.dismissed,
        operativeResult:
            'Habeas corpus petitions dismissed (4:1); Khanna J. dissented, '
            'holding that life and liberty cannot be suspended.',
        majorityOutcome: 'No right to life enforceable during Emergency suspension.',
        minorityOutcome:
            'Khanna J.: life and liberty are fundamental and survive even '
            'suspension of Article 21.',
        evidence: evr('ADM_JABALPUR'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The low point of the Supreme Court during the Emergency; later '
            'declared wrong and overruled by Puttaswamy (2017).',
        legalSignificance:
            'Overruled: the Court now recognises the right to life and dignity as '
            'existing beyond Article 21.',
        upscSignificance:
            'Asked to test the Emergency era and the vindication of individual '
            'rights; the Khanna J. dissent is a famous civil-liberties moment.',
        historicalSignificance:
            'Decided 1976 during the Internal Emergency; a defining episode for '
            'judicial independence.',
        significanceScore: 78,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1976 during the Internal Emergency, 4:1.',
          'Habeas corpus suspended; Khanna J. famously dissented.',
          'Overruled in Puttaswamy v. Union of India (2017).',
        ],
        prelimsTraps: [
          'ADM Jabalpur is no longer good law — it was overruled by Puttaswamy.',
          'Khanna J. dissented; the majority upheld the suspension.',
        ],
        mainsThemes: [
          'Emergency and fundamental rights',
          'Judicial independence during crisis',
        ],
        answerKeywords: [
          'ADM Jabalpur', 'Habeas Corpus', 'Emergency', 'Khanna J.',
          'Article 21', 'Article 359',
        ],
        essayThemes: [
          'The rule of law and the price of constitutional silence',
          'Judges and the courage of dissent',
        ],
        interviewAreas: [
          'Why is the ADM Jabalpur dissent considered a moral landmark?',
        ],
        answerEnrichmentPoints: [
          'Puttaswamy expressly held ADM Jabalpur "must be overruled".',
          'The 44th Amendment (1978) later restored Articles 21 and 22 protections.',
        ],
        contemporaryRelevance: [
          'Cited in debates on preventive detention and executive overreach.',
        ],
        likelyInterviewQuestions: [
          'Would ADM Jabalpur be decided differently today?',
        ],
        conclusionIdeas: [
          'ADM Jabalpur remains the cautionary tale of how rights erode when courts defer during emergencies.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1976,
          event: 'ADM Jabalpur decided (4:1, Khanna J. dissenting).',
          significance: 'Habeas corpus suspended during the Emergency.',
          evidence: evr('ADM_JABALPUR'),
        ),
        JudgmentTimelineEvent(
          year: 2017,
          event: 'Overruled in Puttaswamy v. Union of India.',
          significance: 'Court held the ADM Jabalpur reasoning was wrong.',
          evidence: evr('ADM_JABALPUR'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 9. S.R. Bommai v. Union of India (1994)
    // -----------------------------------------------------------------------
    'SR_BOMMAI': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_bommai_1',
          holding:
              'Federalism and secularism are basic features of the Constitution; '
              'a proclamation under Article 356 is subject to judicial review.',
          legalPrinciple: 'Article 356 is justiciable; secularism is a basic feature.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SR_BOMMAI'),
        ),
        JudgmentHolding(
          holdingId: 'hol_bommai_2',
          holding:
              'The majority of a Legislative Assembly is to be tested only on the '
              'floor of the House; the President cannot dismiss a State '
              'government without satisfying the floor test.',
          legalPrinciple: 'Floor test is the constitutional method for testing majority.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SR_BOMMAI'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court held that a Governor\'s report is not conclusive, that '
            'Articles 356 and 365 operate in distinct fields, and that the '
            'dissolution of an Assembly is subject to judicial review where '
            'mala fides or extraneous considerations appear.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Federal balance and the rule of law',
          'Secularism as constitutional identity',
        ],
        doctrinalReasoning: const ['Basic Structure Doctrine', 'Judicial review of presidential action'],
        reasoningTools: const ['floor test', 'proportionality'],
        evidence: edr('SR_BOMMAI'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Dissolution of the Karnataka Assembly held unconstitutional; '
            'guidelines laid down for Article 356 and floor tests.',
        majorityOutcome: 'Article 356 subject to judicial review; secularism basic feature.',
        evidence: evr('SR_BOMMAI'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Broke the "political question" shield around Article 356; made '
            'secularism and federalism judicially enforceable.',
        legalSignificance:
            'Established the justiciability of presidential proclamations and '
            'the floor-test doctrine.',
        upscSignificance:
            'High-frequency case for federalism, Article 356, President\'s rule '
            'and the floor-test debate.',
        historicalSignificance:
            'Decided in the politically charged context of the early 1990s '
            'Assembly dissolutions.',
        significanceScore: 92,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1994 by a 9-judge bench.',
          'Held secularism and federalism are basic features of the Constitution.',
          'Article 356 proclamations are subject to judicial review.',
          'Majority must be tested on the floor of the House.',
        ],
        prelimsTraps: [
          'Bommai is the 9-judge federalism case — not the 1992 reservations case (Indra Sawhney).',
          'The floor test doctrine, not the Governor\'s opinion, decides majority.',
        ],
        mainsThemes: [
          'President\'s Rule under Article 356 and its limits',
          'Federalism and the unitarian tendencies of Article 356',
          'Secularism as a basic feature',
        ],
        mainsArguments: [
          'A Governor\'s report is not conclusive and can be examined by the court.',
          'Dismissing an elected government without a floor test violates federalism.',
        ],
        mainsCounterarguments: [
          'Political questions are better left to the political process (the US-style political-question doctrine).',
        ],
        answerKeywords: [
          'Article 356', 'Floor Test', 'Secularism', 'Federalism',
          'Basic Structure', 'Judicial Review', '9-judge bench',
        ],
        essayThemes: [
          'Federalism as the architecture of a plural society',
        ],
        interviewAreas: [
          'Should courts review a Governor\'s decision to recommend President\'s Rule?',
        ],
        answerEnrichmentPoints: [
          'Later relied on in the 2018 Karnataka and 2016 Arunachal Pradesh (Nabam Rebia) controversies.',
          'The proclamation needs the floor test within a reasonable time.',
        ],
        contemporaryRelevance: [
          'Constantly invoked in State-Governor disputes and coalition politics.',
        ],
        likelyInterviewQuestions: [
          'What safeguards did Bommai build around Article 356?',
        ],
        conclusionIdeas: [
          'Bommai converted Article 356 from a weapon into a judicially bounded emergency power.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1994,
          event: 'S.R. Bommai decided.',
          significance: 'Article 356 made justiciable; secularism a basic feature.',
          evidence: evr('SR_BOMMAI'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 10. Indra Sawhney v. Union of India (1992)
    // -----------------------------------------------------------------------
    'INDRA_SAWHNEY': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_indra_1',
          holding:
              'Reservations under Article 16(4) are not available to the creamy '
              'layer within backward classes; the 50% ceiling on reservations is '
              'not absolute but is the general rule.',
          legalPrinciple: 'Creamy layer exclusion; 50% cap as general rule.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('INDRA_SAWHNEY'),
        ),
        JudgmentHolding(
          holdingId: 'hol_indra_2',
          holding:
              'Backward class identification under Article 16(4) is not based on '
              'caste alone; economic criteria alone are not a valid test of '
              'backwardness for Article 16(4).',
          legalPrinciple: 'Caste + social backwardness test; no reservation in promotions under Article 16(4).',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('INDRA_SAWHNEY'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The 9-judge bench upheld the Mandal Commission\'s OBC '
            'identification but excluded the creamy layer and denied reservation '
            'in promotions under Article 16(4) (later modified by amendment and '
            'M. Nagaraj).',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Substantive equality and affirmative action',
        ],
        doctrinalReasoning: const ['Creamy layer doctrine'],
        reasoningTools: const ['reasonable classification', '50% ceiling'],
        evidence: edr('INDRA_SAWHNEY'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheldWithDirections,
        operativeResult:
            'Mandal Commission recommendations upheld with creamy layer '
            'exclusion; reservation in promotions under Article 16(4) denied.',
        majorityOutcome: '27% OBC reservation valid; creamy layer excluded.',
        evidence: evr('INDRA_SAWHNEY'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The definitive 9-judge authority on reservation and Article 16, '
            'establishing the creamy layer doctrine.',
        legalSignificance:
            'Set the parameters for backward-class identification and the 50% '
            'cap; reservation in promotion later addressed by amendment and '
            'M. Nagaraj.',
        upscSignificance:
            'One of the most exam-tested judgments on reservations; the creamy '
            'layer and 50% cap are perennial Prelims points.',
        historicalSignificance:
            'Decided in 1992 amid violent reaction to Mandal Commission '
            'implementation; a social-policy watershed.',
        significanceScore: 91,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1992 by a 9-judge bench.',
          'Upheld 27% OBC reservation under Article 16(4).',
          'Excluded the creamy layer among backward classes.',
          'Held the 50% ceiling on reservations is the general rule.',
        ],
        prelimsTraps: [
          'Indra Sawhney denied reservation in promotions under Article 16(4); the 77th Amendment later overrode this.',
          'The 50% cap was later relaxed only in exceptional circumstances (M. Nagaraj).',
        ],
        mainsThemes: [
          'Reservation policy and equality jurisprudence',
          'Creamy layer doctrine',
          'Affirmative action and the merit debate',
        ],
        mainsArguments: [
          'Affirmative action is required by substantive equality, not by '
          'numerical representation alone.',
          'Creamy layer exclusion ensures the benefit reaches the genuinely backward.',
        ],
        mainsCounterarguments: [
          'Excluding the creamy layer can be criticised as defeating the '
          'inter-generational uplift objective of reservations.',
        ],
        answerKeywords: [
          'Article 16(4)', 'Creamy Layer', 'Mandal Commission', '50% ceiling',
          'Backward Class', '9-judge bench',
        ],
        essayThemes: [
          'Equality of opportunity vs equality of outcome',
          'Reservations and social justice in a plural democracy',
        ],
        interviewAreas: [
          'Should reservation be extended in promotions today?',
        ],
        answerEnrichmentPoints: [
          'Followed by the 77th/81st/85th Amendments and M. Nagaraj (2006).',
          'EWS (103rd Amendment) later created a separate 10% quota for the economically weaker.',
        ],
        contemporaryRelevance: [
          'Central to the EWS debate and the current discussion on sub-classification of SC/STs.',
        ],
        likelyInterviewQuestions: [
          'How is the creamy layer defined today, and who should decide it?',
        ],
        conclusionIdeas: [
          'Indra Sawhney balanced affirmative action with the principle that '
          'reservation must reach those who are genuinely backward.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1992,
          event: 'Indra Sawhney decided.',
          significance: 'Creamy layer doctrine and 50% cap established.',
          evidence: evr('INDRA_SAWHNEY'),
        ),
        JudgmentTimelineEvent(
          year: 2006,
          event: 'M. Nagaraj v. Union of India.',
          significance: 'Reservation in promotions under Article 16(4A) with '
              'creamy layer and compelling-reasons data test.',
          evidence: evr('INDRA_SAWHNEY'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 11. Vishaka v. State of Rajasthan (1997)
    // -----------------------------------------------------------------------
    'VISHAKA': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_vishaka_1',
          holding:
              'In the absence of legislation, binding guidelines against sexual '
              'harassment at the workplace were issued under Articles 14, 19 and '
              '21, drawing on the CEDAW convention.',
          legalPrinciple: 'Gender equality and workplace dignity; binding judicial guidelines.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('VISHAKA'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court filled the legislative vacuum on workplace sexual '
            'harassment by reading CEDAW and gender-justice principles into '
            'Articles 14, 19 and 21, and issuing guidelines that operate until '
            'legislation is enacted.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'International law to fill constitutional gaps',
          'Substantive gender equality',
        ],
        doctrinalReasoning: const ['Legislative vacuum doctrine'],
        reasoningTools: const ['reading international conventions into domestic rights'],
        evidence: edr('VISHAKA'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.guidelinesIssued,
        operativeResult:
            'Comprehensive guidelines on workplace sexual harassment issued; '
            'declared binding until superseded by statute.',
        majorityOutcome: 'Guidelines effective as law in the interim.',
        evidence: evr('VISHAKA'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Established the right to a harassment-free workplace as part of '
            'Articles 14, 19 and 21.',
        legalSignificance:
            'Guidelines later codified in the POSH Act, 2013; a leading example '
            'of judicial legislation to fill a vacuum.',
        upscSignificance:
            'Asked for the Vishaka guidelines, their legal basis, and their '
            'codification into the POSH Act.',
        historicalSignificance:
            'Followed the Bhanwari Devi gang-rape and was a turning point for '
            'workplace safety jurisprudence.',
        significanceScore: 88,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1997 by a 3-judge bench led by CJI J.S. Verma.',
          'Issued binding guidelines against workplace sexual harassment.',
          'Grounded in Articles 14, 19 and 21 and the CEDAW convention.',
          'Codified into the POSH Act, 2013.',
        ],
        prelimsTraps: [
          'The POSH Act did NOT exist in 1997 — Vishaka guidelines filled the gap until 2013.',
          'Vishaka is not about the right to privacy; it is about workplace dignity and safety.',
        ],
        mainsThemes: [
          'Gender justice and workplace safety',
          'Judicial creativity in a legislative vacuum',
          'International conventions and constitutional rights',
        ],
        mainsArguments: [
          'Articles 14, 19 and 21 read with CEDAW mandate a safe workplace.',
          'Judicial guidelines can operate until Parliament legislates.',
        ],
        mainsCounterarguments: [
          'Judicial guidelines can be criticised as an intrusion into the '
          'legislative domain.',
        ],
        answerKeywords: [
          'Vishaka', 'POSH Act 2013', 'Sexual Harassment', 'CEDAW',
          'Articles 14 19 21', 'Workplace Dignity',
        ],
        essayThemes: [
          'The law\'s role in the absence of law',
          'From protest to protection: women and the workplace',
        ],
        interviewAreas: [
          'How effective has the POSH Act been in practice?',
        ],
        answerEnrichmentPoints: [
          'The Bhanwari Devi case inspired Vishaka.',
          'The guidelines covered complaints committees, prevention and '
          'redressal — later institutionalised by the 2013 Act.',
        ],
        contemporaryRelevance: [
          'The POSH Act\'s enforcement gaps and the #MeToo movement keep '
          'Vishaka\'s principles live.',
        ],
        likelyInterviewQuestions: [
          'Why did the Court need CEDAW to decide Vishaka?',
        ],
        conclusionIdeas: [
          'Vishaka shows how constitutional courts can act as engines of social '
          'change when the legislature is silent.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1997,
          event: 'Vishaka guidelines issued.',
          significance: 'Binding workplace-harassment norms in a legislative vacuum.',
          evidence: evr('VISHAKA'),
        ),
        JudgmentTimelineEvent(
          year: 2013,
          event: 'POSH Act enacted.',
          significance: 'Vishaka guidelines codified into statute.',
          evidence: evr('VISHAKA'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 12. Olga Tellis v. Bombay Municipal Corporation (1985)
    // -----------------------------------------------------------------------
    'OLGA_TELLIS': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_olga_1',
          holding:
              'The right to livelihood is an integral part of the right to life '
              'under Article 21, but the right to dwell on pavements is not a '
              'constitutional right.',
          legalPrinciple: 'Right to livelihood within Article 21.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('OLGA_TELLIS'),
        ),
        JudgmentHolding(
          holdingId: 'hol_olga_2',
          holding:
              'Eviction of pavement dwellers is permissible only with a fair '
              'opportunity of hearing and in accordance with law.',
          legalPrinciple: 'Natural justice before eviction.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('OLGA_TELLIS'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court read the right to livelihood into Article 21, holding that '
            'eviction without alternative arrangements or hearing violates the '
            'right to life for those whose livelihood depends on dwelling on the '
            'pavement.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Livelihood as the essence of life',
          'Social justice for the urban poor',
        ],
        doctrinalReasoning: const ['Right to livelihood'],
        reasoningTools: const ['reasonableness', 'natural justice'],
        evidence: edr('OLGA_TELLIS'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.upheldWithDirections,
        operativeResult:
            'Eviction held not unconstitutional per se, but subject to notice and '
            'hearing; guidelines for humane eviction issued.',
        majorityOutcome: 'Livelihood part of Article 21; eviction regulated.',
        evidence: evr('OLGA_TELLIS'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Extended Article 21 to economic survival, connecting liberty with '
            'livelihood for the urban poor.',
        legalSignificance:
            'Established the justiciability of livelihood-based claims against '
            'eviction.',
        upscSignificance:
            'The classic "right to livelihood" case, asked in both Prelims and '
            'Mains (urban governance, Article 21).',
        historicalSignificance:
            'Decided in the 1980s when the Court was expanding the social reach '
            'of Article 21.',
        significanceScore: 84,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1985 by a 5-judge bench.',
          'Right to livelihood is part of Article 21.',
          'Pavement dwellers have no constitutional right to dwell on pavements.',
          'Evictions must follow fair procedure and natural justice.',
        ],
        prelimsTraps: [
          'Olga Tellis did NOT hold eviction unconstitutional; it regulated the procedure.',
          'The right to livelihood is not a right to employment or housing per se.',
        ],
        mainsThemes: [
          'Right to livelihood and urban evictions',
          'Article 21 and the urban poor',
          'Due process in administrative evictions',
        ],
        mainsArguments: [
          'Where eviction destroys the means of livelihood, it violates Article 21 unless a fair hearing is given.',
        ],
        answerKeywords: [
          'Olga Tellis', 'Right to Livelihood', 'Article 21',
          'Pavement Dwellers', 'Natural Justice',
        ],
        essayThemes: [
          'The city and the citizen: who owns public space?',
        ],
        interviewAreas: [
          'Does the right to livelihood create a right to housing?',
        ],
        answerEnrichmentPoints: [
          'The Court held the right to livelihood survives where livelihood is '
          'dependent on the pavement, but regulated rather than barred eviction.',
        ],
        contemporaryRelevance: [
          'Relevant to slum evictions, street-vendor regulation and urban '
          'gentrification debates.',
        ],
        likelyInterviewQuestions: [
          'How do you reconcile Olga Tellis with slum-clearance programmes?',
        ],
        conclusionIdeas: [
          'Olga Tellis insists that even lawful evictions respect the human '
          'dignity of the displaced.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1985,
          event: 'Olga Tellis decided.',
          significance: 'Right to livelihood read into Article 21.',
          evidence: evr('OLGA_TELLIS'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 13. Unni Krishnan v. State of A.P. (1993)
    // -----------------------------------------------------------------------
    'UNNIKRISHNAN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_unni_1',
          holding:
              'The right to education is a fundamental right under Article 21 '
              'up to the age of 14, and thereafter subject to the economic '
              'capacity and development of the State.',
          legalPrinciple: 'Free and compulsory education up to 14 years as a fundamental right.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('UNNIKRISHNAN'),
        ),
        JudgmentHolding(
          holdingId: 'hol_unni_2',
          holding:
              'Private professional colleges cannot charge capitation fees; a '
              'regulatory framework for admissions was laid down.',
          legalPrinciple: 'No capitation fee; state-regulated admissions in professional colleges.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('UNNIKRISHNAN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'Building on Mohini Jain, the Court located the right to education '
            'in Articles 21, 41 and 45, fixing the fundamental right at the 6-14 '
            'stage and regulating private professional institutions.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Education as empowerment and dignity',
          'DPSP-Fundamental Right interplay',
        ],
        doctrinalReasoning: const ['Right to education'],
        reasoningTools: const ['reading DPSPs into Article 21'],
        evidence: edr('UNNIKRISHNAN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Right to education declared fundamental up to 14 years; capitation '
            'fee regime rejected; admissions scheme laid down (later superseded '
            'by the 86th Amendment and RTE Act).',
        majorityOutcome: 'Free education 6-14 is a fundamental right.',
        evidence: evr('UNNIKRISHNAN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Confirmed the fundamental status of education for children 6-14, '
            'paving the way for the 86th Amendment and the RTE Act.',
        legalSignificance:
            'Settled the right-to-education controversy between Mohini Jain and '
            'the 86th Amendment; abolished capitation fees.',
        upscSignificance:
            'Asked for the right to education, Article 21A (added by the 86th '
            'Amendment) and the RTE Act.',
        historicalSignificance:
            'Decided 1993; the constitutional foundation later formalised by '
            'Article 21A in 2002.',
        significanceScore: 83,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1993 by a 5-judge bench.',
          'Right to education is fundamental up to age 14 under Article 21.',
          'Capitation fees in private professional colleges invalid.',
          'Led to the 86th Amendment (2002) inserting Article 21A.',
        ],
        prelimsTraps: [
          'Article 21A (86th Amendment) covers ages 6-14; Unni Krishnan '
          'pre-dated it.',
          'Unni Krishnan is not the same as Mohini Jain (1992), though related.',
        ],
        mainsThemes: [
          'Right to education and Article 21A',
          'Regulation of private higher education',
          'DPSP and Fundamental Right convergence',
        ],
        mainsArguments: [
          'Education is the bedrock of dignity and must be constitutionally guaranteed for children.',
        ],
        answerKeywords: [
          'Right to Education', 'Article 21A', '86th Amendment', 'Capitation fee',
          'RTE Act 2009', 'Unni Krishnan',
        ],
        essayThemes: [
          'Education as the equaliser in an unequal society',
        ],
        interviewAreas: [
          'Has the RTE Act achieved universal elementary education?',
        ],
        answerEnrichmentPoints: [
          'The 86th Amendment added Article 21A and changed Article 45 to early '
          'childhood care.',
          'The RTE Act, 2009 operationalised Article 21A.',
        ],
        contemporaryRelevance: [
          'Private-school fee regulation and the 25% RTE quota continue the debate.',
        ],
        likelyInterviewQuestions: [
          'Why is education fundamental only up to 14 years?',
        ],
        conclusionIdeas: [
          'Unni Krishnan made education a constitutional entitlement, later '
          'crystallised in Article 21A and the RTE Act.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1993,
          event: 'Unni Krishnan decided.',
          significance: 'Education fundamental up to 14 years.',
          evidence: evr('UNNIKRISHNAN'),
        ),
        JudgmentTimelineEvent(
          year: 2002,
          event: '86th Amendment inserted Article 21A.',
          significance: 'Free education 6-14 formalised in the Constitution.',
          evidence: evr('UNNIKRISHNAN'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 14. I.R. Coelho v. State of Tamil Nadu (2007)
    // -----------------------------------------------------------------------
    'IR_COELHO': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_coelho_1',
          holding:
              'Laws placed in the Ninth Schedule after 24 April 1973 are not '
              'immune from judicial review and are subject to the basic '
              'structure doctrine.',
          legalPrinciple:
              'Ninth Schedule immunity does not bar basic-structure review.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('IR_COELHO'),
        ),
        JudgmentHolding(
          holdingId: 'hol_coelho_2',
          holding:
              'The test for examining Ninth Schedule laws is the impact on '
              'fundamental rights and basic structure, not merely the extent of '
              'the amending power.',
          legalPrinciple: 'Rights test (impact) applies to Ninth Schedule laws.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('IR_COELHO'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 9-judge bench held that judicial review of the Ninth Schedule is '
            'a basic feature, and that the doctrine of basic structure applies '
            'retrospectively to amendments made after Kesavananda.',
        approach: InterpretiveApproach.harmonious,
        constitutionalPhilosophy: const [
          'Fundamental rights as the core of the basic structure',
        ],
        doctrinalReasoning: const ['Basic Structure Doctrine', 'Ninth Schedule jurisprudence'],
        reasoningTools: const ['impact/rights test', 'retrospective application'],
        evidence: edr('IR_COELHO'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Held the Ninth Schedule not to be a blanket immunity; the basic '
            'structure doctrine governs post-1973 Ninth Schedule laws.',
        majorityOutcome: 'Judicial review of Ninth Schedule laws upheld.',
        evidence: evr('IR_COELHO'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Closed the loophole that shielded Ninth Schedule laws from review, '
            'extending the basic structure doctrine to their content.',
        legalSignificance:
            'Established the impact/rights test and retrospective basic-structure '
            'review of post-1973 amendments.',
        upscSignificance:
            'Asked on the Ninth Schedule, the 24th Amendment cut-off and the '
            'basic structure doctrine.',
        historicalSignificance:
            'Decided by a 9-judge bench; a major reaffirmation of judicial review '
            'over the amendment power.',
        significanceScore: 86,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2007 by a 9-judge bench.',
          'Ninth Schedule laws are not immune from judicial review.',
          'Post-24 April 1973 laws in the Ninth Schedule are subject to basic structure review.',
        ],
        prelimsTraps: [
          'The Ninth Schedule was NOT abolished — only its blanket immunity was removed.',
          'The cut-off is 24 April 1973 (Kesavananda).',
        ],
        mainsThemes: [
          'Ninth Schedule and the basic structure doctrine',
          'Judicial review of constitutional amendments',
        ],
        mainsArguments: [
          'If Ninth Schedule laws could evade fundamental rights, the basic '
          'structure doctrine would be hollow.',
        ],
        answerKeywords: [
          'IR Coelho', 'Ninth Schedule', 'Basic Structure', 'Rights Test',
          '24 April 1973', 'Judicial Review',
        ],
        essayThemes: [
          'The eternal tension between legislative will and constitutional limits',
        ],
        interviewAreas: [
          'Does the Ninth Schedule have any purpose left after Coelho?',
        ],
        answerEnrichmentPoints: [
          'Coelho applied Kesavananda to Schedule Nine retrospectively.',
          'It builds on Waman Rao (1981) and Minerva Mills.',
        ],
        contemporaryRelevance: [
          'Relevant whenever Parliament shields laws from judicial review.',
        ],
        likelyInterviewQuestions: [
          'Can Parliament use the Ninth Schedule today to protect a law from '
          'judicial review?',
        ],
        conclusionIdeas: [
          'Coelho ensures that no constitutional device can place a law beyond '
          'the reach of fundamental rights.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2007,
          event: 'IR Coelho decided.',
          significance: 'Ninth Schedule immunity subjected to basic-structure review.',
          evidence: evr('IR_COELHO'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 15. K.S. Puttaswamy v. Union of India (2017)
    // -----------------------------------------------------------------------
    'PUTTASWAMY': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_puttaswamy_1',
          holding:
              'The right to privacy is a fundamental right protected under '
              'Articles 14, 19 and 21 of the Constitution.',
          legalPrinciple: 'Privacy is a constitutionally protected fundamental right.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('PUTTASWAMY'),
        ),
        JudgmentHolding(
          holdingId: 'hol_puttaswamy_2',
          holding:
              'A.D.M. Jabalpur and M.P. Sharma were overruled to the extent they '
              'denied privacy or the existence of rights beyond Article 21.',
          legalPrinciple: 'Overruling of privacy-denying precedents.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('PUTTASWAMY'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 9-judge bench unanimously recognised privacy as a fundamental '
            'right, tracing it to dignity and autonomy, subject to reasonable '
            'restrictions under a proportionality test.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Dignity and autonomy as the foundation of privacy',
        ],
        doctrinalReasoning: const ['Privacy doctrine', 'Proportionality'],
        reasoningTools: const ['proportionality', 'legitimate state aim', 'reasonable restriction'],
        evidence: edr('PUTTASWAMY'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.declaration,
        operativeResult:
            'Right to privacy declared a fundamental right; Aadhaar challenge '
            'remitted for decision on that basis.',
        majorityOutcome: 'Unanimous declaration of privacy as a fundamental right.',
        evidence: evr('PUTTASWAMY'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Ended decades of ambiguity by recognising privacy as a fundamental '
            'right, reshaping data protection and informational privacy law.',
        legalSignificance:
            'Overruled M.P. Sharma and A.D.M. Jabalpur; set the proportionality '
            'framework for state interference with privacy.',
        upscSignificance:
            'The defining contemporary rights case — asked for privacy, Aadhaar, '
            'and the data protection debate.',
        historicalSignificance:
            'Decided 2017 in the Aadhaar litigation; the basis for the Digital '
            'Personal Data Protection Act.',
        significanceScore: 96,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2017 by a 9-judge bench, unanimously.',
          'Right to privacy is a fundamental right under Articles 14, 19 and 21.',
          'Overruled A.D.M. Jabalpur (1976) and M.P. Sharma (1954).',
          'Privacy is subject to reasonable restrictions and proportionality.',
        ],
        prelimsTraps: [
          'Puttaswamy overruled A.D.M. Jabalpur, not just M.P. Sharma.',
          'Privacy is not absolute — it is subject to reasonable restrictions.',
        ],
        mainsThemes: [
          'Privacy, dignity and the digital state',
          'Data protection and the proportionality test',
          'Informational privacy and surveillance',
        ],
        mainsArguments: [
          'Privacy inheres in dignity and autonomy and is implicit in Articles '
          '14, 19 and 21.',
          'State action limiting privacy must satisfy a three-fold '
          'proportionality test.',
        ],
        mainsCounterarguments: [
          'An unqualified privacy right may impede legitimate state purposes '
          'such as national security and welfare delivery.',
        ],
        answerKeywords: [
          'Right to Privacy', 'Puttaswamy', 'Proportionality', 'Dignity',
          'Articles 14 19 21', 'Data Protection', 'Aadhaar',
        ],
        essayThemes: [
          'Privacy in the age of data',
          'Autonomy and the modern state',
        ],
        interviewAreas: [
          'Is privacy a social good or an individual right?',
        ],
        answerEnrichmentPoints: [
          'The proportionality test requires a legitimate state aim, '
          'necessity and no less-restrictive alternative.',
          'Led to the Digital Personal Data Protection Act, 2023.',
        ],
        contemporaryRelevance: [
          'Underpins the entire digital-governance, surveillance and data '
          'protection framework.',
        ],
        likelyInterviewQuestions: [
          'How does the proportionality test protect privacy against surveillance?',
        ],
        conclusionIdeas: [
          'Puttaswamy makes privacy the pivot on which a digital constitutional '
          'order turns.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2017,
          event: 'Puttaswamy (privacy) decided.',
          significance: 'Privacy recognised as a fundamental right.',
          evidence: evr('PUTTASWAMY'),
        ),
        JudgmentTimelineEvent(
          year: 2023,
          event: 'Digital Personal Data Protection Act enacted.',
          significance: 'Privacy jurisprudence operationalised into statute.',
          evidence: evr('PUTTASWAMY'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 16. Navtej Singh Johar v. Union of India (2018)
    // -----------------------------------------------------------------------
    'NAVTEJ_JOHAR': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_navtej_1',
          holding:
              'Section 377 IPC is unconstitutional insofar as it criminalises '
              'consensual sexual acts between adults, including same-sex '
              'relationships.',
          legalPrinciple: 'Right to sexual orientation and consensual intimacy under Articles 14, 15, 19 and 21.',
          scope: HoldingScope.broad,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('NAVTEJ_JOHAR'),
        ),
        JudgmentHolding(
          holdingId: 'hol_navtej_2',
          holding:
              'Criminalisation of consensual same-sex acts violates dignity, '
              'privacy and equality; it is not a reasonable restriction.',
          legalPrinciple: 'Sexual orientation is an innate aspect of dignity.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('NAVTEJ_JOHAR'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court read down Section 377 for consensual adult conduct, '
            'rejecting the Suresh Kumar Koushal precedent, and grounded the '
            'right in dignity, privacy and the equality of the individual.',
        approach: InterpretiveApproach.progressive,
        constitutionalPhilosophy: const [
          'Dignity and identity',
          'Substantive equality of sexual orientation',
        ],
        doctrinalReasoning: const ['Proportionality', 'Rights of sexual minorities'],
        reasoningTools: const ['proportionality', 'dignity', 'strict scrutiny'],
        evidence: edr('NAVTEJ_JOHAR'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Section 377 read down for consensual adult sexual acts; the offence '
            'remains for non-consensual acts and with minors.',
        majorityOutcome: 'Consensual same-sex conduct decriminalised.',
        evidence: evr('NAVTEJ_JOHAR'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Extended the right to privacy (Puttaswamy) to sexual orientation, '
            'affirming equality and dignity for LGBTQ+ persons.',
        legalSignificance:
            'Overruled Suresh Kumar Koushal and read down Section 377 IPC.',
        upscSignificance:
            'Asked for Section 377, the Navtej Johar holding, and the rights of '
            'sexual minorities.',
        historicalSignificance:
            'Decided 2018, a landmark in Indian social-rights jurisprudence.',
        significanceScore: 90,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2018 by a 5-judge bench.',
          'Section 377 IPC read down for consensual adult conduct.',
          'Sexual orientation is a facet of the right to privacy and dignity.',
          'Non-consensual acts and acts with minors remain offences.',
        ],
        prelimsTraps: [
          'Section 377 was NOT abolished entirely — non-consensual acts remain criminal.',
          'Navtej Johar overruled Suresh Kumar Koushal (2013).',
        ],
        mainsThemes: [
          'Sexual orientation and fundamental rights',
          'Dignity and privacy of LGBTQ+ persons',
          'Reading down penal statutes',
        ],
        mainsArguments: [
          'Criminalising identity-based conduct violates Articles 14, 15, 19 and 21.',
        ],
        answerKeywords: [
          'Section 377', 'Navtej Johar', 'Sexual Orientation', 'Privacy',
          'Dignity', 'Reading down',
        ],
        essayThemes: [
          'Love, law and the state',
          'The arc of rights: from criminalisation to recognition',
        ],
        interviewAreas: [
          'Does decriminalisation automatically confer all civil rights on '
          'same-sex couples?',
        ],
        answerEnrichmentPoints: [
          'Built directly on Puttaswamy\'s privacy holding.',
          'Marriage equality was separately declined in Supriyo (2023).',
        ],
        contemporaryRelevance: [
          'Central to the ongoing marriage-equality and non-discrimination debate.',
        ],
        likelyInterviewQuestions: [
          'Why did the Court distinguish identity-based criminalisation from '
          'other offences?',
        ],
        conclusionIdeas: [
          'Navtej Johar transformed Section 377 from a penal relic into a '
          'statement of constitutional dignity.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2018,
          event: 'Navtej Johar decided.',
          significance: 'Consensual same-sex conduct decriminalised.',
          evidence: evr('NAVTEJ_JOHAR'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 17. Shayara Bano v. Union of India (2017)
    // -----------------------------------------------------------------------
    'SHAYARA_BANO': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_shayara_1',
          holding:
              'Triple talaq (talaq-e-biddat) is unconstitutional for violating '
              'Article 14 and the fundamental rights of Muslim women.',
          legalPrinciple: 'Instant triple talaq struck down; gender justice overrides.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SHAYARA_BANO'),
        ),
        JudgmentHolding(
          holdingId: 'hol_shayara_2',
          holding:
              'The majority held that triple talaq is not an essential religious '
              'practice protected under Article 25.',
          legalPrinciple: 'Essential religious practices test under Article 25.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('SHAYARA_BANO'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'A 3:2 majority struck down instant triple talaq, holding it '
            'arbitrary under Article 14 and not an essential religious practice; '
            'the minority would have upheld it as a matter of personal law.',
        approach: InterpretiveApproach.purposive,
        constitutionalPhilosophy: const [
          'Gender justice and the subordination of personal law to Part III',
        ],
        doctrinalReasoning: const ['Essential religious practices test', 'Arbitrariness'],
        reasoningTools: const ['non-arbitrariness', 'gender equality'],
        evidence: edr('SHAYARA_BANO'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Triple talaq held unconstitutional (3:2); Parliament then enacted '
            'the Muslim Women (Protection of Rights on Marriage) Act, 2019.',
        majorityOutcome: 'Instant triple talaq struck down.',
        minorityOutcome:
            'CJI Khehar and Justice Nazeer upheld triple talaq as part of '
            'personal law, directing legislation instead.',
        evidence: evr('SHAYARA_BANO'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Applied fundamental rights to personal law, striking down instant '
            'triple talaq as arbitrary.',
        legalSignificance:
            'Set the precedent that religious personal law is subject to Part '
            'III; led to the 2019 criminalisation Act.',
        upscSignificance:
            'High-frequency case on personal law, Article 14/25 and gender '
            'justice.',
        historicalSignificance:
            'Decided 2017 in the aftermath of the Triple Talaq debates; a '
            'defining gender-justice judgment.',
        significanceScore: 89,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 2017 by a 5-judge bench, 3:2.',
          'Instant triple talaq held unconstitutional.',
          'Struck down for violating Article 14; not an essential religious practice.',
          'Led to the Muslim Women (Protection of Rights on Marriage) Act, 2019.',
        ],
        prelimsTraps: [
          'Shayara Bano struck down talaq-e-biddat, NOT all forms of Muslim divorce.',
          'The judgment was 3:2, not unanimous.',
        ],
        mainsThemes: [
          'Personal law and fundamental rights',
          'Gender justice and uniform civil code debate',
          'Essential religious practices test',
        ],
        mainsArguments: [
          'Personal law cannot override the guarantee against arbitrary state '
          'action in Article 14.',
        ],
        mainsCounterarguments: [
          'Personal law is a matter of religious freedom and legislative, not '
          'judicial, reform.',
        ],
        answerKeywords: [
          'Triple Talaq', 'Shayara Bano', 'Article 14', 'Article 25',
          'Essential Religious Practice', 'UCC', 'Muslim Women Act 2019',
        ],
        essayThemes: [
          'Law, religion and the rights of women',
          'When does the state intervene in personal law?',
        ],
        interviewAreas: [
          'Should India adopt a Uniform Civil Code?',
        ],
        answerEnrichmentPoints: [
          'The 2019 Act criminalises instant triple talaq.',
          'The essential-religious-practice test originates in Shirur Mutt (1954).',
        ],
        contemporaryRelevance: [
          'Central to the ongoing UCC debate and Article 44 discussions.',
        ],
        likelyInterviewQuestions: [
          'How should the state balance religious freedom and gender equality?',
        ],
        conclusionIdeas: [
          'Shayara Bano marks the moment personal law was made answerable to '
          'Part III.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 2017,
          event: 'Shayara Bano decided.',
          significance: 'Triple talaq struck down.',
          evidence: evr('SHAYARA_BANO'),
        ),
        JudgmentTimelineEvent(
          year: 2019,
          event: 'Muslim Women (Protection of Rights on Marriage) Act enacted.',
          significance: 'Instant triple talaq criminalised.',
          evidence: evr('SHAYARA_BANO'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 18. Romesh Thappar v. State of Madras (1950)
    // -----------------------------------------------------------------------
    'ROMESH_THAPPAR': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_romesh_1',
          holding:
              'A pre-Constitution law is subject to the Article 19(2) reasonable-'
              'restriction test, and a restriction on free speech must relate to '
              'a specified ground under Article 19(2).',
          legalPrinciple: 'Speech restrictions must fall within Article 19(2) grounds.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('ROMESH_THAPPAR'),
        ),
        JudgmentHolding(
          holdingId: 'hol_romesh_2',
          holding:
              'The ban on the Cross Roads journal exceeded permissible limits and '
              'was void.',
          legalPrinciple: 'Sedition/public order restriction narrowly construed.',
          scope: HoldingScope.narrow,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('ROMESH_THAPPAR'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The first free-speech case applied the pre-constitution law review '
            'and held that restrictions on speech must be anchored in a specific '
            'Article 19(2) ground; "public order" as a separate ground was '
            'rejected in 1950.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Free speech as the bedrock of democracy',
        ],
        doctrinalReasoning: const ['Reasonable restriction doctrine'],
        reasoningTools: const ['reasonableness', 'strict grounds test'],
        evidence: edr('ROMESH_THAPPAR'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Ban on the Cross Roads journal held unconstitutional.',
        majorityOutcome: 'Pre-constitution law tested against Article 19(2).',
        evidence: evr('ROMESH_THAPPAR'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The first Supreme Court ruling on free speech, establishing the '
            'Article 19(2) grounds test.',
        legalSignificance:
            'Held pre-constitution laws reviewable; rejected a general public-'
            'order restriction (later added by the First Amendment).',
        upscSignificance:
            'The classic 1950 free-speech case; asked with Brij Bhushan and '
            'Champakam.',
        historicalSignificance:
            'Decided in 1950, weeks after the Constitution came into force.',
        significanceScore: 78,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1950 by a 5-judge bench.',
          'First Supreme Court free-speech case.',
          'Restrictions on speech must fall within Article 19(2) grounds.',
          'The Cross Roads ban held unconstitutional.',
        ],
        prelimsTraps: [
          'In 1950 "public order" was NOT yet a separate ground — added by the '
          'First Amendment (1951).',
        ],
        mainsThemes: [
          'Article 19(1)(a) and the reasonable-restriction framework',
          'Sedition and freedom of speech',
        ],
        answerKeywords: [
          'Romesh Thappar', 'Article 19(2)', 'Cross Roads', 'Public Order',
          'Free Speech', 'Sedition',
        ],
        essayThemes: [
          'The first freedoms and the first restrictions',
        ],
        interviewAreas: [
          'Why did the First Amendment add "public order" to Article 19(2)?',
        ],
        answerEnrichmentPoints: [
          'Paired with Brij Bhushan (1950) on pre-censorship.',
          'Reads Article 19(1)(a) broadly as the essence of democracy.',
        ],
        contemporaryRelevance: [
          'Foundational to the Section 66A and sedition debates.',
        ],
        likelyInterviewQuestions: [
          'How does Romesh Thappar frame the modern free-speech test?',
        ],
        conclusionIdeas: [
          'Romesh Thappar set free speech as the presumptive right and '
          'restrictions as the exception needing constitutional justification.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1950,
          event: 'Romesh Thappar decided.',
          significance: 'Article 19(2) grounds test established.',
          evidence: evr('ROMESH_THAPPAR'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 19. A.K. Gopalan v. State of Madras (1950)
    // -----------------------------------------------------------------------
    'AK_GOPALAN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_gopalan_1',
          holding:
              'Preventive detention under Article 22 is constitutional; Articles '
              '19 and 21 are to be read as self-contained and not overlapping.',
          legalPrinciple: 'Self-contained rights; narrow reading of Article 21 (later overruled).',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('AK_GOPALAN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court read Articles 19, 21 and 22 as separate compartments and '
            'held that preventive detention was governed only by Article 22, '
            'declining to import due process into Article 21.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Positivist, text-bound reading of rights',
        ],
        doctrinalReasoning: const ['Preventive detention'],
        reasoningTools: const ['literal construction'],
        evidence: edr('AK_GOPALAN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.dismissed,
        operativeResult:
            'Preventive detention upheld; the narrow reading of Article 21 later '
            'overruled in Maneka Gandhi (1978).',
        majorityOutcome: 'Article 22 governs preventive detention; 19 not applicable.',
        evidence: evr('AK_GOPALAN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'The pre-Maneka authority for a compartmentalised reading of '
            'fundamental rights.',
        legalSignificance:
            'Overruled by Maneka Gandhi on the self-contained-rights approach.',
        upscSignificance:
            'Asked to show the evolution from Gopalan to Maneka Gandhi.',
        historicalSignificance:
            'One of the first Supreme Court decisions (1950) on preventive '
            'detention.',
        significanceScore: 74,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1950 by a 5-judge bench (some accounts note a larger '
          'concurrence on Article 22).',
          'Held Article 19 inapplicable to preventive detention.',
          'Narrow reading of Article 21, later overruled by Maneka Gandhi.',
        ],
        prelimsTraps: [
          'Gopalan is no longer the law on Article 21 — Maneka Gandhi overruled it.',
        ],
        mainsThemes: [
          'Preventive detention and Article 22',
          'Evolution of Article 21 jurisprudence',
        ],
        answerKeywords: [
          'A.K. Gopalan', 'Preventive Detention', 'Article 22',
          'Article 21', 'Maneka Gandhi',
        ],
        essayThemes: [
          'How courts correct their own reading of rights',
        ],
        interviewAreas: [
          'Why was the Gopalan reading abandoned?',
        ],
        answerEnrichmentPoints: [
          'Maneka Gandhi (1978) rejected the self-contained-rights approach.',
          'Preventive detention is still governed by Article 22.',
        ],
        contemporaryRelevance: [
          'Preventive-detention law continues to draw on Article 22.',
        ],
        likelyInterviewQuestions: [
          'Is preventive detention consistent with Article 21 today?',
        ],
        conclusionIdeas: [
          'Gopalan is the cautionary example of how a narrow textualism can '
          'narrow liberty — and why the Court later broadened it.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1950,
          event: 'A.K. Gopalan decided.',
          significance: 'Narrow reading of Article 21.',
          evidence: evr('AK_GOPALAN'),
        ),
        JudgmentTimelineEvent(
          year: 1978,
          event: 'Maneka Gandhi overruled the narrow reading.',
          significance: 'Due process imported into Article 21.',
          evidence: evr('AK_GOPALAN'),
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 20. Champakam Dorairajan v. State of Madras (1951)
    // -----------------------------------------------------------------------
    'CHAMPAKAM_DORAIRAJAN': JudgmentIntelligenceSeed(
      holdings: [
        JudgmentHolding(
          holdingId: 'hol_champakam_1',
          holding:
              'Communal (caste-based) reservation in admissions to state '
              'educational institutions violated Article 29(2), which guarantees '
              'non-discrimination in admissions.',
          legalPrinciple:
              'Article 29(2) bars caste-based discrimination in state institutions.',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('CHAMPAKAM_DORAIRAJAN'),
        ),
        JudgmentHolding(
          holdingId: 'hol_champakam_2',
          holding:
              'In case of conflict, Fundamental Rights prevail over Directive '
              'Principles under the then-constitutional scheme.',
          legalPrinciple: 'Fundamental Rights prevail over DPSPs (pre-1st Amendment position).',
          scope: HoldingScope.medium,
          confidence: IntelligenceConfidence.verified,
          evidence: evr('CHAMPAKAM_DORAIRAJAN'),
        ),
      ],
      reasoning: JudgmentReasoning(
        summary:
            'The Court struck down the Madras communal order as violating '
            'Article 29(2), and held that Directive Principles cannot override '
            'Fundamental Rights — a position reversed by the First Amendment.',
        approach: InterpretiveApproach.literal,
        constitutionalPhilosophy: const [
          'Fundamental Rights paramount over DPSPs (as then framed)',
        ],
        doctrinalReasoning: const ['FR-DPSP conflict resolution'],
        reasoningTools: const ['textual priority of Part III'],
        evidence: edr('CHAMPAKAM_DORAIRAJAN'),
      ),
      outcome: JudgmentOutcome(
        disposition: OutcomeDisposition.struckDown,
        operativeResult:
            'Madras communal order struck down; the First Amendment (1951) then '
            'inserted Article 15(4) to permit reservations for backward classes.',
        majorityOutcome: 'Article 29(2) violated; FRs prevail.',
        evidence: evr('CHAMPAKAM_DORAIRAJAN'),
      ),
      judicialSignificance: const JudicialSignificance(
        constitutionalSignificance:
            'Confirmed the primacy of Fundamental Rights and triggered the First '
            'Amendment which inserted Article 15(4) for reservations.',
        legalSignificance:
            'First direct FR-DPSP conflict resolution in favour of Part III.',
        upscSignificance:
            'Asked for Article 15(4), Article 29(2) and the First Amendment '
            'connection.',
        historicalSignificance:
            'Decided 1951; the catalyst for the First Amendment\'s reservation '
            'clause.',
        significanceScore: 76,
      ),
      upscIntelligence: const UpscJudgmentIntelligence(
        prelimsFacts: [
          'Decided 1951 by a 7-judge bench.',
          'Communal (caste-based) reservation in admissions struck down under Article 29(2).',
          'Led to Article 15(4) via the First Amendment.',
          'Held Fundamental Rights prevail over DPSPs.',
        ],
        prelimsTraps: [
          'Champakam did NOT end reservations — it prompted Article 15(4).',
        ],
        mainsThemes: [
          'Fundamental Rights vs Directive Principles',
          'Reservation policy under Articles 15(4) and 29(2)',
        ],
        answerKeywords: [
          'Champakam Dorairajan', 'Article 29(2)', 'Article 15(4)',
          'First Amendment', 'Reservation', 'FR vs DPSP',
        ],
        essayThemes: [
          'When the constitution amends itself to correct its own rigidity',
        ],
        interviewAreas: [
          'Did the First Amendment betray or fulfil the constitutional vision?',
        ],
        answerEnrichmentPoints: [
          'Article 15(4) was inserted to allow backward-class reservations.',
        ],
        contemporaryRelevance: [
          'Foundational to the reservation debate and Article 15(4)/(5).',
        ],
        likelyInterviewQuestions: [
          'How did Champakam shape the reservation architecture?',
        ],
        conclusionIdeas: [
          'Champakam showed that rights and social policy had to be reconciled '
          'through amendment, not by sacrificing Part III.',
        ],
        relatedSyllabusAreas: upscPolityCore,
      ),
      timeline: [
        JudgmentTimelineEvent(
          year: 1951,
          event: 'Champakam Dorairajan decided.',
          significance: 'FRs prevail; Article 15(4) soon added.',
          evidence: evr('CHAMPAKAM_DORAIRAJAN'),
        ),
      ],
    ),
  };
}
