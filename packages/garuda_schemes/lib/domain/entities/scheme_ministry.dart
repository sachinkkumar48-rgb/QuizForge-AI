library;

/// Ministry of the Government of India responsible for a Scheme.
/// Official ministry names are used as stable analytics keys; the enum is the
/// authoritative, typed source so that "schemes by ministry" distributions and
/// cross-package references do not drift on uncontrolled strings.
enum SchemeMinistry {
  agricultureFarmersWelfare,
  ruralDevelopment,
  panchayatiRaj,
  healthFamilyWelfare,
  education,
  womenChildDevelopment,
  socialJusticeEmpowerment,
  tribalAffairs,
  labourEmployment,
  skillDevelopmentEntrepreneurship,
  finance,
  housingUrbanAffairs,
  jalShakti,
  environmentForestClimate,
  power,
  newRenewableEnergy,
  petroleumNaturalGas,
  electronicsInformationTechnology,
  communications,
  msme,
  foodProcessingIndustries,
  consumerAffairsFoodPublicDistribution,
  heavyIndustries,
  commerceIndustry,
  scienceTechnology,
  roadTransportHighways,
  railways,
  portsShippingWaterways,
  civilAviation,
  steel,
  chemicalsFertilizers,
  textiles,
  culture,
  homeAffairs,
  statisticsProgrammeImplementation,
  ayush,
  minorityAffairs,
  youthAffairsSports,
  developmentNorthEasternRegion,
  mines,
  earthSciences,
  atomicEnergy,
  space,
  informationBroadcasting,
  tourism,
  lawJustice,
  corporateAffairs,
  personnelTraining,
  primeMinisterOffice,
}

extension SchemeMinistryExtension on SchemeMinistry {
  String get displayName {
    switch (this) {
      case SchemeMinistry.agricultureFarmersWelfare:
        return 'Ministry of Agriculture & Farmers Welfare';
      case SchemeMinistry.ruralDevelopment:
        return 'Ministry of Rural Development';
      case SchemeMinistry.panchayatiRaj:
        return 'Ministry of Panchayati Raj';
      case SchemeMinistry.healthFamilyWelfare:
        return 'Ministry of Health & Family Welfare';
      case SchemeMinistry.education:
        return 'Ministry of Education';
      case SchemeMinistry.womenChildDevelopment:
        return 'Ministry of Women & Child Development';
      case SchemeMinistry.socialJusticeEmpowerment:
        return 'Ministry of Social Justice & Empowerment';
      case SchemeMinistry.tribalAffairs:
        return 'Ministry of Tribal Affairs';
      case SchemeMinistry.labourEmployment:
        return 'Ministry of Labour & Employment';
      case SchemeMinistry.skillDevelopmentEntrepreneurship:
        return 'Ministry of Skill Development & Entrepreneurship';
      case SchemeMinistry.finance:
        return 'Ministry of Finance';
      case SchemeMinistry.housingUrbanAffairs:
        return 'Ministry of Housing & Urban Affairs';
      case SchemeMinistry.jalShakti:
        return 'Ministry of Jal Shakti';
      case SchemeMinistry.environmentForestClimate:
        return 'Ministry of Environment, Forest & Climate Change';
      case SchemeMinistry.power:
        return 'Ministry of Power';
      case SchemeMinistry.newRenewableEnergy:
        return 'Ministry of New & Renewable Energy';
      case SchemeMinistry.petroleumNaturalGas:
        return 'Ministry of Petroleum & Natural Gas';
      case SchemeMinistry.electronicsInformationTechnology:
        return 'Ministry of Electronics & Information Technology';
      case SchemeMinistry.communications:
        return 'Ministry of Communications';
      case SchemeMinistry.msme:
        return 'Ministry of Micro, Small & Medium Enterprises';
      case SchemeMinistry.foodProcessingIndustries:
        return 'Ministry of Food Processing Industries';
      case SchemeMinistry.consumerAffairsFoodPublicDistribution:
        return 'Ministry of Consumer Affairs, Food & Public Distribution';
      case SchemeMinistry.heavyIndustries:
        return 'Ministry of Heavy Industries';
      case SchemeMinistry.commerceIndustry:
        return 'Ministry of Commerce & Industry';
      case SchemeMinistry.scienceTechnology:
        return 'Ministry of Science & Technology';
      case SchemeMinistry.roadTransportHighways:
        return 'Ministry of Road Transport & Highways';
      case SchemeMinistry.railways:
        return 'Ministry of Railways';
      case SchemeMinistry.portsShippingWaterways:
        return 'Ministry of Ports, Shipping & Waterways';
      case SchemeMinistry.civilAviation:
        return 'Ministry of Civil Aviation';
      case SchemeMinistry.steel:
        return 'Ministry of Steel';
      case SchemeMinistry.chemicalsFertilizers:
        return 'Ministry of Chemicals & Fertilizers';
      case SchemeMinistry.textiles:
        return 'Ministry of Textiles';
      case SchemeMinistry.culture:
        return 'Ministry of Culture';
      case SchemeMinistry.homeAffairs:
        return 'Ministry of Home Affairs';
      case SchemeMinistry.statisticsProgrammeImplementation:
        return 'Ministry of Statistics & Programme Implementation';
      case SchemeMinistry.ayush:
        return 'Ministry of Ayush';
      case SchemeMinistry.minorityAffairs:
        return 'Ministry of Minority Affairs';
      case SchemeMinistry.youthAffairsSports:
        return 'Ministry of Youth Affairs & Sports';
      case SchemeMinistry.developmentNorthEasternRegion:
        return 'Ministry of Development of North Eastern Region';
      case SchemeMinistry.mines:
        return 'Ministry of Mines';
      case SchemeMinistry.earthSciences:
        return 'Ministry of Earth Sciences';
      case SchemeMinistry.atomicEnergy:
        return 'Department of Atomic Energy';
      case SchemeMinistry.space:
        return 'Department of Space';
      case SchemeMinistry.informationBroadcasting:
        return 'Ministry of Information & Broadcasting';
      case SchemeMinistry.tourism:
        return 'Ministry of Tourism';
      case SchemeMinistry.lawJustice:
        return 'Ministry of Law & Justice';
      case SchemeMinistry.corporateAffairs:
        return 'Ministry of Corporate Affairs';
      case SchemeMinistry.personnelTraining:
        return 'Ministry of Personnel, Public Grievances & Pensions';
      case SchemeMinistry.primeMinisterOffice:
        return 'Prime Minister\'s Office';
    }
  }
}
