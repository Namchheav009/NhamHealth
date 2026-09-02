import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

/// A scaffold that keeps page chrome readable while the main content scrolls.
///
/// The top bar belongs in [body], outside the page's scroll view. The bottom
/// navigation destinations hide while the user scrolls down and return when
/// they scroll up or reach the top of the page. Persistent actions, such as
/// the AI chatbot, can read [ScrollAwareNavigationVisibility] and stay visible.
class ScrollAwareScaffold extends StatefulWidget {
  const ScrollAwareScaffold({
    super.key,
    required this.body,
    required this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = true,
  });

  final Widget body;
  final Widget bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;

  @override
  State<ScrollAwareScaffold> createState() => _ScrollAwareScaffoldState();
}

class _ScrollAwareScaffoldState extends State<ScrollAwareScaffold> {
  bool _showBottomNavigation = true;

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.reverse:
          _setBottomNavigationVisible(false);
        case ScrollDirection.forward:
          _setBottomNavigationVisible(true);
        case ScrollDirection.idle:
          break;
      }
    } else if (notification.metrics.pixels <=
        notification.metrics.minScrollExtent) {
      _setBottomNavigationVisible(true);
    }

    return false;
  }

  void _setBottomNavigationVisible(bool visible) {
    if (_showBottomNavigation == visible || !mounted) return;
    setState(() => _showBottomNavigation = visible);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 240);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Scaffold(
        extendBody: widget.extendBody,
        backgroundColor: widget.backgroundColor,
        body: widget.body,
        bottomNavigationBar: ScrollAwareNavigationVisibility(
          visible: _showBottomNavigation,
          duration: duration,
          child: widget.bottomNavigationBar,
        ),
      ),
    );
  }
}

/// Shares scroll-driven navigation visibility with a bottom bar's children.
class ScrollAwareNavigationVisibility extends InheritedWidget {
  const ScrollAwareNavigationVisibility({
    super.key,
    required this.visible,
    required this.duration,
    required super.child,
  });

  final bool visible;
  final Duration duration;

  static ScrollAwareNavigationVisibility? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            ScrollAwareNavigationVisibility
          >();

  @override
  bool updateShouldNotify(ScrollAwareNavigationVisibility oldWidget) =>
      visible != oldWidget.visible || duration != oldWidget.duration;
}
