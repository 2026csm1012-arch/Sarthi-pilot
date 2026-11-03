import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a bus passenger ticket in MVC.
class BusTicket {
  BusTicket({
    required this.id,
    required this.route,
    required this.time,
    required this.busNo,
    this.busId = '',
    this.status = 'Valid',
    this.passengerName = 'Student',
    this.pickup = '',
    this.drop = '',
    this.verifiedAt,
  });

  final String id;
  final String route;
  final String time;
  final String busNo;
  final String busId;
  String status; // 'Valid' or 'Used (Onboarded)'
  final String passengerName;
  final String pickup;
  final String drop;
  final DateTime? verifiedAt;

  bool get isConfirmed => status.contains('Used') || status.contains('Onboarded');

  factory BusTicket.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    final id = map['id'] as String? ?? doc.id;
    final busData = map['bus'] as Map<String, dynamic>? ?? {};
    final busId = map['busId'] as String? ?? busData['id'] as String? ?? '';
    final route = map['busRoute'] as String? ?? busData['route'] as String? ?? 'Campus Transit Route';
    final time = map['departureTime'] as String? ?? busData['departureTime'] as String? ?? '';
    final busNo = map['busRegistration'] as String? ?? busData['registrationNumber'] as String? ?? '';
    final isUsed = map['isUsed'] == true || map['status'] == 'Used';
    final status = isUsed ? 'Used (Onboarded)' : (map['status'] as String? ?? 'Valid');
    final passengerName = map['userName'] as String? ?? 'Student';
    final pickup = map['pickup'] as String? ?? '';
    final drop = map['destination'] as String? ?? '';

    DateTime? verifiedAt;
    if (map['confirmedAt'] is Timestamp) {
      verifiedAt = (map['confirmedAt'] as Timestamp).toDate();
    } else if (map['confirmedAt'] is String) {
      verifiedAt = DateTime.tryParse(map['confirmedAt']);
    } else if (map['updatedAt'] is Timestamp && isUsed) {
      verifiedAt = (map['updatedAt'] as Timestamp).toDate();
    }

    return BusTicket(
      id: id,
      route: route,
      time: time,
      busNo: busNo,
      busId: busId,
      status: status,
      passengerName: passengerName,
      pickup: pickup,
      drop: drop,
      verifiedAt: verifiedAt,
    );
  }
}
