import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_input_app/main.dart';

void main() {
  testWidgets('App launches with QR scan screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicInputApp());
    await tester.pump();

    // Verify QR scan screen elements are present
    expect(find.text('Connect to Clinic'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
