import 'package:meta/meta.dart';

/// Pre-configured supported exams in GARUDA PYQ Repository.
enum ExamCategory {
  centralCivilServices,
  defenseServices,
  regulatoryAndBanking,
  statePublicService,
  custom,
}

@immutable
class SupportedExam {
  final String id;
  final String code;
  final String fullName;
  final String conductingBody;
  final ExamCategory category;

  const SupportedExam({
    required this.id,
    required this.code,
    required this.fullName,
    required this.conductingBody,
    required this.category,
  });

  // Pre-defined Supported Exams
  static const SupportedExam upscCse = SupportedExam(
    id: 'upsc_cse',
    code: 'UPSC_CSE',
    fullName: 'UPSC Civil Services Examination',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.centralCivilServices,
  );

  static const SupportedExam cds = SupportedExam(
    id: 'cds',
    code: 'CDS',
    fullName: 'Combined Defence Services Examination',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.defenseServices,
  );

  static const SupportedExam nda = SupportedExam(
    id: 'nda',
    code: 'NDA',
    fullName: 'National Defence Academy Examination',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.defenseServices,
  );

  static const SupportedExam capf = SupportedExam(
    id: 'capf',
    code: 'CAPF',
    fullName: 'Central Armed Police Forces (AC)',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.defenseServices,
  );

  static const SupportedExam epfoEoAo = SupportedExam(
    id: 'epfo_eo_ao',
    code: 'EPFO_EO_AO',
    fullName: 'EPFO Enforcement Officer / Accounts Officer',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.centralCivilServices,
  );

  static const SupportedExam epfoApfc = SupportedExam(
    id: 'epfo_apfc',
    code: 'EPFO_APFC',
    fullName: 'EPFO Assistant Provident Fund Commissioner',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.centralCivilServices,
  );

  static const SupportedExam eseGs = SupportedExam(
    id: 'ese_gs',
    code: 'ESE_GS',
    fullName: 'Engineering Services Examination (General Studies)',
    conductingBody: 'Union Public Service Commission',
    category: ExamCategory.centralCivilServices,
  );

  static const SupportedExam rbiGradeB = SupportedExam(
    id: 'rbi_grade_b',
    code: 'RBI_GRADE_B',
    fullName: 'RBI Grade B Officer Examination',
    conductingBody: 'Reserve Bank of India',
    category: ExamCategory.regulatoryAndBanking,
  );

  static const SupportedExam nabardGradeA = SupportedExam(
    id: 'nabard_grade_a',
    code: 'NABARD_GRADE_A',
    fullName: 'NABARD Grade A Assistant Manager',
    conductingBody: 'NABARD',
    category: ExamCategory.regulatoryAndBanking,
  );

  static const SupportedExam sebiGradeA = SupportedExam(
    id: 'sebi_grade_a',
    code: 'SEBI_GRADE_A',
    fullName: 'SEBI Grade A Assistant Manager',
    conductingBody: 'Securities and Exchange Board of India',
    category: ExamCategory.regulatoryAndBanking,
  );

  static const SupportedExam bpsc = SupportedExam(
    id: 'bpsc',
    code: 'BPSC',
    fullName: 'Bihar Public Service Commission Combined Competitive Exam',
    conductingBody: 'Bihar Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam uppsc = SupportedExam(
    id: 'uppsc',
    code: 'UPPSC',
    fullName: 'Uttar Pradesh Combined State / Upper Subordinate Services',
    conductingBody: 'Uttar Pradesh Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam mppsc = SupportedExam(
    id: 'mppsc',
    code: 'MPPSC',
    fullName: 'Madhya Pradesh State Service Examination',
    conductingBody: 'Madhya Pradesh Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam rpsc = SupportedExam(
    id: 'rpsc',
    code: 'RPSC',
    fullName: 'Rajasthan State and Subordinate Services (RAS/RTS)',
    conductingBody: 'Rajasthan Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam mpsc = SupportedExam(
    id: 'mpsc',
    code: 'MPSC',
    fullName: 'Maharashtra State Services Examination',
    conductingBody: 'Maharashtra Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam jpsc = SupportedExam(
    id: 'jpsc',
    code: 'JPSC',
    fullName: 'Jharkhand Combined Civil Services Examination',
    conductingBody: 'Jharkhand Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam cgpsc = SupportedExam(
    id: 'cgpsc',
    code: 'CGPSC',
    fullName: 'Chhattisgarh State Service Examination',
    conductingBody: 'Chhattisgarh Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam ukpsc = SupportedExam(
    id: 'ukpsc',
    code: 'UKPSC',
    fullName: 'Uttarakhand Combined State Civil Services',
    conductingBody: 'Uttarakhand Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam opsc = SupportedExam(
    id: 'opsc',
    code: 'OPSC',
    fullName: 'Odisha Civil Services Examination',
    conductingBody: 'Odisha Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam gpsc = SupportedExam(
    id: 'gpsc',
    code: 'GPSC',
    fullName: 'Gujarat Civil Services Examination',
    conductingBody: 'Gujarat Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam ppsc = SupportedExam(
    id: 'ppsc',
    code: 'PPSC',
    fullName: 'Punjab State Civil Services Combined Competitive Exam',
    conductingBody: 'Punjab Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam kpsc = SupportedExam(
    id: 'kpsc',
    code: 'KPSC',
    fullName: 'Karnataka Gazette Officers Combined Competitive Exam',
    conductingBody: 'Karnataka Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam tnpsc = SupportedExam(
    id: 'tnpsc',
    code: 'TNPSC',
    fullName: 'Tamil Nadu Public Service Commission Group I',
    conductingBody: 'Tamil Nadu Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  static const SupportedExam wbpsc = SupportedExam(
    id: 'wbpsc',
    code: 'WBPSC',
    fullName: 'West Bengal Civil Service (Executive) Examination',
    conductingBody: 'West Bengal Public Service Commission',
    category: ExamCategory.statePublicService,
  );

  /// List of all built-in pre-configured exams.
  static const List<SupportedExam> initialExams = [
    upscCse,
    cds,
    nda,
    capf,
    epfoEoAo,
    epfoApfc,
    eseGs,
    rbiGradeB,
    nabardGradeA,
    sebiGradeA,
    bpsc,
    uppsc,
    mppsc,
    rpsc,
    mpsc,
    jpsc,
    cgpsc,
    ukpsc,
    opsc,
    gpsc,
    ppsc,
    kpsc,
    tnpsc,
    wbpsc,
  ];

  /// Factory for dynamic extension (unlimited future exams).
  factory SupportedExam.custom({
    required String id,
    required String code,
    required String fullName,
    required String conductingBody,
  }) {
    return SupportedExam(
      id: id,
      code: code,
      fullName: fullName,
      conductingBody: conductingBody,
      category: ExamCategory.custom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'fullName': fullName,
        'conductingBody': conductingBody,
        'category': category.name,
      };

  factory SupportedExam.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String?;
    final cat = ExamCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => ExamCategory.custom,
    );
    return SupportedExam(
      id: json['id'] as String,
      code: json['code'] as String,
      fullName: json['fullName'] as String,
      conductingBody: json['conductingBody'] as String,
      category: cat,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportedExam && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
