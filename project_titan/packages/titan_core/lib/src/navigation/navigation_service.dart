import 'package:flutter/widgets.dart';

/// Abstract Navigation Service contract for Clean Architecture decoupled navigation in Project TITAN.
abstract class NavigationService {
  /// Global navigator key attached to the MaterialApp instance.
  GlobalKey<NavigatorState> get navigatorKey;

  /// Navigate to a named route.
  Future<T?>? pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  });

  /// Navigate to a named route and replace the current route.
  Future<T?>? pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  });

  /// Pop the current route off the navigator stack.
  void pop<T extends Object?>([T? result]);

  /// Pop routes until the predicate returns true.
  void popUntil(bool Function(Route<dynamic>) predicate);

  /// Push a named route and remove routes until the predicate returns true.
  Future<T?>? pushNamedAndRemoveUntil<T extends Object?>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  });
}
