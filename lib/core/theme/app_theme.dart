import 'package:flutter/material.dart';

// ─── Brand Colors ──────────────────────────────────────────────────────────

const _primaryNavy = Color(0xFF1B3A5C);
const _goldAccent = Color(0xFFC49A2A);

// ─── Status Colors ─────────────────────────────────────────────────────────

class AppColors {
  // Status — light
  static const paidLight = Color(0xFF1B8A50);
  static const sentLight = Color(0xFFC49A2A);
  static const draftLight = Color(0xFF73777F);
  static const overdueLight = Color(0xFFBA1A1A);

  // Status — dark
  static const paidDark = Color(0xFF6FDD9B);
  static const sentDark = Color(0xFFE8C35A);
  static const draftDark = Color(0xFF8D9199);
  static const overdueDark = Color(0xFFFFB4AB);

  /// Get status color based on brightness
  static Color paid(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? paidDark : paidLight;

  static Color sent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? sentDark : sentLight;

  static Color draft(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? draftDark : draftLight;

  static Color overdue(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? overdueDark
          : overdueLight;

  /// Revenue / money highlight
  static Color revenue(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE8C35A)
          : _goldAccent;

  /// Expense / cost
  static Color expense(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? overdueDark
          : overdueLight;

  // Note colors (consistent across themes)
  static const noteBlue = Color(0xFF1B3A5C);
  static const noteGreen = Color(0xFF1B8A50);
  static const noteOrange = Color(0xFFC49A2A);
  static const noteRed = Color(0xFFBA1A1A);
  static const notePurple = Color(0xFF6750A4);
  static const noteTeal = Color(0xFF006B5E);
}

// ─── Typography Tokens ──────────────────────────────────────────────────────
/// Centralized text style tokens for cross-screen consistency.
/// Reference direction: Jobs screen (compact, operational, confident).
///
/// Usage: `AppTextStyles.sectionHeader(textTheme)` in build methods
/// where `textTheme = Theme.of(context).textTheme`.
class AppTextStyles {
  AppTextStyles._();

  // ── Section Headers ────────────────────────────────────────────────
  /// Dashboard section headers: "Urgent", "Recent Jobs", etc.
  static TextStyle sectionHeader(TextTheme t) =>
      t.titleMedium!.copyWith(fontWeight: FontWeight.w700);

  // ── Card Content ───────────────────────────────────────────────────
  /// Primary card title — client name, item name. 14/w700.
  static TextStyle cardTitle(TextTheme t) =>
      t.titleSmall!.copyWith(fontWeight: FontWeight.w700);

  /// Card subtitle — description, metadata line. 12/w400 muted.
  static TextStyle cardSubtitle(TextTheme t, ColorScheme c) =>
      t.bodySmall!.copyWith(color: c.onSurfaceVariant);

  /// Card amount — money values. 14/w800 for scannable emphasis.
  static TextStyle cardAmount(TextTheme t) =>
      t.titleSmall!.copyWith(fontWeight: FontWeight.w800);

  // ── Badges ─────────────────────────────────────────────────────────
  /// Status / type badge text. 10/w800.
  static TextStyle badge(Color color) =>
      TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800);

  // ── Action Chips ───────────────────────────────────────────────────
  /// Inline action chip label. 11/w700.
  static TextStyle chipLabel(Color color) =>
      TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700);

  // ── Metadata ───────────────────────────────────────────────────────
  /// Date, timestamp, secondary info. bodySmall muted.
  static TextStyle metadata(TextTheme t, ColorScheme c) =>
      t.bodySmall!.copyWith(color: c.onSurfaceVariant);

  // ── Sheet Titles ───────────────────────────────────────────────────
  /// Bottom sheet / dialog titles. 16/w700.
  static TextStyle sheetTitle(TextTheme t) =>
      t.titleMedium!.copyWith(fontWeight: FontWeight.w700);

  // ── Empty States ───────────────────────────────────────────────────
  static TextStyle emptyTitle(TextTheme t, ColorScheme c) =>
      t.titleSmall!.copyWith(
        color: c.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      );

  static TextStyle emptyBody(TextTheme t, ColorScheme c) =>
      t.bodySmall!.copyWith(color: c.onSurfaceVariant);
}

// ─── Light Theme ───────────────────────────────────────────────────────────

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primaryNavy,
    brightness: Brightness.light,
    primary: _primaryNavy,
    tertiary: _goldAccent,
    surface: const Color(0xFFFAFCFF),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,

    // Typography — system font with custom scale
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0),
      displayMedium: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.15),
      bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),

    // Dividers
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      thickness: 0.5,
      space: 0,
    ),

    // Tab bar — 12px operational, w800 selected for confident active state
    tabBarTheme: TabBarThemeData(
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.primary,
      unselectedLabelColor:
          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      labelStyle:
          const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    // Bottom sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),

    // Snack bar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

// ─── Dark Theme ────────────────────────────────────────────────────────────

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primaryNavy,
    brightness: Brightness.dark,
    tertiary: const Color(0xFFE8C35A),
    surface: const Color(0xFF111318),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,

    // Typography — inherit from dark theme base
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0),
      displayMedium: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.15),
      bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Navigation bar
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),

    // Dividers
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      thickness: 0.5,
      space: 0,
    ),

    // Tab bar — 12px operational, w800 selected for confident active state
    tabBarTheme: TabBarThemeData(
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.primary,
      unselectedLabelColor:
          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      labelStyle:
          const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    // Bottom sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),

    // Snack bar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
