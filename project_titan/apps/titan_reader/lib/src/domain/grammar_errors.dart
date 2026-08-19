/// Typed errors raised by grammar checking.
///
/// The UI never renders raw transport or parse errors; every failure is one
/// of these types so the panel can show an explicit, honest state.
library;

/// Base type for all grammar-check failures.
sealed class GrammarCheckError implements Exception {
  final String message;
  final Object? cause;

  const GrammarCheckError(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// The local grammar engine failed to run (e.g. a corrupt spelling index).
class GrammarEngineException extends GrammarCheckError {
  const GrammarEngineException(super.message, [super.cause]);
}

/// An optional remote grammar engine was unreachable, timed out or returned
/// a non-success status. Never fatal: local results remain available.
class GrammarRemoteException extends GrammarCheckError {
  const GrammarRemoteException(super.message, [super.cause]);
}

/// An optional remote grammar engine answered with a malformed payload.
class GrammarRemoteParseException extends GrammarCheckError {
  const GrammarRemoteParseException(super.message, [super.cause]);
}
