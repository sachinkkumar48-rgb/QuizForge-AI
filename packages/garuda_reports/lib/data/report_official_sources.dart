library;

/// Official-source registry for the Phase-I Reports & Indices corpus.
///
/// Maps every corpus record (Report, Index, Survey, Indicator) to its official
/// portal/source URL and every attached evidence ID to a canonical, traceable
/// official reference. Each entry is a real Government of India, UN-system or
/// multilateral publisher domain. `ReportCorpusSupport` consumes this registry
/// so that no corpus record can exist without a resolvable official source and
/// evidence reference, and so evidence coverage can be measured objectively.
class ReportOfficialSources {
  ReportOfficialSources._();

  /// Date the Phase-I corpus facts were last verified against official
  /// publications. Applied as `lastVerifiedDate` to every seeded record.
  static const String corpusLastVerifiedDate = '2026-08-08';

  /// Canonical official source URL per corpus record ID.
  static const Map<String, String> sourceUrl = {
    // ---- Reports: Indian official publications ----
    'rep_es_2024_25': 'https://www.indiabudget.gov.in/economicsurvey/',
    'rep_ub_2025_26': 'https://www.indiabudget.gov.in/',
    'rep_iyb_2025': 'https://www.publicationsdivision.nic.in/',
    'rep_fc15_2021_26': 'https://fincomindia.nic.in/',
    'rep_fc16_2026': 'https://fincomindia.nic.in/',
    'rep_cag_2024': 'https://cag.gov.in/',
    'rep_rbi_ar_2023_24': 'https://www.rbi.org.in/',
    'rep_sebi_ar_2023_24': 'https://www.sebi.gov.in/',
    'rep_ncrb_cii_2022': 'https://ncrb.gov.in/',
    'rep_isfr_2023': 'https://fsi.nic.in/',
    'rep_adsi_2022': 'https://ncrb.gov.in/',
    'rep_census_2011': 'https://censusindia.gov.in/',
    'rep_soia_2024': 'https://desagri.gov.in/',
    'rep_udise_2023_24': 'https://udiseplus.gov.in/',
    'rep_nha_2020_21': 'https://nhsrcindia.org/',
    'rep_cea_2023_24': 'https://cea.nic.in/annual-report/',
    // ---- Reports: NITI Aayog & international/multilateral ----
    'rep_niti_adp_2024': 'https://www.niti.gov.in/aspirational-districts-programme',
    'rep_wdr_2024': 'https://www.worldbank.org/en/publication/wdr2024',
    'rep_imf_weo_oct_2024': 'https://www.imf.org/en/Publications/WEO',
    'rep_unesco_gem_2024': 'https://www.unesco.org/gem-report/',
    'rep_unicef_sowc_2024': 'https://www.unicef.org/reports/state-of-worlds-children',
    'rep_fao_sofi_2024': 'https://www.fao.org/publications/sofi',
    'rep_who_whs_2024':
        'https://www.who.int/data/gho/publications/world-health-statistics',
    'rep_ipcc_ar6_2023': 'https://www.ipcc.ch/report/ar6/syr/',
    'rep_undp_hdr_2023_24': 'https://hdr.undp.org/',
    'rep_un_wpp_2024': 'https://population.un.org/wpp/',
    'rep_wpfi_2024': 'https://rsf.org/en/index',
    'rep_cpi_2024': 'https://www.transparency.org/en/cpi',
    'rep_ilo_weso_2024':
        'https://www.ilo.org/publications/world-employment-and-social-outlook-trends-2024',
    'rep_wto_wtr_2024': 'https://www.wto.org/english/res_e/booksp_e/wtr24_e/wtr24_e.htm',
    'rep_unep_egr_2024': 'https://www.unep.org/resources/emissions-gap-report-2024',
    // ---- Indices & rankings ----
    'idx_sdg_2023_24': 'https://www.niti.gov.in/sdg-india-index',
    'idx_mpi_2023': 'https://www.niti.gov.in/',
    'idx_ghi_2024': 'https://www.globalhungerindex.org/',
    'idx_gii_2024': 'https://www.wipo.int/global_innovation_index/',
    'idx_hdi_2023_24': 'https://hdr.undp.org/',
    'idx_ggg_2024': 'https://www.weforum.org/publications/gender-gap/',
    'idx_eodb_2020':
        'https://www.worldbank.org/en/programs/business-enabling-environment',
    'idx_leads_2024': 'https://www.dpiit.gov.in/',
    'idx_epi_2024': 'https://epi.yale.edu/',
    // ---- Surveys ----
    'srv_nfhs5_2019_21': 'https://rchiips.org/nfhs/',
    'srv_plfs_2022_23': 'https://mospi.gov.in/periodic-labour-force-survey',
    'srv_hces_2022_23': 'https://mospi.gov.in/',
    'srv_asi_2022_23': 'https://mospi.gov.in/annual-survey-industries',
    // ---- Indicators (source publication URL) ----
    'ind_tfr_2_0': 'https://rchiips.org/nfhs/',
    'ind_stunting_35_5': 'https://rchiips.org/nfhs/',
    'ind_institutional_births_88_6': 'https://rchiips.org/nfhs/',
    'ind_unemployment_3_2': 'https://mospi.gov.in/periodic-labour-force-survey',
    'ind_lfpr_57_9': 'https://mospi.gov.in/periodic-labour-force-survey',
    'ind_mpce_rural_3773': 'https://mospi.gov.in/',
    'ind_mpce_urban_6459': 'https://mospi.gov.in/',
    'ind_gdp_growth_8_2': 'https://www.indiabudget.gov.in/economicsurvey/',
    'ind_cpi_5_4': 'https://mospi.gov.in/',
    'ind_gross_npa_2_8': 'https://www.rbi.org.in/',
    'ind_forest_cover_25_17': 'https://fsi.nic.in/',
    'ind_hdi_0_644': 'https://hdr.undp.org/',
    'ind_hdi_rank_134': 'https://hdr.undp.org/',
    'ind_ghi_score_27_3': 'https://www.globalhungerindex.org/',
    'ind_gii_rank_39': 'https://www.wipo.int/global_innovation_index/',
    'ind_gender_gap_0_641': 'https://www.weforum.org/publications/gender-gap/',
    'ind_mpi_14_96': 'https://www.niti.gov.in/',
    'ind_population_2024': 'https://population.un.org/wpp/',
    'ind_cpi_score_39': 'https://www.transparency.org/en/cpi',
    'ind_cpi_rank_93': 'https://www.transparency.org/en/cpi',
    'ind_wpfi_rank_159': 'https://rsf.org/en/index',
    'ind_literacy_2011': 'https://censusindia.gov.in/',
    'ind_sex_ratio_2011': 'https://censusindia.gov.in/',
    'ind_agri_gva_18': 'https://desagri.gov.in/',
    'ind_oope_37_4': 'https://nhsrcindia.org/',
  };

  /// Canonical official reference URL per evidence ID attached to corpus
  /// records. Every evidence ID used anywhere in the corpus resolves here,
  /// making evidence coverage measurable.
  static const Map<String, String> evidenceSourceUrl = {
    // Reports
    'ev_es_2025_official': 'https://www.indiabudget.gov.in/economicsurvey/',
    'ev_ub_2025_official': 'https://www.indiabudget.gov.in/',
    'ev_iyb_2025_official': 'https://www.publicationsdivision.nic.in/',
    'ev_fc15_official': 'https://fincomindia.nic.in/',
    'ev_fc16_official': 'https://fincomindia.nic.in/',
    'ev_cag_official': 'https://cag.gov.in/',
    'ev_rbi_ar_official': 'https://www.rbi.org.in/',
    'ev_sebi_ar_official': 'https://www.sebi.gov.in/',
    'ev_ncrb_cii_official': 'https://ncrb.gov.in/',
    'ev_isfr_2023_official': 'https://fsi.nic.in/',
    'ev_adsi_2022_official': 'https://ncrb.gov.in/',
    'ev_census_2011_official': 'https://censusindia.gov.in/',
    'ev_soia_2024_official': 'https://desagri.gov.in/',
    'ev_udise_2023_24_official': 'https://udiseplus.gov.in/',
    'ev_nha_2020_21_official': 'https://nhsrcindia.org/',
    'ev_cea_2023_24_official': 'https://cea.nic.in/annual-report/',
    'ev_niti_adp_official': 'https://www.niti.gov.in/aspirational-districts-programme',
    'ev_wdr_2024_official': 'https://www.worldbank.org/en/publication/wdr2024',
    'ev_imf_weo_official': 'https://www.imf.org/en/Publications/WEO',
    'ev_gem_2024_official': 'https://www.unesco.org/gem-report/',
    'ev_sowc_2024_official': 'https://www.unicef.org/reports/state-of-worlds-children',
    'ev_sofi_2024_official': 'https://www.fao.org/publications/sofi',
    'ev_who_whs_official':
        'https://www.who.int/data/gho/publications/world-health-statistics',
    'ev_ipcc_ar6_official': 'https://www.ipcc.ch/report/ar6/syr/',
    'ev_hdr_2024_official': 'https://hdr.undp.org/',
    'ev_undp_hdr_2023_24_official': 'https://hdr.undp.org/',
    'ev_un_wpp_2024_official': 'https://population.un.org/wpp/',
    'ev_wpfi_2024_official': 'https://rsf.org/en/index',
    'ev_cpi_2024_official': 'https://www.transparency.org/en/cpi',
    'ev_ilo_weso_2024_official':
        'https://www.ilo.org/publications/world-employment-and-social-outlook-trends-2024',
    'ev_wtr_2024_official':
        'https://www.wto.org/english/res_e/booksp_e/wtr24_e/wtr24_e.htm',
    'ev_unep_egr_2024_official': 'https://www.unep.org/resources/emissions-gap-report-2024',
    // Indices
    'ev_sdg_index_official': 'https://www.niti.gov.in/sdg-india-index',
    'ev_mpi_2023_official': 'https://www.niti.gov.in/',
    'ev_ghi_2024_official': 'https://www.globalhungerindex.org/',
    'ev_gii_2024_official': 'https://www.wipo.int/global_innovation_index/',
    'ev_ggg_2024_official': 'https://www.weforum.org/publications/gender-gap/',
    'ev_eodb_2020_official':
        'https://www.worldbank.org/en/programs/business-enabling-environment',
    'ev_leads_2024_official': 'https://www.dpiit.gov.in/',
    'ev_epi_2024_official': 'https://epi.yale.edu/',
    // Surveys
    'ev_nfhs5_official': 'https://rchiips.org/nfhs/',
    'ev_plfs_official': 'https://mospi.gov.in/periodic-labour-force-survey',
    'ev_hces_official': 'https://mospi.gov.in/',
    'ev_hces_2022_23_official': 'https://mospi.gov.in/',
    'ev_asi_official': 'https://mospi.gov.in/annual-survey-industries',
  };

  /// Resolves the official URL for a corpus record ID, or empty string when
  /// the record is not part of the seeded corpus.
  static String sourceUrlFor(String id) => sourceUrl[id] ?? '';

  /// Resolves the canonical official URL for an evidence ID, or empty string
  /// when the evidence reference is not registered.
  static String evidenceUrlFor(String evidenceId) =>
      evidenceSourceUrl[evidenceId] ?? '';

  /// Whether a corpus record's evidence is fully traceable: every attached
  /// evidence ID must resolve to a registered official URL.
  static bool evidenceResolvable(Iterable<String> evidenceIds) {
    if (evidenceIds.isEmpty) return false;
    return evidenceIds.every((id) => evidenceUrlFor(id).isNotEmpty);
  }
}
