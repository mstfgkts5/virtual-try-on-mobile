import 'package:flutter/material.dart';

/// SeeItOn dergi tarzı tasarım sisteminin renk belirteçleri (açık / koyu).
/// Ekranlar renkleri doğrudan yazmak yerine `context.tokens` üzerinden okur;
/// böylece koyu mod ve tutarlılık tek yerden yönetilir.
@immutable
class SeeItOnTokens extends ThemeExtension<SeeItOnTokens> {
  const SeeItOnTokens({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.danger,
  });

  /// Zemin (dergi kâğıdı)
  final Color paper;

  /// Kartlar ve giriş alanları
  final Color surface;

  /// Metin ve birincil buton
  final Color ink;

  /// İkincil metin
  final Color muted;

  /// İnce ayırıcı çizgiler ve çerçeveler
  final Color line;

  /// Vurgu: seçili durum, künye, ilerleme
  final Color accent;

  /// Silme ve hata
  final Color danger;

  static const light = SeeItOnTokens(
    paper: Color(0xFFF6F3EE),
    surface: Color(0xB3FFFFFF), // beyaz %70
    ink: Color(0xFF1E1C1A),
    muted: Color(0xFF8A847C),
    line: Color(0xFFE4DED3),
    accent: Color(0xFF7A2E3A),
    danger: Color(0xFFB42318),
  );

  static const dark = SeeItOnTokens(
    paper: Color(0xFF121110),
    surface: Color(0xFF1C1A18),
    ink: Color(0xFFF3EFE7),
    muted: Color(0xFFA39C92),
    line: Color(0xFF2E2B27),
    accent: Color(0xFFC9737F),
    danger: Color(0xFFF97066),
  );

  /// Köşe yarıçapları: yalnızca bu değerler kullanılır
  static const radiusSm = 12.0;
  static const radiusMd = 20.0;
  static const radiusLg = 28.0;
  static const radiusPill = 999.0;

  @override
  SeeItOnTokens copyWith({
    Color? paper,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? accent,
    Color? danger,
  }) =>
      SeeItOnTokens(
        paper: paper ?? this.paper,
        surface: surface ?? this.surface,
        ink: ink ?? this.ink,
        muted: muted ?? this.muted,
        line: line ?? this.line,
        accent: accent ?? this.accent,
        danger: danger ?? this.danger,
      );

  @override
  SeeItOnTokens lerp(ThemeExtension<SeeItOnTokens>? other, double t) {
    if (other is! SeeItOnTokens) return this;
    return SeeItOnTokens(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension TokensX on BuildContext {
  SeeItOnTokens get tokens => Theme.of(this).extension<SeeItOnTokens>() ?? SeeItOnTokens.light;
}
