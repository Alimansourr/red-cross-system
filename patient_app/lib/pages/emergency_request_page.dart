import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/patient_app_bar.dart';
import '../widgets/patient_input_decoration.dart';
import '../widgets/patient_label.dart';
import '../widgets/patient_section_card.dart';
import '../services/emergency_request_service.dart';

class EmergencyRequestPage extends StatefulWidget {
  const EmergencyRequestPage({super.key});

  @override
  State<EmergencyRequestPage> createState() => _EmergencyRequestPageState();
}

class _EmergencyRequestPageState extends State<EmergencyRequestPage> {
  final EmergencyRequestService _service = EmergencyRequestService();

  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedEmergencyType;
  File? _selectedImage;

  bool _isLoading = false;
  AssignedStation? _lastAssignedStation;

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickEmergencyImageFromCamera() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _pickEmergencyImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _submitEmergencyRequest() async {
    final isGuest = _service.currentUser == null;
    final guestName = _guestNameController.text.trim();
    final guestPhone = _guestPhoneController.text.trim();
    final emergencyType = _selectedEmergencyType;
    final currentCondition = _conditionController.text.trim();

    if (isGuest && guestName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name.'),
        ),
      );
      return;
    }

    if (isGuest && guestPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number.'),
        ),
      );
      return;
    }

    if (emergencyType == null || currentCondition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required emergency fields.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _service.submitEmergencyRequest(
        emergencyType: emergencyType,
        currentCondition: currentCondition,
        guestName: guestName,
        guestPhone: guestPhone,
        emergencyImageFile: _selectedImage,
      );

      if (!mounted) return;

      setState(() {
        _lastAssignedStation = result.station;
        _selectedEmergencyType = null;
        _selectedImage = null;
      });

      _guestNameController.clear();
      _guestPhoneController.clear();
      _conditionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Emergency request sent to ${result.station.stationName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send emergency request: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _assignedStationCard() {
    final station = _lastAssignedStation;

    if (station == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffeff6ff),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffbfdbfe)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearest Assigned Station',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff111827),
              ),
            ),
            const SizedBox(height: 8),
            Text('Name: ${station.stationName}'),
            Text('Distance: ${station.distanceKm.toStringAsFixed(2)} km'),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PatientLabel('Emergency Image'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff9fafb),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe5e7eb)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                      _isLoading ? null : _pickEmergencyImageFromCamera,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        _selectedImage == null
                            ? 'Take Photo'
                            : 'Retake Photo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                      _isLoading ? null : _pickEmergencyImageFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove image',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Optional: attach a photo to help the station understand the situation.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _service.currentUser == null;

    return Scaffold(
      appBar: patientAppBar(context, 'Emergency Request'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xffffeef1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xfffecdd3)),
                  ),
                  child: Text(
                    isGuest
                        ? 'You can send an emergency request without logging in. Your current location will be captured automatically and assigned to the nearest station.'
                        : 'Your current location will be captured automatically and your profile information will be sent with the request to the nearest station.',
                    style: const TextStyle(color: Color(0xff6b7280)),
                  ),
                ),
                const SizedBox(height: 20),
                _assignedStationCard(),
                PatientSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isGuest) ...[
                        const PatientLabel('Your Name'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _guestNameController,
                          enabled: !_isLoading,
                          decoration: patientInputDecoration('Enter your name'),
                        ),
                        const SizedBox(height: 16),
                        const PatientLabel('Phone Number'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _guestPhoneController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: patientInputDecoration(
                            'Enter contact number',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const PatientLabel('Emergency Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedEmergencyType,
                        items: const [
                          DropdownMenuItem(
                            value: 'medical',
                            child: Text('Medical Emergency'),
                          ),
                          DropdownMenuItem(
                            value: 'injury',
                            child: Text('Injury / Trauma'),
                          ),
                          DropdownMenuItem(
                            value: 'breathing',
                            child: Text('Breathing Problem'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                          setState(() {
                            _selectedEmergencyType = value;
                          });
                        },
                        decoration: patientInputDecoration(
                          'Select emergency type',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const PatientLabel('Current Condition'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _conditionController,
                        maxLines: 4,
                        enabled: !_isLoading,
                        decoration: patientInputDecoration(
                          'Describe the patient situation briefly',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _imagePickerSection(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                          _isLoading ? null : _submitEmergencyRequest,
                          icon: _isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.local_hospital_outlined),
                          label: Text(
                            _isLoading
                                ? 'Sending...'
                                : 'Send Emergency Request',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffef3b4c),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}