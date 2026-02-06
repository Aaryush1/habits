import 'package:flutter/material.dart';

/// Shared shadow presets for elevated surfaces.
abstract class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x24000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
