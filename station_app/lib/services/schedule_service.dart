import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<String> _readStringList(
      Map<String, dynamic> data,
      List<String> possibleKeys,
      ) {
    for (final key in possibleKeys) {
      final value = data[key];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchSchedule() async {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    final List<Map<String, dynamic>> result = [];

    for (final day in days) {
      final doc = await _db.collection('weekly_schedule').doc(day).get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        result.add({
          'day': day,
          'teamLeader': data['teamLeader'] ?? '',
          'leaderPhone': data['leaderPhone'] ?? '',
          'drivers': _readStringList(data, ['drivers']),
          'missionLeaders':
          _readStringList(data, ['missionLeaders', 'mission_leaders']),
          'emts': _readStringList(data, ['emts', 'EMTs']),
          'firstResponders': _readStringList(
            data,
            ['firstResponders', 'first_responders', 'First Responders'],
          ),
        });
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> fetchStationInfo() async {
    final doc = await _db.collection('station_info').doc('config').get();

    return doc.data() ??
        {
          'headOfStation': 'Ali Al Mokdad',
          'headPhone': '3504469',
          'stationName': 'Station 104',
          'motto': 'Hope Comes in Red and White',
        };
  }
}