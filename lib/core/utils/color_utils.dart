import 'package:flutter/material.dart';

/// Parses a hex color string (with or without '#' prefix) into a Color.
/// Returns null if the string is null, empty, or unparseable.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final normalized = hex.replaceAll('#', '');
    final value = int.parse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    return Color(value);
  } catch (_) {
    return null;
  }
}
