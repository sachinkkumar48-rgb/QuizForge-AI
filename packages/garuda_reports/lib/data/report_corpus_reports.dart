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
      relatedCommitteeIds: ['comm_15th_fc', 'comm_16th_fc'],
      relatedSchemeNames: [],
      relatedCaseLawIds: [],
      relatedDoctrineIds: [
        'Fiscal Consolidation',
        'Counter-cyclical Fiscal Policy'
      ],
      relatedCurrentAffairsIds: ['ca_budget_2025', 'ca_es_2025'],
      relatedPyqIds: ['PYQ_GS3_2023_Q03', 'PYQ_GS3_2022_Q11'],
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
      relatedCommitteeIds: ['comm_15th_fc', 'comm_pac'],
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
      relatedPyqIds: ['PYQ_GS3_2024_Q09', 'PYQ_POL_2023_Q04'],
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
      relatedPyqIds: ['PYQ_POL_2021_Q08'],
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
      relatedCommitteeIds: ['comm_15th_fc'],
      relatedDoctrineIds: ['Cooperative Federalism', 'Fiscal Federalism'],
      relatedCurrentAffairsIds: ['ca_finance_commission_16'],
      relatedPyqIds: ['PYQ_POL_2020_Q03', 'PYQ_GS3_2019_Q08'],
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
      relatedCommitteeIds: ['comm_16th_fc'],
      relatedDoctrineIds: ['Fiscal Federalism'],
      relatedCurrentAffairsIds: ['ca_finance_commission_16'],
      relatedPyqIds: ['PYQ_POL_2024_Q06'],
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
      relatedPyqIds: ['PYQ_POL_2022_Q05', 'PYQ_POL_2019_Q07'],
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
      relatedPyqIds: ['PYQ_GS3_2023_Q12', 'PYQ_GS3_2020_Q07'],
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
      relatedPyqIds: ['PYQ_GS3_2022_Q09', 'PYQ_GS3_2018_Q06'],
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
      relatedPyqIds: ['PYQ_GS3_2021_Q06'],
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
      relatedPyqIds: ['PYQ_GS1_2024_Q15', 'PYQ_GS3_2022_Q18'],
      evidenceIds: ['ev_isfr_2023_official'],
      keywords: [
        'ISFR',
        'Forest Survey of India',
        'Forest Cover',
        'Mangrove',
        'Environment'
      ],
    ),
  ];
}
