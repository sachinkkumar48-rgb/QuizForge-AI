library;

import '../domain/entities/report_enums.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/report_statistic.dart';
import '../domain/entities/recommendation_knowledge_object.dart';

/// Phase-I Seed Corpus - NITI Aayog and international/multilateral reports.
class ReportCorpusGlobal {
  static final List<ReportKnowledgeObject> reports = [
    // 1. NITI Aayog - Aspirational Districts Programme
    ReportKnowledgeObject(
      id: 'rep_niti_adp_2024',
      officialTitle: 'Aspirational Districts Programme - Delta Ranking Reports',
      shortName: 'NITI Aayog ADP Report',
      category: ReportCategory.governance,
      publishingOrganisation: 'NITI Aayog',
      publishingMinistry:
          'NITI Aayog (with Ministry of Panchayati Raj and States)',
      publicationYear: 2024,
      edition: 'Monthly Delta Rankings',
      publicationFrequency: PublicationFrequency.periodic,
      officialUrl: 'https://www.niti.gov.in/aspirational-districts-programme',
      executiveSummary:
          'The Aspirational Districts Programme covers 112 aspirational districts, measuring monthly progress on 49 indicators across five thematic areas to drive social and economic development.',
      objectives: [
        'Accelerate improvement in socio-economic outcomes of backward districts',
        'Drive convergence of central and state schemes at district level',
      ],
      methodology:
          'District-level dashboard measuring 49 indicators across Health & Nutrition, Education, Agriculture & Water Resources, Financial Inclusion & Skill Development, and Basic Infrastructure.',
      keyFindings: [
        '112 aspirational districts monitored through a real-time dashboard',
        'Delta rankings released monthly to drive competition among districts',
      ],
      keyIndicators: [
        'Health & Nutrition',
        'Education',
        'Agriculture & Water',
        'Financial Inclusion',
        'Basic Infrastructure'
      ],
      upscRelevance:
          'Aspirational Districts Programme is a frequently tested scheme in UPSC GS2 (governance, transparency and accountability).',
      relatedArticleIds: ['Article 243ZD', 'Article 243G'],
      relatedActIds: ['Constitution (Seventy-fourth Amendment) Act, 1992'],
      relatedSchemeNames: ['Aspirational Districts Programme'],
      relatedDoctrineIds: ['Cooperative Federalism', 'Competitive Federalism'],
      relatedCurrentAffairsIds: ['ca_adp_delta_ranking'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2022_GS2_Q010'],
      evidenceIds: ['ev_niti_adp_official'],
      keywords: [
        'NITI Aayog',
        'Aspirational Districts',
        'Delta Ranking',
        'Development'
      ],
    ),

    // 2. World Development Report 2024
    ReportKnowledgeObject(
      id: 'rep_wdr_2024',
      officialTitle: 'World Development Report 2024: Economic Growth',
      shortName: 'World Development Report',
      category: ReportCategory.international,
      publishingOrganisation: 'World Bank',
      publishingMinistry: 'International Financial Institution',
      publicationYear: 2024,
      edition: '2024',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.worldbank.org/en/publication/wdr2024',
      executiveSummary:
          'The World Development Report 2024 examines the "middle-income trap" and outlines a growth strategy based on investment, infusion of technology and innovation for developing economies.',
      objectives: [
        'Analyse barriers to sustained growth in middle-income countries',
        'Recommend a sequenced 3I growth strategy: Investment, Infusion, Innovation',
      ],
      methodology:
          'Cross-country empirical analysis using World Bank country data and growth models.',
      keyFindings: [
        'WDR 2024 proposes a "3I" strategy - Investment, Infusion, Innovation',
        'Focuses on why few middle-income countries catch up to high-income status',
      ],
      keyIndicators: ['GDP per capita', 'Total Factor Productivity'],
      recommendations: [
        RecommendationKnowledgeObject(
          id: 'rec_wdr_2024_001',
          title: 'Sequenced 3I growth strategy',
          description:
              'Countries should pursue investment, then infusion of technology, and finally innovation in a sequenced manner to escape the middle-income trap.',
          recommendingBody: 'World Development Report 2024',
          recipientActor: 'Governments of Developing Countries',
          status: RecommendationStatus.underConsideration,
          reportId: 'rep_wdr_2024',
          keywords: ['Middle-Income Trap', 'Growth', 'Innovation'],
        ),
      ],
      upscRelevance:
          'World Bank reports are relevant to UPSC GS3 (Indian economy, growth, global institutions) and for questions on development economics.',
      relatedDoctrineIds: ['Middle-Income Trap'],
      relatedCurrentAffairsIds: ['ca_world_bank_india_growth'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2021_GS3_Q001'],
      relatedInternationalOrganisations: const ['int_world_bank'],
      evidenceIds: ['ev_wdr_2024_official'],
      keywords: ['World Bank', 'WDR', 'Middle-Income Trap', 'Economic Growth'],
    ),

    // 3. IMF World Economic Outlook (October 2024)
    ReportKnowledgeObject(
      id: 'rep_imf_weo_oct_2024',
      officialTitle: 'IMF World Economic Outlook (October 2024)',
      shortName: 'IMF WEO',
      category: ReportCategory.international,
      publishingOrganisation: 'International Monetary Fund',
      publishingMinistry: 'International Financial Institution',
      publicationYear: 2024,
      edition: 'October 2024',
      publicationFrequency: PublicationFrequency.semiAnnual,
      officialUrl: 'https://www.imf.org/en/Publications/WEO',
      executiveSummary:
          'The WEO presents IMF forecasts of global and national economic growth. The October 2024 edition projected global growth of about 3.2 per cent and pegged India\'s growth at 7.0 per cent for 2024 and 6.5 per cent for 2025.',
      objectives: [
        'Present global and regional growth forecasts',
        'Analyse risks to the global outlook',
      ],
      methodology:
          'Compiled by the IMF Research Department from country reports, national accounts and global data.',
      keyFindings: [
        'Global growth projected at about 3.2 per cent for 2024',
        'India projected to grow at 7.0 per cent in 2024 and 6.5 per cent in 2025',
      ],
      keyIndicators: ['Global GDP Growth', 'India GDP Growth', 'Inflation'],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_weo_india_2024',
          label: 'India GDP growth projection 2024',
          value: '7.0',
          unit: 'per cent',
          referenceYear: 2024,
          source: 'IMF WEO October 2024',
        ),
      ],
      upscRelevance:
          'IMF growth projections for India are a standard Current Affairs + GS3 topic and appear regularly in UPSC and State PSC exams.',
      relatedCurrentAffairsIds: ['ca_imf_weo_2024'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2023_GS3_Q002'],
      relatedInternationalOrganisations: const ['int_imf'],
      evidenceIds: ['ev_imf_weo_official'],
      keywords: [
        'IMF',
        'World Economic Outlook',
        'Growth Forecast',
        'Global Economy'
      ],
    ),

    // 4. UNESCO Global Education Monitoring Report 2024/25
    ReportKnowledgeObject(
      id: 'rep_unesco_gem_2024',
      officialTitle:
          'UNESCO Global Education Monitoring Report 2024/25: Leadership in Education',
      shortName: 'GEM Report',
      category: ReportCategory.education,
      publishingOrganisation: 'UNESCO',
      publishingMinistry: 'International Organisation',
      publicationYear: 2024,
      edition: '2024/25',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.unesco.org/gem-report/',
      executiveSummary:
          'The GEM Report monitors progress towards Sustainable Development Goal 4 (quality education). The 2024/25 edition focuses on the role of leadership in education systems.',
      objectives: [
        'Monitor progress on SDG 4',
        'Examine the role and capacity of leaders in education',
      ],
      methodology:
          'Evidence synthesis of national education statistics, policy reviews and case studies submitted by member states.',
      keyFindings: [
        'Focus on leadership as a catalyst for educational quality and equity',
        'Documents gaps in SDG 4 achievement across regions',
      ],
      keyIndicators: [
        'SDG 4 Progress',
        'Out-of-School Children',
        'Learning Outcomes'
      ],
      upscRelevance:
          'GEM Report is relevant to UPSC GS2 (education) and SDG-linked questions.',
      relatedSchemeNames: ['Samagra Shiksha Abhiyan', 'NEP 2020'],
      relatedCurrentAffairsIds: ['ca_gem_report'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2021_GS2_Q005'],
      relatedInternationalOrganisations: const ['int_unesco'],
      evidenceIds: ['ev_gem_2024_official'],
      keywords: ['UNESCO', 'GEM Report', 'SDG 4', 'Education'],
    ),

    // 5. UNICEF State of the World's Children 2024
    ReportKnowledgeObject(
      id: 'rep_unicef_sowc_2024',
      officialTitle:
          'The State of the World\'s Children 2024: The Future of Childhood in a Changing World',
      shortName: 'State of the World\'s Children',
      category: ReportCategory.socialDevelopment,
      publishingOrganisation: 'UNICEF',
      publishingMinistry: 'International Organisation',
      publicationYear: 2024,
      edition: '2024',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.unicef.org/reports/state-of-worlds-children',
      executiveSummary:
          'The flagship UNICEF report examines challenges and opportunities shaping childhood, including demographic shifts, climate change and technology.',
      objectives: [
        'Assess global situation of children',
        'Identify megatrends shaping the future of childhood',
      ],
      methodology:
          'Global child-related statistics compiled from UNICEF data and national sources.',
      keyFindings: [
        'Explores demographic change, climate and technology as forces shaping childhood',
        'Calls for renewed investment in child-centred policies',
      ],
      keyIndicators: [
        'Child Mortality',
        'Child Marriage',
        'Out-of-School Children'
      ],
      upscRelevance:
          'Relevant to UPSC GS1 (social issues, demography) and GS2 (welfare of vulnerable sections).',
      relatedSchemeNames: ['POSHAN Abhiyaan', 'Beti Bachao Beti Padhao'],
      relatedCurrentAffairsIds: ['ca_sowc_2024'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2023_GS1_Q009'],
      relatedInternationalOrganisations: const ['int_unicef'],
      evidenceIds: ['ev_sowc_2024_official'],
      keywords: [
        'UNICEF',
        'State of the World\'s Children',
        'Child Welfare',
        'SDG'
      ],
    ),

    // 6. FAO State of Food Security and Nutrition in the World 2024
    ReportKnowledgeObject(
      id: 'rep_fao_sofi_2024',
      officialTitle:
          'The State of Food Security and Nutrition in the World 2024',
      shortName: 'SOFI Report',
      category: ReportCategory.agriculture,
      publishingOrganisation: 'FAO, IFAD, UNICEF, WFP and WHO',
      publishingMinistry: 'United Nations Agencies',
      publicationYear: 2024,
      edition: '2024',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl: 'https://www.fao.org/publications/sofi',
      executiveSummary:
          'The SOFI report provides global estimates of hunger and food insecurity. The 2024 edition estimated that about 733 million people faced hunger in 2023.',
      objectives: [
        'Track progress on SDG 2 (Zero Hunger)',
        'Estimate the prevalence of undernourishment and food insecurity',
      ],
      methodology:
          'FAO food balance sheets, household surveys and modelling of undernourishment prevalence.',
      keyFindings: [
        'About 733 million people faced hunger in 2023',
        'Financing to end hunger remains a key challenge',
      ],
      keyIndicators: [
        'Prevalence of Undernourishment',
        'Moderate/Severe Food Insecurity',
        'Malnutrition'
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_sofi_hunger',
          label: 'People facing hunger globally (2023)',
          value: '733',
          unit: 'million',
          referenceYear: 2023,
          source: 'SOFI 2024',
        ),
      ],
      upscRelevance:
          'SOFI data is relevant to UPSC GS1 (hunger, malnutrition) and GS3 (food security, agriculture) and connects to India\'s food security debate.',
      relatedIndexIds: ['idx_ghi_2024'],
      relatedArticleIds: [],
      relatedActIds: ['National Food Security Act, 2013'],
      relatedSchemeNames: [
        'PM POSHAN',
        'POSHAN Abhiyaan',
        'Public Distribution System'
      ],
      relatedCurrentAffairsIds: ['ca_sofi_2024', 'ca_global_hunger'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2022_GS1_Q011', 'PYQ_UPSC_CSE_2021_GS3_Q009'],
      relatedInternationalOrganisations: const ['int_fao'],
      sdgGoals: const ['SDG 2 - Zero Hunger'],
      evidenceIds: ['ev_sofi_2024_official'],
      keywords: ['FAO', 'SOFI', 'Hunger', 'Food Security', 'Undernourishment'],
    ),

    // 7. WHO World Health Statistics 2024
    ReportKnowledgeObject(
      id: 'rep_who_whs_2024',
      officialTitle: 'World Health Statistics 2024',
      shortName: 'WHO World Health Statistics',
      category: ReportCategory.health,
      publishingOrganisation: 'World Health Organization',
      publishingMinistry: 'United Nations Agency',
      publicationYear: 2024,
      edition: '2024',
      publicationFrequency: PublicationFrequency.annual,
      officialUrl:
          'https://www.who.int/data/gho/publications/world-health-statistics',
      executiveSummary:
          'World Health Statistics is WHO\'s annual compilation of health indicators for its 194 member states, tracking progress towards health-related SDGs.',
      objectives: [
        'Compile comparable health statistics across member states',
        'Monitor progress on health-related SDG targets',
      ],
      methodology:
          'Data from the Global Health Observatory and member-state reporting.',
      keyFindings: [
        'Tracks life expectancy, mortality, non-communicable disease and health system indicators',
        'Highlights unfinished agenda on universal health coverage',
      ],
      keyIndicators: [
        'Life Expectancy',
        'Under-5 Mortality',
        'Maternal Mortality Ratio',
        'Universal Health Coverage'
      ],
      upscRelevance:
          'WHO health statistics support UPSC GS2 (health, welfare) answers and India-specific health outcomes.',
      relatedSchemeNames: ['Ayushman Bharat', 'National Health Mission'],
      relatedCurrentAffairsIds: ['ca_who_health_statistics'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2022_GS2_Q007'],
      relatedInternationalOrganisations: const ['int_who'],
      sdgGoals: const ['SDG 3 - Good Health & Well-being'],
      evidenceIds: ['ev_who_whs_official'],
      keywords: ['WHO', 'World Health Statistics', 'Life Expectancy', 'Health'],
    ),

    // 8. IPCC AR6 Synthesis Report 2023
    ReportKnowledgeObject(
      id: 'rep_ipcc_ar6_2023',
      officialTitle: 'Climate Change 2023: Synthesis Report (AR6)',
      shortName: 'IPCC AR6 Synthesis',
      category: ReportCategory.climate,
      publishingOrganisation: 'Intergovernmental Panel on Climate Change',
      publishingMinistry: 'WMO and UNEP Body',
      publicationYear: 2023,
      edition: 'Sixth Assessment Report',
      publicationFrequency: PublicationFrequency.periodic,
      officialUrl: 'https://www.ipcc.ch/report/ar6/syr/',
      executiveSummary:
          'The AR6 Synthesis Report consolidates findings of the Sixth Assessment Report. Global surface temperature was 1.1 degree Celsius above the 1850-1900 average in 2011-2020, and emissions need to peak by 2025 and fall 43 per cent by 2030 to limit warming to 1.5 degrees Celsius.',
      objectives: [
        'Synthesise the state of knowledge on climate change',
        'Inform the global response under the Paris Agreement',
      ],
      methodology:
          'Synthesis of the three working-group contributions of AR6 and the special reports.',
      keyFindings: [
        'Human activities have unequivocally caused global warming',
        'Global surface temperature 1.1 degree Celsius above 1850-1900 levels in 2011-2020',
        'Limiting warming to 1.5C requires emissions to peak by 2025 and reduce 43 per cent by 2030',
      ],
      keyIndicators: [
        'Global Temperature Rise',
        'GHG Emissions',
        'CO2 Concentrations'
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_ipcc_temp',
          label: 'Global warming above pre-industrial (2011-2020)',
          value: '1.1',
          unit: 'degree Celsius',
          referenceYear: 2023,
          source: 'IPCC AR6 Synthesis',
        ),
      ],
      upscRelevance:
          'IPCC reports are central to UPSC Environment and Climate Change questions; 1.5C target, NDCs and climate science are frequently tested.',
      relatedArticleIds: ['Article 48A', 'Article 51A'],
      relatedActIds: [
        'Environment (Protection) Act, 1986',
        'Energy Conservation (Amendment) Act, 2022'
      ],
      relatedSchemeNames: [
        'National Action Plan on Climate Change',
        'National Green Hydrogen Mission'
      ],
      relatedDoctrineIds: [
        'Sustainable Development',
        'Polluter Pays Principle',
        'Precautionary Principle'
      ],
      relatedCurrentAffairsIds: ['ca_ipcc_ar6', 'ca_cop28'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2024_GS1_Q018', 'PYQ_UPSC_CSE_2022_GS3_Q016'],
      relatedInternationalOrganisations: const ['int_ipcc', 'int_unfccc'],
      sdgGoals: const ['SDG 13 - Climate Action'],
      evidenceIds: ['ev_ipcc_ar6_official'],
      keywords: [
        'IPCC',
        'Climate Change',
        'AR6',
        'Global Warming',
        '1.5 Degree'
      ],
    ),
    ReportKnowledgeObject(
      id: 'rep_undp_hdr_2023_24',
      officialTitle: 'Human Development Report 2023/24',
      shortName: 'UNDP Human Development Report',
      category: ReportCategory.socialDevelopment,
      publishingOrganisation: 'United Nations Development Programme',
      publishingMinistry: 'UNDP (multilateral)',
      publicationYear: 2024,
      edition: '2023/24',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.globalReport,
      reportingPeriod: '2023/24',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2024-03-13',
      officialUrl: 'https://hdr.undp.org/',
      executiveSummary:
          'The Human Development Report 2023/24 presents the Human Development Index (HDI) for 193 countries, emphasising polarisation and gridlock in development.',
      policySignificance:
          'HDI value and rank are widely cited for India; informs human-development discourse.',
      objectives: const [
        'Rank countries by the Human Development Index',
        'Analyse human-development trends, inequality and polarisation',
      ],
      methodology:
          'HDI composites life expectancy, education (mean and expected years of schooling) and gross national income per capita.',
      keyFindings: const [
        'India HDI value: 0.644 (2022), rank 134 of 193',
        'HDI trend reflects improving life expectancy and schooling',
        'Global development polarisation and gridlock themes',
      ],
      keyIndicators: const ['HDI Value', 'HDI Rank', 'Life Expectancy', 'Expected Years of Schooling'],
      upscRelevance:
          'Human Development Index, UNDP, social development, health-education-income metrics (GS-II, GS-III)',
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Human Development', 'Inequality', 'Social Sector'],
      sectors: const ['Health', 'Education', 'Economy'],
      relatedArticleIds: const ['Article 21'],
      relatedActIds: const [],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2020_GS2_Q004'],
      relatedBodies: const [],
      relatedInternationalOrganisations: const ['int_undp'],
      relationships: const [],
      sdgGoals: const ['SDG 1 - No Poverty', 'SDG 10 - Reduced Inequalities'],
      evidenceIds: const ['ev_undp_hdr_2023_24_official'],
      keywords: const ['Human Development Report', 'HDI', 'UNDP', 'Human Development Index'],
    ),
    ReportKnowledgeObject(
      id: 'rep_un_wpp_2024',
      officialTitle: 'World Population Prospects 2024',
      shortName: 'UN World Population Prospects',
      category: ReportCategory.demography,
      publishingOrganisation: 'United Nations Department of Economic and Social Affairs (UN DESA)',
      publishingMinistry: 'United Nations (multilateral)',
      publicationYear: 2024,
      edition: '2024 Revision',
      publicationFrequency: PublicationFrequency.biennial,
      reportType: ReportType.forecast,
      reportingPeriod: '2024 Revision',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2024-07-11',
      officialUrl: 'https://population.un.org/wpp/',
      executiveSummary:
          'The UN World Population Prospects 2024 provides population estimates and projections for all countries; India became the world\'s most populous country in 2023.',
      policySignificance:
          'Authoritative population projections; informs demographic-dividend, ageing and migration debates.',
      objectives: const [
        'Provide official UN population estimates and projections',
        'Track fertility, mortality and migration trends',
      ],
      methodology:
          'Cohort-component projection method using national statistics and UN estimates.',
      keyFindings: const [
        'India population (mid-2024): about 1.44 billion - the most populous country',
        'Global population to peak at about 10.3 billion in the 2080s',
        'India\'s fertility is below replacement level',
      ],
      keyIndicators: const ['Population', 'Total Fertility Rate', 'Median Age'],
      upscRelevance:
          'Demographic dividend, population policy, ageing, migration (GS-I, GS-III)',
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Demography', 'Population', 'Demographic Dividend'],
      sectors: const ['Statistics', 'Social Welfare'],
      relatedArticleIds: const ['Article 51'],
      relatedActIds: const [],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2023_GS1_Q011'],
      relatedBodies: const [],
      relatedInternationalOrganisations: const ['int_un'],
      relationships: const [],
      sdgGoals: const ['SDG 3 - Good Health & Well-being', 'SDG 8 - Decent Work & Economic Growth'],
      evidenceIds: const ['ev_un_wpp_2024_official'],
      keywords: const ['World Population Prospects', 'Population', 'UN DESA', 'Demographic Dividend'],
    ),
    ReportKnowledgeObject(
      id: 'rep_wpfi_2024',
      officialTitle: 'World Press Freedom Index 2024',
      shortName: 'World Press Freedom Index',
      category: ReportCategory.governance,
      publishingOrganisation: 'Reporters Without Borders (RSF)',
      publishingMinistry: 'RSF (international NGO)',
      publicationYear: 2024,
      edition: '2024',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.indexPublication,
      reportingPeriod: '2024',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2024-05-03',
      officialUrl: 'https://rsf.org/en/index',
      executiveSummary:
          'The World Press Freedom Index 2024 ranks 180 countries on press-freedom conditions; India ranked 159th.',
      policySignificance:
          'Press freedom is a recurring UPSC current-affairs theme; India\'s rank is widely cited.',
      objectives: const [
        'Rank countries by media independence and pluralism',
        'Assess the safety of journalists',
      ],
      methodology:
          'RSF expert questionnaire covering political, legal, economic and socio-cultural indicators.',
      keyFindings: const [
        'India ranked 159 of 180 in 2024 (up from 161 in 2023)',
        'Global concerns over journalist safety and media independence',
      ],
      keyIndicators: const ['Press Freedom Rank'],
      upscRelevance:
          'Press freedom, freedom of expression, media regulation (GS-II)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Freedom of Expression', 'Media', 'Governance'],
      sectors: const ['Governance'],
      relatedArticleIds: const ['Article 19(1)(a)'],
      relatedActIds: const [],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const [],
      relatedBodies: const [],
      relatedInternationalOrganisations: const [],
      relationships: const [],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      evidenceIds: const ['ev_wpfi_2024_official'],
      keywords: const ['World Press Freedom Index', 'Press Freedom', 'RSF', 'Media'],
    ),
    ReportKnowledgeObject(
      id: 'rep_cpi_2024',
      officialTitle: 'Corruption Perceptions Index 2024',
      shortName: 'Corruption Perceptions Index',
      category: ReportCategory.governance,
      publishingOrganisation: 'Transparency International',
      publishingMinistry: 'Transparency International (international NGO)',
      publicationYear: 2024,
      edition: '2024',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.indexPublication,
      reportingPeriod: '2024',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2025-02-11',
      officialUrl: 'https://www.transparency.org/en/cpi',
      executiveSummary:
          'The Corruption Perceptions Index 2024 scores 180 countries on perceived public-sector corruption; India scored 39 and ranked 93rd.',
      policySignificance:
          'Corruption governance indicator frequently cited in UPSC current affairs.',
      objectives: const [
        'Score countries on perceived corruption in the public sector',
        'Track corruption trends across countries',
      ],
      methodology:
          'Composite index aggregating expert assessments and business surveys (0 = highly corrupt, 100 = very clean).',
      keyFindings: const [
        'India scored 39 of 100 in 2024 (unchanged from 2023), rank 93 of 180',
        'Global average remains at 43, with most countries stagnating',
      ],
      keyIndicators: const ['CPI Score', 'CPI Rank'],
      upscRelevance:
          'Corruption, governance, anti-corruption institutions (GS-II)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Corruption', 'Governance', 'Transparency'],
      sectors: const ['Governance'],
      relatedArticleIds: const ['Article 51'],
      relatedActIds: const ['Prevention of Corruption Act, 1988'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const [],
      relatedBodies: const ['bod_cvc'],
      relatedInternationalOrganisations: const [],
      relationships: const [],
      sdgGoals: const ['SDG 16 - Peace, Justice & Strong Institutions'],
      evidenceIds: const ['ev_cpi_2024_official'],
      keywords: const ['Corruption Perceptions Index', 'Transparency International', 'Governance'],
    ),
    ReportKnowledgeObject(
      id: 'rep_ilo_weso_2024',
      officialTitle: 'World Employment and Social Outlook: Trends 2024',
      shortName: 'ILO World Employment and Social Outlook',
      category: ReportCategory.labour,
      publishingOrganisation: 'International Labour Organization',
      publishingMinistry: 'ILO (multilateral)',
      publicationYear: 2024,
      edition: 'Trends 2024',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.assessmentReport,
      reportingPeriod: '2024',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2024-01-10',
      officialUrl: 'https://www.ilo.org/publications/world-employment-and-social-outlook-trends-2024',
      executiveSummary:
          'The ILO World Employment and Social Outlook (WESO) Trends 2024 analyses global and regional labour-market trends, unemployment and social protection.',
      policySignificance:
          'Official global labour statistics; informs employment, labour-force and social-protection debates.',
      objectives: const [
        'Monitor global and regional labour-market trends',
        'Assess unemployment, informality and social-protection gaps',
      ],
      methodology:
          'ILO modelled estimates based on national labour-force surveys and administrative data.',
      keyFindings: const [
        'Global unemployment projected at 5.2 per cent in 2024',
        'Large informal-economy share and social-protection gaps in South Asia',
      ],
      keyIndicators: const ['Unemployment Rate', 'Labour Force Participation', 'Informality'],
      upscRelevance:
          'Labour markets, employment, informal economy, social protection (GS-III, GS-II)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Employment', 'Labour', 'Social Protection'],
      sectors: const ['Labour', 'Economy'],
      relatedArticleIds: const ['Article 41'],
      relatedActIds: const [],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const ['MGNREGA', 'PMKVY'],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const [],
      relatedBodies: const [],
      relatedInternationalOrganisations: const ['int_ilo'],
      relationships: const [],
      sdgGoals: const ['SDG 1 - No Poverty', 'SDG 8 - Decent Work & Economic Growth'],
      evidenceIds: const ['ev_ilo_weso_2024_official'],
      keywords: const ['ILO', 'World Employment', 'Unemployment', 'Labour Market', 'Social Protection'],
    ),
    ReportKnowledgeObject(
      id: 'rep_wto_wtr_2024',
      officialTitle: 'World Trade Report 2024: Re-globalization for a Secure, Inclusive and Sustainable Future',
      shortName: 'WTO World Trade Report',
      category: ReportCategory.trade,
      publishingOrganisation: 'World Trade Organization',
      publishingMinistry: 'WTO (multilateral)',
      publicationYear: 2024,
      edition: '2024 Edition',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.globalReport,
      reportingPeriod: '2024',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2024-09-09',
      officialUrl: 'https://www.wto.org/english/res_e/booksp_e/wtr24_e/wtr24_e.htm',
      executiveSummary:
          'The WTO World Trade Report 2024 argues that "re-globalization" - deepening and widening trade integration through greater inclusion of economies, firms and people - is preferable to de-globalization and fragmentation for secure, inclusive and sustainable growth.',
      policySignificance:
          'Official WTO analysis of the fragmentation debate; anchors India\'s position on multilateral trade and globalisation (GS-III, GS-II).',
      objectives: const [
        'Assess the state of world trade and the case for re-globalization',
        'Examine how inclusive trade can drive growth, security and sustainability',
      ],
      methodology:
          'WTO Secretariat analysis combining trade statistics, empirical research and contributions by leading trade economists.',
      keyFindings: const [
        r'World merchandise trade stabilised at about US$ 24 trillion in 2023',
        'Argues de-globalization and fragmentation would raise costs and reduce growth',
        'Advocates deepening and widening global supply chains ("re-globalization")',
        'WTO forecasts about 2.6 per cent growth in world trade volume in 2024 and about 3.3 per cent in 2025',
      ],
      keyIndicators: const ['Merchandise Trade Volume', 'Trade-to-GDP Ratio', 'Trade Growth Forecast'],
      upscRelevance:
          'Globalisation, trade policy, WTO and India\'s external sector (GS-III, GS-II)',
      prelimsRelevance: RelevanceLevel.medium,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Trade', 'Globalisation', 'Multilateralism', 'Supply Chains'],
      sectors: const ['Trade', 'Industry'],
      relatedArticleIds: const ['Article 51'],
      relatedActIds: const ['Foreign Trade (Development and Regulation) Act, 1992'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const [],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const [],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2023_GS3_Q005'],
      relatedBodies: const [],
      relatedInternationalOrganisations: const ['int_wto'],
      relationships: const [],
      sdgGoals: const ['SDG 8 - Decent Work & Economic Growth', 'SDG 17 - Partnerships for the Goals'],
      evidenceIds: const ['ev_wtr_2024_official'],
      keywords: const ['WTO', 'World Trade Report', 'Re-globalization', 'Trade', 'Supply Chains'],
    ),
    ReportKnowledgeObject(
      id: 'rep_unep_egr_2024',
      officialTitle: 'Emissions Gap Report 2024: No More Hot Air... Please!',
      shortName: 'UNEP Emissions Gap Report',
      category: ReportCategory.climate,
      publishingOrganisation: 'United Nations Environment Programme',
      publishingMinistry: 'UNEP (multilateral)',
      publicationYear: 2024,
      edition: '2024 Edition',
      publicationFrequency: PublicationFrequency.annual,
      reportType: ReportType.assessmentReport,
      reportingPeriod: '2024',
      geographicalScope: 'Global',
      indiaCoverage: true,
      publicationDate: '2024-10-24',
      officialUrl: 'https://www.unep.org/resources/emissions-gap-report-2024',
      executiveSummary:
          'The UNEP Emissions Gap Report 2024 assesses the gap between pledged and required greenhouse-gas emission reductions, reporting that emissions hit a record high and calling for a 42 per cent cut by 2030 to stay within 1.5 degree Celsius.',
      policySignificance:
          'Reference assessment for climate ambition, NDC updates and COP negotiations (GS-III).',
      objectives: const [
        'Quantify the emissions gap for the Paris Agreement temperature goals',
        'Assess progress on mitigation pledges and policy action',
      ],
      methodology:
          'UNEP synthesis of national emission inventories, modelled mitigation scenarios and Nationally Determined Contribution (NDC) analysis.',
      keyFindings: const [
        'Global greenhouse-gas emissions reached a record about 57.1 GtCO2e in 2023',
        'Emissions need to fall about 42 per cent by 2030 to limit warming to 1.5 degree Celsius',
        'Current policies point to warming of about 2.6-3.1 degree Celsius by 2100',
      ],
      keyIndicators: const ['Global GHG Emissions', 'Emissions Gap', 'Temperature Projection'],
      upscRelevance:
          'Climate change, NDCs, Paris Agreement, COP and energy transition (GS-III)',
      prelimsRelevance: RelevanceLevel.high,
      mainsRelevance: RelevanceLevel.high,
      essayRelevance: RelevanceLevel.medium,
      interviewRelevance: RelevanceLevel.medium,
      themes: const ['Climate Change', 'Emissions', 'NDC', 'Paris Agreement'],
      sectors: const ['Environment', 'Energy'],
      relatedArticleIds: const ['Article 48A', 'Article 51A'],
      relatedActIds: const ['Environment (Protection) Act, 1986'],
      relatedCommitteeIds: const [],
      relatedSchemeNames: const ['National Mission for a Green India'],
      relatedCaseLawIds: const [],
      relatedDoctrineIds: const [],
      relatedCurrentAffairsIds: const ['ca_cop28'],
      relatedPyqIds: const ['PYQ_UPSC_CSE_2023_GS3_Q002'],
      relatedBodies: const ['bod_cpcb'],
      relatedInternationalOrganisations: const ['int_unep', 'int_unfccc'],
      relationships: const [],
      sdgGoals: const ['SDG 13 - Climate Action'],
      evidenceIds: const ['ev_unep_egr_2024_official'],
      keywords: const ['UNEP', 'Emissions Gap', 'GHG', 'Climate', 'NDC'],
    ),
  ];
}
