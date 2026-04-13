import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AssignedTransportStation {
  final String id;
  final String stationName;
  final double distanceKm;

  const AssignedTransportStation({
    required this.id,
    required this.stationName,
    required this.distanceKm,
  });
}

class TransportRequestResult {
  final String requestId;
  final AssignedTransportStation station;

  const TransportRequestResult({
    required this.requestId,
    required this.station,
  });
}

class TransportRequestService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<TransportRequestResult> submitTransportRequest({
    required String transportType,
    required String pickupLocation,
    required String destination,
    required String preferredDate,
    required String preferredTime,
    required String notes,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first to send a transport request.');
    }

    final patientDoc =
    await _firestore.collection('patients').doc(user.uid).get();
    final patientData = patientDoc.data() ?? <String, dynamic>{};

    final position = await _determinePosition();

    final station = await _findNearestStation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final requestRef = await _firestore.collection('transport_requests').add({
      'patientId': user.uid,
      'patientName': (patientData['fullName'] ?? '').toString(),
      'patientEmail': (patientData['email'] ?? user.email ?? '').toString(),
      'patientProfilePhone': (patientData['phone'] ?? '').toString(),
      'patientAddress': (patientData['address'] ?? '').toString(),
      'patientAge': patientData['age'],
      'patientBloodType': (patientData['bloodType'] ?? '').toString(),
      'patientMedicalHistory':
      (patientData['medicalHistory'] ?? '').toString(),
      'transportType': transportType.trim(),
      'pickupLocation': pickupLocation.trim(),
      'destination': destination.trim(),
      'preferredDate': preferredDate.trim(),
      'preferredTime': preferredTime.trim(),
      'notes': notes.trim(),
      'assignedStationId': station.id,
      'assignedStationName': station.stationName,
      'requestLatitude': position.latitude,
      'requestLongitude': position.longitude,
      'requestLocation': GeoPoint(position.latitude, position.longitude),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'patient_app',
    });

    return TransportRequestResult(
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

  Future<AssignedTransportStation> _findNearestStation({
    required double latitude,
    required double longitude,
  }) async {
    final snapshot = await _firestore.collection('station_details').get();

    AssignedTransportStation? nearestStation;

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
        nearestStation = AssignedTransportStation(
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