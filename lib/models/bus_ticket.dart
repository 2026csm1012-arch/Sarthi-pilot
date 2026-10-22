/// Model representing a bus passenger ticket in MVC.
class BusTicket {
  BusTicket({
    required this.id,
    required this.route,
    required this.time,
    required this.busNo,
    this.status = 'Valid',
  });

  final String id;
  final String route;
  final String time;
  final String busNo;
  String status; // 'Valid' or 'Used (Onboarded)'
}
