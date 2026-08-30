import 'package:flutter/material.dart';

abstract class AppShadows {
  AppShadows._();

  static const List<BoxShadow> surface = [
    BoxShadow(color: Color(0x0F31543F), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x8FFFFFFF), blurRadius: 4, offset: Offset(-1, -2)),
  ];

  static const List<BoxShadow> search = [
    BoxShadow(color: Color(0x0C31543F), blurRadius: 14, offset: Offset(0, 5)),
  ];

  static const List<BoxShadow> tile = [
    BoxShadow(color: Color(0x0D263D30), blurRadius: 10, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> notificationTile = [
    BoxShadow(color: Color(0x12263D30), blurRadius: 10, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x73FFFFFF), blurRadius: 4, offset: Offset(-1, -2)),
  ];

  static const List<BoxShadow> image = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> selectedNavigation = [
    BoxShadow(color: Color(0x244DBE84), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> innerSurface = [
    BoxShadow(color: Color(0x1000522F), blurRadius: 8, offset: Offset(-1, -1)),
    BoxShadow(color: Color(0x8FFFFFFF), blurRadius: 4, offset: Offset(1, 1)),
  ];

  static const List<BoxShadow> innerSelectedNavigation = [
    BoxShadow(color: Color(0x1F006231), blurRadius: 6, offset: Offset(-1, -1)),
    BoxShadow(color: Color(0x406AF09F), blurRadius: 3, offset: Offset(1, 1)),
  ];
}
