/// Administrative Role Based Access Control (RBAC) Roles in KMP.
enum KmpUserRole {
  editor,
  reviewer,
  publisher,
  administrator;

  String get label {
    switch (this) {
      case KmpUserRole.editor:
        return 'Content Editor / Author';
      case KmpUserRole.reviewer:
        return 'Subject Matter Reviewer';
      case KmpUserRole.publisher:
        return 'Publishing & Release Manager';
      case KmpUserRole.administrator:
        return 'System Administrator';
    }
  }

  bool get canAuthor => true;
  bool get canReview =>
      this == KmpUserRole.reviewer ||
      this == KmpUserRole.publisher ||
      this == KmpUserRole.administrator;
  bool get canPublish =>
      this == KmpUserRole.publisher || this == KmpUserRole.administrator;
  bool get canAdminister => this == KmpUserRole.administrator;
}

class KmpUserSession {
  final String userId;
  final String userName;
  final String email;
  final KmpUserRole role;

  const KmpUserSession({
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
  });
}
