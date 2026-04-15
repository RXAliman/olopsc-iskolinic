import 'package:flutter_test/flutter_test.dart';
import 'package:student_mobile_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentApp());
    await tester.pumpAndSettle();

    // Verify the login screen is shown
    expect(find.text('VVella Student'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
