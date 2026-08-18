/// Privacy classification for documents managed by TITAN Reader.
///
/// The default state for every imported document is [localOnly]; document
/// content must never leave the device unless the user explicitly configures
/// and authorizes an external service in a later phase.
enum DocumentPrivacyState {
  /// Document content stays on the local device. Default for all imports.
  localOnly,

  /// User has explicitly allowed this document to be processed by a
  /// configured external AI service. Never assigned automatically.
  userApprovedExternal,
}

extension DocumentPrivacyStateX on DocumentPrivacyState {
  String get wireName {
    switch (this) {
      case DocumentPrivacyState.localOnly:
        return 'local_only';
      case DocumentPrivacyState.userApprovedExternal:
        return 'user_approved_external';
    }
  }

  static DocumentPrivacyState fromWire(String? value) {
    if (value == 'user_approved_external') {
      return DocumentPrivacyState.userApprovedExternal;
    }
    return DocumentPrivacyState.localOnly;
  }
}
