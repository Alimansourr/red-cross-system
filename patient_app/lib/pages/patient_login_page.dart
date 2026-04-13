import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/patient_input_decoration.dart';
import '../widgets/patient_section_card.dart';
import '../services/auth_service.dart';
import '../services/emergency_request_service.dart';
import 'patient_signup_page.dart';
import 'patient_home_page.dart';

class PatientLoginPage extends StatefulWidget {
  const PatientLoginPage({super.key});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final AuthService _authService = AuthService();
  final EmergencyRequestService _emergencyService = EmergencyRequestService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isEmergencyLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginPatient() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginPatient(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientHomePage(),
        ),
            (route) => false,
      );
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      final errorText = e.toString();

      if (errorText.contains('user-not-found')) {
        errorMessage = 'No account found for this email.';
      } else if (errorText.contains('wrong-password') ||
          errorText.contains('invalid-credential')) {
        errorMessage = 'Incorrect email or password.';
      } else if (errorText.contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _call140() async {
    final uri = Uri(scheme: 'tel', path: '140');
    final launched = await launchUrl(uri);
    if (!launched) {
      throw Exception('Could not call 140.');
    }
  }

  Future<void> _handleQuickEmergency() async {
    setState(() {
      _isEmergencyLoading = true;
    });

    try {
      final result = await _emergencyService.submitQuickEmergencyCall();
      await _call140();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Calling 140 now. Your location was sent to ${result.station.stationName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency action failed: $e'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isEmergencyLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xffffeef1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 48,
                      color: Color(0xffef3b4c),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Patient Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to request emergency help, transportation, and send feedback.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff6b7280),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PatientSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: patientInputDecoration('Enter your email'),
                        ),
                        const SizedBox(height: 18),
                        const Text('Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration:
                          patientInputDecoration('Enter your password'),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginPatient,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffef3b4c),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PatientSignupPage(),
                                ),
                              );
                            },
                            child: const Text('Create a patient account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                    _isEmergencyLoading ? null : _handleQuickEmergency,
                    icon: _isEmergencyLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.call),
                    label: Text(
                      _isEmergencyLoading
                          ? 'Starting emergency...'
                          : 'Emergency? Call 140 now',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffef3b4c),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}