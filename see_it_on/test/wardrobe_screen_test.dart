import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/core/design/tokens.dart';
import 'package:see_it_on/models/wardrobe_item.dart';
import 'package:see_it_on/screens/wardrobe_detail_screen.dart';
import 'package:see_it_on/screens/wardrobe_screen.dart';

import 'fakes.dart';
import 'helpers.dart';

WardrobeItem _item(String id, String category, int daysBack) => WardrobeItem(
      id: id,
      imageUrl: 'https://example.invalid/$id.png',
      category: category,
      createdAt: DateTime.now().subtract(Duration(days: daysBack)),
    );

Future<void> _open(WidgetTester tester, FakeWardrobeRepository repo, {String lang = 'tr'}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localized(WardrobeScreen(repository: repo), lang: lang));
  await tester.pumpAndSettle();
}

Finder _cards() => find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('wardrobe-card-'));

void main() {
  test('gün sayısı çoğul kurallarıyla çevrilir', () {
    expect(l10nFor('tr').wardrobeDaysAgo(1), 'Dün');
    expect(l10nFor('tr').wardrobeDaysAgo(4), '4 gün önce');
    expect(l10nFor('en').wardrobeDaysAgo(1), 'Yesterday');
    expect(l10nFor('en').wardrobeDaysAgo(4), '4 days ago');
  });

  test('kombin sayısı çoğul kurallarıyla çevrilir', () {
    expect(l10nFor('en').wardrobeCount(1), '1 saved look');
    expect(l10nFor('en').wardrobeCount(6), '6 saved looks');
    expect(l10nFor('tr').wardrobeCount(6), '6 kayıtlı kombin');
  });

  testWidgets('oturum yoksa giriş daveti gösterilir', (tester) async {
    await _open(tester, FakeWardrobeRepository(email: null));
    final l = l10nFor('tr');
    expect(find.text(l.wardrobeSignInTitle), findsOneWidget);
    expect(find.text(l.loginButton), findsOneWidget);
    expect(_cards(), findsNothing);
  });

  testWidgets('boş gardırop', (tester) async {
    await _open(tester, FakeWardrobeRepository());
    expect(find.text(l10nFor('tr').wardrobeEmptyTitle), findsOneWidget);
  });

  testWidgets('kayıtlar listelenir ve kategoriye göre süzülür', (tester) async {
    final repo = FakeWardrobeRepository(items: [_item('1', 'lower', 0), _item('2', 'upper', 1), _item('3', 'lower', 4)]);
    await _open(tester, repo);
    final l = l10nFor('tr');
    expect(find.text('GARDIROBUM'), findsOneWidget);
    expect(find.text(l.wardrobeCount(3)), findsOneWidget);
    expect(_cards(), findsNWidgets(3));
    expect(find.text(l.wardrobeDaysAgo(1)), findsOneWidget);

    await tester.tap(find.textContaining(l.categoryLower));
    await tester.pumpAndSettle();
    expect(_cards(), findsNWidgets(2));
    expect(find.byKey(const ValueKey('wardrobe-card-2')), findsNothing);
  });

  testWidgets('detaydan silme onayla kaldırır', (tester) async {
    final repo = FakeWardrobeRepository(items: [_item('1', 'lower', 0), _item('2', 'upper', 1)]);
    await _open(tester, repo);
    final l = l10nFor('tr');

    await tester.tap(find.byKey(const ValueKey('wardrobe-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l.wardrobeDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.wardrobeDeleteConfirm));
    await tester.pumpAndSettle();

    expect(repo.deleted, ['1']);
    expect(_cards(), findsNWidgets(1));
    expect(find.text(l.wardrobeCount(1)), findsOneWidget);
  });

  testWidgets('yükleme hatası tekrar denenebilir', (tester) async {
    final repo = FakeWardrobeRepository(items: [_item('1', 'upper', 0)], failFetch: true);
    await _open(tester, repo);
    final l = l10nFor('tr');
    expect(find.text(l.wardrobeLoadError), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text(l.wardrobeRetry));
    await tester.pumpAndSettle();
    expect(_cards(), findsNWidgets(1));
  });

  testWidgets('EN başlık', (tester) async {
    await _open(tester, FakeWardrobeRepository(items: [_item('1', 'upper', 0)]), lang: 'en');
    expect(find.text('MY WARDROBE'), findsOneWidget);
  });

  testWidgets('kayıtlı liste EN/koyu 360 taşmasız, zemin belirteçten', (tester) async {
    final repo = FakeWardrobeRepository(items: [_item('1', 'lower', 0), _item('2', 'upper', 1), _item('3', 'overall', 9)]);
    await expectNoOverflow(tester, WardrobeScreen(repository: repo), lang: 'en', b: Brightness.dark);
    expect(_cards(), findsNWidgets(3));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, SeeItOnTokens.dark.paper);
  });

  testWidgets('detay koyu temada belirteç zemini, silme düğmesi danger', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeWardrobeRepository(items: [_item('1', 'lower', 0)]);
    await tester.pumpWidget(localized(
      WardrobeDetailScreen(item: _item('1', 'lower', 0), repository: repo),
      lang: 'en',
      brightness: Brightness.dark,
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, SeeItOnTokens.dark.paper);

    await tester.tap(find.byTooltip(l10nFor('en').wardrobeDelete));
    await tester.pumpAndSettle();
    final confirm = tester.widget<Text>(find.text(l10nFor('en').wardrobeDeleteConfirm));
    expect(confirm.style?.color ?? DefaultTextStyle.of(tester.element(find.text(l10nFor('en').wardrobeDeleteConfirm))).style.color,
        SeeItOnTokens.dark.danger);
  });

  testWidgets('yenilenirken liste ekranda kalır', (tester) async {
    final repo = FakeWardrobeRepository(items: [_item('1', 'lower', 0), _item('2', 'upper', 1)]);
    await _open(tester, repo);
    final l = l10nFor('tr');

    await tester.tap(find.byKey(const ValueKey('wardrobe-card-1')));
    await tester.pumpAndSettle();
    repo.gate = Completer<void>(); // silmeden sonraki yenileme beklesin
    await tester.tap(find.byTooltip(l.wardrobeDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.wardrobeDeleteConfirm));
    await tester.pumpAndSettle();

    // Yenileme sürüyor: önceki liste görünmeye devam eder (iskelete dönmez)
    expect(find.byKey(const ValueKey('wardrobe-card-2')), findsOneWidget);

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(_cards(), findsNWidgets(1));
  });
}
