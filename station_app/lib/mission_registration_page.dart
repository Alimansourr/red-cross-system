import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'station_dashboard_page.dart';
import 'services/mission_service.dart';
import 'helpers/auth_helper.dart';

class MissionRegistrationPage extends StatefulWidget {
  final bool fromLogin;

  const MissionRegistrationPage({
    super.key,
    required this.fromLogin,
  });

  @override
  State<MissionRegistrationPage> createState() =>
      _MissionRegistrationPageState();
}

class _MissionRegistrationPageState extends State<MissionRegistrationPage> {
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientPhoneController = TextEditingController();
  final TextEditingController patientAgeController = TextEditingController();
  final TextEditingController subcodeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController departureAreaController = TextEditingController();
  final TextEditingController stop1Controller = TextEditingController();
  final TextEditingController stop2Controller = TextEditingController();

  String? selectedCar;
  String? missionType;
  String? missionStatus;
  String? gender;
  String? selectedDriver;
  String? selectedMissionLeader;
  String? selectedPatientId;

  String _loggedInName = '';
  String _loggedInSubcode = '';

  List<String> carNumbers = [];
  List<String> drivers = [];
  List<String> missionLeaders = [];
  List<Map<String, dynamic>> patients = [];

  bool _loadingData = true;
  bool _isSubmitting = false;

  final MissionService _missionService = MissionService();

  final List<String> types = ["Emergency", "Transfer"];
  final List<String> statuses = ["Pending", "Completed"];
  final List<String> genders = ["Male", "Female"];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    dateController.text =
    '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
    _loadData();
  }

  @override
  void dispose() {
    patientNameController.dispose();
    patientPhoneController.dispose();
    patientAgeController.dispose();
    subcodeController.dispose();
    dateController.dispose();
    departureAreaController.dispose();
    stop1Controller.dispose();
    stop2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');

      final firestore = FirebaseFirestore.instance;

      // 1) Logged-in user info
      final currentUserDoc = await firestore.collection('users').doc(uid).get();
      if (!currentUserDoc.exists) {
        throw Exception('Logged in user document not found.');
      }

      final currentUserData = currentUserDoc.data()!;
      _loggedInName = (currentUserData['fullName'] ?? '').toString();
      _loggedInSubcode = (currentUserData['subcode'] ?? '').toString();

      // 2) Load ALL drivers and mission leaders from ALL weekly_schedule docs
      final weeklySnapshot = await firestore.collection('weekly_schedule').get();

      final Set<String> allDrivers = {};
      final Set<String> allMissionLeaders = {};

      for (final doc in weeklySnapshot.docs) {
        final data = doc.data();

        final dynamic driversField = data['drivers'];
        final dynamic missionLeadersField =
            data['missionLeaders'] ?? data['mission_leaders'];

        if (driversField is List) {
          for (final driver in driversField) {
            final name = driver.toString().trim();
            if (name.isNotEmpty) {
              allDrivers.add(name);
            }
          }
        }

        if (missionLeadersField is List) {
          for (final leader in missionLeadersField) {
            final name = leader.toString().trim();
            if (name.isNotEmpty) {
              allMissionLeaders.add(name);
            }
          }
        }
      }

      // 3) Load ALL car numbers from checklist_status
      final checklistStatusSnapshot =
      await firestore.collection('checklist_status').get();

      final Set<String> allCars = {};

      for (final doc in checklistStatusSnapshot.docs) {
        final data = doc.data();

        void extractCarsFromDynamic(dynamic value) {
          if (value is Map<String, dynamic>) {
            for (final key in value.keys) {
              final car = key.toString().trim();
              if (car.isNotEmpty) {
                allCars.add(car);
              }
            }
          } else if (value is List) {
            for (final item in value) {
              final car = item.toString().trim();
              if (car.isNotEmpty) {
                allCars.add(car);
              }
            }
          } else if (value is String) {
            final car = value.trim();
            if (car.isNotEmpty) {
              allCars.add(car);
            }
          }
        }

        // Supports structures like:
        // morning: { "186": {...}, "187": {...} }
        // evening: { "188": {...} }
        extractCarsFromDynamic(data['morning']);
        extractCarsFromDynamic(data['evening']);

        // Extra fallback support if you later store cars differently
        extractCarsFromDynamic(data['cars']);
        extractCarsFromDynamic(data['carNumbers']);
      }

      // 4) Load patients
      final patientsSnapshot = await firestore
          .collection('patients')
          .orderBy('fullName')
          .get();

      final loadedPatients = patientsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': (data['fullName'] ?? '').toString().trim(),
          'phone': (data['phone'] ?? '').toString().trim(),
          'age': (data['age'] ?? '').toString().trim(),
        };
      }).where((p) => (p['name'] as String).isNotEmpty).toList();

      final sortedCars = allCars.toList()..sort();
      final sortedDrivers = allDrivers.toList()..sort();
      final sortedMissionLeaders = allMissionLeaders.toList()..sort();

      if (!mounted) return;

      setState(() {
        carNumbers = sortedCars;
        drivers = sortedDrivers;
        missionLeaders = sortedMissionLeaders;
        patients = loadedPatients;
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingData = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load data: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _resolvedPatientName() {
    if (selectedPatientId == 'new') {
      return patientNameController.text.trim();
    }

    if (selectedPatientId != null) {
      Map<String, dynamic>? selectedPatient;
      for (final patient in patients) {
        if (patient['id'] == selectedPatientId) {
          selectedPatient = patient;
          break;
        }
      }
      return (selectedPatient?['name'] ?? '').toString().trim();
    }

    return '';
  }

  Future<void> _submitMission() async {
    final resolvedPatientName = _resolvedPatientName();

    if (selectedCar == null ||
        missionType == null ||
        missionStatus == null ||
        dateController.text.trim().isEmpty ||
        departureAreaController.text.trim().isEmpty ||
        stop1Controller.text.trim().isEmpty ||
        selectedDriver == null ||
        selectedMissionLeader == null ||
        resolvedPatientName.isEmpty ||
        patientAgeController.text.trim().isEmpty ||
        gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (subcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your subcode to verify.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _missionService.submitMission(
        carNumber: selectedCar!,
        missionType: missionType!,
        missionStatus: missionStatus!,
        missionDate: dateController.text.trim(),
        departureArea: departureAreaController.text.trim(),
        stop1: stop1Controller.text.trim(),
        stop2: stop2Controller.text.trim(),
        driver: selectedDriver!,
        missionLeader: selectedMissionLeader!,
        patientName: resolvedPatientName,
        patientAge: patientAgeController.text.trim(),
        gender: gender!,
        subcode: subcodeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _resetForm();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    final now = DateTime.now();

    setState(() {
      selectedCar = null;
      missionType = null;
      missionStatus = null;
      gender = null;
      selectedDriver = null;
      selectedMissionLeader = null;
      selectedPatientId = null;
    });

    patientNameController.clear();
    patientPhoneController.clear();
    patientAgeController.clear();
    subcodeController.clear();
    departureAreaController.clear();
    stop1Controller.clear();
    stop2Controller.clear();

    dateController.text =
    '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _loadingData
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xffef3b4c),
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        _buildRegisteredByCard(),
                        const SizedBox(height: 20),
                        _buildMissionHeader(),
                        const SizedBox(height: 20),
                        _buildItinerary(),
                        const SizedBox(height: 20),
                        _buildTeam(),
                        const SizedBox(height: 20),
                        _buildPatient(),
                        const SizedBox(height: 20),
                        _buildVerification(),
                        const SizedBox(height: 20),
                        _buildSubmitButton(),
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

  Widget _buildRegisteredByCard() {
    return _card(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xffFEE2E2),
            child: Icon(Icons.person_outline, color: Color(0xffef3b4c)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registered by',
                  style: TextStyle(fontSize: 13, color: Color(0xff6b7280)),
                ),
                Text(
                  _loggedInName.isEmpty ? 'Unknown' : _loggedInName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionHeader() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mission Header",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 850;

              if (isSmall) {
                return Column(
                  children: [
                    _dropdownField(
                      "Car Number",
                      carNumbers,
                      selectedCar,
                          (v) => setState(() => selectedCar = v),
                    ),
                    const SizedBox(height: 12),
                    _dropdownField(
                      "Mission Type",
                      types,
                      missionType,
                          (v) => setState(() => missionType = v),
                    ),
                    const SizedBox(height: 12),
                    _textField("Date", controller: dateController),
                    const SizedBox(height: 12),
                    _dropdownField(
                      "Mission Status",
                      statuses,
                      missionStatus,
                          (v) => setState(() => missionStatus = v),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dropdownField(
                      "Car Number",
                      carNumbers,
                      selectedCar,
                          (v) => setState(() => selectedCar = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdownField(
                      "Mission Type",
                      types,
                      missionType,
                          (v) => setState(() => missionType = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField("Date", controller: dateController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdownField(
                      "Mission Status",
                      statuses,
                      missionStatus,
                          (v) => setState(() => missionStatus = v),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItinerary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mission Itinerary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 20),
          _textField("Departure Area", controller: departureAreaController),
          const SizedBox(height: 10),
          _textField("Stop 1", controller: stop1Controller),
          const SizedBox(height: 10),
          _textField("Stop 2 (Optional)", controller: stop2Controller),
        ],
      ),
    );
  }

  Widget _buildTeam() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Responding Team",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 20),
          _dropdownField(
            "Driver Name",
            drivers,
            selectedDriver,
                (v) => setState(() => selectedDriver = v),
          ),
          const SizedBox(height: 10),
          _dropdownField(
            "Mission Leader",
            missionLeaders,
            selectedMissionLeader,
                (v) => setState(() => selectedMissionLeader = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPatient() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Patient Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedPatientId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Patient Name",
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffd1d5db)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffd1d5db)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffef3b4c)),
              ),
            ),
            items: [
              ...patients.map(
                    (p) => DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(
                    p['name'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const DropdownMenuItem<String>(
                value: 'new',
                child: Text('New Patient'),
              ),
            ],
            onChanged: (value) {
              if (value == 'new' || value == null) {
                setState(() {
                  selectedPatientId = value;
                  patientNameController.clear();
                  patientPhoneController.clear();
                  patientAgeController.clear();
                });
                return;
              }

              Map<String, dynamic>? selectedPatient;
              for (final patient in patients) {
                if (patient['id'] == value) {
                  selectedPatient = patient;
                  break;
                }
              }

              setState(() {
                selectedPatientId = value;
                patientNameController.text =
                    (selectedPatient?['name'] ?? '').toString();
                patientPhoneController.text =
                    (selectedPatient?['phone'] ?? '').toString();
                patientAgeController.text =
                    (selectedPatient?['age'] ?? '').toString();
              });
            },
          ),
          if (selectedPatientId == 'new') ...[
            const SizedBox(height: 10),
            _input("Enter Patient Name", patientNameController),
            const SizedBox(height: 10),
            _input("Enter Patient Phone", patientPhoneController),
            const SizedBox(height: 10),
            _input("Enter Patient Age", patientAgeController),
          ] else if (selectedPatientId != null) ...[
            const SizedBox(height: 10),
            _readOnlyField("Patient Phone", patientPhoneController),
            const SizedBox(height: 10),
            _readOnlyField("Patient Age", patientAgeController),
          ],
          const SizedBox(height: 10),
          _dropdownField(
            "Gender",
            genders,
            gender,
                (v) => setState(() => gender = v),
          ),
        ],
      ),
    );
  }

  Widget _buildVerification() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verification",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter your personal subcode to confirm this submission.",
            style: TextStyle(fontSize: 13, color: Color(0xff6b7280)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: subcodeController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Your Subcode',
              hintText: 'Enter your subcode',
              prefixIcon:
              const Icon(Icons.lock_outline, color: Color(0xff6b7280)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffd1d5db)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffd1d5db)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffef3b4c)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitMission,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffef3b4c),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          "Register Mission",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: child,
    );
  }

  Widget _textField(String hint, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffef3b4c)),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffef3b4c)),
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xfff9fafb),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffef3b4c)),
        ),
      ),
    );
  }

  Widget _dropdownField(
      String label,
      List<String> items,
      String? value,
      Function(String?) onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd1d5db)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffef3b4c)),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
          value: e,
          child: Text(e, overflow: TextOverflow.ellipsis),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xfff3f4f6),
        border: Border(bottom: BorderSide(color: Color(0xffe5e7eb))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmall = constraints.maxWidth < 700;

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.route,
                      color: Color(0xffef3b4c),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mission Registration",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Log a new mission for Station 104",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff6b7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.fromLogin)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text("Home"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff111827),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xffd1d5db)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const StationDashboardPage(),
                              ),
                                  (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_outlined),
                          label: const Text("Home"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff111827),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xffd1d5db)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => logoutUser(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffef3b4c),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Logout"),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }

          return Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.route,
                color: Color(0xffef3b4c),
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mission Registration",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Log a new mission for Station 104",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.fromLogin
                          ? const LoginPage()
                          : const StationDashboardPage(),
                    ),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text("Home"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff111827),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xffd1d5db)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (!widget.fromLogin) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => logoutUser(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffef3b4c),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Logout"),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}