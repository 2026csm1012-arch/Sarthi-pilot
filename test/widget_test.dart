import 'package:flutter/material.dart';
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
    expect(find.text('PILOT'), findsAtLeastNWidgets(1));
    expect(find.text('IIT Ropar Transit'), findsOneWidget);

    // Verify EV Cart role is active based on driver@iitrpr.ac.in
    expect(find.text('EV Cart Campus Transit'), findsOneWidget);
    expect(find.text('OFFLINE • VEHICLE INACTIVE'), findsOneWidget);

    // Verify no hardcoded requests initially
    expect(find.text('No active ride requests'), findsOneWidget);

    // Test Ride History button in App Bar next to Profile
    await tester.tap(find.byKey(const ValueKey('app_bar_history_button')));
    await tester.pumpAndSettle();
    expect(find.text('Driver History & Logs'), findsOneWidget);

    // Back from Ride History screen
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Open Driver Profile via Circle Profile photo in title bar
    await tester.tap(find.byKey(const ValueKey('app_bar_profile_button')));
    await tester.pumpAndSettle();

    // Verify Profile elements: Driver ID, Driver Mail only in profile card, Device Battery, Assigned Cart
    expect(find.text('Driver Profile'), findsOneWidget);
    expect(find.text('DRIVER ID'), findsOneWidget);
    expect(find.text('driver@iitrpr.ac.in'), findsOneWidget);
    expect(find.text('Assigned Cart & Fleet'), findsOneWidget);
    expect(find.text('Mobile Device & Telemetry'), findsOneWidget);
    expect(find.text('Device Battery'), findsOneWidget);
    // Verify Portal Shortcuts & Tools is removed from profile
    expect(find.text('Portal Shortcuts & Tools'), findsNothing);

    // Sign Out via Profile
    final logoutButton = find.text('Log Out from Driver Portal');
    await tester.scrollUntilVisible(logoutButton, 200);
    await tester.drag(find.byType(ListView).last, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Returned to Login Screen
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('City Bus Scanner validates tickets accurately in DriverScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiPilotApp());
    await tester.pumpAndSettle();

    // Login with Bus Operator credentials (role fixed to bus via email)
    await tester.tap(find.text('Auto-fill Bus Operator'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Directly in City Bus panel
    expect(find.text('City Bus Transit Service'), findsOneWidget);
    expect(find.text('Scan Student Ticket'), findsOneWidget);
    expect(find.text('Open Camera QR Scanner'), findsOneWidget);
    expect(find.text('Ready to scan incoming passengers...'), findsOneWidget);

    // Test valid ticket TKT-8841 using text input
    await tester.enterText(find.byType(TextField), 'TKT-8841');
    await tester.tap(find.text('Verify & Check-In Passenger'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified Successfully!'), findsOneWidget);

    // Test verifying same ticket again (already used)
    await tester.enterText(find.byType(TextField), 'TKT-8841');
    await tester.tap(find.text('Verify & Check-In Passenger'));
    await tester.pumpAndSettle();
    expect(find.textContaining('was already used!'), findsOneWidget);

    // Test verifying invalid ticket
    await tester.enterText(find.byType(TextField), 'TKT-9999');
    await tester.tap(find.text('Verify & Check-In Passenger'));
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

