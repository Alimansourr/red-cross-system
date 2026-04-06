import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback({
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in patient found.');
    }

    final patientDoc =
    await _firestore.collection('patients').doc(user.uid).get();

    final patientData = patientDoc.data() ?? {};

    await _firestore.collection('feedbacks').add({
      'patientId': user.uid,
      'patientEmail': user.email,
      'patientName': patientData['fullName'] ?? '',
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}