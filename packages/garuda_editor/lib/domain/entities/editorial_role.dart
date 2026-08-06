library;

/// Prepared permissions roles for GARUDA Editorial Studio.
enum EditorialRole {
  editor,
  seniorEditor,
  reviewer,
  administrator;

  static const EditorialRole peerReviewer = EditorialRole.reviewer;

  String get label {
    switch (this) {
      case EditorialRole.editor:
        return 'Editor';
      case EditorialRole.seniorEditor:
        return 'Senior Editor';
      case EditorialRole.reviewer:
        return 'Reviewer';
      case EditorialRole.administrator:
        return 'Administrator';
    }
  }

  bool get canApprovePublishing =>
      this == EditorialRole.seniorEditor || this == EditorialRole.administrator;

  bool get canManageSettings => this == EditorialRole.administrator;
}
