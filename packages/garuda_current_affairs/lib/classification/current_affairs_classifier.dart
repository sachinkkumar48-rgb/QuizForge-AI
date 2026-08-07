library;

import '../domain/entities/current_affairs_enums.dart';

/// Automated classification engine mapping current events into 13 UPSC subject categories.
class CurrentAffairsClassifier {
  static CurrentAffairsCategory classify({
    required String headline,
    required String summary,
    required String content,
    String officialSource = '',
    String ministry = '',
  }) {
    final text = '$headline $summary $content $officialSource $ministry'.toLowerCase();

    // 1. Polity
    if (text.contains('constitution') ||
        text.contains('parliament') ||
        text.contains('supreme court') ||
        text.contains('high court') ||
        text.contains('governor') ||
        text.contains('president') ||
        text.contains('election commission') ||
        text.contains('bill passed') ||
        text.contains('amendment') ||
        text.contains('judicial review') ||
        text.contains('fundamental right') ||
        text.contains('federalism')) {
      return CurrentAffairsCategory.polity;
    }

    // 2. Governance
    if (text.contains('scheme') ||
        text.contains('yojana') ||
        text.contains('e-governance') ||
        text.contains('transparency') ||
        text.contains('rti') ||
        text.contains('citizen charter') ||
        text.contains('niti aayog') ||
        text.contains('cag') ||
        text.contains('civil services') ||
        text.contains('public service')) {
      return CurrentAffairsCategory.governance;
    }

    // 3. Economy
    if (text.contains('rbi') ||
        text.contains('repo rate') ||
        text.contains('gdp') ||
        text.contains('inflation') ||
        text.contains('fiscal') ||
        text.contains('monetary') ||
        text.contains('gst') ||
        text.contains('sebi') ||
        text.contains('banking') ||
        text.contains('taxation') ||
        text.contains('export') ||
        text.contains('import') ||
        text.contains('budget')) {
      return CurrentAffairsCategory.economy;
    }

    // 4. Environment
    if (text.contains('climate change') ||
        text.contains('biodiversity') ||
        text.contains('cop') ||
        text.contains('ramsar') ||
        text.contains('pollution') ||
        text.contains('forest') ||
        text.contains('wildlife') ||
        text.contains('renewable energy') ||
        text.contains('emissions') ||
        text.contains('conservation')) {
      return CurrentAffairsCategory.environment;
    }

    // 5. Science & Tech
    if (text.contains('isro') ||
        text.contains('satellite') ||
        text.contains('ai') ||
        text.contains('quantum') ||
        text.contains('biotechnology') ||
        text.contains('semiconductor') ||
        text.contains('space') ||
        text.contains('nuclear') ||
        text.contains('5g') ||
        text.contains('6g') ||
        text.contains('vaccine')) {
      return CurrentAffairsCategory.scienceAndTechnology;
    }

    // 6. Security
    if (text.contains('defence') ||
        text.contains('drdo') ||
        text.contains('cybersecurity') ||
        text.contains('border') ||
        text.contains('insurgency') ||
        text.contains('terrorism') ||
        text.contains('navy') ||
        text.contains('army') ||
        text.contains('air force') ||
        text.contains('exercise')) {
      return CurrentAffairsCategory.security;
    }

    // 7. International Relations
    if (text.contains('bilateral') ||
        text.contains('treaty') ||
        text.contains('unsc') ||
        text.contains('g20') ||
        text.contains('brics') ||
        text.contains('quad') ||
        text.contains('diplomatic') ||
        text.contains('summit') ||
        text.contains('ambassador') ||
        text.contains('foreign affairs')) {
      return CurrentAffairsCategory.internationalRelations;
    }

    // 8. Agriculture
    if (text.contains('msp') ||
        text.contains('crop') ||
        text.contains('farmer') ||
        text.contains('irrigation') ||
        text.contains('fertilizer') ||
        text.contains('kisan') ||
        text.contains('kharif') ||
        text.contains('rabi')) {
      return CurrentAffairsCategory.agriculture;
    }

    // 9. Social Issues
    if (text.contains('health') ||
        text.contains('education') ||
        text.contains('women') ||
        text.contains('poverty') ||
        text.contains('child') ||
        text.contains('vulnerable') ||
        text.contains('tribal') ||
        text.contains('human development')) {
      return CurrentAffairsCategory.socialIssues;
    }

    // 10. Culture
    if (text.contains('unesco') ||
        text.contains('heritage') ||
        text.contains('temple') ||
        text.contains('festival') ||
        text.contains('dance') ||
        text.contains('monument') ||
        text.contains('archaeological')) {
      return CurrentAffairsCategory.culture;
    }

    // 11. Geography & Disaster
    if (text.contains('cyclone') ||
        text.contains('earthquake') ||
        text.contains('tsunami') ||
        text.contains('monsoon') ||
        text.contains('river') ||
        text.contains('glacier') ||
        text.contains('ndma') ||
        text.contains('landslide')) {
      return CurrentAffairsCategory.geography;
    }

    // 12. Ethics
    if (text.contains('integrity') ||
        text.contains('probity') ||
        text.contains('code of conduct') ||
        text.contains('ethics') ||
        text.contains('moral')) {
      return CurrentAffairsCategory.ethics;
    }

    return CurrentAffairsCategory.miscellaneous;
  }
}
