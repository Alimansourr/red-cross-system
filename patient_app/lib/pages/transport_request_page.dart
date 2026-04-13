import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/patient_input_decoration.dart';
import '../widgets/patient_label.dart';
import '../widgets/patient_section_card.dart';
import '../services/transport_request_service.dart';


class TransportRequestPage extends StatefulWidget {
  const TransportRequestPage({super.key});

  @override
  State<TransportRequestPage> createState() => _TransportRequestPageState();
}

class _TransportRequestPageState extends State<TransportRequestPage> {
  final TransportRequestService _service = TransportRequestService();

  final TextEditingController _pickupLocationController =
  TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _preferredDateController =
  TextEditingController();
  final TextEditingController _preferredTimeController =
  TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedTransportType;
  bool _isLoading = false;
  AssignedTransportStation? _lastAssignedStation;

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _destinationController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      _preferredDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _pickPreferredTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      _preferredTimeController.text = DateFormat('hh:mm a').format(dateTime);
    }
  }

  Future<void> _submitTransportRequest() async {
    final transportType = _selectedTransportType;
    final pickupLocation = _pickupLocationController.text.trim();
    final destination = _destinationController.text.trim();
    final preferredDate = _preferredDateController.text.trim();
    final preferredTime = _preferredTimeController.text.trim();
    final notes = _notesController.text.trim();

    if (transportType == null ||
        pickupLocation.isEmpty ||
        destination.isEmpty ||
        preferredDate.isEmpty ||
        preferredTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required transport fields.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _service.submitTransportRequest(
        transportType: transportType,
        pickupLocation: pickupLocation,
        destination: destination,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        notes: notes,
      );

      if (!mounted) return;

      setState(() {
        _lastAssignedStation = result.station;
        _selectedTransportType = null;
      });

      _pickupLocationController.clear();
      _destinationController.clear();
      _preferredDateController.clear();
      _preferredTimeController.clear();
      _notesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transport request sent to ${result.station.stationName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send transport request: $e'),
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
              'Assigned Station',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: patientAppBar(context, 'Transport Request'),
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Transport Service',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your transport request will be saved to Firebase and assigned to the nearest active station.',
                        style: TextStyle(color: Color(0xff6b7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _assignedStationCard(),
                PatientSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PatientLabel('Transport Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTransportType,
                        items: const [
                          DropdownMenuItem(
                            value: 'home_to_hospital',
                            child: Text('Home to Hospital'),
                          ),
                          DropdownMenuItem(
                            value: 'hospital_to_home',
                            child: Text('Hospital to Home'),
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
                            _selectedTransportType = value;
                          });
                        },
                        decoration: patientInputDecoration(
                          'Select transport type',
                        ),
                      ),
                      const SizedBox(height: 16),

                      const PatientLabel('Pickup Location'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pickupLocationController,
                        enabled: !_isLoading,
                        decoration: patientInputDecoration(
                          'Enter pickup location',
                        ),
                      ),
                      const SizedBox(height: 16),

                      const PatientLabel('Destination'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _destinationController,
                        enabled: !_isLoading,
                        decoration:
                        patientInputDecoration('Enter destination'),
                      ),
                      const SizedBox(height: 16),

                      const PatientLabel('Preferred Date'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _preferredDateController,
                        readOnly: true,
                        onTap: _isLoading ? null : _pickPreferredDate,
                        decoration: patientInputDecoration(
                          'Select date',
                        ).copyWith(
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const PatientLabel('Preferred Time'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _preferredTimeController,
                        readOnly: true,
                        onTap: _isLoading ? null : _pickPreferredTime,
                        decoration: patientInputDecoration(
                          'Select time (AM/PM)',
                        ).copyWith(
                          suffixIcon: const Icon(Icons.access_time_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const PatientLabel('Notes'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        enabled: !_isLoading,
                        maxLines: 4,
                        decoration: patientInputDecoration(
                          'Additional information',
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                          _isLoading ? null : _submitTransportRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffef3b4c),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                              : const Text('Submit Transport Request'),
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