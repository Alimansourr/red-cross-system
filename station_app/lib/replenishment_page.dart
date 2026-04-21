import 'package:flutter/material.dart';
import 'services/checklist_service.dart';

class ReplenishmentPage extends StatefulWidget {
  final List<ReplenishmentItem> items;
  final String checklistId;
  final String carNumber;
  final String emtName;
  final String team;
  final ChecklistService checklistService;

  const ReplenishmentPage({
    super.key,
    required this.items,
    required this.checklistId,
    required this.carNumber,
    required this.emtName,
    required this.team,
    required this.checklistService,
  });

  @override
  State<ReplenishmentPage> createState() => _ReplenishmentPageState();
}

class _ReplenishmentPageState extends State<ReplenishmentPage> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await widget.checklistService.saveReplenishment(
        checklistId: widget.checklistId,
        carNumber: widget.carNumber,
        emtName: widget.emtName,
        team: widget.team,
        items: widget.items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Replenishment saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save replenishment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ReplenishmentItem>>{};
    for (final item in widget.items) {
      final key = '${item.sectionTitle} > ${item.subSectionTitle}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: const Text('Replenishment Needed'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff111827),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffffeef1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xfffecdd3)),
              ),
              child: Text(
                'Car ${widget.carNumber} has items below the required quantity. '
                    'Check the items that were brought from stock, then save them to Firestore.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff6b7280),
                ),
              ),
            ),
            Expanded(
              child: widget.items.isEmpty
                  ? const Center(
                child: Text(
                  'No replenishment needed.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xff6b7280),
                  ),
                ),
              )
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: grouped.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffe5e7eb)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...entry.value.map((item) {
                          return CheckboxListTile(
                            value: item.isChecked,
                            onChanged: (value) {
                              setState(() {
                                item.isChecked = value ?? false;
                              });
                            },
                            controlAffinity:
                            ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.itemName),
                            subtitle: Text(
                              'Requirement: ${item.requirement} | Current: ${item.currentValue}',
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffef3b4c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Save Replenishment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}