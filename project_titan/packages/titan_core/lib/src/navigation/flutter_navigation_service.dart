import 'package:flutter/widgets.dart';

import 'navigation_service.dart';

/// Concrete Flutter implementation of [NavigationService] using [GlobalKey<NavigatorState>].
class FlutterNavigationService implements NavigationService {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  FlutterNavigationService({GlobalKey<NavigatorState>? key})
      : navigatorKey = key ?? GlobalKey<NavigatorState>();

  NavigatorState? get _currentState => navigatorKey.currentState;

  @override
  Future<T?>? pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  @override
  Future<T?>? pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return _currentState?.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  @override
  void pop<T extends Object?>([T? result]) {
    if (_currentState?.canPop() ?? false) {
      _currentState?.pop<T>(result);
    }
  }

  @override
  void popUntil(bool Function(Route<dynamic>) predicate) {
    _currentState?.popUntil(predicate);
  }

  @override
  Future<T?>? pushNamedAndRemoveUntil<T extends Object?>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return _currentState?.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }
}
