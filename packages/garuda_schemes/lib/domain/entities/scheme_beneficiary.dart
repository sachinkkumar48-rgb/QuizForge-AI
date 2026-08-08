library;

/// Target beneficiary category of a Scheme, used as a first-class filter and
/// analytics dimension. Categories are syllabus-aligned (UPSC GS-I/II social
/// sector) and map directly to official beneficiary definitions.
enum BeneficiaryGroup {
  farmers,
  smallMarginalFarmers,
  landlessAgriculturalLabourers,
  women,
  girlChild,
  children,
  pregnantLactatingMothers,
  adolescents,
  youth,
  students,
  unorganisedWorkers,
  streetVendors,
  artisans,
  microEntrepreneurs,
  msmeUnits,
  scheduledCastes,
  scheduledTribes,
  pvtgs,
  otherBackwardClasses,
  minorities,
  personsWithDisabilities,
  seniorCitizens,
  urbanPoor,
  ruralPoor,
  farmersProducersOrganisations,
  transgenders,
  allCitizens,
  destituteFamilies,
  constructionWorkers,
  migrants,
}

extension BeneficiaryGroupExtension on BeneficiaryGroup {
  String get displayName {
    switch (this) {
      case BeneficiaryGroup.farmers:
        return 'Farmers';
      case BeneficiaryGroup.smallMarginalFarmers:
        return 'Small & Marginal Farmers';
      case BeneficiaryGroup.landlessAgriculturalLabourers:
        return 'Landless Agricultural Labourers';
      case BeneficiaryGroup.women:
        return 'Women';
      case BeneficiaryGroup.girlChild:
        return 'Girl Child';
      case BeneficiaryGroup.children:
        return 'Children';
      case BeneficiaryGroup.pregnantLactatingMothers:
        return 'Pregnant & Lactating Mothers';
      case BeneficiaryGroup.adolescents:
        return 'Adolescents';
      case BeneficiaryGroup.youth:
        return 'Youth';
      case BeneficiaryGroup.students:
        return 'Students';
      case BeneficiaryGroup.unorganisedWorkers:
        return 'Unorganised Workers';
      case BeneficiaryGroup.streetVendors:
        return 'Street Vendors';
      case BeneficiaryGroup.artisans:
        return 'Artisans & Craftspersons';
      case BeneficiaryGroup.microEntrepreneurs:
        return 'Micro-entrepreneurs';
      case BeneficiaryGroup.msmeUnits:
        return 'MSME Units';
      case BeneficiaryGroup.scheduledCastes:
        return 'Scheduled Castes';
      case BeneficiaryGroup.scheduledTribes:
        return 'Scheduled Tribes';
      case BeneficiaryGroup.pvtgs:
        return 'Particularly Vulnerable Tribal Groups';
      case BeneficiaryGroup.otherBackwardClasses:
        return 'Other Backward Classes';
      case BeneficiaryGroup.minorities:
        return 'Minorities';
      case BeneficiaryGroup.personsWithDisabilities:
        return 'Persons with Disabilities';
      case BeneficiaryGroup.seniorCitizens:
        return 'Senior Citizens';
      case BeneficiaryGroup.urbanPoor:
        return 'Urban Poor';
      case BeneficiaryGroup.ruralPoor:
        return 'Rural Poor';
      case BeneficiaryGroup.farmersProducersOrganisations:
        return 'Farmer Producer Organisations';
      case BeneficiaryGroup.transgenders:
        return 'Transgender Persons';
      case BeneficiaryGroup.allCitizens:
        return 'All Citizens';
      case BeneficiaryGroup.destituteFamilies:
        return 'Destitute Families';
      case BeneficiaryGroup.constructionWorkers:
        return 'Construction Workers';
      case BeneficiaryGroup.migrants:
        return 'Migrant Workers';
    }
  }
}
