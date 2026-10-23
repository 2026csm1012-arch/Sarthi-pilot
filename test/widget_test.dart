import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_pilot/main.dart';

void main() {
  testWidgets('Driver login screen validates, fills credentials and logs in', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiPilotApp());
    await tester.pumpAndSettle();

    // Verify Login Screen Elements
    expect(find.text('SARTHI'), findsOneWidget);
    expect(find.text('PILOT'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Auto-fill demo credentials'), findsOneWidget);

    // Try signing in with empty fields -> shows validation errors
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your email'), findsOneWidget);

    // Click Auto-fill demo credentials
    await tester.tap(find.text('Auto-fill demo credentials'));
    await tester.pumpAndSettle();
    expect(find.text('driver@iitrpr.ac.in'), findsOneWidget);

    // Sign In
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Now on Driver Screen
    expect(find.text('IIT ROPAR TRANSIT'), findsOneWidget);
    expect(find.text('OPERATOR DASHBOARD'), findsOneWidget);
    expect(find.text('Driver & Bus Control'), findsOneWidget);

    // Accept a ride request
    expect(find.text('Satlej Hostel → JC Bose Block'), findsOneWidget);
    await tester.tap(find.text('Accept').first);
    await tester.pumpAndSettle();
    expect(find.text('Satlej Hostel → JC Bose Block'), findsNothing);

    // Sign Out
    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();

    // Returned to Login Screen
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('City Bus Scanner validates tickets accurately in DriverScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiPilotApp());
    await tester.pumpAndSettle();

    // Quick login
    await tester.tap(find.text('Auto-fill demo credentials'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Switch to City Bus Scanner
    await tester.tap(find.text('City Bus Scanner'));
    await tester.pumpAndSettle();

    expect(find.text('Scan Student Ticket'), findsOneWidget);
    expect(find.text('Open Camera QR Scanner'), findsOneWidget);
    expect(find.text('Ready to scan incoming passengers...'), findsOneWidget);

    // Test valid ticket TKT-8841 using quick chip
    await tester.tap(find.text('TKT-8841 (Valid)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified Successfully!'), findsOneWidget);

    // Test verifying same ticket again (already used)
    await tester.tap(find.text('TKT-8841 (Valid)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('was already used!'), findsOneWidget);

    // Test verifying invalid ticket
    await tester.tap(find.text('TKT-9999 (Invalid)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Invalid Ticket ID'), findsOneWidget);
  });

  testWidgets('SplashScreen displays branding elements properly', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiPilotApp());

    // Initially on splash screen before settling duration
    expect(find.text('SARTHI'), findsOneWidget);
    expect(find.text('Your campus. One easy ride.'), findsOneWidget);
    expect(find.text('EV Carts • Campus Shuttles'), findsOneWidget);
    expect(find.text('IIT ROPAR TRANSIT NETWORK'), findsOneWidget);

    // Let splash finish and navigate to login
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });
}

