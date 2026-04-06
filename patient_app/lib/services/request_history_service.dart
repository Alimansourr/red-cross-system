import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientRequestHistoryItem {
  final String id;
  final String title;
  final String status;
  final DateTime? createdAt;
  final String subtitle;
  final String collectionName;

  const PatientRequestHistoryItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.subtitle,
    required this.collectionName,
  });
}

class RequestHistoryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<List<PatientRequestHistoryItem>> fetchPatientRequests() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in patient found.');
    }

    final emergencySnapshot = await _firestore
        .collection('emergency_requests')
        .where('patientId', isEqualTo: user.uid)
        .get();

    final transportSnapshot = await _firestore
        .collection('transport_requests')
        .where('patientId', isEqualTo: user.uid)
        .get();

    final List<PatientRequestHistoryItem> items = [];

    for (final doc in emergencySnapshot.docs) {
      final data = doc.data();

      items.add(
        PatientRequestHistoryItem(
          id: doc.id,
          title: 'Emergency Request',
          status: (data['status'] ?? 'Pending').toString(),
          createdAt: _extractDateTime(data['createdAt']),
          subtitle: _buildEmergencySubtitle(data),
          collectionName: 'emergency_requests',
        ),
      );
    }

    for (final doc in transportSnapshot.docs) {
      final data = doc.data();

      items.add(
        PatientRequestHistoryItem(
          id: doc.id,
          title: 'Transport Request',
          status: (data['status'] ?? 'Pending').toString(),
          createdAt: _extractDateTime(data['createdAt']),
          subtitle: _buildTransportSubtitle(data),
          collectionName: 'transport_requests',
        ),
      );
    }

    items.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return items;
  }

  DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  String _buildEmergencySubtitle(Map<String, dynamic> data) {
    final emergencyType = (data['emergencyType'] ?? '').toString().trim();
    final stationName = (data['assignedStationName'] ?? '').toString().trim();

    final parts = <String>[];

    if (emergencyType.isNotEmpty) {
      parts.add(emergencyType);
    }

    if (stationName.isNotEmpty) {
      parts.add('Assigned to $stationName');
    }

    if (parts.isEmpty) {
      return 'Emergency request submitted';
    }

    return parts.join(' • ');
  }

  String _buildTransportSubtitle(Map<String, dynamic> data) {
    final transportType = (data['transportType'] ?? '').toString().trim();
    final destination = (data['destination'] ?? '').toString().trim();
    final stationName = (data['assignedStationName'] ?? '').toString().trim();

    final parts = <String>[];

    if (transportType.isNotEmpty) {
      parts.add(transportType);
    }

    if (destination.isNotEmpty) {
      parts.add('To $destination');
    }

    if (stationName.isNotEmpty) {
      parts.add('Assigned to $stationName');
    }

    if (parts.isEmpty) {
      return 'Transport request submitted';
    }

    return parts.join(' • ');
  }
}