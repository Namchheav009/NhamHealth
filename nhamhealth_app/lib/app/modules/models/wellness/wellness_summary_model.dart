import 'package:flutter/material.dart';

class WellnessSummaryModel {
  final String name;
  final String current;
  final String target;
  final String unit;
  final int percentage;
  final IconData icon;
  final Color color;

  const WellnessSummaryModel({
    required this.name,
    required this.current,
    required this.target,
    required this.unit,
    required this.percentage,
    required this.icon,
    required this.color,
  });

  double get progress => percentage / 100;
}
