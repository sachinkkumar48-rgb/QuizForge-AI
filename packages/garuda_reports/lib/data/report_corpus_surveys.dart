library;

import '../domain/entities/report_enums.dart';
import '../domain/entities/report_statistic.dart';
import '../domain/entities/survey_knowledge_object.dart';

/// Phase-I Seed Corpus - Official statistical surveys.
class ReportCorpusSurveys {
  static final List<SurveyKnowledgeObject> surveys = [
    // 1. NFHS-5 (2019-21)
    SurveyKnowledgeObject(
      id: 'srv_nfhs5_2019_21',
      officialTitle: 'National Family Health Survey (NFHS-5), 2019-21',
      shortName: 'NFHS-5',
      publishingOrganisation:
          'International Institute for Population Sciences (IIPS)',
      publishingMinistry: 'Ministry of Health and Family Welfare',
      surveyYear: 2021,
      referencePeriod: '2019-21 (conducted in two phases)',
      frequency: PublicationFrequency.periodic,
      sampleSize: '6,36,699 households',
      sampleFrame:
          'Nationally representative sample of households across India',
      methodology:
          'Household interviews covering demographic, health and nutrition indicators; conducted by IIPS under the aegis of the MoHFW.',
      officialUrl: 'https://rchiips.org/nfhs/',
      executiveSummary:
          'NFHS-5 is the fifth round of the National Family Health Survey. It reported the Total Fertility Rate declining to 2.0, institutional births at 88.6 per cent and continuing improvement in child immunisation.',
      objectives: [
        'Provide evidence on population, health and nutrition',
        'Monitor progress under national health and nutrition programmes',
      ],
      keyFindings: [
        'Total Fertility Rate (TFR) declined to 2.0, reaching replacement level',
        'Institutional births rose to 88.6 per cent',
        'Stunting among children under five stood at 35.5 per cent',
        'Full immunisation coverage of children improved to 76.4 per cent',
        'Sex ratio at birth improved to 929 females per 1,000 males',
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_nfhs5_tfr',
          label: 'Total Fertility Rate',
          value: '2.0',
          unit: 'children per woman',
          referenceYear: 2021,
          source: 'NFHS-5',
        ),
        ReportStatistic(
          id: 'st_nfhs5_institutional',
          label: 'Institutional births',
          value: '88.6',
          unit: 'per cent',
          referenceYear: 2021,
          source: 'NFHS-5',
        ),
        ReportStatistic(
          id: 'st_nfhs5_stunting',
          label: 'Stunting among children under five',
          value: '35.5',
          unit: 'per cent',
          referenceYear: 2021,
          source: 'NFHS-5',
        ),
        ReportStatistic(
          id: 'st_nfhs5_immunisation',
          label: 'Full immunisation coverage',
          value: '76.4',
          unit: 'per cent',
          referenceYear: 2021,
          source: 'NFHS-5',
        ),
      ],
      upscRelevance:
          'NFHS-5 data (TFR, stunting, immunisation, institutional births) is heavily tested in UPSC Prelims and GS1/GS2. The decline of TFR to replacement level is a landmark data point.',
      relatedActIds: [
        'Pre-conception and Pre-natal Diagnostic Techniques Act, 1994'
      ],
      relatedSchemeNames: [
        'POSHAN Abhiyaan',
        'National Health Mission',
        'Mission Indradhanush'
      ],
      relatedCurrentAffairsIds: ['ca_nfhs5'],
      relatedPyqIds: [
        'PYQ_UPSC_CSE_2023_GS1_Q011',
        'PYQ_UPSC_CSE_2022_GS1_Q009',
        'PYQ_UPSC_CSE_2021_GS2_Q006'
      ],
      evidenceIds: ['ev_nfhs5_official'],
      keywords: [
        'NFHS',
        'TFR',
        'Fertility Rate',
        'Stunting',
        'Immunisation',
        'Health'
      ],
    ),

    // 2. PLFS Annual Report 2022-23
    SurveyKnowledgeObject(
      id: 'srv_plfs_2022_23',
      officialTitle:
          'Periodic Labour Force Survey (PLFS) Annual Report 2022-23',
      shortName: 'PLFS 2022-23',
      publishingOrganisation: 'National Sample Survey Office (NSSO)',
      publishingMinistry: 'Ministry of Statistics and Programme Implementation',
      surveyYear: 2023,
      referencePeriod: 'July 2022 - June 2023',
      frequency: PublicationFrequency.annual,
      sampleSize: 'Nationally representative household sample',
      sampleFrame:
          'All States and Union Territories covering urban and rural areas',
      methodology:
          'Usual Status (CWS/PS+SS), Current Weekly Status and Current Daily Status measurement of employment using household interview schedules.',
      officialUrl: 'https://mospi.gov.in/periodic-labour-force-survey',
      executiveSummary:
          'PLFS 2022-23 reports the unemployment rate (usual status) for persons aged 15+ at 3.2 per cent, with labour force participation rising to 57.9 per cent.',
      objectives: [
        'Estimate key employment and unemployment indicators',
        'Provide quarterly urban and annual estimates',
      ],
      keyFindings: [
        'Unemployment rate (usual status, 15+): 3.2 per cent',
        'Labour Force Participation Rate (usual status, 15+): 57.9 per cent',
        'Worker Population Ratio (usual status, 15+): 55.0 per cent',
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_plfs_ur',
          label: 'Unemployment rate (usual status, 15+)',
          value: '3.2',
          unit: 'per cent',
          referenceYear: 2023,
          source: 'PLFS 2022-23',
        ),
        ReportStatistic(
          id: 'st_plfs_lfpr',
          label: 'Labour Force Participation Rate (15+)',
          value: '57.9',
          unit: 'per cent',
          referenceYear: 2023,
          source: 'PLFS 2022-23',
        ),
        ReportStatistic(
          id: 'st_plfs_wpr',
          label: 'Worker Population Ratio (15+)',
          value: '55.0',
          unit: 'per cent',
          referenceYear: 2023,
          source: 'PLFS 2022-23',
        ),
      ],
      upscRelevance:
          'PLFS employment indicators (LFPR, WPR, UR) are a core UPSC GS3 topic (employment). NSSO/MoSPI data is routinely cited in Mains answers.',
      relatedActIds: [],
      relatedSchemeNames: ['PM-KISAN', 'MNREGA', 'Skill India'],
      relatedCurrentAffairsIds: ['ca_plfs_2023'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2023_GS3_Q005', 'PYQ_UPSC_CSE_2021_GS3_Q008'],
      evidenceIds: ['ev_plfs_official'],
      keywords: ['PLFS', 'Labour Force', 'Unemployment', 'NSSO', 'MoSPI'],
    ),

    // 3. Household Consumption Expenditure Survey 2022-23
    SurveyKnowledgeObject(
      id: 'srv_hces_2022_23',
      officialTitle: 'Household Consumption Expenditure Survey (HCES) 2022-23',
      shortName: 'HCES 2022-23',
      publishingOrganisation: 'National Sample Survey Office (NSSO)',
      publishingMinistry: 'Ministry of Statistics and Programme Implementation',
      surveyYear: 2024,
      referencePeriod: 'August 2022 - July 2023',
      frequency: PublicationFrequency.periodic,
      sampleSize: '2,61,746 households',
      sampleFrame: 'All States and UTs, both rural and urban',
      methodology:
          'Household interviews capturing consumption of food and non-food items using a modified reference period (7/30/365 days).',
      officialUrl: 'https://mospi.gov.in/',
      executiveSummary:
          'The HCES 2022-23 estimated average Monthly Per Capita Consumption Expenditure (MPCE) at Rs 3,773 in rural areas and Rs 6,459 in urban areas - the first official consumption survey results since 2011-12.',
      objectives: [
        'Estimate household consumption expenditure at national and state level',
        'Provide the basis for poverty estimation and revising consumer price indices',
      ],
      keyFindings: [
        'Average MPCE: Rs 3,773 in rural and Rs 6,459 in urban India',
        'First consumption estimates since the 2017-18 survey was not released',
      ],
      importantStatistics: const [
        ReportStatistic(
          id: 'st_hces_rural',
          label: 'Average MPCE - rural India',
          value: '3,773',
          unit: 'rupees per month',
          referenceYear: 2023,
          source: 'HCES 2022-23',
        ),
        ReportStatistic(
          id: 'st_hces_urban',
          label: 'Average MPCE - urban India',
          value: '6,459',
          unit: 'rupees per month',
          referenceYear: 2023,
          source: 'HCES 2022-23',
        ),
      ],
      upscRelevance:
          'HCES data underpins poverty estimation and inflation measurement; highly relevant to UPSC GS3 (poverty, economy) and for questions on the survey\'s methodology.',
      relatedSchemeNames: [
        'Antyodaya Anna Yojana',
        'Public Distribution System'
      ],
      relatedCurrentAffairsIds: ['ca_hces_2024'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2024_GS3_Q008', 'PYQ_UPSC_CSE_2022_GS3_Q003'],
      evidenceIds: ['ev_hces_official'],
      keywords: ['HCES', 'Consumption Expenditure', 'NSSO', 'MPCE', 'Poverty'],
    ),

    // 4. Annual Survey of Industries 2022-23
    SurveyKnowledgeObject(
      id: 'srv_asi_2022_23',
      officialTitle: 'Annual Survey of Industries (ASI) 2022-23',
      shortName: 'ASI 2022-23',
      publishingOrganisation: 'National Sample Survey Office (NSSO)',
      publishingMinistry: 'Ministry of Statistics and Programme Implementation',
      surveyYear: 2025,
      referencePeriod: '2022-23',
      frequency: PublicationFrequency.annual,
      sampleSize: 'Census-cum-sample of registered factories',
      sampleFrame: 'Factories registered under the Factories Act, 1948',
      methodology:
          'Annual industrial statistics survey of registered factories covering employment, output, value added and capital formation.',
      officialUrl: 'https://mospi.gov.in/annual-survey-industries',
      executiveSummary:
          'The Annual Survey of Industries provides estimates of growth, structure and performance of the registered manufacturing and industrial sector in India.',
      objectives: [
        'Estimate structural and performance indicators of the industrial sector',
        'Compute gross value added and employment in registered factories',
      ],
      keyFindings: [
        'Covers factories registered under the Factories Act, 1948',
        'Feeds into estimates of industrial growth and gross value added',
      ],
      upscRelevance:
          'ASI data supports UPSC GS3 (industrial policy, manufacturing) answers and is the source for the Index of Industrial Production sample frame.',
      relatedActIds: ['Factories Act, 1948'],
      relatedSchemeNames: ['Make in India', 'PLI Schemes'],
      relatedCurrentAffairsIds: ['ca_asi_2023'],
      relatedPyqIds: ['PYQ_UPSC_CSE_2022_GS3_Q004'],
      evidenceIds: ['ev_asi_official'],
      keywords: ['ASI', 'Annual Survey of Industries', 'Manufacturing', 'GVA'],
    ),
  ];
}
