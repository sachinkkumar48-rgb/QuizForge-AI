library;

/// Official-source registry for the Phase-I Schemes corpus.
///
/// Maps every corpus scheme ID to its official portal/source URL and a
/// canonical evidence reference. This is the evidence layer: each entry is a
/// real, traceable Government of India source. `SchemeCorpusSupport` consumes
/// this registry so that every Scheme Knowledge Object carries a mandatory
/// `officialSource` and non-empty `evidenceIds`.
class SchemeOfficialSources {
  SchemeOfficialSources._();

  static const Map<String, String> sourceUrl = {
    // Agriculture, Rural Development & Food Security
    'sch_pm_kisan': 'https://www.pmkisan.gov.in/',
    'sch_pmfby': 'https://pmfby.gov.in/',
    'sch_pmksy': 'https://pmksy.gov.in/',
    'sch_pm_kusum': 'https://pmkusum.mnre.gov.in/',
    'sch_soil_health_card': 'https://www.soilhealth.dac.gov.in/',
    'sch_nfsm': 'https://www.nfsm.gov.in/',
    'sch_pkvy': 'https://pgsindia-ncof.gov.in/PKVY/',
    'sch_kcc': 'https://agriwelfare.gov.in/',
    'sch_aif': 'https://agriinfra.dac.gov.in/',
    'sch_mgnrega': 'https://nrega.nic.in/',
    'sch_pmay_gramin': 'https://pmayg.nic.in/',
    'sch_pmgsy': 'https://pmgsy.nic.in/',
    'sch_nrlm': 'https://aajeevika.gov.in/',
    'sch_rurban': 'https://rurban.gov.in/',
    'sch_pmgkay': 'https://dfpd.gov.in/',
    // Health, Education, Women & Children, Social Justice, Tribal
    'sch_pm_jay': 'https://pmjay.gov.in/',
    'sch_nhm': 'https://nhm.gov.in/',
    'sch_pm_abhim': 'https://abnhpm.mohfw.gov.in/',
    'sch_indradhanush': 'https://nhm.gov.in/',
    'sch_janaushadhi': 'https://janaushadhi.gov.in/',
    'sch_samagra_shiksha': 'https://samagra.education.gov.in/',
    'sch_pm_poshan': 'https://pmposhan.education.gov.in/',
    'sch_nipun': 'https://www.education.gov.in/nipun-bharat/',
    'sch_pm_shri': 'https://www.education.gov.in/pm-shri/',
    'sch_bbbp': 'https://wcd.nic.in/',
    'sch_poshan_abhiyaan': 'https://poshanabhiyaan.gov.in/',
    'sch_pmmvy': 'https://pmmvy.wcd.gov.in/',
    'sch_mission_shakti': 'https://wcd.nic.in/',
    'sch_icds': 'https://icds-wcd.nic.in/',
    'sch_pm_janman': 'https://tribal.nic.in/',
    'sch_emrs': 'https://tribal.nic.in/',
    'sch_van_dhan': 'https://tribal.nic.in/',
    'sch_pm_daksh': 'https://socialjustice.gov.in/',
    // Financial Inclusion, Employment, Skill, MSME/Industry
    'sch_pmjdy': 'https://pmjdy.gov.in/',
    'sch_mudra': 'https://www.mudra.org.in/',
    'sch_apy': 'https://www.jansuraksha.gov.in/',
    'sch_pmsby': 'https://www.jansuraksha.gov.in/',
    'sch_pmjjby': 'https://www.jansuraksha.gov.in/',
    'sch_stand_up': 'https://www.standupmitra.in/',
    'sch_svanidhi': 'https://pmsvanidhi.mohua.gov.in/',
    'sch_startup_india': 'https://www.startupindia.gov.in/',
    'sch_pm_vishwakarma': 'https://pmvishwakarma.gov.in/',
    'sch_pmkvy': 'https://www.msde.gov.in/',
    'sch_skill_india': 'https://www.msde.gov.in/',
    'sch_abry': 'https://labour.gov.in/',
    'sch_pmegp': 'https://www.kviconline.gov.in/',
    'sch_pli': 'https://dpiit.gov.in/',
    'sch_fame': 'https://fame2.heavyindustries.gov.in/',
    // Housing, Water & Sanitation, Energy, Infrastructure, Digital, Env, S&T
    'sch_pmay_urban': 'https://pmay-urban.gov.in/',
    'sch_jjm': 'https://jalshakti-ddws.gov.in/',
    'sch_sbm_gramin': 'https://swachhbharatmission.gov.in/',
    'sch_sbm_urban': 'https://swachhbharatmission.gov.in/',
    'sch_amrut': 'https://mohua.gov.in/',
    'sch_namami_gange': 'https://nmcg.nic.in/',
    'sch_ujjwala': 'https://www.pmuy.gov.in/',
    'sch_saubhagya': 'https://saubhagya.gov.in/',
    'sch_ujala': 'https://www.ujala.gov.in/',
    'sch_pm_surya_ghar': 'https://pmsuryaghar.gov.in/',
    'sch_gati_shakti': 'https://gatishekti.in/',
    'sch_bharatmala': 'https://morth.gov.in/',
    'sch_udan': 'https://www.civilaviation.gov.in/',
    'sch_bharatnet': 'https://www.bharatnet.in/',
    'sch_digital_india': 'https://www.digitalindia.gov.in/',
    'sch_green_india': 'https://moef.gov.in/',
    'sch_ncap': 'https://moef.gov.in/',
    'sch_nsm': 'https://www.nsmindia.org/',
    'sch_deep_ocean': 'https://moes.gov.in/',
  };

  static String evidenceIdFor(String schemeId) => 'ev_${schemeId}_official';
}
