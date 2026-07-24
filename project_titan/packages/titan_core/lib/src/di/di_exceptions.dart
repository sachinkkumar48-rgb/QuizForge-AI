/// Base exception for dependency injection errors in Project TITAN.
abstract class TitanServiceLocatorException implements Exception {
  final String message;
  const TitanServiceLocatorException(this.message);

  @override
  String toString() => 'TitanServiceLocatorException: $message';
}

/// Thrown when attempting to resolve a service type that has not been registered.
class TitanMissingDependencyException extends TitanServiceLocatorException {
  final Type type;

  TitanMissingDependencyException(this.type)
      : super(
            'Service of type $type is not registered in TitanServiceLocator.');
}

/// Thrown when attempting to register a service type that is already registered
/// without setting allowOverride = true.
class TitanDuplicateDependencyException extends TitanServiceLocatorException {
  final Type type;

  TitanDuplicateDependencyException(this.type)
      : super(
            'Service of type $type is already registered in TitanServiceLocator. Use allowOverride: true to overwrite.');
}
