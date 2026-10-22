/// Model representing authenticated driver in MVC.
class DriverUser {
  const DriverUser({
    required this.uid,
    required this.email,
    required this.name,
  });

  final String uid;
  final String email;
  final String name;
}
