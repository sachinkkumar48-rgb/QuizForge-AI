library;

import '../../domain/entities/editorial_role.dart';
import 'review_models.dart';

class EditorialAssignment {
  final String id;
  final String objectId;
  final String reviewerId;
  final String reviewerName;
  final EditorialRole reviewerRole;
  final ReviewerTier tier;
  final DateTime assignedAt;
  final bool isCompleted;

  const EditorialAssignment({
    required this.id,
    required this.objectId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerRole,
    required this.tier,
    required this.assignedAt,
    this.isCompleted = false,
  });

  EditorialAssignment copyWith({bool? isCompleted}) {
    return EditorialAssignment(
      id: id,
      objectId: objectId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerRole: reviewerRole,
      tier: tier,
      assignedAt: assignedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class EditorialAssignmentService {
  final Map<String, List<EditorialAssignment>> _assignmentsByObject = {};
  final Map<String, int> _reviewerWorkload = {};

  EditorialAssignment assignReviewer({
    required String objectId,
    required String reviewerId,
    required String reviewerName,
    required EditorialRole reviewerRole,
    ReviewerTier tier = ReviewerTier.singleReviewer,
  }) {
    final assignment = EditorialAssignment(
      id: 'assign_${DateTime.now().millisecondsSinceEpoch}_$reviewerId',
      objectId: objectId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerRole: reviewerRole,
      tier: tier,
      assignedAt: DateTime.now(),
    );

    _assignmentsByObject.putIfAbsent(objectId, () => []).add(assignment);
    _reviewerWorkload[reviewerId] = (_reviewerWorkload[reviewerId] ?? 0) + 1;

    return assignment;
  }

  void completeAssignment(String objectId, String reviewerId) {
    final list = _assignmentsByObject[objectId];
    if (list != null) {
      final index = list.indexWhere((a) => a.reviewerId == reviewerId && !a.isCompleted);
      if (index != -1) {
        list[index] = list[index].copyWith(isCompleted: true);
        _reviewerWorkload[reviewerId] = ((_reviewerWorkload[reviewerId] ?? 1) - 1).clamp(0, 99999);
      }
    }
  }

  List<EditorialAssignment> getAssignmentsForObject(String objectId) {
    return List.unmodifiable(_assignmentsByObject[objectId] ?? []);
  }

  Map<String, int> getReviewerWorkloads() {
    return Map.unmodifiable(_reviewerWorkload);
  }

  String? autoAssignReviewer(List<String> availableReviewerIds, {Map<String, int>? currentWorkloads}) {
    if (availableReviewerIds.isEmpty) return null;
    final workloads = currentWorkloads ?? _reviewerWorkload;
    availableReviewerIds.sort((a, b) => (workloads[a] ?? 0).compareTo(workloads[b] ?? 0));
    return availableReviewerIds.first;
  }
}
