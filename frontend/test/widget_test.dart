import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MonitoringPklApp());

    // Verify that the login screen header is displayed
    expect(find.text('SMART PKL'), findsWidgets);
    expect(find.text('Sistem Monitoring PKL SMK'), findsOneWidget);
  });
}
