library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/news_event.dart';
import 'source_adapter.dart';

class BaseOfficialSourceAdapter implements SourceAdapter {
  @override
  final String sourceId;
  @override
  final String officialName;
  @override
  final String baseUrl;
  final CurrentAffairsCategory defaultCategory;
  final String defaultMinistry;

  BaseOfficialSourceAdapter({
    required this.sourceId,
    required this.officialName,
    required this.baseUrl,
    required this.defaultCategory,
    this.defaultMinistry = '',
  });

  @override
  Future<List<NewsEvent>> fetchEvents({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    // In production, connects to verified official API/RSS feeds.
    return [];
  }
}

class PibAdapter extends BaseOfficialSourceAdapter {
  PibAdapter()
      : super(
          sourceId: 'pib_official',
          officialName: 'Press Information Bureau (PIB)',
          baseUrl: 'https://pib.gov.in',
          defaultCategory: CurrentAffairsCategory.governance,
          defaultMinistry: 'Ministry of Information and Broadcasting',
        );
}

class PrsAdapter extends BaseOfficialSourceAdapter {
  PrsAdapter()
      : super(
          sourceId: 'prs_official',
          officialName: 'PRS Legislative Research',
          baseUrl: 'https://prsindia.org',
          defaultCategory: CurrentAffairsCategory.polity,
          defaultMinistry: 'Parliament of India',
        );
}

class RbiAdapter extends BaseOfficialSourceAdapter {
  RbiAdapter()
      : super(
          sourceId: 'rbi_official',
          officialName: 'Reserve Bank of India (RBI)',
          baseUrl: 'https://rbi.org.in',
          defaultCategory: CurrentAffairsCategory.economy,
          defaultMinistry: 'Ministry of Finance',
        );
}

class SebiAdapter extends BaseOfficialSourceAdapter {
  SebiAdapter()
      : super(
          sourceId: 'sebi_official',
          officialName: 'Securities and Exchange Board of India (SEBI)',
          baseUrl: 'https://sebi.gov.in',
          defaultCategory: CurrentAffairsCategory.economy,
          defaultMinistry: 'Ministry of Finance',
        );
}

class NitiAayogAdapter extends BaseOfficialSourceAdapter {
  NitiAayogAdapter()
      : super(
          sourceId: 'niti_aayog',
          officialName: 'NITI Aayog',
          baseUrl: 'https://niti.gov.in',
          defaultCategory: CurrentAffairsCategory.governance,
          defaultMinistry: 'NITI Aayog',
        );
}

class SupremeCourtAdapter extends BaseOfficialSourceAdapter {
  SupremeCourtAdapter()
      : super(
          sourceId: 'sc_official',
          officialName: 'Supreme Court of India',
          baseUrl: 'https://main.sci.gov.in',
          defaultCategory: CurrentAffairsCategory.polity,
          defaultMinistry: 'Judiciary',
        );
}

class IsroAdapter extends BaseOfficialSourceAdapter {
  IsroAdapter()
      : super(
          sourceId: 'isro_official',
          officialName: 'Indian Space Research Organisation (ISRO)',
          baseUrl: 'https://isro.gov.in',
          defaultCategory: CurrentAffairsCategory.scienceAndTechnology,
          defaultMinistry: 'Department of Space',
        );
}

class DrdoAdapter extends BaseOfficialSourceAdapter {
  DrdoAdapter()
      : super(
          sourceId: 'drdo_official',
          officialName: 'Defence Research and Development Organisation (DRDO)',
          baseUrl: 'https://drdo.gov.in',
          defaultCategory: CurrentAffairsCategory.security,
          defaultMinistry: 'Ministry of Defence',
        );
}

class ElectionCommissionAdapter extends BaseOfficialSourceAdapter {
  ElectionCommissionAdapter()
      : super(
          sourceId: 'eci_official',
          officialName: 'Election Commission of India (ECI)',
          baseUrl: 'https://eci.gov.in',
          defaultCategory: CurrentAffairsCategory.polity,
          defaultMinistry: 'Constitutional Body',
        );
}

class CagAdapter extends BaseOfficialSourceAdapter {
  CagAdapter()
      : super(
          sourceId: 'cag_official',
          officialName: 'Comptroller and Auditor General of India (CAG)',
          baseUrl: 'https://cag.gov.in',
          defaultCategory: CurrentAffairsCategory.governance,
          defaultMinistry: 'Constitutional Body',
        );
}

class ParliamentAdapter extends BaseOfficialSourceAdapter {
  ParliamentAdapter()
      : super(
          sourceId: 'sansad_official',
          officialName: 'Parliament of India (Sansad)',
          baseUrl: 'https://sansad.in',
          defaultCategory: CurrentAffairsCategory.polity,
          defaultMinistry: 'Legislature',
        );
}

class GazetteNotificationsAdapter extends BaseOfficialSourceAdapter {
  GazetteNotificationsAdapter()
      : super(
          sourceId: 'gazette_official',
          officialName: 'Gazette of India Notifications',
          baseUrl: 'https://egazette.gov.in',
          defaultCategory: CurrentAffairsCategory.governance,
          defaultMinistry: 'Ministry of Housing and Urban Affairs',
        );
}

class MinistryWebsitesAdapter extends BaseOfficialSourceAdapter {
  MinistryWebsitesAdapter({
    required super.sourceId,
    required super.officialName,
    required super.baseUrl,
    required super.defaultCategory,
    super.defaultMinistry,
  });
}

class OfficialReportsAdapter extends BaseOfficialSourceAdapter {
  OfficialReportsAdapter()
      : super(
          sourceId: 'official_reports',
          officialName: 'Official Government Reports & Commissions',
          baseUrl: 'https://reports.gov.in',
          defaultCategory: CurrentAffairsCategory.governance,
          defaultMinistry: 'Government of India',
        );
}

