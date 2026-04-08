import 'package:flutter/material.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/patient_input_decoration.dart';
import '../widgets/patient_label.dart';
import '../widgets/patient_section_card.dart';
import '../services/auth_service.dart';
import 'patient_home_page.dart';

class PatientSignupPage extends StatefulWidget {
  const PatientSignupPage({super.key});

  @override
  State<PatientSignupPage> createState() => _PatientSignupPageState();
}

class _PatientSignupPageState extends State<PatientSignupPage> {
  final AuthService _authService = AuthService();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController medicalHistoryController =
  TextEditingController();

  String? selectedBloodType;

  final List<String> bloodTypes = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    addressController.dispose();
    ageController.dispose();
    medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _signUpPatient() async {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final address = addressController.text.trim();
    final ageText = ageController.text.trim();
    final medicalHistory = medicalHistoryController.text.trim();
    final bloodType = selectedBloodType;

    if (fullName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        address.isEmpty ||
        ageText.isEmpty ||
        bloodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
        ),
      );
      return;
    }

    final age = int.tryParse(ageText);

    if (age == null || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpPatient(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        address: address,
        age: age,
        bloodType: bloodType,
        medicalHistory: medicalHistory,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientHomePage(),
        ),
            (route) => false,
      );
    } catch (e) {
      String errorMessage = 'Signup failed. Please try again.';

      final errorText = e.toString();

      if (errorText.contains('email-already-in-use')) {
        errorMessage = 'This email is already in use.';
      } else if (errorText.contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      } else if (errorText.contains('weak-password')) {
        errorMessage = 'Weak password. Please choose a stronger one.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: patientAppBar(context, 'Create Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: PatientSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Registration',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create your patient account to request emergency help, transport, and send feedback.',
                    style: TextStyle(color: Color(0xff6b7280)),
                  ),
                  const SizedBox(height: 24),

                  const PatientLabel('Full Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fullNameController,
                    decoration: patientInputDecoration('Enter your full name'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Phone Number'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: patientInputDecoration('Enter your phone number'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Email'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: patientInputDecoration('Enter your email'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: patientInputDecoration('Create a password'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressController,
                    maxLines: 3,
                    decoration: patientInputDecoration('Enter your home address'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Age'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: patientInputDecoration('Enter your age'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Blood Type'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedBloodType,
                    items: bloodTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBloodType = value;
                      });
                    },
                    decoration: patientInputDecoration('Select blood type'),
                  ),
                  const SizedBox(height: 16),

                  const PatientLabel('Medical History'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: medicalHistoryController,
                    maxLines: 4,
                    decoration: patientInputDecoration(
                      'Enter allergies, chronic conditions, surgeries, medications...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUpPatient,
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
                          : const Text('Create Account'),
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