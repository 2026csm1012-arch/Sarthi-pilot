import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a student's ride request in MVC.
class RideRequest {
  RideRequest({
    required dynamic id,
    required this.from,
    required this.to,
    required this.time,
    this.status = 'pending', // 'pending', 'accepted', 'arriving', 'in_progress', 'completed', 'rejected', 'cancelled'
    this.userName = 'Student',
    this.driverId,
    this.driverName,
    this.assignedCartId,
    this.completedAt,
    this.createdAt,
  }) : id = id.toString();

  final String id;
  final String from;
  final String to;
  final String time;
  String status;
  final String userName;
  final String? driverId;
  final String? driverName;
  final String? assignedCartId;
  final DateTime? completedAt;
  final DateTime? createdAt;

  String get pickup => from;
  String get drop => to;

  int get numericId => int.tryParse(id) ?? id.hashCode;

  bool matchesId(dynamic searchId) {
    if (searchId == null) return false;
    return id == searchId.toString();
  }

  factory RideRequest.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created;
    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      created = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    DateTime? completed;
    if (map['completedAt'] is Timestamp) {
      completed = (map['completedAt'] as Timestamp).toDate();
    } else if (map['completedAt'] is String) {
      completed = DateTime.tryParse(map['completedAt']);
    }

    final diff = DateTime.now().difference(created);
    String timeLabel;
    if (diff.inSeconds < 60) {
      timeLabel = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeLabel = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeLabel = '${diff.inHours}h ago';
    } else {
      timeLabel = '${diff.inDays}d ago';
    }

    return RideRequest(
      id: doc.id,
      from: map['pickup'] as String? ?? map['from'] as String? ?? 'Campus',
      to: map['drop'] as String? ?? map['to'] as String? ?? 'Campus',
      time: timeLabel,
      status: map['status'] as String? ?? 'pending',
      userName: map['userName'] as String? ?? 'Student',
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      assignedCartId: map['assignedCartId'] as String?,
      completedAt: completed,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
    'pickup': from,
    'drop': to,
    'status': status,
    'userName': userName,
    if (driverId != null) 'driverId': driverId,
    if (driverName != null) 'driverName': driverName,
    if (assignedCartId != null) 'assignedCartId': assignedCartId,
    if (completedAt != null) 'completedAt': completedAt,
    if (createdAt != null) 'createdAt': createdAt,
  };
}
