import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer_app_poc/app.dart';

void main() {
  testWidgets('CRM App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CRMApp(),
      ),
    );

    // Verify that the app title is present.
    expect(find.text('CRM Dialer'), findsOneWidget);
  });
}
