library;

import '../../domain/entities/editorial_status.dart';

/// State Machine controlling allowed status transitions across the 10 Editorial States.
class EditorialStateMachine {
  /// Defines valid transition targets from a given state.
  static const Map<EditorialStatus, Set<EditorialStatus>> _allowedTransitions = {
    EditorialStatus.imported: {
      EditorialStatus.pendingReview,
      EditorialStatus.draft,
      EditorialStatus.rejected,
    },
    EditorialStatus.draft: {
      EditorialStatus.pendingReview,
      EditorialStatus.rejected,
    },
    EditorialStatus.pendingReview: {
      EditorialStatus.inReview,
      EditorialStatus.rejected,
      EditorialStatus.needsRevision,
    },
    EditorialStatus.reviewPending: {
      EditorialStatus.inReview,
      EditorialStatus.rejected,
      EditorialStatus.needsRevision,
    },
    EditorialStatus.inReview: {
      EditorialStatus.evidenceVerified,
      EditorialStatus.needsRevision,
      EditorialStatus.rejected,
    },
    EditorialStatus.evidenceVerified: {
      EditorialStatus.factVerified,
      EditorialStatus.needsRevision,
      EditorialStatus.rejected,
    },
    EditorialStatus.factVerified: {
      EditorialStatus.technicalReview,
      EditorialStatus.needsRevision,
      EditorialStatus.rejected,
    },
    EditorialStatus.technicalReview: {
      EditorialStatus.seniorEditorialReview,
      EditorialStatus.needsRevision,
      EditorialStatus.rejected,
    },
    EditorialStatus.seniorEditorialReview: {
      EditorialStatus.approved,
      EditorialStatus.needsRevision,
      EditorialStatus.rejected,
    },
    EditorialStatus.approved: {
      EditorialStatus.published,
      EditorialStatus.needsRevision,
      EditorialStatus.archived,
    },
    EditorialStatus.published: {
      EditorialStatus.approved, // Unpublish action
      EditorialStatus.archived,
      EditorialStatus.seniorEditorialReview, // Republish workflow
    },
    EditorialStatus.needsRevision: {
      EditorialStatus.pendingReview,
      EditorialStatus.inReview,
      EditorialStatus.rejected,
    },
    EditorialStatus.rejected: {
      EditorialStatus.pendingReview,
      EditorialStatus.imported,
    },
    EditorialStatus.archived: {
      EditorialStatus.approved,
      EditorialStatus.pendingReview,
    },
  };

  /// Returns true if transition from [current] to [target] is valid.
  static bool canTransition(EditorialStatus current, EditorialStatus target) {
    if (current == target) return true;
    final allowed = _allowedTransitions[current];
    return allowed != null && allowed.contains(target);
  }

  /// Returns the next sequential forward stage in the 10-state progression.
  static EditorialStatus? getNextSequentialStage(EditorialStatus current) {
    switch (current) {
      case EditorialStatus.imported:
      case EditorialStatus.draft:
        return EditorialStatus.pendingReview;
      case EditorialStatus.pendingReview:
      case EditorialStatus.reviewPending:
        return EditorialStatus.inReview;
      case EditorialStatus.inReview:
        return EditorialStatus.evidenceVerified;
      case EditorialStatus.evidenceVerified:
        return EditorialStatus.factVerified;
      case EditorialStatus.factVerified:
        return EditorialStatus.technicalReview;
      case EditorialStatus.technicalReview:
        return EditorialStatus.seniorEditorialReview;
      case EditorialStatus.seniorEditorialReview:
        return EditorialStatus.approved;
      case EditorialStatus.approved:
        return EditorialStatus.published;
      case EditorialStatus.published:
        return EditorialStatus.archived;
      default:
        return null;
    }
  }
}
