import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:see_it_on/main.dart';
import 'package:see_it_on/providers/tryon_provider.dart';

void main() {
  testWidgets('App starts with SeeItOn title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TryOnProvider()),
        ],
        child: const SeeItOnApp(),
      ),
    );

    // Verify app brand is present
    expect(find.text('SeeItOn'), findsOneWidget);
  });
}
