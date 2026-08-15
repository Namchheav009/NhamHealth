import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  AppSpacing._();

  static const double pageHorizontal = 20;
  static const double pageTop = 16;
  static const double pageBottom = 32;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    pageHorizontal,
    pageTop,
    pageHorizontal,
    pageBottom,
  );

  static const EdgeInsets pagePaddingWithNavigation = EdgeInsets.fromLTRB(
    pageHorizontal,
    pageTop,
    pageHorizontal,
    100,
  );
}
