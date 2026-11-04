import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/screens/wardrobe_screen.dart';

import 'helpers.dart';

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

  testWidgets('gardırop TR başlığı', (tester) async {
    await tester.pumpWidget(localized(const WardrobeScreen()));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('GARDIROBUM'), findsOneWidget);
  });
}
