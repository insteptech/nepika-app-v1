import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepika/core/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton renders and responds to tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Tap Me',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );
    expect(find.text('Tap Me'), findsOneWidget);
    await tester.tap(find.text('Tap Me'));
    await tester.pump();
    expect(tapped, isTrue);
  });
} 