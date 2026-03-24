import 'package:flutter/material.dart';

/// Dark-app [SegmentedButton] colors: cyan selection with light label/icon (not black on cyan).
ButtonStyle appDarkSegmentedButtonStyle() {
  return SegmentedButton.styleFrom(
    backgroundColor: const Color(0xFF1E293B),
    foregroundColor: const Color(0xFF94A3B8),
    selectedForegroundColor: const Color(0xFFF8FAFC),
    selectedBackgroundColor: const Color(0xFF06B6D4),
    side: const BorderSide(color: Color(0xFF334155)),
  );
}
