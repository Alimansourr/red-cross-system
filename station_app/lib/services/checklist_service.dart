import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChecklistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ChecklistSubmitResult> submitChecklist({
    required String emtName,
    required String team,
    required String carNumber,
    required String subcode,
    required List<ChecklistSectionData> sections,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You must be logged in to submit.');

    final now = DateTime.now();
    final shift = _shiftForTime(now);
    final statusDocId = _statusDocId(now);

    final sectionsData = sections.map((section) {
      return {
        'title': section.title,
        'subSections': section.subSections.map((sub) {
          return {
            'title': sub.title,
            'items': sub.items.map((item) {
              return {
                'name': item.name,
                'type': item.type,
                'value': item.value,
                'requirement': item.requirement ?? '',
              };
            }).toList(),
          };
        }).toList(),
      };
    }).toList();

    final checklistRef = await _db.collection('checklists').add({
      'submittedAt': FieldValue.serverTimestamp(),
      'submittedByUid': uid,
      'emtName': emtName,
      'team': team,
      'carNumber': carNumber,
      'subcode': subcode,
      'sections': sectionsData,
      'statusDate': statusDocId,
      'shift': shift,
    });

    await _db.collection('checklist_status').doc(statusDocId).set({
      shift: {
        carNumber: true,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final replenishmentItems = _extractReplenishmentItems(sections);

    return ChecklistSubmitResult(
      checklistId: checklistRef.id,
      replenishmentItems: replenishmentItems,
    );
  }

  Future<void> saveReplenishment({
    required String checklistId,
    required String carNumber,
    required String emtName,
    required String team,
    required List<ReplenishmentItem> items,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You must be logged in.');

    final checkedItems = items
        .where((item) => item.isChecked)
        .map((item) => {
      'sectionTitle': item.sectionTitle,
      'subSectionTitle': item.subSectionTitle,
      'itemName': item.itemName,
      'requirement': item.requirement,
      'currentValue': item.currentValue,
      'isChecked': item.isChecked,
    })
        .toList();

    await _db.collection('replenishment').add({
      'checklistId': checklistId,
      'carNumber': carNumber,
      'emtName': emtName,
      'team': team,
      'submittedByUid': uid,
      'submittedAt': FieldValue.serverTimestamp(),
      'items': checkedItems,
    });
  }

  Future<List<String>> fetchCarNumbersFromChecklistStatus() async {
    final snapshot = await _db.collection('checklist_status').get();
    final carNumbers = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final morning = data['morning'] as Map<String, dynamic>? ?? {};
      final evening = data['evening'] as Map<String, dynamic>? ?? {};
      carNumbers.addAll(morning.keys.map((e) => e.toString()));
      carNumbers.addAll(evening.keys.map((e) => e.toString()));
    }

    return carNumbers.toList()..sort();
  }

  List<ReplenishmentItem> _extractReplenishmentItems(
      List<ChecklistSectionData> sections,
      ) {
    final result = <ReplenishmentItem>[];

    for (final section in sections) {
      for (final subSection in section.subSections) {
        for (final item in subSection.items) {
          if (_needsReplenishment(item)) {
            result.add(
              ReplenishmentItem(
                sectionTitle: section.title,
                subSectionTitle: subSection.title,
                itemName: item.name,
                requirement: item.requirement ?? '',
                currentValue: item.value?.toString() ?? '',
              ),
            );
          }
        }
      }
    }

    return result;
  }

  bool _needsReplenishment(ChecklistItemData item) {
    final requirement = item.requirement ?? '';

    if (item.type == 'toggle') {
      return item.value == false;
    }

    if (item.type == 'textQty') {
      final entered = int.tryParse(item.value?.toString() ?? '') ?? 0;
      final match = RegExp(r'(\d+)').firstMatch(requirement);
      if (match == null) return false;
      final requiredValue = int.tryParse(match.group(1) ?? '') ?? 0;
      return entered < requiredValue;
    }

    if (item.type == 'quantity') {
      final selected = int.tryParse(item.value?.toString() ?? '') ?? 0;
      final match = RegExp(r'(\d+)').firstMatch(requirement);
      if (match == null) return false;
      final requiredValue = int.tryParse(match.group(1) ?? '') ?? 0;
      return selected < requiredValue;
    }

    if (item.type == 'dropdown') {
      final value = (item.value ?? '').toString();
      final match = RegExp(r'(\d+)').firstMatch(requirement);
      if (match == null) return false;
      final requiredValue = int.tryParse(match.group(1) ?? '') ?? 0;

      if (value == 'Select...' || value == 'Select.') return true;
      if (value == 'Below 75') return true;
      if (value == '0-4') return 4 < requiredValue;
      if (value == '5-9') return 9 < requiredValue;
      if (value == '10+') return 10 < requiredValue;
      if (value == '75+') return 75 < requiredValue;
      if (value == '100') return 100 < requiredValue;
    }

    return false;
  }

  String _shiftForTime(DateTime now) {
    return (now.hour >= 6 && now.hour < 18) ? 'morning' : 'evening';
  }

  String _statusDocId(DateTime now) {
    final operationalDate =
    now.hour < 6 ? now.subtract(const Duration(days: 1)) : now;
    final y = operationalDate.year.toString().padLeft(4, '0');
    final m = operationalDate.month.toString().padLeft(2, '0');
    final d = operationalDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class ChecklistSubmitResult {
  final String checklistId;
  final List<ReplenishmentItem> replenishmentItems;

  ChecklistSubmitResult({
    required this.checklistId,
    required this.replenishmentItems,
  });
}

class ReplenishmentItem {
  final String sectionTitle;
  final String subSectionTitle;
  final String itemName;
  final String requirement;
  final String currentValue;
  bool isChecked;

  ReplenishmentItem({
    required this.sectionTitle,
    required this.subSectionTitle,
    required this.itemName,
    required this.requirement,
    required this.currentValue,
    this.isChecked = false,
  });
}

class ChecklistSectionData {
  final String title;
  final List<ChecklistSubSectionData> subSections;
  ChecklistSectionData({required this.title, required this.subSections});
}

class ChecklistSubSectionData {
  final String title;
  final List<ChecklistItemData> items;
  ChecklistSubSectionData({required this.title, required this.items});
}

class ChecklistItemData {
  final String name;
  final String type;
  final dynamic value;
  final String? requirement;
  ChecklistItemData({
    required this.name,
    required this.type,
    required this.value,
    this.requirement,
  });
}