import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarMarker {
  final DateTime date;
  final String title;
  final String type; // event

  CalendarMarker({
    required this.date,
    required this.title,
    required this.type,
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String operationalDateKey() {
    final now = DateTime.now();
    final operationalDate =
    now.hour < 6 ? now.subtract(const Duration(days: 1)) : now;
    return DateFormat('yyyy-MM-dd').format(operationalDate);
  }

  Stream<QuerySnapshot> watchAnnouncements() {
    return _db
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> watchChecklistStatus() {
    final docId = operationalDateKey();
    _ensureDocExists(docId);
    return _db.collection('checklist_status').doc(docId).snapshots();
  }

  Future<void> _ensureDocExists(String docId) async {
    final ref = _db.collection('checklist_status').doc(docId);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'morning': {
          '186': false,
          '187': false,
          '188': false,
          '189': false,
          '190': false,
          '191': false,
          '192': false,
          '912': false,
        },
        'evening': {
          '186': false,
          '187': false,
          '188': false,
          '189': false,
          '190': false,
          '191': false,
          '192': false,
          '912': false,
        },
      });
    }
  }

  Future<List<String>> fetchCarNumbersFromChecklistStatus() async {
    final snapshot = await _db.collection('checklist_status').get();
    final carNumbers = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final morning = (data['morning'] as Map<String, dynamic>? ?? {});
      final evening = (data['evening'] as Map<String, dynamic>? ?? {});
      carNumbers.addAll(morning.keys.map((e) => e.toString()));
      carNumbers.addAll(evening.keys.map((e) => e.toString()));
    }

    final result = carNumbers.toList()..sort();
    return result;
  }

  Future<Map<String, List<CalendarMarker>>> fetchCalendarMarkersForMonth(
      DateTime month,
      ) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final nextMonthStart = DateTime(month.year, month.month + 1, 1);

    final Map<String, List<CalendarMarker>> markers = {};

    final eventsSnapshot = await _db.collection('events').get();

    for (final doc in eventsSnapshot.docs) {
      final data = doc.data();

      if ((data['isActive'] ?? true) != true) continue;

      final dateValue = data['date'];
      DateTime? date;

      if (dateValue is String) {
        try {
          date = DateFormat('yyyy-MM-dd').parseStrict(dateValue);
        } catch (_) {
          date = null;
        }
      } else if (dateValue is Timestamp) {
        date = dateValue.toDate();
      }

      if (date == null) continue;

      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (normalizedDate.isBefore(monthStart) ||
          !normalizedDate.isBefore(nextMonthStart)) {
        continue;
      }

      final key = _dateKey(normalizedDate);
      markers.putIfAbsent(key, () => []);
      markers[key]!.add(
        CalendarMarker(
          date: normalizedDate,
          title: (data['title'] ?? 'Event').toString(),
          type: 'event',
        ),
      );
    }

    return markers;
  }

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(
      DateTime(date.year, date.month, date.day),
    );
  }
}