/// Model representing a student's ride request in MVC.
class RideRequest {
  RideRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.time,
  });

  final int id;
  final String from;
  final String to;
  final String time;
}
