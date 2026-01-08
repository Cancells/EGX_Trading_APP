import 'package:flutter_test/flutter_test.dart';
import 'package:statch_app/main.dart';

void main() {
  testWidgets('Statch app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StatchApp());

    // Verify the app renders
    expect(find.text('Statch'), findsWidgets);
  });
}
