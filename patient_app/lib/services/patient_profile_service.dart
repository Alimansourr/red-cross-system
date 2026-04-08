import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getPatientProfileStream() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in patient found.');
    }

    return _firestore.collection('patients').doc(user.uid).snapshots();
  }

  Future<void> updatePatientProfile({
    required String fullName,
    required String phone,
    required String address,
    int? age,
    String? bloodType,
    String? medicalHistory,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in patient found.');
    }

    final Map<String, dynamic> data = {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (age != null) {
      data['age'] = age;
    }

    if (bloodType != null && bloodType.trim().isNotEmpty) {
      data['bloodType'] = bloodType.trim();
    }

    if (medicalHistory != null) {
      data['medicalHistory'] = medicalHistory.trim();
    }

    await _firestore.collection('patients').doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }
}