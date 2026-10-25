/// Model representing a student's ride request in MVC.
class RideRequest {
  RideRequest({
    required dynamic id,
    required this.from,
    required this.to,
    required this.time,
    this.status = 'pending', // 'pending', 'accepted', 'arriving', 'in_progress', 'completed'
    this.userName = 'Student',
  }) : id = id.toString();

  final String id;
  final String from;
  final String to;
  final String time;
  String status;
  final String userName;

  String get pickup => from;
  String get drop => to;

  int get numericId => int.tryParse(id) ?? id.hashCode;

  bool matchesId(dynamic searchId) {
    if (searchId == null) return false;
    return id == searchId.toString();
  }
}
