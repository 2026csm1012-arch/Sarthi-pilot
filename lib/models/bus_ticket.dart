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
    this.unboardedAt,
  });

  final String id;
  final String route;
  final String time;
  final String busNo;
  final String busId;
  String status; // 'Valid', 'Used (Onboarded)', 'Completed'
  final String passengerName;
  final String pickup;
  final String drop;
  final DateTime? verifiedAt;
  final DateTime? unboardedAt;

  /// True if the passenger is currently onboarded on the bus.
  bool get isBoarded =>
      (status.contains('Used') || status.contains('Onboarded') || status == 'Boarded') &&
      !isCompleted;

  /// True if the passenger has unboarded / completed their trip (consumed ticket).
  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.contains('Completed');

  /// Compatibility getter: represents actively confirmed/onboarded passengers occupying seats.
  bool get isConfirmed => isBoarded;

  factory BusTicket.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    final id = map['id'] as String? ?? doc.id;
    final busData = map['bus'] as Map<String, dynamic>? ?? {};
    final busId = map['busId'] as String? ?? busData['id'] as String? ?? '';
    final route = map['busRoute'] as String? ?? busData['route'] as String? ?? 'Campus Transit Route';
    final time = map['departureTime'] as String? ?? busData['departureTime'] as String? ?? '';
    final busNo = map['busRegistration'] as String? ?? busData['registrationNumber'] as String? ?? '';

    final rawStatus = (map['status'] as String? ?? '').trim();
    final isCompletedFlag = map['isCompleted'] == true ||
        rawStatus.toLowerCase() == 'completed' ||
        map['tripStatus'] == 'Completed';
    final isUsed = map['isUsed'] == true || rawStatus == 'Used';

    final String status;
    if (isCompletedFlag) {
      status = 'Completed';
    } else if (isUsed || rawStatus.contains('Onboarded') || rawStatus.contains('Boarded')) {
      status = 'Used (Onboarded)';
    } else {
      status = rawStatus.isNotEmpty ? rawStatus : 'Valid';
    }

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

    DateTime? unboardedAt;
    if (map['unboardedAt'] is Timestamp) {
      unboardedAt = (map['unboardedAt'] as Timestamp).toDate();
    } else if (map['unboardedAt'] is String) {
      unboardedAt = DateTime.tryParse(map['unboardedAt']);
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
      unboardedAt: unboardedAt,
    );
  }
}
