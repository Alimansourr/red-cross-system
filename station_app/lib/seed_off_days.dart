import 'package:cloud_firestore/cloud_firestore.dart';

class OffDaysSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedLebanonOffDays2026() async {
    final offDays = [
      {'date': '2026-01-01', 'title': 'New Year', 'isActive': true},
      {'date': '2026-01-06', 'title': 'Orthodox Christmas', 'isActive': true},
      {'date': '2026-02-09', 'title': "St Maron's Day", 'isActive': true},
      {'date': '2026-02-14', 'title': 'Rafic Hariri Memorial Day', 'isActive': true},
      {'date': '2026-03-20', 'title': 'Eid al-Fitr', 'isActive': true},
      {'date': '2026-03-21', 'title': 'Eid al-Fitr Holiday', 'isActive': true},
      {'date': '2026-03-22', 'title': 'Eid al-Fitr Holiday', 'isActive': true},
      {'date': '2026-03-23', 'title': 'Eid al-Fitr Holiday', 'isActive': true},
      {'date': '2026-03-25', 'title': 'Feast of the Annunciation', 'isActive': true},
      {'date': '2026-04-03', 'title': 'Good Friday', 'isActive': true},
      {'date': '2026-04-05', 'title': 'Easter Sunday', 'isActive': true},
      {'date': '2026-04-06', 'title': 'Easter Monday', 'isActive': true},
      {'date': '2026-04-10', 'title': 'Orthodox Good Friday', 'isActive': true},
      {'date': '2026-04-12', 'title': 'Orthodox Easter', 'isActive': true},
      {'date': '2026-04-13', 'title': 'Orthodox Easter Monday', 'isActive': true},
      {'date': '2026-05-01', 'title': 'Labor Day', 'isActive': true},
      {'date': '2026-05-03', 'title': "Martyrs' Day", 'isActive': true},
      {'date': '2026-05-10', 'title': 'Liberation and Resistance Holiday', 'isActive': true},
      {'date': '2026-05-25', 'title': 'Liberation and Resistance Day', 'isActive': true},
      {'date': '2026-05-27', 'title': 'Eid al-Adha', 'isActive': true},
      {'date': '2026-05-28', 'title': 'Eid al-Adha Holiday', 'isActive': true},
      {'date': '2026-06-17', 'title': 'Muharram', 'isActive': true},
      {'date': '2026-06-26', 'title': 'Ashoura', 'isActive': true},
      {'date': '2026-08-15', 'title': 'Assumption of Mary', 'isActive': true},
      {'date': '2026-08-26', 'title': "The Prophet's Birthday", 'isActive': true},
      {'date': '2026-11-22', 'title': 'Independence Day', 'isActive': true},
      {'date': '2026-12-25', 'title': 'Christmas Day', 'isActive': true},
    ];

    final batch = _db.batch();

    for (final offDay in offDays) {
      final docRef = _db.collection('off_days').doc(offDay['date'] as String);
      batch.set(docRef, offDay);
    }

    await batch.commit();
  }
}