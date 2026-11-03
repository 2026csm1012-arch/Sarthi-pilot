/// Model representing authenticated driver in MVC.
class DriverUser {
  const DriverUser({
    required this.uid,
    required this.email,
    required this.name,
    String? driverId,
  }) : _explicitDriverId = driverId;

  final String uid;
  final String email;
  final String name;
  final String? _explicitDriverId;

  /// Returns an 8-digit hexadecimal driver ID (e.g. '4A8F10CD').
  String get driverId {
    final explicit = _explicitDriverId;
    if (explicit != null && isHex8(explicit)) {
      return explicit.toUpperCase();
    }
    return formatHexId(explicit ?? uid);
  }

  /// Checks if a string is already an 8-character hexadecimal code.
  static bool isHex8(String str) {
    return RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(str);
  }

  /// Deterministically converts any identifier (Firebase UID, email, seed)
  /// into an 8-digit uppercase hexadecimal string.
  static String formatHexId(String source) {
    if (source.isEmpty) return '4A8F10CD';
    final clean = source.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (clean.length == 8) {
      return clean.toUpperCase();
    }
    // 32-bit FNV-1a hash to guarantee a consistent, uniform 8-digit hex
    var hash = 0x811c9dc5;
    for (var i = 0; i < source.length; i++) {
      hash ^= source.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}
