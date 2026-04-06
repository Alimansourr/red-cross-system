import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'station_dashboard_page.dart';
import 'services/wound_care_service.dart';
import 'helpers/auth_helper.dart';

class WoundCareReportPage extends StatefulWidget {
  final bool fromLogin;

  const WoundCareReportPage({
    super.key,
    required this.fromLogin,
  });

  @override
  State<WoundCareReportPage> createState() => _WoundCareReportPageState();
}

class _WoundCareReportPageState extends State<WoundCareReportPage> {
  // ── Controllers ──
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController additionalInjuryController =
  TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController subcodeController = TextEditingController();

  // ── Selections ──
  String? selectedGender;
  String? selectedNationality;
  String? selectedEmt;

  final Set<String> selectedInjuryTypes = {};
  final Set<String> selectedInjurySites = {};
  final Set<String> selectedMaterials = {};

  // ── Logged-in user ──
  String _loggedInName = '';

  // ── Loaded from Firestore ──
  List<String> emtOptions = [];
  bool _loadingData = true;
  bool _isSubmitting = false;

  final WoundCareService _service = WoundCareService();

  // ── Static lists ──
  final List<String> genderOptions = ["Male", "Female"];
  final List<String> nationalityOptions = [
    "Lebanese",
    "Syrian",
    "Palestinian",
    "Other"
  ];
  final List<String> injuryTypes = [
    "Wound / جرح",
    "Burn / حرق",
    "Abrasion / خدش",
    "Laceration / تمزق بالجلد",
    "Surgical Wound / جرح عملية",
    "Ulcer / قرح",
    "Penetration / اختراق",
    "Infected Wound / جرح ملتهب",
    "Avulsion / البتر",
  ];
  final List<String> injurySites = [
    "Head / رأس",
    "Chest / صدر",
    "Abdomen / البطن",
    "Back / ظهر",
    "Femur / الفخذ",
    "Knee / ركبة",
    "Leg / الرجل",
    "Foot / قدم",
    "Fingers / أصابع",
    "Shoulder / الكتف",
    "Hand / اليد",
  ];
  final List<String> materialsUsed = [
    "Sterile Set",
    "Serum",
    "Betadine",
    "DHR",
    "Flamazine/silverderma",
    "Tricopore",
    "Sofratulle",
    "Compressive Bandage",
    "Elastic Bandage",
    "Gauze Roll",
    "Compresse / Gauze",
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    dateController.text =
    '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final hour = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    timeController.text = '$hour:$minute $period';

    _loadData();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    additionalInjuryController.dispose();
    notesController.dispose();
    subcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');

      final firestore = FirebaseFirestore.instance;

      // 1) Get logged-in user's name for "Submitted by"
      final userDoc = await firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      _loggedInName = userData['fullName']?.toString() ?? '';

      // 2) Get all EMT names from all weekly_schedule docs
      final weeklySnapshot = await firestore.collection('weekly_schedule').get();

      final Set<String> emtNames = {};

      for (final doc in weeklySnapshot.docs) {
        final data = doc.data();

        final dynamic emtsField = data['emts'] ?? data['EMTs'];

        if (emtsField is List) {
          for (final emt in emtsField) {
            final name = emt.toString().trim();
            if (name.isNotEmpty) {
              emtNames.add(name);
            }
          }
        }
      }

      final sortedEmts = emtNames.toList()..sort();

      if (mounted) {
        setState(() {
          emtOptions = sortedEmts;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load data. Check connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        selectedGender == null ||
        selectedNationality == null ||
        selectedEmt == null) {
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
      await _service.submitReport(
        date: dateController.text.trim(),
        time: timeController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        age: ageController.text.trim(),
        gender: selectedGender!,
        nationality: selectedNationality!,
        injuryTypes: selectedInjuryTypes.toList(),
        injurySites: selectedInjurySites.toList(),
        additionalInjury: additionalInjuryController.text.trim(),
        materialsUsed: selectedMaterials.toList(),
        emtName: selectedEmt!,
        notes: notesController.text.trim(),
        subcode: subcodeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wound care report submitted successfully!'),
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
    final hour = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    setState(() {
      selectedGender = null;
      selectedNationality = null;
      selectedEmt = null;
      selectedInjuryTypes.clear();
      selectedInjurySites.clear();
      selectedMaterials.clear();
    });

    firstNameController.clear();
    lastNameController.clear();
    ageController.clear();
    additionalInjuryController.clear();
    notesController.clear();
    subcodeController.clear();

    dateController.text =
    '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
    timeController.text = '$hour:$minute $period';
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
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      children: [
                        _buildRegisteredByCard(),
                        const SizedBox(height: 20),
                        _buildCaseDetailsCard(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xffFEE2E2),
            child: Icon(Icons.person_outline, color: Color(0xffef3b4c)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submitted by',
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
        ],
      ),
    );
  }

  Widget _buildCaseDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Case Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please fill out all the fields below. Use N/A if a field is not applicable.",
            style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 800;
            if (isSmall) {
              return Column(
                children: [
                  _buildLabeledTextField(
                    "Date / التاريخ",
                    dateController,
                    suffixIcon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledTextField(
                    "Time / الوقت",
                    timeController,
                    suffixIcon: Icons.access_time_outlined,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildLabeledTextField(
                    "Date / التاريخ",
                    dateController,
                    suffixIcon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildLabeledTextField(
                    "Time / الوقت",
                    timeController,
                    suffixIcon: Icons.access_time_outlined,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          LayoutBuilder(builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 800;
            if (isSmall) {
              return Column(
                children: [
                  _buildLabeledTextField(
                    "First Name / اسم المريض",
                    firstNameController,
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledTextField(
                    "Last Name / كنية المريض",
                    lastNameController,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildLabeledTextField(
                    "First Name / اسم المريض",
                    firstNameController,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildLabeledTextField(
                    "Last Name / كنية المريض",
                    lastNameController,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          LayoutBuilder(builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 800;
            if (isSmall) {
              return Column(
                children: [
                  _buildLabeledTextField(
                    "Age / عمر المريض",
                    ageController,
                  ),
                  const SizedBox(height: 16),
                  _buildLabeledDropdown(
                    "Gender / الجنس",
                    selectedGender,
                    genderOptions,
                        (v) => setState(() => selectedGender = v),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildLabeledTextField(
                    "Age / عمر المريض",
                    ageController,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildLabeledDropdown(
                    "Gender / الجنس",
                    selectedGender,
                    genderOptions,
                        (v) => setState(() => selectedGender = v),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth < 800
                  ? double.infinity
                  : constraints.maxWidth * 0.46,
              child: _buildLabeledDropdown(
                "Nationality / جنسية المريض",
                selectedNationality,
                nationalityOptions,
                    (v) => setState(() => selectedNationality = v),
              ),
            );
          }),

          const SizedBox(height: 28),
          _sectionTitle("Type of injury - نوعية الإصابة"),
          const SizedBox(height: 14),
          _buildCheckboxGrid(
            items: injuryTypes,
            selectedItems: selectedInjuryTypes,
            columns: 3,
          ),

          const SizedBox(height: 28),
          _sectionTitle("Site of injury - مكان الإصابة"),
          const SizedBox(height: 6),
          const Text(
            "Select all applicable injury sites.",
            style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
          ),
          const SizedBox(height: 14),
          _buildCheckboxGrid(
            items: injurySites,
            selectedItems: selectedInjurySites,
            columns: 3,
          ),

          const SizedBox(height: 24),
          _buildLabeledMultilineTextField(
            "Additional injury details - تفاصيل إضافية",
            additionalInjuryController,
            hintText: "e.g., Burn on left arm",
          ),

          const SizedBox(height: 28),
          _sectionTitle("Materials Used - المواد المستعملة"),
          const SizedBox(height: 6),
          const Text(
            "Select all materials that were used in the treatment.",
            style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
          ),
          const SizedBox(height: 14),
          _buildCheckboxGrid(
            items: materialsUsed,
            selectedItems: selectedMaterials,
            columns: 2,
          ),

          const SizedBox(height: 24),
          _buildLabeledDropdown(
            "EMT's Name / اسم المسعف",
            selectedEmt,
            emtOptions,
                (v) => setState(() => selectedEmt = v),
            hint: "Select EMT...",
          ),
          const SizedBox(height: 6),
          const Text(
            "Select the EMT who handled the case.",
            style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
          ),

          const SizedBox(height: 24),
          _buildLabeledMultilineTextField(
            "Notes / ملاحظات",
            notesController,
            hintText: "Any additional notes...",
          ),

          const SizedBox(height: 24),
          _sectionTitle("Verification"),
          const SizedBox(height: 6),
          const Text(
            "Enter your personal subcode to confirm this submission.",
            style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
          ),
          const SizedBox(height: 12),
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
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xffd1d5db)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xffd1d5db)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xffef3b4c)),
              ),
            ),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xfff53246),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
                "Submit Report",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xff111827),
      ),
    );
  }

  Widget _buildLabeledTextField(
      String label,
      TextEditingController controller, {
        String? hintText,
        IconData? suffixIcon,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xff111827))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon,
                size: 18, color: const Color(0xff111827))
                : null,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffef3b4c)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledMultilineTextField(
      String label,
      TextEditingController controller, {
        String? hintText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xff111827))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffef3b4c)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged, {
        String? hint,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xff111827))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffef3b4c)),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCheckboxGrid({
    required List<String> items,
    required Set<String> selectedItems,
    required int columns,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = columns;
        if (constraints.maxWidth < 900) cols = 2;
        if (constraints.maxWidth < 600) cols = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 4,
            mainAxisExtent: 34,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isChecked = selectedItems.contains(item);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isChecked) {
                    selectedItems.remove(item);
                  } else {
                    selectedItems.add(item);
                  }
                });
              },
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: const Color(0xffef3b4c),
                    side: const BorderSide(color: Color(0xffef3b4c)),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedItems.add(item);
                        } else {
                          selectedItems.remove(item);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff111827),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xff111827)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.medical_services_outlined,
                        color: Color(0xffef3b4c), size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Wound Care Report",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Log a new patient wound care case.",
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
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xff111827)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.medical_services_outlined,
                  color: Color(0xffef3b4c), size: 30),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wound Care Report",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Log a new patient wound care case.",
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                        horizontal: 18, vertical: 14),
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