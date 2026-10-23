import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sarthi_pilot/core/app_colors.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/views/driver_view.dart';
import 'package:sarthi_pilot/views/login_view.dart';

/// Splash screen displayed when the application launches.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(seconds: 2),
    this.nextScreen,
  });

  /// Duration to show the splash screen before navigating.
  final Duration minimumDuration;

  /// Optional destination widget for testing or custom navigation.
  final Widget? nextScreen;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  /// Waits for minimum display duration, checks saved login, and navigates.
  Future<void> _startApp() async {
    // Wait for the splash screen duration
    await Future.delayed(widget.minimumDuration);

    if (!mounted) return;

    // Determine which screen to open
    Widget destination;
    if (widget.nextScreen != null) {
      destination = widget.nextScreen!;
    } else {
      final user = _checkSavedLogin();
      destination = user != null
          ? DriverView(driverUser: user)
          : const LoginView();
    }

    if (!mounted) return;

    // Navigate to the next screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  /// Checks if the driver was previously logged in.
  DriverUser? _checkSavedLogin() {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final email = currentUser.email ?? '';
        final name =
            currentUser.displayName ??
            (email.isNotEmpty
                ? email.split('@').first.replaceAll('.', ' ').toUpperCase()
                : 'DRIVER');
        return DriverUser(uid: currentUser.uid, email: email, name: name);
      }
    } catch (e) {
      debugPrint('Auto sign-in check notice: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decorative circle 1 (top right)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF009B6A).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Background decorative circle 2 (bottom left)
          Positioned(
            bottom: -70,
            left: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF009B6A).withValues(alpha: 0.06),
              ),
            ),
          ),

          // Background decorative circle 3 (center right)
          Positioned(
            top: 260,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF009B6A).withValues(alpha: 0.05),
              ),
            ),
          ),

          // Foreground content
          SafeArea(
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Logo container
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009B6A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'SARTHI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF14241F),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    const Text(
                      'Pilot',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF14241F),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    const Text(
                      'Your campus. One easy ride.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7873),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shuttle badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'EV Carts • Campus Shuttles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF00875A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Loading spinner
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF009B6A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // College network label
                    const Text(
                      'IIT ROPAR TRANSIT NETWORK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8B9692),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
