library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/report_enums.dart';

/// Phase-I Seed Corpus - National and global indices & rankings.
class ReportCorpusIndices {
  static final List<IndexKnowledgeObject> indices = [
    // 1. SDG India Index 2023-24
    IndexKnowledgeObject(
      id: 'idx_sdg_2023_24',
      indexName: 'SDG India Index 2023-24',
      publisher: 'NITI Aayog',
      publishingMinistry: 'NITI Aayog',
      methodology:
          'Composite index scoring States and UTs on 113 indicators mapped to the 17 Sustainable Development Goals; higher score indicates better performance.',
      indicators: [
        'Goal 1 No Poverty',
        'Goal 2 Zero Hunger',
        'Goal 3 Good Health',
        'Goal 4 Quality Education',
        'Goal 5 Gender Equality',
        'Goal 6 Clean Water',
        'Goal 7 Affordable Energy',
        'Goal 8 Decent Work',
        'Goal 9 Industry & Innovation',
        'Goal 10 Reduced Inequalities',
        'Goal 11 Sustainable Cities',
        'Goal 12 Responsible Consumption',
        'Goal 13 Climate Action',
        'Goal 15 Life on Land',
        'Goal 16 Peace & Justice',
        'Goal 17 Partnerships',
      ],
      weightage: 'Equal weightage across the 17 SDGs',
      latestRanking: 'Kerala ranks first among States',
      indiasRanking: 'Composite score 71',
      indiaScore: '71',
      trend: IndexTrend.improving,
      hasStateWiseData: true,
      topStates: ['Kerala', 'Uttarakhand', 'Goa'],
      latestEditionYear: 2024,
      editionHistory: const [
        IndexEdition(
            editionYear: 2018,
            indiaRanking: 'Baseline',
            indiaScore: '57',
            totalEconomies: 0),
        IndexEdition(
            editionYear: 2019,
            indiaRanking: 'Score improved',
            indiaScore: '60',
            totalEconomies: 0),
        IndexEdition(
            editionYear: 2020,
            indiaRanking: 'Score improved',
            indiaScore: '66',
            totalEconomies: 0),
        IndexEdition(
            editionYear: 2023,
            indiaRanking: 'Composite score 71',
            indiaScore: '71',
            totalEconomies: 0),
      ],
      officialUrl: 'https://www.niti.gov.in/sdg-india-index',
      upscRelevance:
          'SDG India Index is a high-yield UPSC topic (GS2/GS3): India\'s composite score and state-wise SDG performance are frequently asked.',
      relatedReportIds: ['rep_niti_adp_2024'],
      relatedCurrentAffairsIds: ['ca_sdg_india_index'],
      relatedPyqIds: ['PYQ_GS3_2022_Q08'],
      evidenceIds: ['ev_sdg_index_official'],
      keywords: [
        'SDG India Index',
        'NITI Aayog',
        'Sustainable Development Goals',
        'Composite Score'
      ],
    ),

    // 2. National Multidimensional Poverty Index 2023
    IndexKnowledgeObject(
      id: 'idx_mpi_2023',
      indexName:
          'National Multidimensional Poverty Index (Progress Review 2023)',
      publisher: 'NITI Aayog',
      publishingMinistry: 'NITI Aayog',
      methodology:
          'Measures multidimensional poverty across 12 indicators in three dimensions - health, education and standard of living - based on NFHS data.',
      indicators: [
        'Nutrition',
        'Child Mortality',
        'Maternal Health',
        'Years of Schooling',
        'School Attendance',
        'Cooking Fuel',
        'Sanitation',
        'Drinking Water',
        'Electricity',
        'Housing',
        'Assets',
        'Bank Account'
      ],
      weightage: 'Each of the three dimensions carries equal weight (1/3)',
      latestRanking: 'MPI headcount ratio 14.96 per cent (2019-21)',
      indiasRanking:
          '13.5 crore people moved out of multidimensional poverty between 2015-16 and 2019-21',
      indiaScore: '14.96 per cent',
      trend: IndexTrend.improving,
      hasStateWiseData: true,
      topStates: [],
      latestEditionYear: 2023,
      editionHistory: const [
        IndexEdition(
            editionYear: 2021,
            indiaRanking: 'Baseline',
            indiaScore: '24.85 per cent (2015-16)',
            totalEconomies: 0),
        IndexEdition(
            editionYear: 2023,
            indiaRanking: 'Decline in MPI',
            indiaScore: '14.96 per cent (2019-21)',
            totalEconomies: 0),
      ],
      officialUrl:
          'https://www.niti.gov.in/national-multidimensional-poverty-index',
      upscRelevance:
          'Multidimensional Poverty Index is a recurring UPSC topic (GS1 poverty, GS2 welfare). The decline from 24.85% to 14.96% and 13.5 crore figure are high-yield facts.',
      relatedReportIds: ['rep_es_2024_25'],
      relatedSchemeNames: [
        'Antyodaya Anna Yojana',
        'PMAY',
        'Jal Jeevan Mission',
        'Ujjwala Yojana'
      ],
      relatedCurrentAffairsIds: ['ca_mpi_2023'],
      relatedPyqIds: ['PYQ_GS1_2023_Q13', 'PYQ_GS2_2021_Q06'],
      evidenceIds: ['ev_mpi_2023_official'],
      keywords: ['MPI', 'Multidimensional Poverty', 'NITI Aayog', 'Poverty'],
    ),

    // 3. Global Hunger Index 2024
    IndexKnowledgeObject(
      id: 'idx_ghi_2024',
      indexName: 'Global Hunger Index 2024',
      publisher: 'Concern Worldwide and Welthungerhilfe',
      publishingMinistry: 'International Non-Governmental Organisations',
      methodology:
          'Composite score from four indicators - undernourishment, child stunting, child wasting and child mortality.',
      indicators: [
        'Undernourishment',
        'Child Stunting',
        'Child Wasting',
        'Child Mortality'
      ],
      weightage: 'Equal weightage across the four indicators',
      latestRanking: 'India ranked 105 out of 127 countries',
      indiasRanking: 'Rank 105 (score 27.3, serious category)',
      indiaScore: '27.3',
      trend: IndexTrend.improving,
      hasStateWiseData: false,
      latestEditionYear: 2024,
      totalEconomies: 127,
      editionHistory: const [
        IndexEdition(
            editionYear: 2023,
            indiaRanking: 'Rank 111 of 125',
            indiaScore: '28.7',
            totalEconomies: 125),
        IndexEdition(
            editionYear: 2024,
            indiaRanking: 'Rank 105 of 127',
            indiaScore: '27.3',
            totalEconomies: 127),
      ],
      officialUrl: 'https://www.globalhungerindex.org/',
      upscRelevance:
          'GHI is a standard UPSC Prelims fact (hunger, malnutrition) though the Government of India disputes its methodology. India\'s rank and the FAO undernourishment estimate are commonly tested.',
      relatedReportIds: ['rep_fao_sofi_2024'],
      relatedActIds: ['National Food Security Act, 2013'],
      relatedSchemeNames: [
        'POSHAN Abhiyaan',
        'PM POSHAN',
        'Anganwadi Services'
      ],
      relatedCurrentAffairsIds: ['ca_global_hunger', 'ca_ghi_2024'],
      relatedPyqIds: ['PYQ_GS1_2022_Q11'],
      evidenceIds: ['ev_ghi_2024_official'],
      keywords: [
        'Global Hunger Index',
        'Hunger',
        'Stunting',
        'Wasting',
        'Malnutrition'
      ],
    ),

    // 4. Global Innovation Index 2024
    IndexKnowledgeObject(
      id: 'idx_gii_2024',
      indexName: 'Global Innovation Index 2024',
      publisher: 'World Intellectual Property Organization (WIPO)',
      publishingMinistry: 'United Nations Agency (partner: CII, India)',
      methodology:
          'Ranks economies on innovation capability and output using around 80 indicators across institutions, human capital, infrastructure, market sophistication and business sophistication.',
      indicators: [
        'Institutions',
        'Human Capital & Research',
        'Infrastructure',
        'Market Sophistication',
        'Business Sophistication',
        'Knowledge & Technology Outputs',
        'Creative Outputs'
      ],
      weightage: 'Composite of innovation inputs and outputs pillars',
      latestRanking: 'India ranked 39 out of 133 economies',
      indiasRanking: 'Rank 39 (improved from 40 in 2023)',
      indiaScore: 'Rank 39',
      trend: IndexTrend.improving,
      hasStateWiseData: false,
      latestEditionYear: 2024,
      totalEconomies: 133,
      editionHistory: const [
        IndexEdition(
            editionYear: 2023,
            indiaRanking: 'Rank 40 of 132',
            indiaScore: 'Rank 40',
            totalEconomies: 132),
        IndexEdition(
            editionYear: 2024,
            indiaRanking: 'Rank 39 of 133',
            indiaScore: 'Rank 39',
            totalEconomies: 133),
      ],
      officialUrl: 'https://www.wipo.int/global_innovation_index/',
      upscRelevance:
          'GII is a high-yield UPSC Prelims and GS3 topic (science, technology and innovation). India\'s rank and its standing among lower-middle-income economies are regularly asked.',
      relatedReportIds: ['rep_es_2024_25'],
      relatedSchemeNames: [
        'National Mission on Interdisciplinary Cyber-Physical Systems',
        'Startup India'
      ],
      relatedCurrentAffairsIds: ['ca_gii_2024'],
      relatedPyqIds: ['PYQ_GS3_2023_Q07', 'PYQ_GS3_2021_Q04'],
      evidenceIds: ['ev_gii_2024_official'],
      keywords: ['Global Innovation Index', 'WIPO', 'Innovation', 'Ranking'],
    ),

    // 5. Human Development Index 2023-24
    IndexKnowledgeObject(
      id: 'idx_hdi_2023_24',
      indexName: 'Human Development Index (Human Development Report 2023/24)',
      publisher: 'United Nations Development Programme (UNDP)',
      publishingMinistry: 'United Nations Agency',
      methodology:
          'Composite index of life expectancy, expected and mean years of schooling, and Gross National Income per capita.',
      indicators: [
        'Life Expectancy at Birth',
        'Expected Years of Schooling',
        'Mean Years of Schooling',
        'GNI per Capita'
      ],
      weightage: 'Geometric mean of the three dimensions',
      latestRanking: 'India ranked 134 out of 193 countries',
      indiasRanking: 'Rank 134 (HDI value 0.644)',
      indiaScore: '0.644',
      trend: IndexTrend.improving,
      hasStateWiseData: false,
      latestEditionYear: 2024,
      totalEconomies: 193,
      officialUrl: 'https://hdr.undp.org/',
      upscRelevance:
          'HDI and the Human Development Report are a recurring UPSC topic (GS1 human development, GS2). India\'s HDI rank and value, plus related indices (GII, GDI), are frequently tested.',
      relatedReportIds: [],
      relatedSchemeNames: ['Ayushman Bharat', 'Samagra Shiksha Abhiyan'],
      relatedCurrentAffairsIds: ['ca_hdr_2024'],
      relatedPyqIds: ['PYQ_GS1_2022_Q08', 'PYQ_GS2_2020_Q04'],
      evidenceIds: ['ev_hdr_2024_official'],
      keywords: ['Human Development Index', 'UNDP', 'HDI', 'Human Development'],
    ),

    // 6. Global Gender Gap Report 2024
    IndexKnowledgeObject(
      id: 'idx_ggg_2024',
      indexName: 'Global Gender Gap Report 2024',
      publisher: 'World Economic Forum',
      publishingMinistry: 'International Organisation',
      methodology:
          'Benchmarks gender parity across four sub-indexes - economic participation, educational attainment, health and survival, and political empowerment.',
      indicators: [
        'Economic Participation & Opportunity',
        'Educational Attainment',
        'Health & Survival',
        'Political Empowerment'
      ],
      weightage: 'Composite of the four sub-indexes',
      latestRanking: 'India ranked 129 out of 146 countries',
      indiasRanking: 'Rank 129 (score 0.641)',
      indiaScore: '0.641',
      trend: IndexTrend.worsening,
      hasStateWiseData: false,
      latestEditionYear: 2024,
      totalEconomies: 146,
      editionHistory: const [
        IndexEdition(
            editionYear: 2023,
            indiaRanking: 'Rank 127 of 146',
            indiaScore: '0.642',
            totalEconomies: 146),
        IndexEdition(
            editionYear: 2024,
            indiaRanking: 'Rank 129 of 146',
            indiaScore: '0.641',
            totalEconomies: 146),
      ],
      officialUrl:
          'https://www.weforum.org/publications/global-gender-gap-report-2024/',
      upscRelevance:
          'Gender gap data supports UPSC GS1 (role of women) and GS2 (women welfare) answers. India\'s ranking and the political empowerment sub-index are commonly cited.',
      relatedArticleIds: ['Article 15', 'Article 16', 'Article 39'],
      relatedActIds: ['Maternity Benefit (Amendment) Act, 2017'],
      relatedSchemeNames: [
        'Beti Bachao Beti Padhao',
        'Mission Shakti',
        'Nari Shakti Vandan Adhiniyam'
      ],
      relatedCurrentAffairsIds: ['ca_ggg_2024', 'ca_women_reservation'],
      relatedPyqIds: ['PYQ_GS1_2023_Q12', 'PYQ_GS2_2021_Q07'],
      evidenceIds: ['ev_ggg_2024_official'],
      keywords: [
        'Global Gender Gap',
        'Gender Parity',
        'World Economic Forum',
        'Women'
      ],
    ),

    // 7. Ease of Doing Business 2020 (historical)
    IndexKnowledgeObject(
      id: 'idx_eodb_2020',
      indexName: 'Ease of Doing Business (World Bank) - Historical',
      publisher: 'World Bank',
      publishingMinistry: 'International Financial Institution',
      methodology:
          'Ranked economies on 10 business regulation indicators covering starting a business, getting credit, trading across borders, enforcing contracts and resolving insolvency. Discontinued after DB2020.',
      indicators: [
        'Starting a Business',
        'Dealing with Construction Permits',
        'Getting Electricity',
        'Registering Property',
        'Getting Credit',
        'Protecting Minority Investors',
        'Paying Taxes',
        'Trading Across Borders',
        'Enforcing Contracts',
        'Resolving Insolvency'
      ],
      weightage: 'Distance-to-frontier scores across the 10 indicators',
      latestRanking: 'India ranked 63 out of 190 economies (DB2020)',
      indiasRanking: 'Rank 63 (improved from 142 in DB2015)',
      indiaScore: 'Rank 63',
      trend: IndexTrend.improving,
      hasStateWiseData: false,
      latestEditionYear: 2020,
      totalEconomies: 190,
      editionHistory: const [
        IndexEdition(
            editionYear: 2015,
            indiaRanking: 'Rank 142 of 189',
            indiaScore: 'Rank 142',
            totalEconomies: 189),
        IndexEdition(
            editionYear: 2018,
            indiaRanking: 'Rank 100 of 190',
            indiaScore: 'Rank 100',
            totalEconomies: 190),
        IndexEdition(
            editionYear: 2020,
            indiaRanking: 'Rank 63 of 190',
            indiaScore: 'Rank 63',
            totalEconomies: 190),
      ],
      officialUrl:
          'https://www.worldbank.org/en/programs/business-enabling-environment',
      upscRelevance:
          'Ease of Doing Business is a historical UPSC GS3 topic (business regulation, reforms). India\'s climb from 142 to 63 and the discontinuation of the index after data irregularities are key facts.',
      relatedReportIds: ['rep_es_2024_25'],
      relatedActIds: [
        'Insolvency and Bankruptcy Code, 2016',
        'Companies Act, 2013',
        'GST Act, 2017'
      ],
      relatedSchemeNames: ['Startup India', 'Make in India'],
      relatedDoctrineIds: ['Deregulation', 'Regulatory Impact Assessment'],
      relatedCurrentAffairsIds: ['ca_bready_report'],
      relatedPyqIds: ['PYQ_GS3_2023_Q06', 'PYQ_GS3_2019_Q03'],
      evidenceIds: ['ev_eodb_2020_official'],
      keywords: [
        'Ease of Doing Business',
        'World Bank',
        'Business Regulation',
        'Deregulation'
      ],
    ),

    // 8. LEADS 2024
    IndexKnowledgeObject(
      id: 'idx_leads_2024',
      indexName: 'Logistics Ease Across Different States (LEADS) 2024',
      publisher:
          'Department for Promotion of Industry and Internal Trade (DPIIT)',
      publishingMinistry: 'Ministry of Commerce and Industry',
      methodology:
          'State-level perception-and-metric composite measuring logistics ecosystem performance across 12 indicators under four pillars - logistics infrastructure, services, operating environment, and cost & time.',
      indicators: [
        'Logistics Infrastructure',
        'Logistics Services',
        'Operating Environment',
        'Cost & Time'
      ],
      weightage: 'Composite across the four pillars',
      latestRanking: 'States classified as Achievers, Fast Movers and Aspirers',
      indiasRanking:
          'Gujarat, Karnataka, Tamil Nadu and others in top Achiever category',
      indiaScore: 'Achiever / Fast Mover categories',
      trend: IndexTrend.improving,
      hasStateWiseData: true,
      topStates: [
        'Gujarat',
        'Karnataka',
        'Tamil Nadu',
        'Haryana',
        'Punjab',
        'Telangana'
      ],
      latestEditionYear: 2024,
      officialUrl: 'https://www.dpiit.gov.in/',
      upscRelevance:
          'LEADS and the National Logistics Policy are UPSC GS3 topics (logistics, infrastructure). State-wise classification of the logistics ecosystem is frequently tested.',
      relatedActIds: ['National Logistics Policy, 2022'],
      relatedSchemeNames: ['PM Gati Shakti', 'National Logistics Policy'],
      relatedCurrentAffairsIds: ['ca_leads_2024'],
      relatedPyqIds: ['PYQ_GS3_2023_Q09'],
      evidenceIds: ['ev_leads_2024_official'],
      keywords: [
        'LEADS',
        'Logistics',
        'DPIIT',
        'PM Gati Shakti',
        'National Logistics Policy'
      ],
    ),

    // 9. Environmental Performance Index 2024
    IndexKnowledgeObject(
      id: 'idx_epi_2024',
      indexName: 'Environmental Performance Index 2024',
      publisher:
          'Yale Center for Environmental Law and Policy and Columbia CIESIN',
      publishingMinistry: 'Academic Institutions',
      methodology:
          'Measures country performance on environmental health and ecosystem vitality using 58 indicators across 11 categories.',
      indicators: [
        'Environmental Health',
        'Ecosystem Vitality',
        'Climate Change',
        'Air Quality',
        'Biodiversity',
        'Water Quality',
        'Waste Management'
      ],
      weightage:
          'Composite of environmental health (40%) and ecosystem vitality (60%)',
      latestRanking: 'India ranked 176 out of 180 countries',
      indiasRanking: 'Rank 176',
      indiaScore: 'Rank 176',
      trend: IndexTrend.worsening,
      hasStateWiseData: false,
      latestEditionYear: 2024,
      totalEconomies: 180,
      officialUrl: 'https://epi.yale.edu/',
      upscRelevance:
          'EPI data is relevant to UPSC Environment questions; India\'s poor ranking on air quality and ecosystem vitality is a recurring theme.',
      relatedArticleIds: ['Article 48A', 'Article 51A'],
      relatedActIds: [
        'Environment (Protection) Act, 1986',
        'Air (Prevention and Control of Pollution) Act, 1981'
      ],
      relatedSchemeNames: [
        'National Clean Air Programme',
        'National Air Quality Monitoring'
      ],
      relatedCurrentAffairsIds: ['ca_epi_2024'],
      relatedPyqIds: ['PYQ_GS1_2023_Q15', 'PYQ_GS3_2020_Q18'],
      evidenceIds: ['ev_epi_2024_official'],
      keywords: [
        'Environmental Performance Index',
        'Yale',
        'Air Quality',
        'Ecosystem Vitality'
      ],
    ),
  ];
}
