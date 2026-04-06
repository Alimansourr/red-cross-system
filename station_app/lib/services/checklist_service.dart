import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChecklistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitChecklist({
    required String emtName,
    required String team,
    required String carNumber,
    required String checklistType,
    required String subcode,
    required List<ChecklistSectionData> sections,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You must be logged in to submit.');

    final now         = DateTime.now();
    final shift       = _shiftForTime(now);
    final statusDocId = _statusDocId(now);

    final sectionsData = sections.map((section) {
      return {
        'title': section.title,
        'subSections': section.subSections.map((sub) {
          return {
            'title': sub.title,
            'items': sub.items.map((item) {
              return {
                'name':        item.name,
                'type':        item.type,
                'value':       item.value,
                'requirement': item.requirement ?? '',
              };
            }).toList(),
          };
        }).toList(),
      };
    }).toList();

    // Save checklist document
    await _db.collection('checklists').add({
      'submittedAt':    FieldValue.serverTimestamp(),
      'submittedByUid': uid,
      'emtName':        emtName,
      'team':           team,
      'carNumber':      carNumber,
      'checklistType':  checklistType,
      'subcode':        subcode,
      'sections':       sectionsData,
      'statusDate':     statusDocId,
      'shift':          shift,
    });

    // Update checklist_status — mark this car as checked for the current shift
    await _db.collection('checklist_status').doc(statusDocId).set({
      shift: {
        carNumber: true,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> fetchCarNumbersFromChecklistStatus() async {
    final snapshot   = await _db.collection('checklist_status').get();
    final carNumbers = <String>{};

    for (final doc in snapshot.docs) {
      final data    = doc.data();
      final morning = data['morning'] as Map<String, dynamic>? ?? {};
      final evening = data['evening'] as Map<String, dynamic>? ?? {};
      carNumbers.addAll(morning.keys.map((e) => e.toString()));
      carNumbers.addAll(evening.keys.map((e) => e.toString()));
    }

    return carNumbers.toList()..sort();
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

// ── Serialization data classes ─────────────────────────────────────────────

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