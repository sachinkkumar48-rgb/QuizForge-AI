library;

import '../domain/entities/committee_enums.dart';
import '../domain/entities/committee_knowledge_object.dart';
import '../domain/entities/committee_member.dart';
import '../domain/entities/committee_report.dart';
import '../domain/entities/committee_timeline.dart';
import '../domain/entities/recommendation.dart';
import '../domain/entities/terms_of_reference.dart';

/// Phase-I Seed Corpus featuring landmark Indian Committees, Commissions, and Expert Bodies.
class CommitteeSeedCorpus {
  static final List<CommitteeKnowledgeObject> phase1Committees = [
    // 1. Sarkaria Commission
    CommitteeKnowledgeObject(
      id: 'comm_sarkaria_1983',
      officialName: 'Commission on Centre-State Relations (Sarkaria Commission)',
      shortName: 'Sarkaria Commission',
      category: CommitteeCategory.executive,
      constitutingAuthority: 'Ministry of Home Affairs, Government of India',
      chairperson: const CommitteeMember(
        name: 'Justice R.S. Sarkaria',
        designation: 'Retired Judge, Supreme Court of India',
        role: 'Chairperson',
      ),
      members: const [
        CommitteeMember(name: 'B. Sivaraman', role: 'Member'),
        CommitteeMember(name: 'Dr. S.R. Sen', role: 'Member'),
      ],
      yearConstituted: 1983,
      yearDissolved: 1988,
      currentStatus: CommitteeStatus.implemented,
      termsOfReference: const TermsOfReference(
        id: 'tor_sarkaria',
        description:
            'Examine and review the working of existing arrangements between Union and States in all spheres.',
        focusAreas: ['Article 356', 'Governor Role', 'Inter-State Council', 'All India Services'],
      ),
      objectives: const [
        'Review Centre-State financial and administrative balance of power',
        'Prevent misuse of Article 356 president rule',
        'Strengthen cooperative federalism institutions',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_sarkaria_001',
          title: 'Establishment of Permanent Inter-State Council',
          description: 'Establish permanent Inter-State Council under Article 263 of the Constitution.',
          status: RecommendationStatus.implemented,
          relatedArticleIds: ['Article 263'],
          relatedPyqIds: ['PYQ_POL_2018_Q12'],
        ),
        Recommendation(
          id: 'rec_sarkaria_002',
          title: 'Restraint in Exercise of Article 356',
          description: 'Article 356 should be used as a last resort in extreme cases after warning state.',
          status: RecommendationStatus.acceptedPartially,
          relatedArticleIds: ['Article 356'],
          relatedPyqIds: ['PYQ_POL_2019_Q05'],
        ),
      ],
      implementationStatus: 'Inter-State Council established in 1990; guidelines cited in S.R. Bommai case.',
      relatedMinistries: const ['Ministry of Home Affairs'],
      relatedActIds: const [],
      relatedArticleIds: const ['Article 263', 'Article 356', 'Article 246', 'Article 312'],
      relatedCaseLawIds: const ['S.R. Bommai v. Union of India (1994)'],
      relatedDoctrineIds: const ['Cooperative Federalism'],
      reports: [
        CommitteeReport(
          id: 'rep_sarkaria_1988',
          title: 'Report of the Commission on Centre-State Relations',
          submissionDate: DateTime(1988, 1, 1),
          reportUrl: 'https://interstatecouncil.gov.in/sarkaria-commission-report',
        ),
      ],
      relatedPyqIds: const ['PYQ_POL_2018_Q12', 'PYQ_POL_2019_Q05'],
      evidenceIds: const ['ev_sarkaria_official_1988'],
      keywords: const ['Centre-State Relations', 'Article 356', 'Article 263', 'S.R. Bommai', 'Governor'],
      timeline: [
        CommitteeTimeline(date: DateTime(1983, 6, 9), milestone: 'Constituted by MHA Notification'),
        CommitteeTimeline(date: DateTime(1987, 10, 27), milestone: 'Submitted final report to PM'),
      ],
    ),

    // 2. Punchhi Commission
    CommitteeKnowledgeObject(
      id: 'comm_punchhi_2007',
      officialName: 'Second Commission on Centre-State Relations (Punchhi Commission)',
      shortName: 'Punchhi Commission',
      category: CommitteeCategory.executive,
      constitutingAuthority: 'Ministry of Home Affairs, Government of India',
      chairperson: const CommitteeMember(
        name: 'Justice M.M. Punchhi',
        designation: 'Former Chief Justice of India',
        role: 'Chairperson',
      ),
      members: const [
        CommitteeMember(name: 'Dheerendra Singh', role: 'Member'),
        CommitteeMember(name: 'Vinod Kumar Duggal', role: 'Member'),
      ],
      yearConstituted: 2007,
      yearDissolved: 2010,
      currentStatus: CommitteeStatus.submitted,
      termsOfReference: const TermsOfReference(
        id: 'tor_punchhi',
        description: 'Review Centre-State relations keeping in view social and economic changes since Sarkaria Commission.',
        focusAreas: ['Local Self Governance', 'Treaty Making Powers', 'National Security', 'Governor Impeachment'],
      ),
      objectives: const [
        'Examine constitutional role of Governor in hung assemblies',
        'Propose fixed tenure and impeachment procedure for Governors',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_punchhi_001',
          title: 'Fixed Tenure and Impeachment for Governors',
          description: 'Governor should have fixed 5-year tenure and be removed only via impeachment by state legislature.',
          status: RecommendationStatus.underConsideration,
          relatedArticleIds: ['Article 155', 'Article 156'],
        ),
      ],
      implementationStatus: 'Under active review by Inter-State Council Standing Committee.',
      relatedMinistries: const ['Ministry of Home Affairs'],
      relatedArticleIds: const ['Article 155', 'Article 156', 'Article 355', 'Article 356'],
      relatedDoctrineIds: const ['Federalism'],
      evidenceIds: const ['ev_punchhi_2010'],
      keywords: const ['Punchhi Commission', 'Governor Impeachment', 'Centre State Relations'],
    ),

    // 3. 2nd Administrative Reforms Commission (ARC)
    CommitteeKnowledgeObject(
      id: 'comm_arc_2nd_2005',
      officialName: 'Second Administrative Reforms Commission (2nd ARC)',
      shortName: '2nd ARC',
      category: CommitteeCategory.executive,
      constitutingAuthority: 'Department of Administrative Reforms and Public Grievances',
      chairperson: const CommitteeMember(
        name: 'Veerappa Moily',
        designation: 'Former Union Minister',
        role: 'Chairperson',
      ),
      yearConstituted: 2005,
      yearDissolved: 2009,
      currentStatus: CommitteeStatus.partiallyImplemented,
      termsOfReference: const TermsOfReference(
        id: 'tor_2nd_arc',
        description: 'Suggest measures to achieve a proactive, responsive, transparent, and accountable administration at all levels.',
        focusAreas: ['Ethics in Governance', 'RTI', 'Local Governance', 'e-Governance', 'Public Order'],
      ),
      objectives: const [
        'Transform civil service into citizen-centric governance delivery mechanism',
        'Strengthen anti-corruption legal framework',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_arc_ethics',
          title: 'Ethics in Governance (4th Report)',
          description: 'Recommend Lokpal, Lokayuktas, and strict conflict of interest disclosure for public servants.',
          status: RecommendationStatus.acceptedPartially,
          relatedActIds: ['Lokpal and Lokayuktas Act, 2013'],
        ),
      ],
      implementationStatus: '15 reports submitted; key recommendations incorporated into Lokpal Act and Civil Services Code.',
      relatedMinistries: const ['Ministry of Personnel, Public Grievances and Pensions'],
      relatedActIds: const ['Right to Information Act, 2005', 'Lokpal and Lokayuktas Act, 2013'],
      evidenceIds: const ['ev_2nd_arc_reports'],
      keywords: const ['2nd ARC', 'Ethics in Governance', 'Civil Services Reforms', 'RTI', 'Citizen Charter'],
    ),

    // 4. National Commission on Farmers (Swaminathan Committee)
    CommitteeKnowledgeObject(
      id: 'comm_swaminathan_2004',
      officialName: 'National Commission on Farmers (Swaminathan Committee)',
      shortName: 'Swaminathan Committee',
      category: CommitteeCategory.agriculture,
      constitutingAuthority: 'Ministry of Agriculture, Government of India',
      chairperson: const CommitteeMember(
        name: 'Dr. M.S. Swaminathan',
        designation: 'Father of Green Revolution in India',
        role: 'Chairperson',
      ),
      yearConstituted: 2004,
      yearDissolved: 2006,
      currentStatus: CommitteeStatus.partiallyImplemented,
      termsOfReference: const TermsOfReference(
        id: 'tor_swaminathan',
        description: 'Propose medium-term strategy for food and nutrition security and agricultural sustainability.',
        focusAreas: ['MSP Formula', 'Soil Health', 'Water Security', 'Credit Access'],
      ),
      objectives: const [
        'Formulate farmer-centric agricultural growth framework',
        'Recommend MSP at C2 + 50% benchmark',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_swaminathan_msp',
          title: 'MSP at Comprehensive Cost C2 + 50%',
          description: 'Minimum Support Price should be set at minimum 50% above weighted average cost of production (C2).',
          status: RecommendationStatus.underConsideration,
          relatedSchemeNames: ['PM-KISAN'],
        ),
      ],
      implementationStatus: 'PM-KISAN launched; A2+FL+50% MSP adopted by Government.',
      relatedMinistries: const ['Ministry of Agriculture and Farmers Welfare'],
      relatedSchemeNames: const ['PM-KISAN', 'Soil Health Card Scheme'],
      evidenceIds: const ['ev_swaminathan_2006'],
      keywords: const ['Swaminathan Committee', 'MSP C2+50%', 'Farmer Prosperity', 'Agriculture Reform'],
    ),

    // 5. Kasturirangan Committee (National Education Policy 2020)
    CommitteeKnowledgeObject(
      id: 'comm_kasturirangan_nep_2017',
      officialName: 'Committee for Draft National Education Policy',
      shortName: 'Kasturirangan Committee',
      category: CommitteeCategory.education,
      constitutingAuthority: 'Ministry of Human Resource Development (now Ministry of Education)',
      chairperson: const CommitteeMember(
        name: 'Dr. K. Kasturirangan',
        designation: 'Former ISRO Chairman',
        role: 'Chairperson',
      ),
      yearConstituted: 2017,
      yearDissolved: 2019,
      currentStatus: CommitteeStatus.implemented,
      termsOfReference: const TermsOfReference(
        id: 'tor_nep',
        description: 'Draft comprehensive National Education Policy to overhaul Indian education system.',
        focusAreas: ['5+3+3+4 Curricular Structure', 'Higher Education Regulation', 'Gross Enrolment Ratio'],
      ),
      objectives: const [
        'Replace 10+2 system with 5+3+3+4 foundational to secondary stage learning',
        'Promote multilingualism and mother tongue medium instruction',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_nep_structure',
          title: 'Restructuring School Education to 5+3+3+4',
          description: 'Cover early childhood care education from age 3 to 18.',
          status: RecommendationStatus.implemented,
        ),
      ],
      implementationStatus: 'National Education Policy 2020 formally approved and being implemented across India.',
      relatedMinistries: const ['Ministry of Education'],
      relatedSchemeNames: const ['PM SHRI', 'SAMAGRA SHIKSHA'],
      evidenceIds: const ['ev_nep_2020_official'],
      keywords: const ['Kasturirangan Committee', 'NEP 2020', '5+3+3+4 Structure', 'Education Reforms'],
    ),

    // 6. 15th Finance Commission
    CommitteeKnowledgeObject(
      id: 'comm_fc_15th_2017',
      officialName: 'Fifteenth Finance Commission of India',
      shortName: '15th Finance Commission',
      category: CommitteeCategory.constitutional,
      constitutingAuthority: 'President of India under Article 280',
      chairperson: const CommitteeMember(
        name: 'N.K. Singh',
        designation: 'Former Senior Bureaucrat & MP',
        role: 'Chairperson',
      ),
      yearConstituted: 2017,
      yearDissolved: 2021,
      currentStatus: CommitteeStatus.implemented,
      termsOfReference: const TermsOfReference(
        id: 'tor_fc15',
        description: 'Recommend tax revenue devolution ratio between Centre and States for 2021-26 award period.',
        focusAreas: ['Vertical Devolution', 'Horizontal Devolution Formula', 'Demographic Performance', 'Local Grants'],
      ),
      objectives: const [
        'Determine vertical tax share of states (fixed at 41%)',
        'Introduce Demographic Performance criterion using 2011 Census',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_fc15_devolution',
          title: '41% Vertical Tax Devolution to States',
          description: 'Adjusted from 42% to 41% to accommodate newly created UTs of J&K and Ladakh.',
          status: RecommendationStatus.implemented,
          relatedArticleIds: ['Article 280', 'Article 270'],
        ),
      ],
      implementationStatus: 'Report accepted by Parliament; award period active 2021-2026.',
      relatedMinistries: const ['Ministry of Finance'],
      relatedArticleIds: const ['Article 280', 'Article 270', 'Article 275'],
      evidenceIds: const ['ev_15th_fc_official'],
      keywords: const ['15th Finance Commission', 'N.K. Singh', 'Article 280', 'Vertical Devolution 41%'],
    ),
    CommitteeKnowledgeObject(
      id: 'comm_fc_16th_2026',
      officialName: 'Sixteenth Finance Commission of India',
      shortName: '16th Finance Commission',
      category: CommitteeCategory.constitutional,
      constitutingAuthority: 'President of India under Article 280',
      chairperson: const CommitteeMember(
        name: 'Dr. Arvind Panagariya',
        designation: 'Former Vice-Chairman, NITI Aayog',
        role: 'Chairperson',
      ),
      yearConstituted: 2022,
      yearDissolved: 2026,
      currentStatus: CommitteeStatus.submitted,
      termsOfReference: const TermsOfReference(
        id: 'tor_fc16',
        description:
            'Recommend tax revenue devolution between Centre and States for the 2026-31 award period.',
        focusAreas: [
          'Vertical Devolution',
          'Horizontal Devolution Formula',
          'Fiscal Consolidation',
          'Local Government Grants',
        ],
      ),
      objectives: const [
        'Recommend the tax devolution share of States for 2026-31',
        'Suggest measures for fiscal consolidation and local-body financing',
      ],
      implementationStatus:
          'Constituted in November 2022; report submitted to the President for the 2026-31 award period.',
      relatedMinistries: const ['Ministry of Finance'],
      relatedArticleIds: const ['Article 280', 'Article 270', 'Article 275'],
      evidenceIds: const ['ev_16th_fc_official'],
      keywords: const [
        '16th Finance Commission',
        'Arvind Panagariya',
        'Article 280',
        'Devolution 2026-31'
      ],
    ),

    // 7. Balwant Rai Mehta Committee
    CommitteeKnowledgeObject(
      id: 'comm_balwant_rai_1957',
      officialName: 'Team for the Study of Community Projects and National Extension Service',
      shortName: 'Balwant Rai Mehta Committee',
      category: CommitteeCategory.executive,
      constitutingAuthority: 'Planning Commission of India',
      chairperson: const CommitteeMember(
        name: 'Balwantrai Mehta',
        designation: 'Former Chief Minister of Gujarat',
        role: 'Chairperson',
      ),
      yearConstituted: 1957,
      yearDissolved: 1957,
      currentStatus: CommitteeStatus.implemented,
      termsOfReference: const TermsOfReference(
        id: 'tor_balwant_rai',
        description: 'Examine working of Community Development Programme (1952) and suggest measures for democratic decentralization.',
        focusAreas: ['Panchayati Raj', '3-Tier System', 'Gram Panchayat', 'Block Samiti', 'Zila Parishad'],
      ),
      objectives: const [
        'Establish 3-tier Panchayati Raj system',
        'Transfer power and genuine responsibility to local elected bodies',
      ],
      recommendations: const [
        Recommendation(
          id: 'rec_3tier_panchayat',
          title: 'Establishment of 3-Tier Panchayati Raj System',
          description: 'Gram Panchayat at Village, Panchayat Samiti at Block, Zila Parishad at District level.',
          status: RecommendationStatus.implemented,
          relatedArticleIds: ['Article 40', 'Article 243'],
          relatedActIds: ['73rd Constitutional Amendment Act, 1992'],
        ),
      ],
      implementationStatus: 'Pioneered local self-governance; led to 73rd Constitutional Amendment Act.',
      relatedMinistries: const ['Ministry of Panchayati Raj'],
      relatedArticleIds: const ['Article 40', 'Article 243'],
      relatedActIds: const ['73rd Constitutional Amendment Act, 1992'],
      evidenceIds: const ['ev_balwantrai_1957'],
      keywords: const ['Balwant Rai Mehta', 'Panchayati Raj', '3 Tier System', '73rd Amendment', 'Article 40'],
    ),
  ];
}
