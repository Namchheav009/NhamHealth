import 'package:flutter/widgets.dart';

/// Gives the shared bottom bar access to the persistent main tabs.
class MainTabScope extends InheritedWidget {
  const MainTabScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final ValueChanged<int> selectTab;

  static MainTabScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MainTabScope>();

  @override
  bool updateShouldNotify(covariant MainTabScope oldWidget) => false;
}
