import 'package:flutter/material.dart';

import 'tokens.dart';

const _display = 'PlayfairDisplay';
const _body = 'Inter';

/// Dergi tarzı tema: başlıklar Playfair Display, metin Inter; renkler [SeeItOnTokens]'tan.
ThemeData buildTheme(Brightness brightness) {
  final t = brightness == Brightness.dark ? SeeItOnTokens.dark : SeeItOnTokens.light;

  TextStyle serif(double size, {FontWeight weight = FontWeight.w500, double height = 1.15}) =>
      TextStyle(fontFamily: _display, fontSize: size, fontWeight: weight, height: height, color: t.ink, letterSpacing: -0.3);
  TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color? color, double? spacing}) =>
      TextStyle(fontFamily: _body, fontSize: size, fontWeight: weight, color: color ?? t.ink, letterSpacing: spacing);

  final textTheme = TextTheme(
    displaySmall: serif(40),
    headlineLarge: serif(32),
    headlineSmall: serif(22),
    titleMedium: sans(16, weight: FontWeight.w600),
    bodyMedium: sans(14),
    bodySmall: sans(12, color: t.muted),
    labelLarge: sans(14, weight: FontWeight.w600),
    labelSmall: sans(11, weight: FontWeight.w600, color: t.muted, spacing: 1.6),
  );

  final scheme = ColorScheme.fromSeed(
    seedColor: t.accent,
    brightness: brightness,
    primary: t.ink,
    onPrimary: t.paper,
    secondary: t.accent,
    surface: t.paper,
    onSurface: t.ink,
    error: t.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.paper,
    fontFamily: _body,
    textTheme: textTheme,
    extensions: [t],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: t.ink,
      centerTitle: false,
      titleTextStyle: serif(20),
    ),
    dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.ink,
      contentTextStyle: sans(13, color: t.paper),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SeeItOnTokens.radiusSm)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.paper,
      titleTextStyle: serif(22),
      contentTextStyle: sans(14, color: t.muted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SeeItOnTokens.radiusMd)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: t.paper,
      selectedItemColor: t.ink,
      unselectedItemColor: t.muted,
      selectedLabelStyle: sans(10, weight: FontWeight.w600, spacing: 1.2),
      unselectedLabelStyle: sans(10, spacing: 1.2),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent, linearTrackColor: t.line),
    sliderTheme: SliderThemeData(activeTrackColor: t.ink, inactiveTrackColor: t.line, thumbColor: t.ink),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: t.ink)),
  );
}
