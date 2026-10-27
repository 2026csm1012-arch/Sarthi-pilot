import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a campus EV Cart vehicle fetched dynamically from Firebase.
class VehicleCart {
  VehicleCart({
    required this.id,
    required this.name,
    this.status = 'offline',
    this.batteryLevel = 100,
    this.driverOnline = false,
    this.latitude = 30.9686,
    this.longitude = 76.4685,
    this.heading = 0.0,
  });

  final String id;
  final String name;
  final String status;
  final int batteryLevel;
  final bool driverOnline;
  final double latitude;
  final double longitude;
  final double heading;

  bool get isOnline {
    final s = status.trim().toLowerCase();
    if (s == 'offline' || !driverOnline) return false;
    return s == 'active' || s == 'online' || driverOnline;
  }

  factory VehicleCart.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VehicleCart(
      id: doc.id,
      name: data['name'] as String? ?? 'EV Cart (${doc.id})',
      status: data['status'] as String? ?? 'offline',
      batteryLevel: (data['batteryLevel'] as num?)?.toInt() ?? 100,
      driverOnline: data['driverOnline'] as bool? ?? false,
      latitude: double.parse(
          ((data['latitude'] as num?)?.toDouble() ?? 30.969205)
              .toStringAsFixed(6)),
      longitude: double.parse(
          ((data['longitude'] as num?)?.toDouble() ?? 76.468457)
              .toStringAsFixed(6)),
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'status': status,
    'batteryLevel': batteryLevel,
    'driverOnline': driverOnline,
    'latitude': double.parse(latitude.toStringAsFixed(6)),
    'longitude': double.parse(longitude.toStringAsFixed(6)),
    'heading': heading,
  };
}

