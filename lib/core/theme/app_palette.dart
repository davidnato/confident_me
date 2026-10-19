import 'package:flutter/material.dart';

/// The colour palettes a person can choose in Settings. Each one is a seed
/// colour: Material 3 builds a full set of matching, accessible colours from it
/// for both light and dark mode. [id] is saved, so never change an existing id.
enum AppPalette {
  lavender(
    id: 'lavender',
    label: 'Lavender',
    seed: Color(0xFF6A5ACD),
    lightBackground: Color(0xFFF5F3FF),
    tertiaryLight: Color(0xFF2E9E93),
    tertiaryDark: Color(0xFF7ADBD0),
  ),
  ocean(
    id: 'ocean',
    label: 'Ocean',
    seed: Color(0xFF2F7FD8),
    lightBackground: Color(0xFFF1F6FD),
    tertiaryLight: Color(0xFF2E9E93),
    tertiaryDark: Color(0xFF7ADBD0),
  ),
  mint(
    id: 'mint',
    label: 'Mint',
    seed: Color(0xFF2E9E93),
    lightBackground: Color(0xFFF0F8F6),
    tertiaryLight: Color(0xFF6A5ACD),
    tertiaryDark: Color(0xFFB8AEF2),
  ),
  rose(
    id: 'rose',
    label: 'Rose',
    seed: Color(0xFFC2578A),
    lightBackground: Color(0xFFFDF2F7),
    tertiaryLight: Color(0xFF2E9E93),
    tertiaryDark: Color(0xFF7ADBD0),
  ),
  sunrise(
    id: 'sunrise',
    label: 'Sunrise',
    seed: Color(0xFFD9822B),
    lightBackground: Color(0xFFFFF7EE),
    tertiaryLight: Color(0xFF2E9E93),
    tertiaryDark: Color(0xFF7ADBD0),
  );

  const AppPalette({
    required this.id,
    required this.label,
    required this.seed,
    required this.lightBackground,
    required this.tertiaryLight,
    required this.tertiaryDark,
  });

  final String id;
  final String label;
  final Color seed;

  /// Soft tint behind the screens in light mode.
  final Color lightBackground;
  final Color tertiaryLight;
  final Color tertiaryDark;

  /// Unknown or missing ids fall back to Lavender.
  static AppPalette fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return AppPalette.lavender;
  }
}
