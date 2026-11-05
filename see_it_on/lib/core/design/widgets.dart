import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

/// Başlık üstü küçük büyük harf etiket ("NE DENEMEK İSTİYORSUN?").
/// Büyük harf metin ARB'de yazılır; burada `toUpperCase` yapılmaz (Türkçe i/İ).
class EditorialOverline extends StatelessWidget {
  const EditorialOverline(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color));
}

/// Playfair Display başlık.
class EditorialHeading extends StatelessWidget {
  const EditorialHeading(this.text, {super.key, this.size = 32, this.textAlign});

  final String text;
  final double size;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) =>
      Text(text, textAlign: textAlign, style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontSize: size));
}

/// Görsel altı / ikincil açıklama; dergi altyazısı gibi italik olabilir.
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key, this.italic = false, this.textAlign});

  final String text;
  final bool italic;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall!;
    return Text(
      text,
      textAlign: textAlign,
      style: italic
          ? base.copyWith(fontFamily: 'PlayfairDisplay', fontStyle: FontStyle.italic, fontSize: 14)
          : base,
    );
  }
}

/// 1 px ince ayırıcı.
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({super.key, this.verticalPadding = 0});

  final double verticalPadding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Container(height: 1, color: context.tokens.line),
      );
}

/// Hap biçimli buton. Birincil: ink zemin / paper yazı; ikincil: ince çerçeve.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool busy;

  /// true ise bulunduğu satırı boydan boya kaplar
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = primary ? t.paper : t.ink;
    final enabled = onPressed != null && !busy;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: 18, color: fg),
        if (busy || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: fg),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Material(
        color: primary ? t.ink : Colors.transparent,
        shape: StadiumBorder(side: primary ? BorderSide.none : BorderSide(color: t.ink.withValues(alpha: 0.25))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onPressed : null,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: content),
        ),
      ),
    );
  }
}

/// Eşit genişlikte hap seçici: kategori, dil, tema, karşılaştırma sekmeleri.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icons,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          for (final (id, label) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: id == value ? t.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(SeeItOnTokens.radiusPill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icons?[id] != null) ...[
                        Icon(icons![id], size: 15, color: id == value ? t.paper : t.muted),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                fontSize: 12,
                                color: id == value ? t.paper : t.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Yüzey kartı: surface zemin, ince çerçeve, büyük köşe yarıçapı.
class EditorialCard extends StatelessWidget {
  const EditorialCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(SeeItOnTokens.radiusLg),
        border: Border.all(color: t.line),
      ),
      child: child,
    );
  }
}

/// Dergi sayfası çevirir gibi: hafif sağdan kayarak ve solarak açılan ekran geçişi.
Future<T?> pushEditorial<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(
    context,
    PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}
