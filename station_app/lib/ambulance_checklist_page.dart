import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'station_dashboard_page.dart';
import 'services/checklist_service.dart';
import 'helpers/auth_helper.dart';

class AmbulanceChecklistPage extends StatefulWidget {
  final bool fromLogin;

  const AmbulanceChecklistPage({
    super.key,
    required this.fromLogin,
  });

  @override
  State<AmbulanceChecklistPage> createState() => _AmbulanceChecklistPageState();
}

class _AmbulanceChecklistPageState extends State<AmbulanceChecklistPage> {
  // ── Profile ──
  String _emtName = '';
  String _team    = '';
  String _subcode = '';
  bool _loadingProfile = true;

  // ── Car numbers ──
  List<String> _carNumbers      = [];
  String?      selectedCarNumber;

  // ── Checklist ──
  String? selectedChecklistType;
  bool    checklistStarted = false;
  bool    _isSubmitting    = false;

  final ChecklistService _checklistService = ChecklistService();

  final List<String> checklistTypes = ['Pre-Checklist', 'Post-Checklist'];

  late List<ChecklistSection> sections;

  @override
  void initState() {
    super.initState();
    sections = _buildChecklistSections();
    _loadUserProfile();
    _loadCarNumbers();
  }

  // ── Load logged-in user's profile ──
  Future<void> _loadUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in.');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data() ?? {};

      if (mounted) {
        setState(() {
          _emtName        = data['fullName']?.toString() ?? '';
          _team           = data['team']?.toString() ?? '';
          _subcode        = data['subcode']?.toString() ?? '';
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load your profile.')),
        );
      }
    }
  }

  // ── Load car numbers from checklist_status ──
  Future<void> _loadCarNumbers() async {
    try {
      final cars = await _checklistService.fetchCarNumbersFromChecklistStatus();
      if (mounted) {
        setState(() => _carNumbers = cars);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load car numbers.')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final section in sections) {
      for (final subSection in section.subSections) {
        for (final item in subSection.items) {
          item.textController?.dispose();
        }
      }
    }
    super.dispose();
  }

  List<ChecklistSection> _buildChecklistSections() {
    return [
      ChecklistSection(
        title: 'Front Compartment',
        subSections: [
          ChecklistSubSection(
            title: 'Front Compartment',
            items: [
              ChecklistItem.dropdown(
                name: 'Legal Sheets',
                requirement: '>= 10',
                dropdownOptions: ['Select...', '0-4', '5-9', '10+'],
              ),
              ChecklistItem.quantity(
                name: 'Radio',
                requirement: '>= 5',
                maxValue: 5,
              ),
              ChecklistItem.toggle(
                name: 'MCI Commander Kit',
                warningOnly: true,
              ),
            ],
          ),
        ],
      ),
      ChecklistSection(
        title: 'Back Compartment',
        subSections: [
          ChecklistSubSection(
            title: 'Back Compartment',
            items: [
              ChecklistItem.quantity(name: 'Scoop belts',  requirement: '>= 2', maxValue: 2),
              ChecklistItem.dropdown(
                name: 'AED',
                requirement: '>= 75',
                dropdownOptions: ['Select...', 'Below 75', '75+', '100'],
              ),
              ChecklistItem.quantity(name: 'AED patches',  requirement: '>= 2', maxValue: 2),
              ChecklistItem.toggle(name: 'Gloves S',   warningOnly: true),
              ChecklistItem.toggle(name: 'Gloves M',   warningOnly: true),
              ChecklistItem.toggle(name: 'Gloves L',   warningOnly: true),
              ChecklistItem.toggle(name: 'Gloves XL',  warningOnly: true),
              ChecklistItem.toggle(name: 'Kidney basin', warningOnly: true),
            ],
          ),
          ChecklistSubSection(
            title: 'Medical Bag',
            items: [
              ChecklistItem.textQty(name: 'glucometer needles', requirement: 'Exp: 10'),
              ChecklistItem.textQty(name: 'glucometer strips',  requirement: 'Exp: 15'),
              ChecklistItem.textQty(name: 'Gauze',              requirement: 'Exp: 10'),
              ChecklistItem.quantity(name: 'Thermal blankets',  requirement: '>= 2', maxValue: 2),
              ChecklistItem.toggle(name: 'Scissor',             warningOnly: true),
              ChecklistItem.quantity(name: 'Plaster',           requirement: '>= 2', maxValue: 2),
              ChecklistItem.quantity(name: 'Elastic Bandage',   requirement: '>= 4', maxValue: 4),
            ],
          ),
          ChecklistSubSection(
            title: 'Trauma Bag',
            items: [
              ChecklistItem.quantity(name: 'Towels',             requirement: '>= 2', maxValue: 2),
              ChecklistItem.quantity(name: 'Ice Packs',          requirement: '>= 2', maxValue: 2),
              ChecklistItem.quantity(name: 'SAM Splints',        requirement: '>= 3', maxValue: 3),
              ChecklistItem.toggle(name: 'Spider Belt',          warningOnly: true),
              ChecklistItem.quantity(name: 'Hooks',              requirement: '>= 5', maxValue: 5),
              ChecklistItem.toggle(name: 'Duct tape',            warningOnly: true),
              ChecklistItem.quantity(name: 'Triangular bandage', requirement: '>= 5', maxValue: 5),
              ChecklistItem.quantity(name: 'Thermal blanket',    requirement: '>= 2', maxValue: 2),
              ChecklistItem.toggle(name: 'Pelvic belt',          warningOnly: true),
            ],
          ),
        ],
      ),
    ];
  }

  Future<void> _startChecklist() async {
    if (selectedChecklistType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a checklist type.')),
      );
      return;
    }

    if (selectedCarNumber == null || selectedCarNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car number.')),
      );
      return;
    }

    if (_emtName.isEmpty || _team.isEmpty || _subcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Your profile is incomplete. Contact admin.')),
      );
      return;
    }

    final subcodeController = TextEditingController();

    final enteredSubcode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Subcode'),
        content: TextField(
          controller: subcodeController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter your subcode',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, subcodeController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffef3b4c),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (enteredSubcode == null) return;

    if (enteredSubcode != _subcode) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong subcode. Checklist cannot start.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => checklistStarted = true);
  }

  Future<void> _submitChecklist() async {
    if (selectedCarNumber == null || selectedCarNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car number.')),
      );
      return;
    }

    final sectionsData = sections.map((section) {
      return ChecklistSectionData(
        title: section.title,
        subSections: section.subSections.map((sub) {
          return ChecklistSubSectionData(
            title: sub.title,
            items: sub.items.map((item) => item.toData()).toList(),
          );
        }).toList(),
      );
    }).toList();

    setState(() => _isSubmitting = true);

    try {
      await _checklistService.submitChecklist(
        emtName:       _emtName,
        team:          _team,
        carNumber:     selectedCarNumber!,
        checklistType: selectedChecklistType!,
        subcode:       _subcode,
        sections:      sectionsData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        checklistStarted      = false;
        selectedChecklistType = null;
        selectedCarNumber     = null;
        sections              = _buildChecklistSections();
      });
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

  bool _showWarning(ChecklistItem item) {
    if (item.name == 'AED') return item.selectedDropdownValue == 'Below 75';
    if (item.warningOnly && item.type == ChecklistItemType.toggle) {
      return item.toggleValue == false;
    }
    if (item.type == ChecklistItemType.textQty) {
      final entered = int.tryParse(item.textController?.text.trim() ?? '') ?? 0;
      if (item.requirement != null) {
        final match = RegExp(r'(\d+)').firstMatch(item.requirement!);
        if (match != null) {
          return entered < (int.tryParse(match.group(1) ?? '') ?? 0);
        }
      }
    }
    if ((item.type == ChecklistItemType.quantity ||
        item.type == ChecklistItemType.quantityWithZero) &&
        item.requirement != null) {
      final selected = item.selectedRadioValue ?? 0;
      final match    = RegExp(r'(\d+)').firstMatch(item.requirement!);
      if (match != null) {
        return selected < (int.tryParse(match.group(1) ?? '') ?? 0);
      }
    }
    if (item.type == ChecklistItemType.dropdown && item.requirement != null) {
      final value = item.selectedDropdownValue ?? '';
      final match = RegExp(r'(\d+)').firstMatch(item.requirement!);
      if (match != null) {
        final req = int.tryParse(match.group(1) ?? '') ?? 0;
        if (value == 'Select...') return true;
        if (value == '0-4') return 4 < req;
        if (value == '5-9') return 9 < req;
        if (value == '10+') return 10 < req;
      }
    }
    return false;
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1250),
                    child: checklistStarted
                        ? _buildChecklistContent()
                        : _buildPreChecklistCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreChecklistCard() {
    if (_loadingProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(color: Color(0xffef3b4c)),
        ),
      );
    }

    return Center(
      child: Container(
        width: 430,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffe5e7eb)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pre-Checklist Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review your info and select a checklist type to begin.',
              style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
            ),
            const SizedBox(height: 24),

            // ── Read-only profile info ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xfff9fafb),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Name', _emtName),
                  const Divider(height: 20),
                  _infoRow(Icons.group_outlined, 'Team', _team),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Checklist type ──
            _buildLabeledDropdown(
              'Checklist Type',
              selectedChecklistType,
              checklistTypes,
                  (value) => setState(() => selectedChecklistType = value),
              hint: 'Select Pre or Post checklist',
            ),

            const SizedBox(height: 16),

            // ── Car number from checklist_status ──
            _buildLabeledDropdown(
              'Car Number',
              selectedCarNumber,
              _carNumbers,
                  (value) => setState(() => selectedCarNumber = value),
              hint: 'Select ambulance car number',
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _carNumbers.isEmpty ? null : _startChecklist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfff53246),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _carNumbers.isEmpty ? 'Loading cars...' : 'Start Checklist',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff6b7280)),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(fontSize: 14, color: Color(0xff6b7280))),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not set' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistContent() {
    return Column(
      children: [
        _buildAmbulanceInfoCard(),
        const SizedBox(height: 20),
        ...sections.map((section) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildMainSection(section),
        )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitChecklist,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xfff53246),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : const Text(
              'Submit Checklist',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmbulanceInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ambulance',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff111827)),
          ),
          const SizedBox(height: 8),
          Text(
            'Checking for: $_emtName on Car: ${selectedCarNumber ?? '-'}'
                ' for Team: $_team at Station: 104',
            style: const TextStyle(fontSize: 14, color: Color(0xff6b7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(ChecklistSection section) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xffe5e7eb)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xffe5e7eb)),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        leading: const Icon(Icons.inventory_2_outlined,
            color: Color(0xff64748b)),
        title: Text(
          section.title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827)),
        ),
        initiallyExpanded: true,
        children: section.subSections
            .map((subSection) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildSubSection(subSection),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildSubSection(ChecklistSubSection subSection) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xffe5e7eb)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xffe5e7eb)),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        leading: const Icon(Icons.inventory_2_outlined,
            color: Color(0xff64748b)),
        title: Text(
          subSection.title,
          style: const TextStyle(fontSize: 16, color: Color(0xff111827)),
        ),
        initiallyExpanded: true,
        children: subSection.items
            .map((item) => _buildChecklistItemRow(item))
            .toList(),
      ),
    );
  }

  Widget _buildChecklistItemRow(ChecklistItem item) {
    final showWarning = _showWarning(item);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xfff1f5f9)))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool small = constraints.maxWidth < 850;
          if (small) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemName(item, showWarning),
                const SizedBox(height: 10),
                _buildRequirement(item, showWarning),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildItemControl(item),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 4, child: _buildItemName(item, showWarning)),
              Expanded(flex: 2, child: _buildRequirement(item, showWarning)),
              Expanded(
                flex: 2,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildItemControl(item)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemName(ChecklistItem item, bool showWarning) {
    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined,
            size: 18, color: Color(0xff64748b)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(item.name,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xff111827))),
        ),
        if (showWarning)
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xfff4b400), size: 22),
      ],
    );
  }

  Widget _buildRequirement(ChecklistItem item, bool showWarning) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.requirement ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xff94a3b8)),
        ),
        if (showWarning) ...[
          const SizedBox(width: 6),
          const Text('!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xfff4b400))),
        ],
      ],
    );
  }

  Widget _buildItemControl(ChecklistItem item) {
    switch (item.type) {
      case ChecklistItemType.quantity:
        return Wrap(
          spacing: 10,
          runSpacing: 6,
          children: List.generate(item.maxValue ?? 0, (index) {
            final value = index + 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<int>(
                  value: value,
                  groupValue: item.selectedRadioValue,
                  activeColor: const Color(0xffef3b4c),
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) =>
                      setState(() => item.selectedRadioValue = v),
                ),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xff111827))),
              ],
            );
          }),
        );

      case ChecklistItemType.quantityWithZero:
        return Wrap(
          spacing: 10,
          runSpacing: 6,
          children: List.generate((item.maxValue ?? 0) + 1, (index) {
            final value = index;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<int>(
                  value: value,
                  groupValue: item.selectedRadioValue,
                  activeColor: const Color(0xffef3b4c),
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) =>
                      setState(() => item.selectedRadioValue = v),
                ),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xff111827))),
              ],
            );
          }),
        );

      case ChecklistItemType.dropdown:
        return SizedBox(
          width: 130,
          child: DropdownButtonFormField<String>(
            value: item.selectedDropdownValue,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xffe5e7eb)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xffe5e7eb)),
              ),
            ),
            items: item.dropdownOptions!
                .map((option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option,
                  overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: (value) =>
                setState(() => item.selectedDropdownValue = value),
          ),
        );

      case ChecklistItemType.toggle:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No',
                style:
                TextStyle(fontSize: 14, color: Color(0xff111827))),
            Switch(
              value: item.toggleValue,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xffef3b4c),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xffe2e8f0),
              onChanged: (value) =>
                  setState(() => item.toggleValue = value),
            ),
            const Text('Yes',
                style:
                TextStyle(fontSize: 14, color: Color(0xff111827))),
          ],
        );

      case ChecklistItemType.textQty:
        return SizedBox(
          width: 82,
          child: TextField(
            controller: item.textController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Qty',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xffe5e7eb)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: Color(0xffe5e7eb)),
              ),
            ),
          ),
        );
    }
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
            style: const TextStyle(
                fontSize: 14, color: Color(0xff111827))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xffd1d5db)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xffef3b4c)),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item,
                overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xfff3f4f6),
        border:
        Border(bottom: BorderSide(color: Color(0xffe5e7eb))),
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
                    const Icon(Icons.checklist_rtl,
                        color: Color(0xffef3b4c), size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Ambulance Checklist',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff111827))),
                          SizedBox(height: 2),
                          Text(
                              'Inspect ambulance equipment and readiness',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xff6b7280))),
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
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                            (route) => false,
                      ),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff111827),
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: Color(0xffd1d5db)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                    const StationDashboardPage()),
                                    (route) => false,
                              ),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            const Color(0xff111827),
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                                color: Color(0xffd1d5db)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => logoutUser(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xffef3b4c),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                          child: const Text('Logout'),
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
              const Icon(Icons.checklist_rtl,
                  color: Color(0xffef3b4c), size: 30),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ambulance Checklist',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff111827))),
                    SizedBox(height: 2),
                    Text(
                        'Inspect ambulance equipment and readiness',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color(0xff6b7280))),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => widget.fromLogin
                        ? const LoginPage()
                        : const StationDashboardPage(),
                  ),
                      (route) => false,
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff111827),
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                      color: Color(0xffd1d5db)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Model classes ─────────────────────────────────────────────────────────────

class ChecklistSection {
  final String title;
  final List<ChecklistSubSection> subSections;
  ChecklistSection({required this.title, required this.subSections});
}

class ChecklistSubSection {
  final String title;
  final List<ChecklistItem> items;
  ChecklistSubSection({required this.title, required this.items});
}

enum ChecklistItemType { quantity, quantityWithZero, dropdown, toggle, textQty }

class ChecklistItem {
  final String name;
  final String? requirement;
  final ChecklistItemType type;
  final int? maxValue;
  final bool warningOnly;
  final List<String>? dropdownOptions;

  int? selectedRadioValue;
  String? selectedDropdownValue;
  bool toggleValue;
  TextEditingController? textController;

  ChecklistItem._({
    required this.name,
    required this.type,
    this.requirement,
    this.maxValue,
    this.warningOnly = false,
    this.dropdownOptions,
    this.selectedRadioValue,
    this.selectedDropdownValue,
    this.toggleValue = false,
    this.textController,
  });

  factory ChecklistItem.quantity({
    required String name,
    required String requirement,
    required int maxValue,
  }) =>
      ChecklistItem._(
          name: name,
          type: ChecklistItemType.quantityWithZero,
          requirement: requirement,
          maxValue: maxValue);

  factory ChecklistItem.dropdown({
    required String name,
    required String requirement,
    required List<String> dropdownOptions,
  }) =>
      ChecklistItem._(
          name: name,
          type: ChecklistItemType.dropdown,
          requirement: requirement,
          dropdownOptions: dropdownOptions,
          selectedDropdownValue: dropdownOptions.first);

  factory ChecklistItem.toggle({
    required String name,
    bool warningOnly = false,
  }) =>
      ChecklistItem._(
          name: name,
          type: ChecklistItemType.toggle,
          warningOnly: warningOnly);

  factory ChecklistItem.textQty({
    required String name,
    required String requirement,
  }) =>
      ChecklistItem._(
          name: name,
          type: ChecklistItemType.textQty,
          requirement: requirement,
          textController: TextEditingController());

  ChecklistItemData toData() {
    dynamic value;
    String typeStr;
    switch (type) {
      case ChecklistItemType.quantity:
      case ChecklistItemType.quantityWithZero:
        value   = selectedRadioValue ?? 0;
        typeStr = 'quantity';
        break;
      case ChecklistItemType.dropdown:
        value   = selectedDropdownValue ?? '';
        typeStr = 'dropdown';
        break;
      case ChecklistItemType.toggle:
        value   = toggleValue;
        typeStr = 'toggle';
        break;
      case ChecklistItemType.textQty:
        value   = textController?.text.trim() ?? '';
        typeStr = 'textQty';
        break;
    }
    return ChecklistItemData(
        name: name, type: typeStr, value: value, requirement: requirement);
  }
}