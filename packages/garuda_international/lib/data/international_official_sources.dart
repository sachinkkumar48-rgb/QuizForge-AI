library;

/// Official-source registry for the Phase-I International corpus.
///
/// Maps every corpus organisation ID to its official portal/source URL and a
/// canonical evidence reference. Each entry is a real, traceable source: the
/// organisation's own official website, the UN/treaty depository, or the
/// official Government of India (Ministry of External Affairs) page where the
/// body has no permanent secretariat. `InternationalCorpusSupport` consumes
/// this registry so that every International Knowledge Object carries a
/// mandatory `officialSource` and non-empty `evidenceIds`.
class InternationalOfficialSources {
  InternationalOfficialSources._();

  static const Map<String, String> sourceUrl = {
    // United Nations System
    'int_un': 'https://www.un.org/',
    'int_unsc': 'https://main.un.org/securitycouncil/',
    'int_unga': 'https://www.un.org/en/ga/',
    'int_icj': 'https://www.icj-cij.org/',
    'int_icc': 'https://www.icc-cpi.int/',
    'int_unhrc': 'https://www.ohchr.org/en/hrbodies/hrc',
    'int_unctad': 'https://unctad.org/',
    'int_undp': 'https://www.undp.org/',
    'int_unep': 'https://www.unep.org/',
    'int_unesco': 'https://www.unesco.org/',
    'int_unicef': 'https://www.unicef.org/',
    'int_unhcr': 'https://www.unhcr.org/',
    'int_unwomen': 'https://www.unwomen.org/',
    'int_fao': 'https://www.fao.org/',
    'int_who': 'https://www.who.int/',
    'int_wfp': 'https://www.wfp.org/',
    'int_ilo': 'https://www.ilo.org/',
    'int_imo': 'https://www.imo.org/',
    'int_icao': 'https://www.icao.int/',
    'int_wipo': 'https://www.wipo.int/',
    // Bretton Woods / Finance / Trade
    'int_imf': 'https://www.imf.org/',
    'int_world_bank': 'https://www.worldbank.org/',
    'int_ida': 'https://ida.worldbank.org/',
    'int_ifc': 'https://www.ifc.org/',
    'int_miga': 'https://www.miga.org/',
    'int_bis': 'https://www.bis.org/',
    'int_adb': 'https://www.adb.org/',
    'int_aiib': 'https://www.aiib.org/',
    'int_ndb': 'https://www.ndb.int/',
    'int_afdb': 'https://www.afdb.org/',
    'int_ifad': 'https://www.ifad.org/',
    'int_wto': 'https://www.wto.org/',
    'int_oecd': 'https://www.oecd.org/',
    'int_fatf': 'https://www.fatf-gafi.org/',
    'int_fsb': 'https://www.fsb.org/',
    'int_iea': 'https://www.iea.org/',
    'int_irena': 'https://www.irena.org/',
    // Regional / Political Groupings
    'int_g20': 'https://www.g20.org/',
    'int_g7': 'https://www.g7italy.it/en/',
    'int_brics': 'https://www.mea.gov.in/',
    'int_sco': 'https://sco-sec.org/',
    'int_asean': 'https://asean.org/',
    'int_arf': 'https://aseanregionalforum.asean.org/',
    'int_saarc': 'https://www.saarc-sec.org/',
    'int_bimstec': 'https://bimstec.org/',
    'int_quad': 'https://www.mea.gov.in/',
    'int_iora': 'https://www.iora.int/',
    'int_ibsa': 'https://www.mea.gov.in/',
    'int_commonwealth': 'https://thecommonwealth.org/',
    'int_eu': 'https://europa.eu/',
    'int_au': 'https://au.int/',
    // Security / Strategic Organisations
    'int_nato': 'https://www.nato.int/',
    'int_interpol': 'https://www.interpol.int/',
    'int_ctbto': 'https://www.ctbto.org/',
    'int_opcw': 'https://www.opcw.org/',
    'int_iaea': 'https://www.iaea.org/',
    'int_nsg': 'https://nuclearsuppliersgroup.org/',
    'int_mtcr': 'https://mtcr.info/',
    'int_wassenaar': 'https://www.wassenaar.org/',
    // Environment / Climate
    'int_unfccc': 'https://unfccc.int/',
    'int_ipcc': 'https://www.ipcc.ch/',
    'int_cbd': 'https://www.cbd.int/',
    'int_iucn': 'https://www.iucn.org/',
    'int_gcf': 'https://www.greenclimate.fund/',
    'int_gef': 'https://www.thegef.org/',
    'int_isa': 'https://isolaralliance.org/',
  };

  static String evidenceIdFor(String id) => 'ev_${id}_official';
}
