import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moew_flutter/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MoewApp());
    await tester.pump();
    // App should render — basic smoke test
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
