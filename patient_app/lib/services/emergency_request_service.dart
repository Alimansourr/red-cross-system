import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AssignedStation {
  final String id;
  final String stationName;
  final double distanceKm;

  const AssignedStation({
    required this.id,
    required this.stationName,
    required this.distanceKm,
  });
}

class EmergencyRequestResult {
  final String requestId;
  final AssignedStation station;

  const EmergencyRequestResult({
    required this.requestId,
    required this.station,
  });
}

class EmergencyRequestService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<EmergencyRequestResult> submitEmergencyRequest({
    required String emergencyType,
    required String currentCondition,
    required String phoneNumber,
    String guestName = '',
  }) async {
    final user = _auth.currentUser;
    Map<String, dynamic> patientData = {};

    if (user != null) {
      final patientDoc =
      await _firestore.collection('patients').doc(user.uid).get();
      patientData = patientDoc.data() ?? <String, dynamic>{};
    }

    final position = await _determinePosition();

    final station = await _findNearestStation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final requestRef = await _firestore.collection('emergency_requests').add({
      'patientId': user?.uid,
      'isGuest': user == null,
      'patientName': user != null
          ? (patientData['fullName'] ?? '').toString()
          : guestName.trim(),
      'patientEmail': user != null
          ? (patientData['email'] ?? user.email ?? '').toString()
          : '',
      'patientProfilePhone': user != null
          ? (patientData['phone'] ?? '').toString()
          : '',
      'contactPhone': phoneNumber.trim(),
      'emergencyType': emergencyType.trim(),
      'currentCondition': currentCondition.trim(),
      'assignedStationId': station.id,
      'assignedStationName': station.stationName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'location': GeoPoint(position.latitude, position.longitude),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'patient_app',
    });

    return EmergencyRequestResult(
      requestId: requestRef.id,
      station: station,
    );
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please enable location services on your phone.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it from settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<AssignedStation> _findNearestStation({
    required double latitude,
    required double longitude,
  }) async {
    final snapshot = await _firestore.collection('station_details').get();

    AssignedStation? nearestStation;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final isActive = data['isActive'];
      if (isActive != true) {
        continue;
      }

      final stationLatitude = _toDouble(data['latitude']);
      final stationLongitude = _toDouble(data['longitude']);

      if (stationLatitude == null || stationLongitude == null) {
        continue;
      }

      final distanceKm = _calculateDistanceKm(
        latitude,
        longitude,
        stationLatitude,
        stationLongitude,
      );

      if (nearestStation == null || distanceKm < nearestStation.distanceKm) {
        nearestStation = AssignedStation(
          id: doc.id,
          stationName: (data['stationName'] ?? 'Red Cross Station').toString(),
          distanceKm: distanceKm,
        );
      }
    }

    if (nearestStation == null) {
      throw Exception(
        'No active station with valid coordinates was found in station_details.',
      );
    }

    return nearestStation;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _calculateDistanceKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(_degreesToRadians(lat1)) *
                math.cos(_degreesToRadians(lat2)) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}