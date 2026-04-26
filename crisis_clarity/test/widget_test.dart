import 'package:flutter_test/flutter_test.dart';
import 'package:crisis_clarity/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CrisisClarityApp());

    // Verify that our app loads by finding the title text
    expect(find.text('CrisisClarity'), findsWidgets);
  });
}
