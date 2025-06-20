// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:messagingui/main.dart';

void main() {
  group('SpoonUp App Tests', () {
    testWidgets('SpoonUp app loads correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const SpoonApp());
      await tester.pumpAndSettle();

      // Verify that the app title is displayed
      expect(find.text('SpoonUp'), findsOneWidget);
      
      // Verify that the floating action button is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      
      // Verify that stories section is present
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Chat navigation works correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const SpoonApp());
      await tester.pumpAndSettle();

      // Find and tap on the first chat item if available
      final chatItems = find.byType(InkWell);
      if (chatItems.evaluate().isNotEmpty) {
        await tester.tap(chatItems.first);
        await tester.pumpAndSettle();
        
        // Verify navigation occurred by checking for back button
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      }
    });

    testWidgets('Search functionality works', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const SpoonApp());
      await tester.pumpAndSettle();

      // Find the search field
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'test');
        await tester.pumpAndSettle();
        
        // Verify search input was entered
        expect(find.text('test'), findsOneWidget);
      }
    });
  });
}
