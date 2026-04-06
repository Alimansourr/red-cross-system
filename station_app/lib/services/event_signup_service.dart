import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventSignupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<Map<String, dynamic>> getCurrentUserData() async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception('User document not found in Firestore.');
    }

    return userDoc.data()!;
  }

  Stream<List<Map<String, dynamic>>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      events.sort((a, b) {
        final aDate = (a['date'] ?? '').toString();
        final bDate = (b['date'] ?? '').toString();
        return aDate.compareTo(bDate);
      });

      return events;
    });
  }

  Stream<bool> isUserSignedUpStream(String eventId) {
    final user = currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> signUpForEvent({
    required String eventId,
    required String enteredSubcode,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final trimmedEnteredSubcode = enteredSubcode.trim();

    if (trimmedEnteredSubcode.isEmpty) {
      throw Exception('Please enter your subcode.');
    }

    final userData = await getCurrentUserData();

    final savedSubcode = (userData['subcode'] ?? '').toString().trim();

    if (savedSubcode.isEmpty) {
      throw Exception('Your account does not have a saved subcode.');
    }

    if (trimmedEnteredSubcode != savedSubcode) {
      throw Exception('Incorrect subcode. Signup was not completed.');
    }

    final eventRef = _firestore.collection('events').doc(eventId);
    final eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      throw Exception('Event not found.');
    }

    final registrationRef =
    eventRef.collection('registrations').doc(user.uid);

    final existingRegistration = await registrationRef.get();
    if (existingRegistration.exists) {
      throw Exception('You are already signed up for this event.');
    }

    await registrationRef.set({
      'userId': user.uid,
      'fullName': userData['fullName'] ?? '',
      'subcode': savedSubcode,
      'email': userData['email'] ?? '',
      'role': userData['role'] ?? '',
      'team': userData['team'] ?? '',
      'signedUpAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelSignup({
    required String eventId,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(user.uid)
        .delete();
  }
}