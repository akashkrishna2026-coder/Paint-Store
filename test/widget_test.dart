import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:c_h_p/widgets/home_sections.dart';

Widget _wrapForTest(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('SectionTitle smoke test renders text', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrapForTest(
        const SectionTitle('Smoke Test Title'),
      ),
    );

    expect(find.text('Smoke Test Title'), findsOneWidget);
  });
}
