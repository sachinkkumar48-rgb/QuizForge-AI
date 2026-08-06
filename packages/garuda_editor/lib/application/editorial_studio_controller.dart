library;

import 'package:flutter/foundation.dart';
import 'package:garuda_evidence/garuda_evidence.dart' hide EditorialStatus;
import 'package:garuda_graph/garuda_graph.dart';
import '../domain/entities/audit_log_entry.dart';
import '../domain/entities/dashboard_metrics.dart';
import '../domain/entities/editorial_role.dart';
import '../domain/entities/editorial_status.dart';
import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_object_version.dart';
import '../domain/repositories/editorial_repository.dart';
import '../infrastructure/in_memory_editorial_repository.dart';
import '../validators/knowledge_object_validator.dart';

/// Central state controller for GARUDA Editorial Studio.
class EditorialStudioController extends ChangeNotifier {
  final EditorialRepository repository;
  final KnowledgeGraphRepository graphRepository;

  int _currentTabIndex = 0;
  EditorialRole _currentRole = EditorialRole.seniorEditor;
  bool _isDarkMode = true;
  String _searchQuery = '';
  String _activeFilterCategory = 'All';

  List<KnowledgeObject> _objects = [];
  KnowledgeObject? _selectedObject;
  List<KnowledgeObjectVersion> _selectedObjectVersions = [];
  List<AuditLogEntry> _auditLogs = [];
  DashboardMetrics _metrics = const DashboardMetrics();

  // Mock Evidence Inbox and Link Review storage for studio
  List<EvidenceObject> _evidenceInbox = [];
  List<KnowledgeLink> _pendingLinks = [];

  EditorialStudioController({
    EditorialRepository? repository,
    KnowledgeGraphRepository? graphRepository,
  })  : repository = repository ?? InMemoryEditorialRepository(),
        graphRepository = graphRepository ?? InMemoryKnowledgeGraphRepository() {
    _seedMockEvidenceAndLinks();
    _initializeData();
  }

  // Getters
  int get currentTabIndex => _currentTabIndex;
  EditorialRole get currentRole => _currentRole;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;
  String get activeFilterCategory => _activeFilterCategory;
  List<KnowledgeObject> get objects => List.unmodifiable(_objects);
  KnowledgeObject? get selectedObject => _selectedObject;
  List<KnowledgeObjectVersion> get selectedObjectVersions => List.unmodifiable(_selectedObjectVersions);
  List<AuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);
  DashboardMetrics get metrics => _metrics;
  List<EvidenceObject> get evidenceInbox => List.unmodifiable(_evidenceInbox);
  List<KnowledgeLink> get pendingLinks => List.unmodifiable(_pendingLinks);

  Future<void> _initializeData() async {
    await refreshData();
  }

  void _seedMockEvidenceAndLinks() {
    final now = DateTime.now();

    _evidenceInbox = [
      EvidenceObject(
        id: 'EV-PIB-2026-001',
        title: 'Cabinet Approves National Green Hydrogen Mission Guidelines',
        sourceName: 'PIB Release',
        sourceType: EvidenceSourceType.government,
        authority: const EvidenceAuthority(id: 'pib', name: 'Press Information Bureau', type: EvidenceSourceType.government, jurisdiction: 'India'),
        publicationDate: now.subtract(const Duration(hours: 4)),
        retrievedDate: now,
        category: 'Environment',
        subject: 'Environment',
        topic: 'Green Hydrogen',
        subtopic: 'Clean Energy Target',
        keywords: const ['Hydrogen', 'Art 48A', 'MNRE'],
        language: 'en',
        summary: 'Official notification on Rs 19,744 crore outlay for Green Hydrogen.',
        originalUrl: 'https://pib.gov.in/PressReleasePage.aspx?PRID=1888500',
        knowledgeObjectLinks: const KnowledgeObjectLinks(constitutionArticles: ['Art 48A']),
        createdAt: now,
        updatedAt: now,
      ),
      EvidenceObject(
        id: 'EV-SC-2026-88',
        title: 'Supreme Court Ruling on Electoral Reforms & Transparency',
        sourceName: 'Supreme Court Judgments',
        sourceType: EvidenceSourceType.judiciary,
        authority: const EvidenceAuthority(id: 'sc', name: 'Supreme Court of India', type: EvidenceSourceType.judiciary, jurisdiction: 'India'),
        publicationDate: now.subtract(const Duration(hours: 12)),
        retrievedDate: now,
        category: 'Polity',
        subject: 'Polity',
        topic: 'Elections',
        subtopic: 'Right to Information',
        keywords: const ['Article 19', 'RTI', 'Elections'],
        language: 'en',
        summary: 'Five-judge bench holds voter information right as intrinsic to Article 19(1)(a).',
        originalUrl: 'https://sci.gov.in/judgments/2026/088.pdf',
        knowledgeObjectLinks: const KnowledgeObjectLinks(constitutionArticles: ['Art 19']),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    _pendingLinks = [
      KnowledgeLink(
        id: 'link_sug_001',
        sourceObject: const KnowledgeNodeRef(id: 'EV-PIB-2026-001', name: 'Green Hydrogen Release', nodeType: NodeType.evidence),
        targetObject: const KnowledgeNodeRef(id: 'KO-ENV-003', name: 'National Green Hydrogen Mission Guidelines', nodeType: NodeType.knowledgeObject),
        relationshipType: KnowledgeRelationshipType.interprets,
        confidenceScore: 0.95,
        createdAt: now,
        updatedAt: now,
        status: LinkStatus.linkReviewPending,
        evidenceReferences: const ['https://pib.gov.in/1888500'],
        reason: 'Exact keyword and MNRE directive alignment',
      ),
      KnowledgeLink(
        id: 'link_sug_002',
        sourceObject: const KnowledgeNodeRef(id: 'EV-SC-2026-88', name: 'Electoral Judgment', nodeType: NodeType.evidence),
        targetObject: const KnowledgeNodeRef(id: 'KO-POLITY-001', name: 'Right to Privacy & Article 21', nodeType: NodeType.knowledgeObject),
        relationshipType: KnowledgeRelationshipType.references,
        confidenceScore: 0.88,
        createdAt: now,
        updatedAt: now,
        status: LinkStatus.linkReviewPending,
        evidenceReferences: const ['https://sci.gov.in/088.pdf'],
        reason: 'Substantial constitutional bench reference',
      ),
    ];

    notifyListeners();
  }

  Future<void> refreshData() async {
    _metrics = await repository.getDashboardMetrics();
    _objects = await repository.getKnowledgeObjects(searchQuery: _searchQuery);
    _auditLogs = await repository.getAuditLogs();

    if (_selectedObject != null) {
      _selectedObject = await repository.getKnowledgeObjectById(_selectedObject!.id);
      if (_selectedObject != null) {
        _selectedObjectVersions = await repository.getVersionHistory(_selectedObject!.id);
      }
    } else if (_objects.isNotEmpty) {
      _selectedObject = _objects.first;
      _selectedObjectVersions = await repository.getVersionHistory(_selectedObject!.id);
    }
    notifyListeners();
  }

  void selectTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setRole(EditorialRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshData();
  }

  void setFilterCategory(String cat) {
    _activeFilterCategory = cat;
    notifyListeners();
  }

  void selectKnowledgeObject(KnowledgeObject object) async {
    _selectedObject = object;
    _selectedObjectVersions = await repository.getVersionHistory(object.id);
    notifyListeners();
  }

  // Knowledge Object Lifecycle Actions
  Future<KnowledgeObjectValidationResult> createKnowledgeObject(KnowledgeObject draft) async {
    final valRes = KnowledgeObjectValidator.validate(draft);
    if (!valRes.isValid) return valRes;

    final created = await repository.saveKnowledgeObject(
      draft,
      editor: _currentRole.label,
      changeSummary: 'Created initial draft in Editorial Studio',
    );

    _selectedObject = created;
    await refreshData();
    return KnowledgeObjectValidationResult.success();
  }

  Future<KnowledgeObjectValidationResult> updateKnowledgeObject(KnowledgeObject updated, String changeSummary) async {
    final valRes = KnowledgeObjectValidator.validate(updated);
    if (!valRes.isValid) return valRes;

    final res = await repository.updateKnowledgeObject(
      updated,
      editor: _currentRole.label,
      changeSummary: changeSummary,
    );

    _selectedObject = res;
    await refreshData();
    return KnowledgeObjectValidationResult.success();
  }

  Future<void> changeObjectStatus(String id, EditorialStatus newStatus, {String? comment}) async {
    await repository.changeStatus(id, newStatus, editor: _currentRole.label, comment: comment);
    await refreshData();
  }

  Future<void> duplicateObject(String id) async {
    final dup = await repository.duplicateKnowledgeObject(id, editor: _currentRole.label);
    _selectedObject = dup;
    await refreshData();
  }

  Future<void> deleteObject(String id, {String? reason}) async {
    await repository.deleteKnowledgeObject(id, editor: _currentRole.label, reason: reason);
    if (_selectedObject?.id == id) {
      _selectedObject = null;
    }
    await refreshData();
  }

  Future<void> restoreVersion(String objectId, int versionNumber) async {
    final restored = await repository.restoreVersion(objectId, versionNumber, editor: _currentRole.label);
    if (restored != null) {
      _selectedObject = restored;
      await refreshData();
    }
  }

  // Evidence Inbox Actions
  Future<void> approveEvidence(String evidenceId, {String? comment}) async {
    _evidenceInbox.removeWhere((e) => e.id == evidenceId);
    await repository.logAuditEntry(AuditLogEntry(
      id: 'aud_ev_${DateTime.now().millisecondsSinceEpoch}',
      editor: _currentRole.label,
      timestamp: DateTime.now(),
      action: 'EVIDENCE_APPROVED',
      objectId: evidenceId,
      comment: comment ?? 'Evidence approved for Knowledge Graph linking',
    ));
    await refreshData();
  }

  Future<void> rejectEvidence(String evidenceId, {String? reason}) async {
    _evidenceInbox.removeWhere((e) => e.id == evidenceId);
    await repository.logAuditEntry(AuditLogEntry(
      id: 'aud_ev_${DateTime.now().millisecondsSinceEpoch}',
      editor: _currentRole.label,
      timestamp: DateTime.now(),
      action: 'EVIDENCE_REJECTED',
      objectId: evidenceId,
      comment: reason ?? 'Evidence rejected',
    ));
    await refreshData();
  }

  // Link Review Actions
  Future<void> approveLink(String linkId) async {
    _pendingLinks.removeWhere((l) => l.id == linkId);
    await repository.logAuditEntry(AuditLogEntry(
      id: 'aud_lnk_${DateTime.now().millisecondsSinceEpoch}',
      editor: _currentRole.label,
      timestamp: DateTime.now(),
      action: 'LINK_APPROVED',
      objectId: linkId,
      comment: 'Suggested KnowledgeLink approved by editor',
    ));
    await refreshData();
  }

  Future<void> rejectLink(String linkId, {String? reason}) async {
    _pendingLinks.removeWhere((l) => l.id == linkId);
    await repository.logAuditEntry(AuditLogEntry(
      id: 'aud_lnk_${DateTime.now().millisecondsSinceEpoch}',
      editor: _currentRole.label,
      timestamp: DateTime.now(),
      action: 'LINK_REJECTED',
      objectId: linkId,
      comment: reason ?? 'Suggested KnowledgeLink rejected',
    ));
    await refreshData();
  }
}
