import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignedRequest {
  final String id;
  final String collectionName; // 'emergency_requests' or 'transport_requests'
  final Map<String, dynamic> data;

  AssignedRequest({
    required this.id,
    required this.collectionName,
    required this.data,
  });

  String get patientName => (data['patientName'] ?? '').toString();
  String get patientPhone => (data['patientProfilePhone'] ?? '').toString();
  String get emergencyType => (data['emergencyType'] ?? '').toString();
  String get currentCondition => (data['currentCondition'] ?? '').toString();
  String get pickupLocation => (data['pickupLocation'] ?? '').toString();
  String get destination => (data['destination'] ?? '').toString();
  String get status => (data['status'] ?? 'pending').toString();
  String get patientAddress => (data['patientAddress'] ?? '').toString();
  String get patientBloodType => (data['patientBloodType'] ?? '').toString();
  String? get patientAge => data['patientAge']?.toString();
  String get patientMedicalHistory => (data['patientMedicalHistory'] ?? '').toString();
  double? get latitude => _toDouble(data['latitude']);
  double? get longitude => _toDouble(data['longitude']);
  Timestamp? get createdAt => data['createdAt'] as Timestamp?;
  bool get isEmergency => collectionName == 'emergency_requests';

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class AssignedRequestsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of all requests assigned to the current EMT
  Stream<List<AssignedRequest>> watchAssignedRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    final emergenciesStream = _db
        .collection('emergency_requests')
        .where('assignedToEmtId', isEqualTo: user.uid)
        .snapshots();

    final transportsStream = _db
        .collection('transport_requests')
        .where('assignedToEmtId', isEqualTo: user.uid)
        .snapshots();

    // Combine both streams
    return emergenciesStream.asyncMap((emerSnap) async {
      final transportSnap = await transportsStream.first;

      final emergencies = emerSnap.docs.map((d) => AssignedRequest(
        id: d.id,
        collectionName: 'emergency_requests',
        data: d.data(),
      ));

      final transports = transportSnap.docs.map((d) => AssignedRequest(
        id: d.id,
        collectionName: 'transport_requests',
        data: d.data(),
      ));

      final all = [...emergencies, ...transports];
      // Sort by createdAt desc
      all.sort((a, b) {
        final aTime = a.createdAt?.seconds ?? 0;
        final bTime = b.createdAt?.seconds ?? 0;
        return bTime.compareTo(aTime);
      });

      return all;
    });
  }

  /// Update status of an assigned request
  Future<void> updateStatus(AssignedRequest req, String newStatus) async {
    await _db.collection(req.collectionName).doc(req.id).update({
      'status': newStatus,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}