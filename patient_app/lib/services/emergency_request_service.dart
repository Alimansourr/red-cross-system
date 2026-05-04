import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

  static const String _uploadUrl =
      'http://192.168.10.45:8000/upload-emergency-image';

  User? get currentUser => _auth.currentUser;

  Future<EmergencyRequestResult> submitEmergencyRequest({
    required String emergencyType,
    required String currentCondition,
    String guestName = '',
    String guestPhone = '',
    File? emergencyImageFile,
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

    final requestDoc = _firestore.collection('emergency_requests').doc();

    String? emergencyImageUrl;
    String? emergencyImagePath;

    if (emergencyImageFile != null) {
      final uploaded = await _uploadEmergencyImage(
        imageFile: emergencyImageFile,
        requestId: requestDoc.id,
      );

      emergencyImageUrl = uploaded['imageUrl'];
      emergencyImagePath = uploaded['imagePath'];
    }

    await requestDoc.set({
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
          : guestPhone.trim(),

      'patientAddress': user != null
          ? (patientData['address'] ?? '').toString()
          : '',

      'patientAge': user != null ? patientData['age'] : null,

      'patientBloodType': user != null
          ? (patientData['bloodType'] ?? '').toString()
          : '',

      'patientMedicalHistory': user != null
          ? (patientData['medicalHistory'] ?? '').toString()
          : '',

      'emergencyType': emergencyType.trim(),
      'currentCondition': currentCondition.trim(),
      'assignedStationId': station.id,
      'assignedStationName': station.stationName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'location': GeoPoint(position.latitude, position.longitude),
      'locationUrl':
      'https://maps.google.com/?q=${position.latitude},${position.longitude}',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'patient_app',

      'hasImage': emergencyImageUrl != null,
      'emergencyImageUrl': emergencyImageUrl,
      'emergencyImagePath': emergencyImagePath,
    });

    return EmergencyRequestResult(
      requestId: requestDoc.id,
      station: station,
    );
  }

  Future<Map<String, String>> _uploadEmergencyImage({
    required File imageFile,
    required String requestId,
  }) async {
    final uri = Uri.parse(_uploadUrl);

    final request = http.MultipartRequest('POST', uri);

    request.fields['requestId'] = requestId;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      throw Exception('Image upload failed: $responseBody');
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

    if (decoded['success'] != true || decoded['imageUrl'] == null) {
      throw Exception(decoded['message'] ?? 'Image upload failed.');
    }

    return {
      'imageUrl': decoded['imageUrl'].toString(),
      'imagePath': decoded['imagePath']?.toString() ?? '',
    };
  }

  Future<EmergencyRequestResult> submitQuickEmergencyCall() async {
    final position = await _determinePosition();

    final station = await _findNearestStation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final requestRef =
    await _firestore.collection('quick_emergency_requests').add({
      'isGuest': true,
      'emergencyType': 'quick_call',
      'currentCondition': 'Quick emergency button pressed before login.',
      'assignedStationId': station.id,
      'assignedStationName': station.stationName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'location': GeoPoint(position.latitude, position.longitude),
      'locationUrl':
      'https://maps.google.com/?q=${position.latitude},${position.longitude}',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'quick_emergency_button',
      'requiresDirectCall140': true,
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
      if (isActive != true) continue;

      final stationLatitude = _toDouble(data['latitude']);
      final stationLongitude = _toDouble(data['longitude']);

      if (stationLatitude == null || stationLongitude == null) continue;

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

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
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