import 'reader_deep_link_request.dart';

/// Engine-independent interface for handling deep-link navigation into TITAN Reader.
abstract interface class ReaderDeepLinkHandler {
  /// Navigates the application or reader interface to the specified document source location.
  /// Returns true if navigation succeeded, or false if the target document or location could not be resolved.
  Future<bool> openReaderToSource(ReaderDeepLinkRequest request);
}

/// In-memory test double & default implementation of [ReaderDeepLinkHandler].
class InMemoryReaderDeepLinkHandler implements ReaderDeepLinkHandler {
  final List<ReaderDeepLinkRequest> handledRequests = [];
  bool Function(ReaderDeepLinkRequest request)? onNavigate;

  InMemoryReaderDeepLinkHandler({this.onNavigate});

  @override
  Future<bool> openReaderToSource(ReaderDeepLinkRequest request) async {
    handledRequests.add(request);
    if (onNavigate != null) {
      return onNavigate!(request);
    }
    return true;
  }

  void clear() {
    handledRequests.clear();
  }
}
