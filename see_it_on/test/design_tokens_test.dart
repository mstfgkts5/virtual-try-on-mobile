import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/design/theme.dart';
import 'package:see_it_on/core/design/tokens.dart';

void main() {
  test('açık ve koyu belirteçler', () {
    expect(SeeItOnTokens.light.accent, const Color(0xFF7A2E3A));
    expect(SeeItOnTokens.light.paper, const Color(0xFFF6F3EE));
    expect(SeeItOnTokens.dark.paper, const Color(0xFF121110));
    expect(SeeItOnTokens.dark.ink, const Color(0xFFF3EFE7));
    expect(buildTheme(Brightness.dark).extension<SeeItOnTokens>(), SeeItOnTokens.dark);
    expect(buildTheme(Brightness.light).scaffoldBackgroundColor, SeeItOnTokens.light.paper);
  });

  test('tipografi ölçeği', () {
    final t = buildTheme(Brightness.light).textTheme;
    expect(t.headlineLarge!.fontFamily, 'PlayfairDisplay');
    expect(t.headlineLarge!.fontSize, 32);
    expect(t.displaySmall!.fontSize, 40);
    expect(t.bodyMedium!.fontFamily, 'Inter');
    expect(t.labelSmall!.fontSize, 11);
    expect(t.labelSmall!.letterSpacing, 1.6);
  });

  test('belirteçler arası geçiş (lerp) uçlarda doğru', () {
    expect(SeeItOnTokens.light.lerp(SeeItOnTokens.dark, 1).paper, SeeItOnTokens.dark.paper);
  });
}
