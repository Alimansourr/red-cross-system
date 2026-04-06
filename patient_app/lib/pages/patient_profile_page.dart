import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/patient_input_decoration.dart';
import '../widgets/patient_label.dart';
import '../widgets/patient_section_card.dart';
import '../services/patient_profile_service.dart';

class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({super.key});

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff111827),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(
      BuildContext context,
      Map<String, dynamic> currentData,
      ) async {
    await showDialog(
      context: context,
      builder: (_) => EditProfileDialog(currentData: currentData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileService = PatientProfileService();
    final currentUser = profileService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: patientAppBar(context, 'Profile'),
        body: const Center(
          child: Text('No patient is currently logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: patientAppBar(context, 'Profile'),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileService.getPatientProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xffef3b4c),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load profile.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Patient profile not found.'),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final fullName = (data['fullName'] ?? 'Not provided').toString();
          final email =
          (data['email'] ?? currentUser.email ?? 'Not provided').toString();
          final phone = (data['phone'] ?? 'Not provided').toString();
          final address = (data['address'] ?? 'Not provided').toString();
          final age = (data['age'] ?? 'Not provided').toString();
          final bloodType = (data['bloodType'] ?? 'Not provided').toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: PatientSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffffeef1),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xffef3b4c),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Color(0xff6b7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _infoTile('Phone Number', phone),
                      _infoTile('Address', address),
                      _infoTile('Age', age),
                      _infoTile('Blood Type', bloodType),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showEditProfileDialog(context, data),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> currentData;

  const EditProfileDialog({
    super.key,
    required this.currentData,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final PatientProfileService _profileService = PatientProfileService();

  late final TextEditingController fullNameController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;
  late final TextEditingController ageController;

  String? selectedBloodType;
  bool isSaving = false;

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

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: (widget.currentData['fullName'] ?? '').toString(),
    );
    phoneController = TextEditingController(
      text: (widget.currentData['phone'] ?? '').toString(),
    );
    addressController = TextEditingController(
      text: (widget.currentData['address'] ?? '').toString(),
    );
    ageController = TextEditingController(
      text: (widget.currentData['age'] ?? '').toString(),
    );

    final blood = widget.currentData['bloodType']?.toString().trim();
    selectedBloodType = (blood != null && blood.isNotEmpty) ? blood : null;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final ageText = ageController.text.trim();

    if (fullName.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name, phone, and address are required.'),
        ),
      );
      return;
    }

    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid age.'),
          ),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      await _profileService.updatePatientProfile(
        fullName: fullName,
        phone: phone,
        address: address,
        age: age,
        bloodType: selectedBloodType,
      );

      if (!mounted) return;

      FocusScope.of(context).unfocus();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const PatientLabel('Address'),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                maxLines: 3,
                decoration: patientInputDecoration('Enter your address'),
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
              const SizedBox(height: 10),
              const Text(
                'Email is read-only here because changing login email needs Firebase Auth update too.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffef3b4c),
            foregroundColor: Colors.white,
          ),
          child: isSaving
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Save'),
        ),
      ],
    );
  }
}