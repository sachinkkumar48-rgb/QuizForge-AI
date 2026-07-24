/// Strongly typed route identifiers for Project TITAN.
class TitanRoutes {
  TitanRoutes._();

  static const String initial = '/';
  static const String home = '/home';
  static const String notFound = '/404';

  /// List of registered core system routes.
  static const List<String> allRoutes = [
    initial,
    home,
    notFound,
  ];
}
