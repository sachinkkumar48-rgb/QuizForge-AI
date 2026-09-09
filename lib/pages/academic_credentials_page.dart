import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garuda_learning/garuda_learning.dart';

import 'gradebook_page.dart';

/// Academic Credentials, Transcripts & Tamper-Evident Verification Portal (TITAN-KO-051.0 P51).
///
/// Multi-persona portal providing:
/// 1. Learner Perspective:
///    - My Academic Record: authoritative published grades only.
///    - My Transcripts: official transcripts, versions (v1, v2), and historical revisions.
///    - My Certificates: course completion certificates with credential IDs and SHA-256 fingerprints.
/// 2. Faculty / Institutional Perspective:
///    - Completion Eligibility evaluation dashboard with unmet criteria breakdown.
///    - Official Transcript generation, reissuance, and voiding.
///    - Course Completion Certificate issuance and formal revocation.
///    - Immutable credential audit trail inspection.
/// 3. Public Verification Boundary:
///    - Public verification of credentials by ID with minimal disclosure.
class AcademicCredentialsPage extends StatefulWidget {
  final AcademicCredentialService? credentialService;
  final GradebookService? gradebookService;
  final String initialFacultyId;
  final String initialLearnerId;
  final String? initialCohortId;
  final bool initialIsFaculty;
  final String? initialVerifyCredentialId;

  const AcademicCredentialsPage({
    super.key,
    this.credentialService,
    this.gradebookService,
    this.initialFacultyId = 'faculty_admin',
    this.initialLearnerId = 'default_learner',
    this.initialCohortId,
    this.initialIsFaculty = true,
    this.initialVerifyCredentialId,
  });

  static AcademicCredentialService? _sharedDefaultService;
  static AcademicCredentialService get sharedService =>
      _sharedDefaultService ??= AcademicCredentialService(
        credentialRepository: InMemoryCredentialRepository(),
        gradebookRepository: GradebookPage.sharedService.repository,
        cohortRepository: GradebookPage.sharedService.cohortRepository,
        assessmentRepository: GradebookPage.sharedService.assessmentRepository,
      );

  @override
  State<AcademicCredentialsPage> createState() =>
      _AcademicCredentialsPageState();
}

class _AcademicCredentialsPageState extends State<AcademicCredentialsPage>
    with SingleTickerProviderStateMixin {
  late final AcademicCredentialService _credentialService;
  late final GradebookService _gradebookService;

  late bool _isFacultyMode;
  late String _currentFacultyId;
  late String _currentLearnerId;
  late String _selectedCohortId;

  bool _isLoading = true;
  String? _errorMessage;
  TabController? _tabController;

  // Faculty state
  List<Cohort> _availableCohorts = [];
  Map<String, CompletionEligibility> _eligibilityMap = {};
  List<AcademicTranscript> _cohortTranscripts = [];
  List<CompletionCertificate> _cohortCertificates = [];
  List<CredentialAuditRecord> _auditRecords = [];

  // Learner state
  AcademicRecord? _learnerAcademicRecord;
  List<AcademicTranscript> _learnerTranscripts = [];
  List<CompletionCertificate> _learnerCertificates = [];

  // Public verification state
  final TextEditingController _verifyInputController = TextEditingController();
  CredentialVerificationResult? _verificationResult;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _isFacultyMode = widget.initialIsFaculty;
    _currentFacultyId = widget.initialFacultyId;
    _currentLearnerId = widget.initialLearnerId;
    _selectedCohortId = widget.initialCohortId ?? 'cohort_default';

    if (widget.initialVerifyCredentialId != null &&
        widget.initialVerifyCredentialId!.isNotEmpty) {
      _verifyInputController.text = widget.initialVerifyCredentialId!;
    }

    _gradebookService = widget.gradebookService ?? GradebookPage.sharedService;
    _credentialService = widget.credentialService ??
        AcademicCredentialService(
          credentialRepository: InMemoryCredentialRepository(),
          gradebookRepository: _gradebookService.repository,
          cohortRepository: _gradebookService.cohortRepository,
          assessmentRepository: _gradebookService.assessmentRepository,
        );

    _initTabController();
    _loadData();
  }

  void _initTabController() {
    _tabController?.dispose();
    final tabCount = _isFacultyMode ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _verifyInputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _availableCohorts =
          await _gradebookService.cohortRepository.listCohorts();
      if (_availableCohorts.isNotEmpty &&
          !_availableCohorts.any((c) => c.cohortId == _selectedCohortId)) {
        _selectedCohortId = _availableCohorts.first.cohortId;
      }

      if (_isFacultyMode) {
        await _loadFacultyData();
      } else {
        await _loadLearnerData();
      }

      // If initial verify ID was passed, verify immediately
      if (_verifyInputController.text.trim().isNotEmpty &&
          _verificationResult == null) {
        await _performVerification(_verifyInputController.text.trim());
      }
    } catch (e) {
      _errorMessage = 'Error loading credentials data: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFacultyData() async {
    final cohort = await _gradebookService.cohortRepository
        .getCohortById(_selectedCohortId);
    if (cohort == null) return;

    final eligibility = <String, CompletionEligibility>{};
    for (final lid in cohort.learnerIds) {
      try {
        final el = await _credentialService.evaluateCompletionEligibility(
          learnerId: lid,
          cohortId: _selectedCohortId,
        );
        eligibility[lid] = el;
      } catch (_) {
        // Learner may not have records yet
      }
    }
    _eligibilityMap = eligibility;

    _cohortTranscripts = await _credentialService.credentialRepository
        .listTranscripts(cohortId: _selectedCohortId);

    _cohortCertificates = await _credentialService.credentialRepository
        .listCertificates(cohortId: _selectedCohortId);

    _auditRecords =
        await _credentialService.credentialRepository.listAuditRecords();
  }

  Future<void> _loadLearnerData() async {
    try {
      _learnerAcademicRecord = await _credentialService.generateAcademicRecord(
        learnerId: _currentLearnerId,
        cohortId: _selectedCohortId,
        requestingActorId: _currentLearnerId,
        requestingActorRole: 'learner',
      );
    } catch (_) {
      _learnerAcademicRecord = null;
    }

    _learnerTranscripts = await _credentialService.credentialRepository
        .listTranscriptsForLearner(learnerId: _currentLearnerId);

    _learnerCertificates = await _credentialService.credentialRepository
        .listCertificatesForLearner(learnerId: _currentLearnerId);
  }

  Future<void> _performVerification(String credentialId) async {
    final cleanId = credentialId.trim();
    if (cleanId.isEmpty) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final res =
          await _credentialService.verifyCredential(credentialId: cleanId);
      setState(() {
        _verificationResult = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Actions: Faculty
  // ---------------------------------------------------------------------------

  Future<void> _handleGenerateTranscript(String learnerId) async {
    try {
      final tr = await _credentialService.issueOfficialTranscript(
        learnerId: learnerId,
        cohortId: _selectedCohortId,
        facultyId: _currentFacultyId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Official Transcript v${tr.version} generated (${tr.transcriptId})',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate transcript: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleIssueCertificate(String learnerId) async {
    try {
      final cert = await _credentialService.issueCompletionCertificate(
        learnerId: learnerId,
        cohortId: _selectedCohortId,
        facultyId: _currentFacultyId,
        learnerName: learnerId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completion Certificate issued! Credential ID: ${cert.credentialId}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to issue certificate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showVoidTranscriptDialog(AcademicTranscript tr) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Void Transcript ${tr.transcriptId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voiding will invalidate this official transcript. Mandatory justification is required:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Justification Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Void Transcript'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _credentialService.voidTranscript(
          transcriptId: tr.transcriptId,
          facultyId: _currentFacultyId,
          reason: reasonController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transcript voided successfully')),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voiding transcript: $e')),
        );
      }
    }
  }

  Future<void> _showRevokeCertificateDialog(CompletionCertificate cert) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Revoke Certificate ${cert.credentialId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revoking a credential marks it as permanently revoked in public verification. Mandatory justification:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Revocation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke Credential'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _credentialService.revokeCertificate(
          certificateId: cert.certificateId,
          facultyId: _currentFacultyId,
          reason: reasonController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate revoked successfully')),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error revoking certificate: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('academic_credentials_scaffold'),
      appBar: AppBar(
        title: Text(
          _isFacultyMode
              ? 'Academic Credentials & Certificates'
              : 'My Academic Credentials',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Faculty'),
                  icon: Icon(Icons.school, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Learner'),
                  icon: Icon(Icons.person, size: 16),
                ),
              ],
              selected: {_isFacultyMode},
              onSelectionChanged: (set) {
                setState(() {
                  _isFacultyMode = set.first;
                  _initTabController();
                });
                _loadData();
              },
            ),
          ),
          IconButton(
            key: const Key('open_public_verification_button'),
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Public Verification',
            onPressed: _showPublicVerificationModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _isFacultyMode
              ? const [
                  Tab(
                    icon: Icon(Icons.rule_folder_outlined),
                    text: 'Eligibility',
                  ),
                  Tab(
                    icon: Icon(Icons.description_outlined),
                    text: 'Transcripts',
                  ),
                  Tab(
                    icon: Icon(Icons.workspace_premium_outlined),
                    text: 'Certificates',
                  ),
                  Tab(
                    icon: Icon(Icons.history_edu_outlined),
                    text: 'Audit Trail',
                  ),
                ]
              : const [
                  Tab(
                    icon: Icon(Icons.menu_book_outlined),
                    text: 'Academic Record',
                  ),
                  Tab(
                    icon: Icon(Icons.article_outlined),
                    text: 'Transcripts',
                  ),
                  Tab(
                    icon: Icon(Icons.card_membership_outlined),
                    text: 'My Certificates',
                  ),
                ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                )
              : _isFacultyMode
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFacultyEligibilityTab(),
                        _buildFacultyTranscriptsTab(),
                        _buildFacultyCertificatesTab(),
                        _buildFacultyAuditTab(),
                      ],
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLearnerRecordTab(),
                        _buildLearnerTranscriptsTab(),
                        _buildLearnerCertificatesTab(),
                      ],
                    ),
    );
  }

  // ---------------------------------------------------------------------------
  // Faculty Views
  // ---------------------------------------------------------------------------

  Widget _buildFacultyEligibilityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCohortSelectorCard(),
        const SizedBox(height: 16),
        Text(
          'Completion Eligibility Matrix (${_eligibilityMap.length} Learners)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_eligibilityMap.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No enrolled learners or records in this cohort.'),
              ),
            ),
          )
        else
          ..._eligibilityMap.entries.map((entry) {
            final lid = entry.key;
            final el = entry.value;
            final isEligible = el.isEligible;

            return Card(
              key: Key('eligibility_card_$lid'),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isEligible
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            isEligible ? Icons.check_circle : Icons.pending,
                            color: isEligible ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lid,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Overall: ${el.overallPercentage.toStringAsFixed(1)}% | Completed: ${el.completedAssessments}/${el.totalRequiredAssessments} | Published: ${el.publishedAssessments}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            isEligible ? 'ELIGIBLE' : 'INCOMPLETE',
                            style: TextStyle(
                              color: isEligible
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor: isEligible
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                        ),
                      ],
                    ),
                    if (el.unmetCriteria.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text(
                        'Unmet Criteria:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      ...el.unmetCriteria.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• $c',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          key: Key('generate_transcript_$lid'),
                          icon: const Icon(Icons.description, size: 16),
                          label: const Text('Generate Transcript'),
                          onPressed: () => _handleGenerateTranscript(lid),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          key: Key('issue_cert_$lid'),
                          icon: const Icon(Icons.workspace_premium, size: 16),
                          label: const Text('Issue Certificate'),
                          onPressed: isEligible
                              ? () => _handleIssueCertificate(lid)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFacultyTranscriptsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCohortSelectorCard(),
        const SizedBox(height: 16),
        Text(
          'Official Transcripts (${_cohortTranscripts.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_cohortTranscripts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child:
                    Text('No official transcripts issued for this cohort yet.'),
              ),
            ),
          )
        else
          ..._cohortTranscripts.map((tr) {
            final isVoid = tr.isVoid;
            final isReissued = tr.isReissued;

            return Card(
              key: Key('transcript_card_${tr.transcriptId}'),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isVoid
                      ? Colors.red.shade100
                      : isReissued
                          ? Colors.grey.shade200
                          : Colors.blue.shade100,
                  child: Text('v${tr.version}'),
                ),
                title: Text(
                  '${tr.transcriptId} (${tr.learnerId})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isVoid ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  'Overall: ${tr.overallGrade} (${tr.overallPercentage.toStringAsFixed(1)}%) | Issued: ${tr.issuedAt.toLocal().toString().split(".").first}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        tr.status.name.toUpperCase(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'view') {
                          _showTranscriptDetailsDialog(tr);
                        } else if (val == 'reissue') {
                          _handleGenerateTranscript(tr.learnerId);
                        } else if (val == 'void') {
                          _showVoidTranscriptDialog(tr);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('View Details'),
                        ),
                        if (!isVoid)
                          const PopupMenuItem(
                            value: 'reissue',
                            child: Text('Reissue (New Revision)'),
                          ),
                        if (!isVoid)
                          const PopupMenuItem(
                            value: 'void',
                            child: Text('Void Transcript'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFacultyCertificatesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCohortSelectorCard(),
        const SizedBox(height: 16),
        Text(
          'Issued Certificates (${_cohortCertificates.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_cohortCertificates.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No certificates issued for this cohort yet.'),
              ),
            ),
          )
        else
          ..._cohortCertificates.map((cert) {
            final isRevoked = cert.isRevoked;

            return Card(
              key: Key('cert_card_${cert.certificateId}'),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: isRevoked ? Colors.red : Colors.amber.shade800,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert.credentialId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Recipient: ${cert.learnerName ?? cert.learnerId} | Program: ${cert.programName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            cert.status.name.toUpperCase(),
                            style: TextStyle(
                              color: isRevoked ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          backgroundColor: isRevoked
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SHA-256 Fingerprint: ${cert.fingerprint}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.verified, size: 16),
                          label: const Text('Verify'),
                          onPressed: () {
                            _verifyInputController.text = cert.credentialId;
                            _showPublicVerificationModal();
                          },
                        ),
                        if (!isRevoked) ...[
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            key: Key('revoke_button_${cert.certificateId}'),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('Revoke'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => _showRevokeCertificateDialog(cert),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFacultyAuditTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Credential Audit Trail (${_auditRecords.length} Events)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_auditRecords.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child:
                  Center(child: Text('No credential audit events recorded.')),
            ),
          )
        else
          ..._auditRecords.map((a) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.shield_outlined, size: 18),
                ),
                title: Text(
                  '${a.action.name.toUpperCase()} by ${a.actorId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Target: ${a.targetId} (Learner: ${a.learnerId})\nTimestamp: ${a.timestamp.toLocal().toString().split(".").first}${a.reason != null ? "\nReason: ${a.reason}" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Learner Views
  // ---------------------------------------------------------------------------

  Widget _buildLearnerRecordTab() {
    final rec = _learnerAcademicRecord;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rec == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No published academic records available for this cohort.',
                ),
              ),
            ),
          )
        else ...[
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.institutionName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Program: ${rec.programName ?? "N/A"}'),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overall Grade: ${rec.overallGrade}'),
                      Text('Average: ${rec.overallPercentage}%'),
                      Text(
                          'Passed: ${rec.passedAssessments}/${rec.totalAssessments}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Authoritative Published Grades',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...rec.entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.isPassed
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Text(e.letterGrade),
                  ),
                  title: Text(
                    e.assessmentTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Score: ${e.finalScore}/${e.maxScore} (${e.percentage.toStringAsFixed(1)}%) | Published: ${e.publishedAt?.toLocal().toString().split(".").first ?? "Yes"}',
                  ),
                  trailing: e.isOverridden
                      ? const Chip(
                          label: Text('OVERRIDDEN',
                              style: TextStyle(fontSize: 10)),
                        )
                      : null,
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildLearnerTranscriptsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'My Official Transcripts (${_learnerTranscripts.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_learnerTranscripts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No official transcripts issued yet.'),
              ),
            ),
          )
        else
          ..._learnerTranscripts.map((tr) {
            return Card(
              key: Key('learner_transcript_${tr.transcriptId}'),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text('v${tr.version}')),
                title: Text(
                  tr.transcriptId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Status: ${tr.status.name.toUpperCase()} | Grade: ${tr.overallGrade} (${tr.overallPercentage}%)',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View Transcript',
                  onPressed: () => _showTranscriptDetailsDialog(tr),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLearnerCertificatesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'My Course Completion Certificates (${_learnerCertificates.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_learnerCertificates.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No course certificates issued yet.'),
              ),
            ),
          )
        else
          ..._learnerCertificates.map((c) {
            return Card(
              key: Key('learner_cert_${c.certificateId}'),
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: Colors.amber,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.programName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(c.institutionName),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            c.status.name.toUpperCase(),
                            style: TextStyle(
                              color: c.isRevoked ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Credential ID: ${c.credentialId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SHA-256 Fingerprint: ${c.fingerprint}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Credential ID'),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: c.credentialId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Credential ID copied to clipboard'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.verified, size: 16),
                          label: const Text('Verify Authenticity'),
                          onPressed: () {
                            _verifyInputController.text = c.credentialId;
                            _showPublicVerificationModal();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Modals & Dialogs
  // ---------------------------------------------------------------------------

  Widget _buildCohortSelectorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined),
            const SizedBox(width: 12),
            const Text('Cohort: ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: DropdownButton<String>(
                value: _availableCohorts
                        .any((c) => c.cohortId == _selectedCohortId)
                    ? _selectedCohortId
                    : null,
                isExpanded: true,
                underline: const SizedBox(),
                items: _availableCohorts
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.cohortId,
                        child: Text('${c.name} (${c.cohortId})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCohortId = val);
                    _loadData();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranscriptDetailsDialog(AcademicTranscript tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Official Transcript ${tr.transcriptId}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr.institutionName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Program: ${tr.programName ?? "Core Curriculum"}'),
                Text('Learner: ${tr.learnerId} | Version: v${tr.version}'),
                Text('Status: ${tr.status.name.toUpperCase()}'),
                Text(
                    'Issued: ${tr.issuedAt.toLocal().toString().split(".").first} by ${tr.issuedByFacultyId}'),
                const Divider(height: 24),
                const Text(
                  'Assessments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...tr.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.assessmentTitle)),
                          Text(
                            '${e.score}/${e.maxScore} (${e.percentage.toStringAsFixed(1)}%) [${e.letterGrade}]',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Aggregate Result:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${tr.overallGrade} (${tr.overallPercentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPublicVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Public Credential Verification',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter a canonical Credential ID to verify authenticity against authoritative cryptographic fingerprints.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('verify_credential_input'),
                    controller: _verifyInputController,
                    decoration: const InputDecoration(
                      labelText: 'Credential ID',
                      hintText: 'e.g. QFA-CERT-COHORT1-LEARNER1-ABC12345',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('verify_credential_button'),
                    icon: _isVerifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Verify Credential'),
                    onPressed: _isVerifying
                        ? null
                        : () async {
                            setModalState(() => _isVerifying = true);
                            await _performVerification(
                                _verifyInputController.text);
                            setModalState(() => _isVerifying = false);
                          },
                  ),
                  if (_verificationResult != null) ...[
                    const SizedBox(height: 20),
                    _buildVerificationResultCard(_verificationResult!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationResultCard(CredentialVerificationResult res) {
    Color bg;
    Color fg;
    IconData icon;
    String statusTitle;

    switch (res.status) {
      case CredentialVerificationStatus.valid:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle;
        statusTitle = 'AUTHENTIC & VALID CREDENTIAL';
        break;
      case CredentialVerificationStatus.revoked:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        icon = Icons.cancel;
        statusTitle = 'FORMALLY REVOKED CREDENTIAL';
        break;
      case CredentialVerificationStatus.invalid:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.warning;
        statusTitle = 'INTEGRITY MISMATCH / TAMPERED';
        break;
      case CredentialVerificationStatus.notFound:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        icon = Icons.search_off;
        statusTitle = 'CREDENTIAL NOT FOUND';
        break;
    }

    return Container(
      key: const Key('verification_result_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Text(
                statusTitle,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Credential ID: ${res.credentialId}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (res.institutionName != null)
            Text('Institution: ${res.institutionName}'),
          if (res.programName != null) Text('Program: ${res.programName}'),
          if (res.learnerDisplayName != null)
            Text('Recipient: ${res.learnerDisplayName}'),
          if (res.completionDate != null)
            Text(
                'Completion Date: ${res.completionDate!.toLocal().toString().split(".").first}'),
          const SizedBox(height: 8),
          Text(res.message, style: TextStyle(fontSize: 12, color: fg)),
          const SizedBox(height: 8),
          Text(
            'Verified at: ${res.verificationTimestamp.toLocal().toString().split(".").first} (UTC) via SHA-256 Checksum.\nNotice: Tamper-evident checksum verified; not an asymmetric PKI digital signature.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
