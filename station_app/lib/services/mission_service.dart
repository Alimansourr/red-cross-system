import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MissionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitMission({
    required String carNumber,
    required String missionType,
    required String missionStatus,
    required String missionDate,
    required String departureArea,
    required String stop1,
    required String stop2,
    required String driver,
    required String missionLeader,
    required String patientName,
    required String patientAge,
    required String gender,
    required String subcode,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You must be logged in.');

    // Verify subcode against Firestore
    final userDoc = await _db.collection('users').doc(uid).get();
    final storedSubcode = userDoc.data()?['subcode']?.toString() ?? '';
    final loggedInName = userDoc.data()?['fullName']?.toString() ?? '';

    if (storedSubcode.isEmpty) {
      throw Exception('Your account has no subcode set. Contact admin.');
    }

    if (subcode.trim() != storedSubcode) {
      throw Exception('Incorrect subcode. Please try again.');
    }

    await _db.collection('missions').add({
      'submittedAt':     FieldValue.serverTimestamp(),
      'submittedByUid':  uid,
      'submittedByName': loggedInName,
      'carNumber':       carNumber,
      'missionType':     missionType,
      'missionStatus':   missionStatus,
      'missionDate':     missionDate,
      'departureArea':   departureArea,
      'stop1':           stop1,
      'stop2':           stop2,
      'driver':          driver,
      'missionLeader':   missionLeader,
      'subcode':         subcode.trim(),
      'patient': {
        'name':   patientName,
        'age':    patientAge,
        'gender': gender,
      },
    });
  }
}