import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme Mode Provider ─────────────────────────────────────────────────────

const _kThemeModeKey = 'theme_mode';

enum AppThemeMode { system, light, dark }

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kThemeModeKey);
      switch (stored) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    } catch (_) {
      // Keep default ThemeMode.system if SharedPreferences fails
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (mode) {
        case ThemeMode.light:
          await prefs.setString(_kThemeModeKey, 'light');
          break;
        case ThemeMode.dark:
          await prefs.setString(_kThemeModeKey, 'dark');
          break;
        case ThemeMode.system:
          await prefs.setString(_kThemeModeKey, 'system');
          break;
      }
    } catch (_) {
      // Persist failure is non-critical — theme is already applied in memory
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
