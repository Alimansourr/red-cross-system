import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WoundCareService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitReport({
    required String date,
    required String time,
    required String firstName,
    required String lastName,
    required String age,
    required String gender,
    required String nationality,
    required List<String> injuryTypes,
    required List<String> injurySites,
    required String additionalInjury,
    required List<String> materialsUsed,
    required String emtName,
    required String notes,
    required String subcode,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You must be logged in.');

    // Verify subcode against Firestore
    final userDoc = await _db.collection('users').doc(uid).get();
    final storedSubcode = userDoc.data()?['subcode']?.toString() ?? '';
    final loggedInName  = userDoc.data()?['fullName']?.toString() ?? '';

    if (storedSubcode.isEmpty) {
      throw Exception('Your account has no subcode set. Contact admin.');
    }

    if (subcode.trim() != storedSubcode) {
      throw Exception('Incorrect subcode. Please try again.');
    }

    await _db.collection('wound_care_reports').add({
      'submittedAt':      FieldValue.serverTimestamp(),
      'submittedByUid':   uid,
      'submittedByName':  loggedInName,
      'subcode':          subcode.trim(),
      'date':             date,
      'time':             time,
      'patient': {
        'firstName':   firstName,
        'lastName':    lastName,
        'age':         age,
        'gender':      gender,
        'nationality': nationality,
      },
      'injuryTypes':      injuryTypes,
      'injurySites':      injurySites,
      'additionalInjury': additionalInjury,
      'materialsUsed':    materialsUsed,
      'emtName':          emtName,
      'notes':            notes,
    });
  }
}