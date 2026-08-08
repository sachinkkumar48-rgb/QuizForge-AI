library;

import '../domain/entities/chapter_knowledge_object.dart';
import '../domain/entities/report_chart.dart';
import '../domain/entities/report_enums.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/report_statistic.dart';
import '../domain/entities/report_table.dart';
import '../domain/entities/recommendation_knowledge_object.dart';

/// Phase-I Seed Corpus - Indian official reports & government publications.
class ReportCorpusIndian {
  static final List<ReportKnowledgeObject> reports = [
    // 1. Economic Survey 2024-25
    ReportKnowledgeObject(
      id: 'rep_es_2024_25',
      officialTitle: 'Economic Survey 2024-25',
      shortName: 'Economic Survey',
      category: ReportCategory.economy,
      publishingOrganisation:
          'Economic Division, Department of Economic Affairs, Ministry of Finance',
      publishingMinistry: 'Ministry of Finance',
      publicationYear: 2025,
      edition: '2024-25',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.indiabudget.gov.in/economicsurvey/',
      executiveSummary:
          'The Economic Survey reviews the performance of the Indian economy over the preceding financial year and outlines the outlook. The 2024-25 edition projects real GDP growth of 6.3-6.8 per cent for FY2025-26 and underscores deregulation and trust-based governance as drivers of growth.',
      objectives: [
        'Review the state of the Indian economy and short-to-medium term prospects',
        'Present economic analysis to inform the Union Budget',
        'Highlight reforms needed for sustained high growth',
      ],
      methodology:
          'Compiled by the Economic Division of DEA from National Accounts Statistics (MoSPI), RBI data, DGCIS trade data and administrative sources; cross-verified with recent high-frequency indicators.',
      keyFindings: [
        'Real GDP growth projected at 6.3-6.8 per cent for FY2025-26',
        'Survey advocates economic deregulation to unlock private investment',
        'Flags global uncertainties, tariff tensions and their spillovers on the economy',
        'Headline CPI inflation averaged about 4.9 per cent during April-December 2024',
      ],
      keyIndicators: [
        'GDP Growth Rate',
        'CPI Inflation',
        'Fiscal Deficit',
        'Current Account Deficit'
      ],
      recommendations: [
        RecommendationKnowledgeObject(
          id: 'rec_es_2025_001',
          title: 'Economic deregulation to spur private investment',
          description:
              'Survey calls for a focused deregulation agenda to reduce compliance burden and attract private capital across manufacturing and services.',
          recommendingBody: 'Economic Survey 2024-25',
          recipientActor: 'Union Government',
          status: RecommendationStatus.underConsideration,
          reportId: 'rep_es_2024_25',
          keywords: ['Deregulation', 'Investment', 'Ease of Doing Business'],
        ),
        RecommendationKnowledgeObject(
          id: 'rec_es_2025_002',
          title: 'Nurturing emerging sectors for the future',
          description:
              'Survey identifies semiconductors, space, AI and green transition as sunrise sectors requiring targeted policy support.',
          recommendingBody: 'Economic Survey 2024-25',
          recipientActor: 'Union Government',
          status: RecommendationStatus.underConsideration,
          reportId: 'rep_es_2024_25',
          keywords: [
            'Semiconductors',
            'Artificial Intelligence',
            'Green Transition'
          ],
        ),
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_es_2025_gdp',
          label: 'Real GDP growth projection (FY2025-26)',
          value: '6.3-6.8',
          unit: 'per cent',
          referenceYear: 2025,
          source: 'Economic Survey 2024-25',
        ),
        ReportStatistic(
          id: 'st_es_2025_inflation',
          label: 'Headline CPI inflation (Apr-Dec 2024)',
          value: '4.9',
          unit: 'per cent',
          referenceYear: 2024,
          source: 'Economic Survey 2024-25',
        ),
      ],
      importantCharts: const [
        ReportChartMetadata(
          id: 'ch_es_2025_growth',
          title: 'Real GDP growth trajectory',
          chartType: ReportChartType.line,
          description: 'Trajectory of quarterly real GDP growth',
        ),
      ],
      chapters: [
        ChapterKnowledgeObject(
          id: 'chp_es_2025_state_of_economy',
          parentReportId: 'rep_es_2024_25',
          chapterNumber: 'Chapter 1',
          title: 'State of the Economy',
          summary:
              'Reviews macroeconomic performance, growth drivers, inflation and outlook for FY2025-26.',
          keyPoints: [
            'GDP growth 6.3-6.8 per cent projection',
            'Inflation moderation',
            'External stability'
          ],
          keyIndicators: ['GDP Growth Rate', 'CPI Inflation'],
          relatedArticleIds: ['Article 112'],
        ),
      ],
      upscRelevance:
          'Economic Survey is a favourite source for UPSC Prelims & GS Paper 3. Growth projections, inflation and deregulation themes appear regularly in questions on Indian Economy and Government Budgeting.',
      relatedIndexIds: ['idx_eodb_2020'],
      relatedArticleIds: ['Article 112', 'Article 265'],
      relatedActIds: ['FRBM Act, 2003'],
      relatedCommitteeIds: ['comm_fc_15th_2017', 'comm_fc_16th_2026'],
      relatedSchemeNames: [],
      relatedCaseLawIds: [],
      relatedDoctrineIds: [
        'Fiscal Consolidation',
        'Counter-cyclical Fiscal Policy'
      ],
      relatedCurrentAffairsIds: ['ca_budget_2025', 'ca_es_2025'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2023_GS3_Q003', 'PYQ_UPSC_CSE_2022_GS3_Q011'],
      relatedInternationalOrganisations: const ['int_imf', 'int_world_bank'],
      sdgGoals: const ['SDG 8 - Decent Work & Economic Growth'],
      evidenceIds: ['ev_es_2025_official'],
      keywords: [
        'Economic Survey',
        'GDP Growth',
        'Indian Economy',
        'Deregulation',
        'Budget'
      ],
    ),

    // 2. Union Budget 2025-26
    ReportKnowledgeObject(
      id: 'rep_ub_2025_26',
      officialTitle: 'Union Budget 2025-26',
      shortName: 'Union Budget',
      category: ReportCategory.budget,
      publishingOrganisation:
          'Budget Division, Department of Economic Affairs, Ministry of Finance',
      publishingMinistry: 'Ministry of Finance',
      publicationYear: 2025,
      edition: '2025-26',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.indiabudget.gov.in/',
      executiveSummary:
          'The Union Budget 2025-26 sets out the fiscal framework, taxation changes and expenditure priorities of the Government. It targets a fiscal deficit of 4.4 per cent of GDP, provides income-tax relief under the new regime and funds large infrastructure and social-sector programmes.',
      objectives: [
        'Present the Annual Financial Statement under Article 112 of the Constitution',
        'Set fiscal consolidation path and resource allocation across ministries',
        'Announce tax and expenditure policy measures',
      ],
      methodology:
          'Prepared by the Budget Division, DEA; consolidated from demands for grants of ministries and departments and audited by the Comptroller and Auditor General.',
      keyFindings: [
        'No income tax liability up to an annual income of Rs 12 lakh under the new regime',
        'Capital expenditure outlay of Rs 11.21 lakh crore',
        'Fiscal deficit pegged at 4.4 per cent of GDP for FY2025-26',
        'Announced PM Dhan-Dhaanya Krishi Yojana and National Manufacturing Mission',
      ],
      keyIndicators: [
        'Fiscal Deficit',
        'Capital Expenditure',
        'Tax Revenue',
        'Revenue Expenditure'
      ],
      recommendations: [
        RecommendationKnowledgeObject(
          id: 'rec_ub_2025_001',
          title: 'Doubling MSME investment and turnover thresholds',
          description:
              'Investment and turnover limits for MSME classification were enhanced to enable easier credit access and growth of small units.',
          recommendingBody: 'Union Budget 2025-26',
          recipientActor: 'Ministry of Micro, Small and Medium Enterprises',
          status: RecommendationStatus.implemented,
          reportId: 'rep_ub_2025_26',
          keywords: ['MSME', 'Credit', 'Manufacturing'],
        ),
        RecommendationKnowledgeObject(
          id: 'rec_ub_2025_002',
          title:
              'Fifty-year interest-free loans to States for capital expenditure',
          description:
              'States to receive Rs 1.5 lakh crore in 50-year interest-free loans for capex to boost infrastructure spending.',
          recommendingBody: 'Union Budget 2025-26',
          recipientActor: 'State Governments',
          status: RecommendationStatus.implemented,
          reportId: 'rep_ub_2025_26',
          keywords: ['State Capex', 'Infrastructure', 'Fiscal Federalism'],
        ),
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_ub_2025_fiscal',
          label: 'Fiscal deficit target',
          value: '4.4',
          unit: 'per cent of GDP',
          referenceYear: 2025,
          source: 'Union Budget 2025-26',
        ),
        ReportStatistic(
          id: 'st_ub_2025_capex',
          label: 'Capital expenditure outlay',
          value: '11.21',
          unit: 'lakh crore rupees',
          referenceYear: 2025,
          source: 'Union Budget 2025-26',
        ),
      ],
      importantTables: const [
        ReportTableMetadata(
          id: 'tb_ub_2025_budget',
          title: 'Budget at a Glance',
          tableNumber: '1.1',
          description:
              'Key fiscal aggregates: receipts, expenditure and deficit indicators',
          columns: ['Particulars', '2024-25 BE', '2025-26 BE'],
          rowCount: 12,
        ),
      ],
      chapters: [
        ChapterKnowledgeObject(
          id: 'chp_ub_2025_estimates',
          parentReportId: 'rep_ub_2025_26',
          chapterNumber: 'Part A',
          title: 'Budget Estimates and Fiscal Position',
          summary:
              'Sets out revenue and expenditure estimates and the fiscal consolidation path.',
          keyPoints: [
            'Fiscal deficit 4.4 per cent',
            'Capex 11.21 lakh crore',
            'Tax relief in new regime'
          ],
          keyIndicators: ['Fiscal Deficit', 'Capital Expenditure'],
          relatedArticleIds: ['Article 112', 'Article 114'],
        ),
      ],
      upscRelevance:
          'Union Budget is central to UPSC GS Paper 3 (Budgeting, fiscal policy) and Polity (Article 112-114). Tax slabs, capex, fiscal deficit and new schemes are routinely asked.',
      relatedIndexIds: ['idx_eodb_2020'],
      relatedArticleIds: [
        'Article 112',
        'Article 113',
        'Article 114',
        'Article 265',
        'Article 266'
      ],
      relatedActIds: [
        'FRBM Act, 2003',
        'Appropriation Act, 2025',
        'Finance Act, 2025'
      ],
      relatedCommitteeIds: ['comm_fc_15th_2017', 'comm_pac'],
      relatedSchemeNames: [
        'PM Dhan-Dhaanya Krishi Yojana',
        'National Manufacturing Mission',
        'PM Swayam Nidhi'
      ],
      relatedCaseLawIds: [],
      relatedDoctrineIds: [
        'Fiscal Consolidation',
        'Expansionary Fiscal Policy'
      ],
      relatedCurrentAffairsIds: ['ca_budget_2025', 'ca_income_tax_slabs_2025'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2024_GS3_Q009', 'PYQ_UPSC_CSE_2023_GS1_Q004'],
      sdgGoals: const ['SDG 8 - Decent Work & Economic Growth'],
      evidenceIds: ['ev_ub_2025_official'],
      keywords: [
        'Union Budget',
        'Fiscal Deficit',
        'Capex',
        'Income Tax',
        'Budgeting'
      ],
    ),

    // 3. India Year Book 2025
    ReportKnowledgeObject(
      id: 'rep_iyb_2025',
      officialTitle: 'India 2025 - A Reference Annual (India Year Book)',
      shortName: 'India Year Book',
      category: ReportCategory.governance,
      publishingOrganisation:
          'Publications Division, Ministry of Information and Broadcasting',
      publishingMinistry: 'Ministry of Information and Broadcasting',
      publicationYear: 2025,
      edition: '2025',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.publicationsdivision.nic.in/',
      executiveSummary:
          'India Year Book is the official annual reference book covering the structure and activities of all Union Ministries and Departments, States and UTs, public sector and flagship schemes.',
      objectives: [
        'Provide authoritative reference on Government of India organisations and programmes',
        'Cover state-wise administrative and developmental information',
      ],
      methodology:
          'Compiled by the Publications Division from inputs supplied by all Ministries and Departments of the Government of India.',
      keyFindings: [
        'Comprehensive directory of ministries, departments and statutory bodies',
        'Summaries of flagship schemes and programmes across sectors',
      ],
      keyIndicators: ['Ministries Covered', 'Flagship Schemes'],
      upscRelevance:
          'India Year Book is a key static source for UPSC Prelims covering constitutional bodies, ministries, schemes and institutions.',
      relatedArticleIds: ['Article 77'],
      relatedActIds: [],
      relatedCommitteeIds: [],
      relatedSchemeNames: [
        'Digital India',
        'Swachh Bharat Mission',
        'Make in India'
      ],
      relatedCurrentAffairsIds: [],
      relatedPyqIds: ['PYQ_UPSC_CSE_2021_GS1_Q008'],
      evidenceIds: ['ev_iyb_2025_official'],
      keywords: [
        'India Year Book',
        'Reference Annual',
        'Ministries',
        'Government of India'
      ],
    ),

    // 4. Fifteenth Finance Commission Report (2021-26)
    ReportKnowledgeObject(
      id: 'rep_fc15_2021_26',
      officialTitle:
          'Report of the Fifteenth Finance Commission for the period 2021-26',
      shortName: '15th Finance Commission',
      category: ReportCategory.fiscalFederalism,
      publishingOrganisation: 'Fifteenth Finance Commission',
      publishingMinistry: 'Ministry of Finance',
      publicationYear: 2021,
      edition: '2021-26',
      publicationFrequency: PublicationFrequency.quinquennial,
      officialUrl: 'https://fincomindia.nic.in/',
      executiveSummary:
          'The Fifteenth Finance Commission (Chairperson: N.K. Singh) recommended the vertical devolution of 41 per cent of the divisible pool of taxes to States for 2021-26, along with revenue deficit grants and grants to local bodies and disaster management.',
      objectives: [
        'Make recommendations on the distribution of net proceeds of taxes between Union and States',
        'Recommend principles governing grants-in-aid under Article 275',
        'Recommend measures to augment the Consolidated Fund of States',
      ],
      methodology:
          'Consultations with States, Union Territories and experts; analysis of fiscal data and projection models.',
      keyFindings: [
        'Vertical devolution fixed at 41 per cent of the divisible pool',
        'Revenue deficit grants recommended for 17 States',
        'Grants for local bodies and disaster management funds provided for 2021-26',
        'A performance-linked incentive framework for States',
      ],
      keyIndicators: [
        'Vertical Devolution Share',
        'Revenue Deficit Grants',
        'Local Body Grants'
      ],
      recommendations: [
        RecommendationKnowledgeObject(
          id: 'rec_fc15_001',
          title: 'Vertical devolution of 41 per cent to States',
          description:
              'Recommended 41 per cent of the divisible pool of taxes be devolved to States for 2021-26.',
          recommendingBody: 'Fifteenth Finance Commission',
          recipientActor: 'Union Government',
          status: RecommendationStatus.implemented,
          reportId: 'rep_fc15_2021_26',
          relatedArticleIds: ['Article 280', 'Article 281'],
          keywords: ['Devolution', 'Fiscal Federalism'],
        ),
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_fc15_devolution',
          label: 'Vertical devolution to States',
          value: '41',
          unit: 'per cent',
          referenceYear: 2021,
          source: '15th Finance Commission',
        ),
      ],
      upscRelevance:
          'Finance Commission is a key UPSC topic (GS2 Polity & Governance, GS3 Economy). Vertical devolution percentages and grant architecture are frequently tested.',
      relatedArticleIds: [
        'Article 280',
        'Article 281',
        'Article 275',
        'Article 268',
        'Article 269'
      ],
      relatedActIds: [
        'Finance Commission (Miscellaneous Provisions) Act, 1951'
      ],
      relatedCommitteeIds: ['comm_fc_15th_2017'],
      relatedDoctrineIds: ['Cooperative Federalism', 'Fiscal Federalism'],
      relatedCurrentAffairsIds: ['ca_finance_commission_16'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2020_GS1_Q003', 'PYQ_UPSC_CSE_2019_GS3_Q008'],
      relatedBodies: const ['bod_finance_commission'],
      evidenceIds: ['ev_fc15_official'],
      keywords: [
        'Finance Commission',
        'Article 280',
        'Devolution',
        'Fiscal Federalism'
      ],
    ),

    // 5. Sixteenth Finance Commission
    ReportKnowledgeObject(
      id: 'rep_fc16_2026',
      officialTitle: 'Report of the Sixteenth Finance Commission (2026-31)',
      shortName: '16th Finance Commission',
      category: ReportCategory.fiscalFederalism,
      publishingOrganisation: 'Sixteenth Finance Commission',
      publishingMinistry: 'Ministry of Finance',
      publicationYear: 2026,
      edition: '2026-31',
      publicationFrequency: PublicationFrequency.quinquennial,
      officialUrl: 'https://fincomindia.nic.in/',
      executiveSummary:
          'The Sixteenth Finance Commission, chaired by Dr. Arvind Panagariya, was constituted in December 2023 to make recommendations for the award period 2026-31. Its report was submitted to the President within the mandated timeframe and its recommendations govern transfers from FY2026-27.',
      objectives: [
        'Recommend distribution of the divisible pool of taxes for 2026-31',
        'Recommend grants-in-aid and sector-specific grants',
        'Address fiscal space of States and local bodies',
      ],
      methodology:
          'Constitutional mandate under Article 280; extensive State consultations and fiscal modelling.',
      keyFindings: [
        'Constituted under Article 280 with the widest Terms of Reference since the 15th FC',
        'Report submitted for the award period 2026-31',
      ],
      keyIndicators: ['Vertical Devolution Share', 'Award Period'],
      upscRelevance:
          '16th Finance Commission recommendations are a live current-affairs topic for UPSC GS2/GS3 (fiscal federalism, state finances).',
      relatedArticleIds: ['Article 280', 'Article 281', 'Article 275'],
      relatedActIds: [
        'Finance Commission (Miscellaneous Provisions) Act, 1951'
      ],
      relatedCommitteeIds: ['comm_fc_16th_2026'],
      relatedDoctrineIds: ['Fiscal Federalism'],
      relatedCurrentAffairsIds: ['ca_finance_commission_16'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2024_GS1_Q006'],
      relatedBodies: const ['bod_finance_commission'],
      evidenceIds: ['ev_fc16_official'],
      keywords: [
        '16th Finance Commission',
        'Article 280',
        'Arvind Panagariya',
        'Fiscal Federalism'
      ],
    ),

    // 6. CAG Reports
    ReportKnowledgeObject(
      id: 'rep_cag_2024',
      officialTitle:
          'Reports of the Comptroller and Auditor General of India (Union & State Audit)',
      shortName: 'CAG Reports',
      category: ReportCategory.governance,
      publishingOrganisation: 'Comptroller and Auditor General of India',
      publishingMinistry: 'Independent Constitutional Authority',
      publicationYear: 2024,
      edition: '2023-24 Audit Cycle',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://cag.gov.in/',
      executiveSummary:
          'Audit Reports of the CAG examine the accounts of the Union and State Governments and public-sector undertakings, and are laid before Parliament and State Legislatures under Article 151. They are scrutinised by the Public Accounts Committee.',
      objectives: [
        'Audit the accounts of the Union, States and UTs',
        'Assess regularity and propriety of expenditure and compliance with law',
        'Report on performance of programmes and financial management',
      ],
      methodology:
          'Compliance, financial and performance audits conducted under the Comptroller and Auditor-General (DPC) Act, 1971 and the DPC Regulations.',
      keyFindings: [
        'Audit reports tabled in Parliament and State Legislatures each year',
        'Findings examined by the Public Accounts Committee and Committee on Public Undertakings',
      ],
      keyIndicators: ['Number of Audit Reports', 'Public Accounts Committee'],
      upscRelevance:
          'CAG is a vital UPSC topic (GS2 Polity): constitutional office, audit mandate, Article 148-151 and accountability role.',
      relatedArticleIds: [
        'Article 148',
        'Article 149',
        'Article 150',
        'Article 151'
      ],
      relatedActIds: [
        'Comptroller and Auditor-General (DPC) Act, 1971',
        'CAG Act, 1971'
      ],
      relatedCommitteeIds: ['comm_pac', 'comm_copu'],
      relatedDoctrineIds: ['Accountability', 'Public Finance Accountability'],
      relatedCurrentAffairsIds: ['ca_cag_reports_2024'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2022_GS1_Q005', 'PYQ_UPSC_CSE_2019_GS1_Q007'],
      relatedBodies: const ['bod_cag'],
      evidenceIds: ['ev_cag_official'],
      keywords: [
        'CAG',
        'Audit',
        'Article 148',
        'Public Accounts Committee',
        'Accountability'
      ],
    ),

    // 7. RBI Annual Report 2023-24
    ReportKnowledgeObject(
      id: 'rep_rbi_ar_2023_24',
      officialTitle: 'Reserve Bank of India Annual Report 2023-24',
      shortName: 'RBI Annual Report',
      category: ReportCategory.finance,
      publishingOrganisation: 'Reserve Bank of India',
      publishingMinistry:
          'Ministry of Finance (RBI is an autonomous central bank)',
      publicationYear: 2024,
      edition: '2023-24',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.rbi.org.in/',
      executiveSummary:
          'The RBI Annual Report reviews the operations of the central bank and the state of the economy for 2023-24, covering monetary policy, financial regulation, currency management and the transfer of surplus to the Government.',
      objectives: [
        'Report on RBI operations and balance sheet for the year',
        'Assess macroeconomic and financial-sector developments',
        'Document monetary policy stance and regulatory actions',
      ],
      methodology:
          'Compiled by RBI from monetary, banking, trade and external-sector data reported by regulated entities.',
      keyFindings: [
        'Real GDP growth for FY2023-24 estimated at 8.2 per cent',
        'Headline CPI inflation averaged 5.4 per cent in FY2023-24',
        'Record surplus of Rs 2.11 lakh crore transferred to the Government of India',
        'Scheduled commercial banks gross NPA ratio declined to about 2.8 per cent',
      ],
      keyIndicators: [
        'Real GDP Growth',
        'CPI Inflation',
        'Gross NPA Ratio',
        'Foreign Exchange Reserves'
      ],
      recommendations: [
        RecommendationKnowledgeObject(
          id: 'rec_rbi_ar_001',
          title: 'Continued vigil on inflation',
          description:
              'RBI underscored maintaining price stability while supporting growth, with continued monitoring of food inflation.',
          recommendingBody: 'Reserve Bank of India',
          recipientActor: 'Monetary Policy Committee',
          status: RecommendationStatus.implemented,
          reportId: 'rep_rbi_ar_2023_24',
          keywords: ['Inflation', 'Monetary Policy'],
        ),
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_rbi_gdp',
          label: 'Real GDP growth FY2023-24',
          value: '8.2',
          unit: 'per cent',
          referenceYear: 2024,
          source: 'RBI Annual Report',
        ),
        ReportStatistic(
          id: 'st_rbi_surplus',
          label: 'Surplus transferred to Government',
          value: '2.11',
          unit: 'lakh crore rupees',
          referenceYear: 2024,
          source: 'RBI Annual Report',
        ),
        ReportStatistic(
          id: 'st_rbi_npa',
          label: 'Gross NPA ratio of SCBs',
          value: '2.8',
          unit: 'per cent',
          referenceYear: 2024,
          source: 'RBI Annual Report',
        ),
      ],
      importantCharts: const [
        ReportChartMetadata(
          id: 'ch_rbi_npa',
          title: 'Declining NPA trajectory of banks',
          chartType: ReportChartType.line,
          description:
              'Improvement in asset quality of scheduled commercial banks',
        ),
      ],
      upscRelevance:
          'RBI is a core UPSC GS3 topic: monetary policy, banking regulation, MPC, and RBI-Government relations. Annual Report data is frequently cited.',
      relatedIndexIds: [],
      relatedArticleIds: [],
      relatedActIds: ['Reserve Bank of India Act, 1934'],
      relatedCommitteeIds: ['comm_mpc'],
      relatedDoctrineIds: [
        'Monetary Policy Transmission',
        'Autonomy of the Central Bank'
      ],
      relatedCurrentAffairsIds: ['ca_rbi_surplus_transfer'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2023_GS3_Q012', 'PYQ_UPSC_CSE_2020_GS3_Q007'],
      relatedBodies: const ['bod_rbi'],
      evidenceIds: ['ev_rbi_ar_official'],
      keywords: ['RBI', 'Monetary Policy', 'Inflation', 'GDP', 'Banking'],
    ),

    // 8. SEBI Annual Report 2023-24
    ReportKnowledgeObject(
      id: 'rep_sebi_ar_2023_24',
      officialTitle:
          'Securities and Exchange Board of India Annual Report 2023-24',
      shortName: 'SEBI Annual Report',
      category: ReportCategory.finance,
      publishingOrganisation: 'Securities and Exchange Board of India',
      publishingMinistry: 'Ministry of Finance',
      publicationYear: 2024,
      edition: '2023-24',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.sebi.gov.in/',
      executiveSummary:
          'The SEBI Annual Report documents the regulator\'s activities covering primary and secondary markets, investor protection, market surveillance and developmental measures for the securities market.',
      objectives: [
        'Protect the interests of investors in securities',
        'Promote the development and regulate the securities market',
      ],
      methodology:
          'Compiled from SEBI registration records, exchange data and regulatory actions during the year.',
      keyFindings: [
        'Regulatory and developmental interventions across primary, secondary and derivatives markets',
        'Growth in retail investor participation and digital onboarding (KYC) frameworks',
      ],
      keyIndicators: [
        'Registered Intermediaries',
        'FPI Registrations',
        'Investor Complaints'
      ],
      upscRelevance:
          'SEBI is tested in UPSC GS3 (capital markets, investor protection). Its statutory basis under the SEBI Act 1992 and regulatory role are key points.',
      relatedActIds: [
        'SEBI Act, 1992',
        'Depositories Act, 1996',
        'Securities Contracts (Regulation) Act, 1956'
      ],
      relatedCommitteeIds: ['comm_sat'],
      relatedDoctrineIds: ['Investor Protection'],
      relatedCurrentAffairsIds: ['ca_sebi_2024'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2022_GS3_Q009', 'PYQ_UPSC_CSE_2018_GS3_Q006'],
      relatedBodies: const ['bod_sebi'],
      evidenceIds: ['ev_sebi_ar_official'],
      keywords: [
        'SEBI',
        'Securities Market',
        'Investor Protection',
        'Regulator'
      ],
    ),

    // 9. NCRB Crime in India 2022
    ReportKnowledgeObject(
      id: 'rep_ncrb_cii_2022',
      officialTitle: 'Crime in India 2022 - National Crime Records Bureau',
      shortName: 'Crime in India',
      category: ReportCategory.security,
      publishingOrganisation: 'National Crime Records Bureau',
      publishingMinistry: 'Ministry of Home Affairs',
      publicationYear: 2023,
      edition: 'Volume I & II, 2022',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://ncrb.gov.in/',
      executiveSummary:
          'Crime in India is the annual statistical compendium of crimes registered and disposed of across the country, providing state-wise and crime-head-wise data for the year 2022.',
      objectives: [
        'Provide comprehensive statistics on crimes registered in India',
        'Support evidence-based policing and policy making',
      ],
      methodology:
          'Compiled from returns furnished by State/UT police through the Crime and Criminal Tracking Network and Systems (CCTNS).',
      keyFindings: [
        'A total of 58.24 lakh cognizable crimes registered in 2022, an increase of 0.5 per cent over 2021',
        'Detailed crime-head-wise and state-wise data published in two volumes',
      ],
      keyIndicators: [
        'Cognizable Crimes Registered',
        'Crime Rate',
        'IPC Crimes',
        'SLL Crimes'
      ],
      upscRelevance:
          'NCRB reports are relevant to UPSC GS3 (internal security) and for understanding the crime data ecosystem and police reforms.',
      relatedArticleIds: [],
      relatedActIds: [
        'Bharatiya Nyaya Sanhita, 2023',
        'Bharatiya Nagarik Suraksha Sanhita, 2023',
        'Indian Penal Code, 1860'
      ],
      relatedCommitteeIds: ['comm_police_reforms'],
      relatedSchemeNames: ['CCTNS'],
      relatedDoctrineIds: [],
      relatedCurrentAffairsIds: ['ca_ncrb_cii_2022'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2021_GS3_Q006'],
      relatedBodies: const ['bod_cbi'],
      evidenceIds: ['ev_ncrb_cii_official'],
      keywords: ['NCRB', 'Crime in India', 'Internal Security', 'CCTNS'],
    ),

    // 10. India State of Forest Report 2023
    ReportKnowledgeObject(
      id: 'rep_isfr_2023',
      officialTitle: 'India State of Forest Report 2023',
      shortName: 'ISFR 2023',
      category: ReportCategory.forest,
      publishingOrganisation: 'Forest Survey of India',
      publishingMinistry: 'Ministry of Environment, Forest and Climate Change',
      publicationYear: 2023,
      edition: 'ISFR 2023 (18th edition)',
      publicationFrequency: PublicationFrequency.biennial,
      officialUrl: 'https://fsi.nic.in/',
      executiveSummary:
          'The India State of Forest Report 2023 assesses the forest and tree cover of India. Total forest and tree cover is 8,27,357 sq km, 25.17 per cent of the geographical area, with an increase over the 2021 assessment.',
      objectives: [
        'Assess forest and tree cover of India biennially',
        'Provide information on forest carbon stock, mangrove cover and forest fire monitoring',
      ],
      methodology:
          'Remote-sensing based forest cover mapping using indigenous methodology, supplemented by field inventory and satellite data.',
      keyFindings: [
        'Total forest and tree cover: 8,27,357 sq km (25.17 per cent of geographical area)',
        'Forest cover: 7,15,343 sq km (21.76 per cent); Tree cover: 1,12,014 sq km (3.41 per cent)',
        'Increase of 156 sq km in forest cover and 1,289 sq km in tree cover over 2021',
        'Mangrove cover stands at 4,992 sq km',
      ],
      keyIndicators: [
        'Forest Cover',
        'Tree Cover',
        'Mangrove Cover',
        'Carbon Stock'
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_isfr_forest',
          label: 'Total forest and tree cover',
          value: '8,27,357',
          unit: 'sq km',
          referenceYear: 2023,
          source: 'ISFR 2023',
        ),
        ReportStatistic(
          id: 'st_isfr_pct',
          label: 'Forest and tree cover share of geographical area',
          value: '25.17',
          unit: 'per cent',
          referenceYear: 2023,
          source: 'ISFR 2023',
        ),
      ],
      upscRelevance:
          'ISFR figures are routinely asked in UPSC Prelims (Environment). Forest cover percentages, mangrove cover and carbon stock are high-yield static+dynamic data.',
      relatedArticleIds: ['Article 48A', 'Article 51A'],
      relatedActIds: [
        'Forest (Conservation) Act, 1980',
        'Indian Forest Act, 1927'
      ],
      relatedCommitteeIds: ['comm_national_forest'],
      relatedSchemeNames: ['National Mission for a Green India'],
      relatedDoctrineIds: ['Sustainable Development', 'Public Trust Doctrine'],
      relatedCurrentAffairsIds: ['ca_isfr_2023'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2024_GS1_Q015', 'PYQ_UPSC_CSE_2022_GS3_Q018'],
      sdgGoals: const ['SDG 13 - Climate Action', 'SDG 15 - Life on Land'],
      evidenceIds: ['ev_isfr_2023_official'],
      keywords: [
        'ISFR',
        'Forest Survey of India',
        'Forest Cover',
        'Mangrove',
        'Environment'
      ],
    ),
    ReportKnowledgeObject(
      id: 'rep_adsi_2022',
      officialTitle: 'Accidental Deaths & Suicides in India 2022',
      shortName: 'ADSI 2022',
      category: ReportCategory.security,
      publishingOrganisation: 'National Crime Records Bureau',
      publishingMinistry: 'Ministry of Home Affairs',
      publicationYear: 2023,
      edition: 'ADSI 2022',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.statisticalPublication,
      reportingPeriod: '2022',
      geographicalScope: 'India',
      indiaCoverage: true,
      publicationDate: '2023-12-01',
      officialUrl: 'https://ncrb.gov.in/',
      executiveSummary:
          'Accidental Deaths & Suicides in India 2022 compiles cause-wise statistics on accidental deaths and suicides in India, including age, gender and profession profiles of victims.',
      policySignificance:
          'Primary official source on suicides and accidents; informs mental-health, safety and social-welfare policy.',
      objectives: const [
        'Present annual statistics on accidental deaths and suicides in India',
        'Provide cause-wise, State-wise and demographic disaggregation',
      ],
      methodology:
          'Compiled by the National Crime Records Bureau from police-reported FIRs and inquest reports across States/UTs.',
      keyFindings: const [
        'About 1.70 lakh suicides reported in 2022 (increase over 2021)',
        'Causes of death: accidental falls, road accidents, drowning and burns among top causes',
        'Daily-wage earners and self-employed constitute a large share of suicide victims',
      ],
      keyIndicators: const ['Suicides', 'Accidental Deaths', 'Cause-wise Distribution'],
      upscRelevance:
          'Suicide statistics, mental health, social issues, agrarian distress indicators (GS-I, GS-III)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Social Issues', 'Mental Health', 'Public Safety'],
      sectors: const ['Security', 'Social Welfare', 'Health'],
      relatedArticleIds: const ['Article 21'],
      relatedActIds: const [],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const [],
      relatedBodies: const ['bod_cbi'],
      relatedInternationalOrganisations: const [],
      relationships: const [],
      sdgGoals: const ['SDG 3 - Good Health & Well-being', 'SDG 16 - Peace, Justice & Strong Institutions'],
      evidenceIds: const ['ev_adsi_2022_official'],
      keywords: const ['ADSI', 'Suicides', 'Accidental Deaths', 'NCRB', 'Mental Health'],
    ),
    ReportKnowledgeObject(
      id: 'rep_census_2011',
      officialTitle: 'Census of India 2011',
      shortName: 'Census 2011',
      category: ReportCategory.demography,
      publishingOrganisation: 'Office of the Registrar General & Census Commissioner, India',
      publishingMinistry: 'Ministry of Home Affairs',
      publicationYear: 2011,
      edition: 'Census of India 2011',
      publicationFrequency: PublicationFrequency.quinquennial,
      reportType: ReportType.census,
      reportingPeriod: '2011',
      geographicalScope: 'India',
      indiaCoverage: true,
      publicationDate: '2011-03-15',
      officialUrl: 'https://censusindia.gov.in/',
      executiveSummary:
          'The Census of India 2011 enumerated a population of 1,210.85 million with a decadal growth of 17.7 per cent, literacy of 74.04 per cent and a sex ratio of 943 females per 1,000 males.',
      policySignificance:
          'Foundational demographic dataset underpinning delimitation, reservation and welfare-programme design.',
      objectives: const [
        'Conduct the 15th Indian Census enumeration',
        'Provide reliable demographic, social and economic data on every household',
      ],
      methodology:
          'Household enumeration through a de facto canvasser method conducted in two phases (house-listing and population enumeration).',
      keyFindings: const [
        'Total population: 1,210.85 million (CAGR 1.64 per cent since 2001)',
        'Literacy rate: 74.04 per cent (male 82.14, female 65.46)',
        'Sex ratio: 943 females per 1,000 males (up from 933 in 2001)',
        'Child sex ratio (0-6): 919, a decline from 927 in 2001',
      ],
      keyIndicators: const ['Population', 'Literacy Rate', 'Sex Ratio', 'Decadal Growth'],
      upscRelevance:
          'Census, demography, population policy, child sex ratio, literacy (GS-I, GS-II)',
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Demography', 'Population', 'Social Indicators'],
      sectors: const ['Statistics', 'Social Welfare'],
      relatedArticleIds: const ['Article 21A', 'Article 15(3)'],
      relatedActIds: const ['Census Act, 1948'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2019_GS1_Q012', 'PYQ_UPSC_CSE_2018_GS1_Q010'],
      relatedBodies: const [],
      relatedInternationalOrganisations: const [],
      relationships: const [],
      sdgGoals: const ['SDG 1 - No Poverty', 'SDG 10 - Reduced Inequalities'],
      evidenceIds: const ['ev_census_2011_official'],
      keywords: const ['Census 2011', 'Population', 'Literacy', 'Sex Ratio', 'Demography'],
    ),
    ReportKnowledgeObject(
      id: 'rep_soia_2024',
      officialTitle: 'State of Indian Agriculture 2024',
      shortName: 'State of Indian Agriculture',
      category: ReportCategory.agriculture,
      publishingOrganisation:
          'Directorate of Economics & Statistics, Ministry of Agriculture & Farmers Welfare',
      publishingMinistry: 'Ministry of Agriculture & Farmers Welfare',
      publicationYear: 2024,
      edition: '2024 Edition',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.statisticalPublication,
      reportingPeriod: '2023-24',
      geographicalScope: 'India',
      indiaCoverage: true,
      publicationDate: '2024-06-30',
      officialUrl: 'https://desagri.gov.in/',
      executiveSummary:
          'The State of Indian Agriculture compiles the status of the agricultural economy, including production of foodgrains, horticulture, livestock, fertiliser consumption, credit flow and farmer income, drawing on official Departmental and NSSO data.',
      policySignificance:
          'Flagship reference for agricultural policy, MSP economics, agrarian distress and the contribution of agriculture to national income (GS-III).',
      objectives: const [
        'Present an annual statistical review of the Indian agricultural economy',
        'Track production, input use, credit, trade and allied-sector performance',
      ],
      methodology:
          'Compiled by the Directorate of Economics & Statistics from Agricultural Statistics at a Glance, NSSO situation-assessment data, Departmental administrative returns and trade statistics.',
      keyFindings: const [
        'Agriculture and allied sectors contributed about 18 per cent of Gross Value Added in FY2023-24',
        'Around 45 per cent of India\'s workforce depends on agriculture for livelihood',
        'Kharif foodgrain production reached a record about 3,287 lakh tonnes in 2023-24',
        'Minimum Support Prices continue to be announced for 22 mandated crops',
      ],
      keyIndicators: const ['Foodgrain Production', 'GVA from Agriculture', 'Gross Capital Formation', 'Credit Flow to Agriculture'],
      upscRelevance:
          'Agriculture, food security, MSP, agrarian distress, allied sectors and farm incomes (GS-III)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Agriculture', 'Food Security', 'Rural Economy', 'Farm Incomes'],
      sectors: const ['Agriculture', 'Rural Development', 'Food Processing'],
      relatedArticleIds: const ['Article 39'],
      relatedActIds: const ['Essential Commodities Act, 1955'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const ['PM-KISAN', 'PMFBY', 'Kisan Credit Card'],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const ['ca_finance_commission_16'],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2020_GS3_Q004'],
      relatedBodies: const [],
      relatedInternationalOrganisations: const ['int_fao'],
      relationships: const [],
      sdgGoals: const ['SDG 2 - Zero Hunger'],
      evidenceIds: const ['ev_soia_2024_official'],
      keywords: const ['Agriculture', 'Foodgrain Production', 'MSP', 'Farm Income', 'Agri GVA'],
    ),
    ReportKnowledgeObject(
      id: 'rep_udise_2023_24',
      officialTitle: 'Unified District Information System for Education Plus (UDISE+) 2023-24',
      shortName: 'UDISE+ Report',
      category: ReportCategory.education,
      publishingOrganisation:
          'Department of School Education & Literacy, Ministry of Education',
      publishingMinistry: 'Ministry of Education',
      publicationYear: 2024,
      edition: '2023-24',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.statisticalPublication,
      reportingPeriod: '2023-24',
      geographicalScope: 'India',
      indiaCoverage: true,
      publicationDate: '2024-10-31',
      officialUrl: 'https://udiseplus.gov.in/',
      executiveSummary:
          'UDISE+ 2023-24 is the official statistical publication on school education in India, covering enrolment, schools, teachers, infrastructure, Gross Enrolment Ratios and performance indicators for more than 14.7 lakh schools.',
      policySignificance:
          'Primary official source for school-education indicators, GER, drop-out and the Right to Education implementation (GS-II).',
      objectives: const [
        'Provide reliable annual statistics on school education in India',
        'Inform NEP 2020 implementation monitoring and Samagra Shiksha Abhiyan',
      ],
      methodology:
          'Computerised data collected from every recognised school in India through the UDISE+ portal and validated by State/UT education departments.',
      keyFindings: const [
        'More than 14.7 lakh schools and about 24.8 crore students covered in 2023-24',
        'Gross Enrolment Ratio at the secondary level shows continued improvement',
        'Pupil-teacher ratio and basic infrastructure (toilets, electricity) show steady gains',
      ],
      keyIndicators: const ['Total Schools', 'Total Enrolment', 'GER', 'Pupil-Teacher Ratio'],
      upscRelevance:
          'School education, GER, RTE Act 2009, NEP 2020 and social-sector outcomes (GS-II)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Education', 'School Education', 'NEP 2020', 'Social Sector'],
      sectors: const ['Education', 'Skill Development'],
      relatedArticleIds: const ['Article 21A', 'Article 45'],
      relatedActIds: const ['Right of Children to Free and Compulsory Education Act, 2009'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const ['Samagra Shiksha Abhiyan', 'PM POSHAN'],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2021_GS2_Q002'],
      relatedBodies: const [],
      relatedInternationalOrganisations: const ['int_unesco'],
      relationships: const [],
      sdgGoals: const ['SDG 4 - Quality Education'],
      evidenceIds: const ['ev_udise_2023_24_official'],
      keywords: const ['UDISE+', 'School Education', 'GER', 'Enrolment', 'NEP 2020'],
    ),
    ReportKnowledgeObject(
      id: 'rep_nha_2020_21',
      officialTitle: 'National Health Accounts Estimates for India 2020-21',
      shortName: 'National Health Accounts',
      category: ReportCategory.health,
      publishingOrganisation:
          'National Health Accounts Technical Secretariat, National Health Systems Resource Centre',
      publishingMinistry: 'Ministry of Health and Family Welfare',
      publicationYear: 2023,
      edition: '2020-21',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.statisticalPublication,
      reportingPeriod: '2020-21',
      geographicalScope: 'India',
      indiaCoverage: true,
      publicationDate: '2023-10-01',
      officialUrl: 'https://nhsrcindia.org/',
      executiveSummary:
          'The National Health Accounts (NHA) Estimates present the composition of health expenditure in India, tracking Total Health Expenditure, Government Health Expenditure and Out-of-Pocket Expenditure against GDP for the reference year.',
      policySignificance:
          'Authoritative source on health financing, OOP expenditure and the Government\'s progress towards universal health coverage (GS-II).',
      objectives: const [
        'Measure total health expenditure in India against GDP',
        'Track government, private and out-of-pocket financing flows in health',
      ],
      methodology:
          'Prepared under the NHA framework of the Ministry of Health & Family Welfare using a System of Health Accounts-based (SHA 2011) approach drawing on National Accounts and administrative data.',
      keyFindings: const [
        'Total Health Expenditure stood at about 3.8 per cent of GDP in 2020-21',
        'Out-of-Pocket Expenditure declined to about 37 per cent of Total Health Expenditure',
        'Government Health Expenditure rose to about 48 per cent of Total Health Expenditure',
      ],
      keyIndicators: const ['Total Health Expenditure (% of GDP)', 'Out-of-Pocket Expenditure', 'Government Health Expenditure'],
      upscRelevance:
          'Health financing, universal health coverage, OOP burden and Ayushman Bharat context (GS-II, GS-III)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Health', 'Health Financing', 'Universal Health Coverage'],
      sectors: const ['Health', 'Social Welfare'],
      relatedArticleIds: const ['Article 21'],
      relatedActIds: const ['Clinical Establishments (Registration and Regulation) Act, 2010'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const ['Ayushman Bharat', 'National Health Mission'],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2019_GS2_Q003'],
      relatedBodies: const ['bod_nmc'],
      relatedInternationalOrganisations: const ['int_who'],
      relationships: const [],
      sdgGoals: const ['SDG 3 - Good Health & Well-being'],
      evidenceIds: const ['ev_nha_2020_21_official'],
      keywords: const ['National Health Accounts', 'Health Expenditure', 'OOP', 'Health Financing', 'GDP'],
    ),
    ReportKnowledgeObject(
      id: 'rep_cea_2023_24',
      officialTitle: 'Central Electricity Authority Annual Report 2023-24',
      shortName: 'CEA Annual Report',
      category: ReportCategory.energy,
      publishingOrganisation: 'Central Electricity Authority',
      publishingMinistry: 'Ministry of Power',
      publicationYear: 2024,
      edition: '2023-24',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.annualReport,
      reportingPeriod: '2023-24',
      geographicalScope: 'India',
      indiaCoverage: true,
      publicationDate: '2024-09-30',
      officialUrl: 'https://cea.nic.in/annual-report/',
      executiveSummary:
          'The CEA Annual Report reviews the performance of the Indian power sector, covering installed generation capacity, generation, transmission, renewable energy growth and peak demand management in the financial year.',
      policySignificance:
          'Authoritative official source on the energy sector for infrastructure and energy-transition questions (GS-III).',
      objectives: const [
        'Present annual statistics on installed capacity, generation and transmission',
        'Track progress on renewable energy and grid reliability',
      ],
      methodology:
          'Compiled by the Central Electricity Authority from returns filed by generators, transmission utilities and State/UT power departments.',
      keyFindings: const [
        'India\'s total installed power generation capacity crossed about 440 GW during FY2023-24',
        'Renewable energy capacity (excluding large hydro) continued its rapid expansion',
        'Peak power demand crossed about 240 GW in FY2023-24',
      ],
      keyIndicators: const ['Installed Capacity', 'Peak Demand', 'Renewable Capacity', 'Generation Growth'],
      upscRelevance:
          'Energy security, renewable energy, power sector reforms and infrastructure (GS-III)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Energy', 'Power Sector', 'Renewable Energy', 'Infrastructure'],
      sectors: const ['Energy', 'Infrastructure'],
      relatedArticleIds: const ['Article 246'],
      relatedActIds: const ['Electricity Act, 2003'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const ['PM-KUSUM', 'Saubhagya'],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const ['ca_cop28'],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2022_GS3_Q003'],
      relatedBodies: const ['bod_cerc'],
      relatedInternationalOrganisations: const ['int_iea', 'int_irena'],
      relationships: const [],
      sdgGoals: const ['SDG 7 - Affordable and Clean Energy', 'SDG 13 - Climate Action'],
      evidenceIds: const ['ev_cea_2023_24_official'],
      keywords: const ['CEA', 'Power Sector', 'Installed Capacity', 'Renewable Energy', 'Peak Demand'],
    ),
  ];
}
