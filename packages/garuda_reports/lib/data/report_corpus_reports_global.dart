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
      relatedPyqIds: ['PYQ_GS2_2022_Q10'],
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
      relatedPyqIds: ['PYQ_GS3_2021_Q01'],
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
      relatedPyqIds: ['PYQ_GS3_2023_Q02'],
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
      relatedPyqIds: ['PYQ_GS2_2021_Q05'],
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
      relatedPyqIds: ['PYQ_GS1_2023_Q09'],
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
      relatedArticleIds: [],
      relatedActIds: ['National Food Security Act, 2013'],
      relatedSchemeNames: [
        'PM POSHAN',
        'POSHAN Abhiyaan',
        'Public Distribution System'
      ],
      relatedCurrentAffairsIds: ['ca_sofi_2024', 'ca_global_hunger'],
      relatedPyqIds: ['PYQ_GS1_2022_Q11', 'PYQ_GS3_2021_Q09'],
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
      relatedPyqIds: ['PYQ_GS2_2022_Q07'],
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
      relatedPyqIds: ['PYQ_GS1_2024_Q18', 'PYQ_GS3_2022_Q16'],
      evidenceIds: ['ev_ipcc_ar6_official'],
      keywords: [
        'IPCC',
        'Climate Change',
        'AR6',
        'Global Warming',
        '1.5 Degree'
      ],
    ),
  ];
}
