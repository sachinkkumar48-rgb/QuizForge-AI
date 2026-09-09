import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/academic_credentials_page.dart';

void main() {
  final now = DateTime.utc(2026, 11, 20, 10, 0, 0);

  late InMemoryCredentialRepository credRepo;
  late InMemoryGradebookRepository gradebookRepo;
  late InMemoryCohortRepository cohortRepo;
  late InMemoryAssessmentRepository assessmentRepo;
  late GradebookService gradebookService;
  late AcademicCredentialService credentialService;

  setUp(() async {
    credRepo = InMemoryCredentialRepository();
    gradebookRepo = InMemoryGradebookRepository();
    cohortRepo = InMemoryCohortRepository();
    assessmentRepo = InMemoryAssessmentRepository();

    gradebookService = GradebookService(
      repository: gradebookRepo,
      cohortRepository: cohortRepo,
      clock: () => now,
    );

    credentialService = AcademicCredentialService(
      credentialRepository: credRepo,
      gradebookRepository: gradebookRepo,
      cohortRepository: cohortRepo,
      assessmentRepository: assessmentRepo,
      clock: () => now,
    );

    // Seed Cohort
    await cohortRepo.saveCohort(Cohort(
      cohortId: 'cohort_p51_ui',
      name: 'Judicial Services Examination Cohort',
      examId: 'djs_2026',
      primaryFacultyId: 'faculty_sharma',
      learnerIds: {'learner_alice'},
      metadata: {'academicPeriod': 'Autumn 2026'},
    ));

    // Seed Assessment
    await assessmentRepo.saveAssessment(Assessment(
      assessmentId: 'assess_evidence_law',
      title: 'Law of Evidence & Burden of Proof',
      examId: 'djs_2026',
      cohortIds: {'cohort_p51_ui'},
      creatorFacultyId: 'faculty_sharma',
      questionIds: ['q1', 'q2'],
    ));

    // Seed published grade
    final entry = GradebookEntry(
      entryId: GradebookEntry.generateId(
        cohortId: 'cohort_p51_ui',
        assessmentId: 'assess_evidence_law',
        learnerId: 'learner_alice',
      ),
      cohortId: 'cohort_p51_ui',
      assessmentId: 'assess_evidence_law',
      learnerId: 'learner_alice',
      finalScore: 85.0,
      finalMaxScore: 100.0,
      finalPercentage: 85.0,
      letterGrade: 'A',
      gradingStatus: GradingStatus.published,
      publicationStatus: GradePublicationStatus.published,
      publishedAt: now,
      publishedByFacultyId: 'faculty_sharma',
    );
    await gradebookRepo.saveGradeEntry(entry);
  });

  testWidgets(
      'AcademicCredentialsPage renders in Faculty perspective with Eligibility tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AcademicCredentialsPage(
        credentialService: credentialService,
        gradebookService: gradebookService,
        initialCohortId: 'cohort_p51_ui',
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Academic Credentials & Certificates'), findsOneWidget);
    expect(find.text('Eligibility'), findsOneWidget);
    expect(find.text('Transcripts'), findsOneWidget);
    expect(find.text('Certificates'), findsOneWidget);
    expect(find.text('Audit Trail'), findsOneWidget);

    // Verify learner card is present with Generate Transcript button
    expect(find.byKey(const Key('eligibility_card_learner_alice')),
        findsOneWidget);
    expect(find.byKey(const Key('generate_transcript_learner_alice')),
        findsOneWidget);
    expect(find.byKey(const Key('issue_cert_learner_alice')), findsOneWidget);
  });

  testWidgets(
      'Faculty can generate official transcript and issue certificate via UI',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AcademicCredentialsPage(
        credentialService: credentialService,
        gradebookService: gradebookService,
        initialCohortId: 'cohort_p51_ui',
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap Generate Transcript
    await tester
        .tap(find.byKey(const Key('generate_transcript_learner_alice')));
    await tester.pumpAndSettle();

    // Verify transcript is generated
    expect(find.textContaining('Official Transcript v1 generated'),
        findsOneWidget);

    // Tap Issue Certificate
    await tester.tap(find.byKey(const Key('issue_cert_learner_alice')));
    await tester.pumpAndSettle();

    // Verify certificate is issued
    expect(
        find.textContaining('Completion Certificate issued!'), findsOneWidget);

    // Switch to Certificates tab
    await tester.tap(find.text('Certificates'));
    await tester.pumpAndSettle();

    expect(find.textContaining('QFA-CERT-COHORTP51UI-LEARNERALICE-'),
        findsWidgets);
  });

  testWidgets('AcademicCredentialsPage renders in Learner perspective',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AcademicCredentialsPage(
        credentialService: credentialService,
        gradebookService: gradebookService,
        initialCohortId: 'cohort_p51_ui',
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialIsFaculty: false, // Learner perspective
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('My Academic Credentials'), findsOneWidget);
    expect(find.text('Academic Record'), findsOneWidget);
    expect(find.text('Transcripts'), findsOneWidget);
    expect(find.text('My Certificates'), findsOneWidget);

    // Learner can see published grade on Law of Evidence
    expect(find.text('Law of Evidence & Burden of Proof'), findsOneWidget);
    expect(find.textContaining('Score: 85.0/100.0 (85.0%)'), findsOneWidget);
  });

  testWidgets(
      'Public Verification Modal verifies credential and renders result card',
      (WidgetTester tester) async {
    // Pre-issue a certificate to test verification
    final cert = await credentialService.issueCompletionCertificate(
      learnerId: 'learner_alice',
      cohortId: 'cohort_p51_ui',
      facultyId: 'faculty_sharma',
      learnerName: 'Alice Walker',
    );

    await tester.pumpWidget(MaterialApp(
      home: AcademicCredentialsPage(
        credentialService: credentialService,
        gradebookService: gradebookService,
        initialCohortId: 'cohort_p51_ui',
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Open public verification modal
    await tester.tap(find.byKey(const Key('open_public_verification_button')));
    await tester.pumpAndSettle();

    expect(find.text('Public Credential Verification'), findsOneWidget);

    // Enter credential ID
    await tester.enterText(
      find.byKey(const Key('verify_credential_input')),
      cert.credentialId,
    );
    await tester.pumpAndSettle();

    // Tap Verify Credential
    await tester.tap(find.byKey(const Key('verify_credential_button')));
    await tester.pumpAndSettle();

    // Verify result card displayed
    expect(find.byKey(const Key('verification_result_card')), findsOneWidget);
    expect(find.text('AUTHENTIC & VALID CREDENTIAL'), findsOneWidget);
    expect(find.textContaining('Alice W.'), findsOneWidget);
  });
}
