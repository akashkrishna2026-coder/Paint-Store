import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_p/widgets/home_sections.dart'; // Import the file to test

// A helper function to wrap our widget in a MaterialApp
// This is needed to give it context (like text direction, themes, etc.)
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('HomeSections Widgets Test', () {

    // Test 1: Test the SectionTitle widget
    testWidgets('SectionTitle displays the correct title text', (WidgetTester tester) async {
      // 1. Pump the widget
      await tester.pumpWidget(
        createTestableWidget(
          const SectionTitle('Our Top Brands'),
        ),
      );

      // 2. Find the widget by its text
      final titleFinder = find.text('Our Top Brands');

      // 3. Verify it exists
      expect(titleFinder, findsOneWidget);
    });

    // Test 2: Test the HeroSection content
    testWidgets('HeroSection displays its title and button', (WidgetTester tester) async {
      // 1. Pump the widget
      // Note: This widget might have dependencies (like url_launcher)
      // but for just finding text, it's usually fine.
      await tester.pumpWidget(
        createTestableWidget(
          const HeroSection(),
        ),
      );

      // 2. Find the text widgets
      final titleFinder = find.text('Paint Your World');
      final subtitleFinder = find.text('Find the perfect color for your home, with free delivery.');
      final buttonFinder = find.text('Explore Products');

      // 3. Verify they all exist
      expect(titleFinder, findsOneWidget);
      expect(subtitleFinder, findsOneWidget);
      expect(buttonFinder, findsOneWidget);
    });

    // Test 3: Test the FooterSection content
    testWidgets('FooterSection displays its title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          const FooterSection(),
        ),
      );

      // Find the main title in the footer
      expect(find.text('Chandra Paints'), findsOneWidget);
    });

  });
}
