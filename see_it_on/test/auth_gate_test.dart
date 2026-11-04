import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:see_it_on/screens/auth_gate.dart';

Widget _gate(StreamController<bool> c, {required bool signedIn}) => MaterialApp(
      home: AuthGate(
        authStates: c.stream,
        initialSignedIn: signedIn,
        signedInBuilder: (_) => const Text('HOME'),
        signedOutBuilder: (_) => const Text('WELCOME'),
      ),
    );

void main() {
  testWidgets('başlangıçta oturum var → HOME', (tester) async {
    final c = StreamController<bool>();
    await tester.pumpWidget(_gate(c, signedIn: true));
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('WELCOME'), findsNothing);
    await c.close();
  });

  testWidgets('başlangıçta oturum yok → WELCOME', (tester) async {
    final c = StreamController<bool>();
    await tester.pumpWidget(_gate(c, signedIn: false));
    expect(find.text('WELCOME'), findsOneWidget);
    await c.close();
  });

  testWidgets('oturum açılınca HOME\'a geçer', (tester) async {
    final c = StreamController<bool>();
    await tester.pumpWidget(_gate(c, signedIn: false));
    c.add(true);
    await tester.pump();
    expect(find.text('HOME'), findsOneWidget);
    await c.close();
  });

  testWidgets('çıkış yapılınca HOME ağaçtan kalkar', (tester) async {
    final c = StreamController<bool>();
    await tester.pumpWidget(_gate(c, signedIn: true));
    c.add(false);
    await tester.pump();
    expect(find.text('WELCOME'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    await c.close();
  });
}
