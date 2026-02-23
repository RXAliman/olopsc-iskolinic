import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_desktop_app/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicApp());
    // Verify login screen renders
    expect(find.text('Clinic Admin'), findsOneWidget);
  });
}
