import 'package:meta/meta.dart';
import '../../domain/entities/evidence_object.dart';

/// Status of an item in the editorial review queue.
enum QueueStatus {
  pending,
  approved,
  rejected,
}

/// Payload item held in the editorial review queue.
@immutable
class EditorialItem {
  final EvidenceObject evidence;
  final QueueStatus status;
  final DateTime enqueuedAt;
  final String? reviewer;
  final String? reviewNotes;
  final String? rejectionReason;

  const EditorialItem({
    required this.evidence,
    this.status = QueueStatus.pending,
    required this.enqueuedAt,
    this.reviewer,
    this.reviewNotes,
    this.rejectionReason,
  });

  EditorialItem copyWith({
    EvidenceObject? evidence,
    QueueStatus? status,
    DateTime? enqueuedAt,
    String? reviewer,
    String? reviewNotes,
    String? rejectionReason,
  }) {
    return EditorialItem(
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      enqueuedAt: enqueuedAt ?? this.enqueuedAt,
      reviewer: reviewer ?? this.reviewer,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'evidence': evidence.toJson(),
        'status': status.name,
        'enqueuedAt': enqueuedAt.toIso8601String(),
        'reviewer': reviewer,
        'reviewNotes': reviewNotes,
        'rejectionReason': rejectionReason,
      };

  factory EditorialItem.fromJson(Map<String, dynamic> json) => EditorialItem(
        evidence: EvidenceObject.fromJson(
            Map<String, dynamic>.from(json['evidence'] as Map)),
        status: QueueStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => QueueStatus.pending,
        ),
        enqueuedAt: DateTime.tryParse(json['enqueuedAt'] as String? ?? '') ??
            DateTime.now(),
        reviewer: json['reviewer'] as String?,
        reviewNotes: json['reviewNotes'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EditorialItem &&
        other.evidence.id == evidence.id &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(evidence.id, status);
}

/// Abstract contract for managing Evidence Objects in the editorial approval pipeline.
abstract class EditorialQueue {
  Future<EditorialItem> enqueue(EvidenceObject evidence, {String? reason});
  Future<EditorialItem?> approve(String evidenceId,
      {required String reviewer, String? notes});
  Future<EditorialItem?> reject(String evidenceId,
      {required String reviewer, required String reason});
  Future<EditorialItem?> assignReviewer(String evidenceId, String reviewer);
  Future<EditorialItem?> markReviewed(String evidenceId, String reviewer);
  Future<List<EditorialItem>> pending();
  Future<List<EditorialItem>> approved();
  Future<List<EditorialItem>> rejected();
}

/// In-memory thread-safe implementation of [EditorialQueue].
class InMemoryEditorialQueue implements EditorialQueue {
  final Map<String, EditorialItem> _queue = {};

  @override
  Future<EditorialItem> enqueue(EvidenceObject evidence, {String? reason}) async {
    final item = EditorialItem(
      evidence: evidence,
      status: QueueStatus.pending,
      enqueuedAt: DateTime.now(),
      reviewNotes: reason,
    );
    _queue[evidence.id] = item;
    return item;
  }

  @override
  Future<EditorialItem?> approve(String evidenceId,
      {required String reviewer, String? notes}) async {
    final item = _queue[evidenceId];
    if (item == null) return null;

    final updated = item.copyWith(
      status: QueueStatus.approved,
      reviewer: reviewer,
      reviewNotes: notes ?? 'Approved for publishing',
    );
    _queue[evidenceId] = updated;
    return updated;
  }

  @override
  Future<EditorialItem?> reject(String evidenceId,
      {required String reviewer, required String reason}) async {
    final item = _queue[evidenceId];
    if (item == null) return null;

    final updated = item.copyWith(
      status: QueueStatus.rejected,
      reviewer: reviewer,
      rejectionReason: reason,
    );
    _queue[evidenceId] = updated;
    return updated;
  }

  @override
  Future<EditorialItem?> assignReviewer(String evidenceId, String reviewer) async {
    final item = _queue[evidenceId];
    if (item == null) return null;

    final updated = item.copyWith(reviewer: reviewer);
    _queue[evidenceId] = updated;
    return updated;
  }

  @override
  Future<EditorialItem?> markReviewed(String evidenceId, String reviewer) async {
    return await assignReviewer(evidenceId, reviewer);
  }

  @override
  Future<List<EditorialItem>> pending() async {
    return _queue.values
        .where((i) => i.status == QueueStatus.pending)
        .toList();
  }

  @override
  Future<List<EditorialItem>> approved() async {
    return _queue.values
        .where((i) => i.status == QueueStatus.approved)
        .toList();
  }

  @override
  Future<List<EditorialItem>> rejected() async {
    return _queue.values
        .where((i) => i.status == QueueStatus.rejected)
        .toList();
  }
}
