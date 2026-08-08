library;

/// Official-source registry for the Phase-I Bodies corpus.
///
/// Maps every corpus body ID to its official portal/source URL and a canonical
/// evidence reference. Each entry is a real, traceable Government of India
/// source (official portal, constitutional text repository, or statutory
/// authority domain). `BodyCorpusSupport` consumes this registry so that every
/// Body Knowledge Object carries a mandatory `officialSource` and non-empty
/// `evidenceIds`.
class BodyOfficialSources {
  BodyOfficialSources._();

  static const Map<String, String> sourceUrl = {
    // Constitutional Bodies
    'bod_eci': 'https://eci.gov.in/',
    'bod_upsc': 'https://www.upsc.gov.in/',
    'bod_finance_commission': 'https://fincomindia.nic.in/',
    'bod_cag': 'https://cag.gov.in/',
    'bod_attorney_general': 'https://legalaffairs.gov.in/',
    'bod_state_psc': 'https://www.indiacode.nic.in/',
    'bod_state_election_commissions': 'https://www.indiacode.nic.in/',
    'bod_state_finance_commissions': 'https://www.indiacode.nic.in/',
    'bod_ncsc': 'https://ncsc.nic.in/',
    'bod_ncst': 'https://ncst.nic.in/',
    'bod_ncbc': 'https://ncbc.nic.in/',
    // Statutory / Regulatory / National Bodies
    'bod_cic': 'https://cic.gov.in/',
    'bod_cvc': 'https://cvc.gov.in/',
    'bod_lokpal': 'https://lokpal.gov.in/',
    'bod_nhrc': 'https://nhrc.nic.in/',
    'bod_ncw': 'https://ncw.gov.in/',
    'bod_ncm': 'https://ncm.nic.in/',
    'bod_ncdrc': 'https://ncdrc.nic.in/',
    'bod_cci': 'https://www.cci.gov.in/',
    'bod_sebi': 'https://www.sebi.gov.in/',
    'bod_rbi': 'https://www.rbi.org.in/',
    'bod_trai': 'https://www.trai.gov.in/',
    'bod_irdai': 'https://www.irdai.gov.in/',
    'bod_pfrda': 'https://www.pfrda.org.in/',
    'bod_ngt': 'https://www.greentribunal.gov.in/',
    'bod_cpcb': 'https://cpcb.nic.in/',
    'bod_ndma': 'https://ndma.gov.in/',
    'bod_fssai': 'https://www.fssai.gov.in/',
    'bod_nmc': 'https://www.nmc.org.in/',
    'bod_ugc': 'https://www.ugc.gov.in/',
    'bod_aicte': 'https://www.aicte-india.org/',
    'bod_ncism': 'https://ncismindia.org/',
    'bod_ncahp': 'https://main.mohfw.gov.in/',
    'bod_nia': 'https://nia.gov.in/',
    'bod_ibbi': 'https://www.ibbi.gov.in/',
    'bod_ncpcr': 'https://ncpcr.gov.in/',
    'bod_uidai': 'https://uidai.gov.in/',
    'bod_cerc': 'https://cercind.gov.in/',
    'bod_aptel': 'https://aptel.gov.in/',
    'bod_nabard': 'https://www.nabard.org/',
    'bod_sidbi': 'https://www.sidbi.in/',
    'bod_ifsca': 'https://ifsca.gov.in/',
    'bod_cbi': 'https://cbi.gov.in/',
  };

  static String evidenceIdFor(String bodyId) => 'ev_${bodyId}_official';
}
