import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/auth_controller.dart';
import 'package:sarthi_pilot/views/driver_view.dart';

/// Driver Firebase authentication view in MVC architecture.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _authController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Pre-fills credentials for testing
  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'driver@iitrpr.ac.in';
      _passwordController.text = 'driver123';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final user = _isRegistering
        ? await _authController.register(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await _authController.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (user != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => DriverView(driverUser: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _authController.errorMessage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // App Brand Icon
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(
                        Icons.electric_rickshaw,
                        color: Color(0xFF059669),
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Brand Titles
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SARTHI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PILOT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Center(
                    child: Text(
                      'IIT Ropar Transit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF71717A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error Banner if present
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  const Text(
                    'Operator Email',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F3F46),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF18181B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. driver@iitrpr.ac.in',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA1A1AA),
                      ),
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        size: 20,
                        color: Color(0xFF71717A),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: _authController.validateEmail,
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F3F46),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF18181B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your password (min 6 chars)',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA1A1AA),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Color(0xFF71717A),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF71717A),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: _authController.validatePassword,
                  ),

                  const SizedBox(height: 12),

                  // Quick Demo Credentials Chip
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _fillDemoCredentials,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 14,
                              color: Color(0xFF059669),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Auto-fill demo credentials',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button (Sign In / Register)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _authController.isLoading
                          ? null
                          : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _authController.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegistering ? 'Register' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Toggle between Sign In and Register
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                        });
                      },
                      child: Text(
                        _isRegistering
                            ? 'Already registered? Sign In'
                            : "Don't have an operator account? Register",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Footer security disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF4F4F5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFFA1A1AA),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Secured with Firebase Authentication. Operator role policies apply.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}
