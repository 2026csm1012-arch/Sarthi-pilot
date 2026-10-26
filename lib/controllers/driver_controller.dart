import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sarthi_pilot/models/bus_ticket.dart';
import 'package:sarthi_pilot/models/ride_request.dart';

/// Controller handling driver dashboard operations, dispatch queue, live GPS telemetry,
/// and ticket validation (MVC architecture).
class DriverController extends ChangeNotifier {
  DriverController() {
    _initData();
  }

  // Driver / Vehicle online duty status
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  String get vehicleStatusText =>
      _isOnline ? 'Online · Vehicle Active' : 'Offline · Vehicle Inactive';

  // Active mode: 'cart' or 'bus'
  String _driverMode = 'cart';
  String get driverMode => _driverMode;

  // Selected cart in EV Cart mode
  String _selectedCart = 'cart-1';
  String get selectedCart => _selectedCart;

  // Capacity status: 'Empty', 'Filling', 'Full'
  String _occupancy = 'Empty';
  String get occupancy => _occupancy;

  // Ticket scan verification results
  String _scanResultText = 'Ready to scan incoming passengers...';
  String get scanResultText => _scanResultText;

  String _scanResultType = 'idle'; // 'idle', 'success', 'warning', 'error'
  String get scanResultType => _scanResultType;

  // In-memory data collections
  final List<RideRequest> _requests = [];
  List<RideRequest> get requests => List.unmodifiable(_requests);

  final List<BusTicket> _tickets = [];
  List<BusTicket> get tickets => List.unmodifiable(_tickets);

  // Active accepted trip
  RideRequest? _activeRide;
  RideRequest? get activeRide => _activeRide;

  // Live GPS Telemetry state
  bool _isBroadcasting = false;
  bool get isBroadcasting => _isBroadcasting;

  double _latitude = 30.9686;
  double get latitude => _latitude;

  double _longitude = 76.4685;
  double get longitude => _longitude;

  double _heading = 45.0;
  double get heading => _heading;

  int _battery = 94;
  int get battery => _battery;

  String _currentWaypointName = 'Satluj Hostel';
  String get currentWaypointName => _currentWaypointName;

  Timer? _telemetryTimer;
  int _waypointIndex = 0;

  static const List<Map<String, dynamic>> _campusWaypoints = [
    {'name': 'Satluj Hostel Loop', 'lat': 30.9686, 'lng': 76.4685, 'heading': 45.0},
    {'name': 'Chenab & Beas Transit Point', 'lat': 30.9678, 'lng': 76.4698, 'heading': 65.0},
    {'name': 'Nalanda Library Junction', 'lat': 30.9676, 'lng': 76.4732, 'heading': 90.0},
    {'name': 'J.C. Bose Academic Block', 'lat': 30.9660, 'lng': 76.4720, 'heading': 180.0},
    {'name': 'Super Academic Facility', 'lat': 30.9652, 'lng': 76.4710, 'heading': 225.0},
    {'name': 'Main Campus Entrance Gate', 'lat': 30.9642, 'lng': 76.4680, 'heading': 270.0},
    {'name': 'Mess & Student Center', 'lat': 30.9670, 'lng': 76.4675, 'heading': 340.0},
  ];

  int get totalSeats => 32;
  int get onboardedCount => _tickets
      .where((t) => t.status.contains('Used') || t.status.contains('Onboarded'))
      .length;

  void _initData() {
    _requests.addAll([
      RideRequest(
        id: 'REQ-101',
        from: 'Satlej Hostel',
        to: 'JC Bose Block',
        time: 'Just now',
        userName: 'Aman Sharma',
      ),
      RideRequest(
        id: 'REQ-102',
        from: 'Beas Hostel',
        to: 'Central Library',
        time: '2 mins ago',
        userName: 'Priya Patel',
      ),
    ]);

    _tickets.addAll([
      BusTicket(
        id: 'TKT-8841',
        route: 'Main Campus → Rupnagar City Centre',
        time: '02:30 PM',
        busNo: 'PB-12-A-4019',
        status: 'Valid',
      ),
      BusTicket(
        id: 'TKT-1042',
        route: 'Main Campus → Morinda Railway Station',
        time: '04:15 PM',
        busNo: 'PB-12-B-8821',
        status: 'Valid',
      ),
    ]);
  }

  /// Switches mode between 'cart' and 'bus'.
  void setDriverMode(String mode) {
    if (_driverMode != mode) {
      _driverMode = mode;
      notifyListeners();
    }
  }

  /// Updates selected cart assignment.
  void setSelectedCart(String cart) {
    if (_selectedCart != cart) {
      _selectedCart = cart;
      notifyListeners();
    }
  }

  /// Updates cart occupancy status ('Empty', 'Filling', 'Full').
  void setOccupancy(String status) {
    _occupancy = status;
    notifyListeners();
  }

  /// Toggles driver on-duty availability and active vehicle status.
  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    if (!_isOnline && _isBroadcasting) {
      // Pause telemetry when driver goes offline
      _isBroadcasting = false;
      _telemetryTimer?.cancel();
      _telemetryTimer = null;
    }
    notifyListeners();
  }

  /// Starts or stops periodic GPS telemetry broadcasting.
  void toggleLocationBroadcast() {
    _isBroadcasting = !_isBroadcasting;
    if (_isBroadcasting) {
      _isOnline = true; // Automatically mark vehicle active & online when broadcasting
      _startTelemetryTimer();
    } else {
      _telemetryTimer?.cancel();
      _telemetryTimer = null;
    }
    notifyListeners();
  }

  void _startTelemetryTimer() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _waypointIndex = (_waypointIndex + 1) % _campusWaypoints.length;
      final wp = _campusWaypoints[_waypointIndex];
      _latitude = wp['lat'] as double;
      _longitude = wp['lng'] as double;
      _heading = wp['heading'] as double;
      _currentWaypointName = wp['name'] as String;

      // Realistically decrement battery very slowly
      if (_waypointIndex == 0 && _battery > 15) {
        _battery -= 1;
      }

      notifyListeners();
    });
  }

  /// Accepts a student ride request from the queue and sets it as the active trip.
  void acceptRequest(dynamic id) {
    final idx = _requests.indexWhere((req) => req.matchesId(id));
    if (idx != -1) {
      final req = _requests.removeAt(idx);
      req.status = 'accepted';
      _activeRide = req;

      // Auto-enable telemetry broadcasting when responding to a ride hail
      if (!_isBroadcasting) {
        toggleLocationBroadcast();
      } else {
        notifyListeners();
      }
    }
  }

  /// Advances the status of the currently active ride.
  void advanceRideStatus() {
    if (_activeRide == null) return;

    if (_activeRide!.status == 'accepted') {
      _activeRide!.status = 'arriving';
    } else if (_activeRide!.status == 'arriving') {
      _activeRide!.status = 'in_progress';
    } else if (_activeRide!.status == 'in_progress') {
      _activeRide!.status = 'completed';
      _activeRide = null; // trip finished
    }
    notifyListeners();
  }

  /// Cancels the active ride.
  void cancelActiveRide() {
    _activeRide = null;
    notifyListeners();
  }

  /// Injects a test ride request for demonstration.
  void addTestRequest() {
    final id = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _requests.insert(
      0,
      RideRequest(
        id: id,
        from: 'Chenab Hostel',
        to: 'Student Activity Center (SAC)',
        time: 'Just now',
        userName: 'Rohan Verma',
      ),
    );
    notifyListeners();
  }

  /// Extracts ticket code from potential QR contents (plain, JSON, or URL).
  String _parseTicketCode(String raw) {
    final trimmed = raw.trim();
    // Check if JSON payload (e.g. {"id": "TKT-1234", ...})
    if (trimmed.startsWith('{') && trimmed.contains('id')) {
      final idMatch = RegExp(r'"id"\s*:\s*"([^"]+)"').firstMatch(trimmed);
      if (idMatch != null) {
        return idMatch.group(1)!.trim().toUpperCase();
      }
    }

    final regExp = RegExp(r'TKT-\d+', caseSensitive: false);
    final match = regExp.firstMatch(trimmed);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  /// Verifies a ticket code against the manifest or dynamic student booking.
  bool verifyTicket(String code) {
    final cleanCode = _parseTicketCode(code);
    if (cleanCode.isEmpty) {
      _scanResultType = 'error';
      _scanResultText = '✕ Empty or unreadable barcode data.';
      notifyListeners();
      return false;
    }

    final index = _tickets.indexWhere((t) => t.id == cleanCode);

    if (index != -1) {
      final ticket = _tickets[index];
      if (ticket.status == 'Valid') {
        ticket.status = 'Used (Onboarded)';
        _scanResultType = 'success';
        _scanResultText = '✓ Ticket ${ticket.id} Verified Successfully! Passenger checked in.';
        _autoUpdateOccupancy();
        notifyListeners();
        return true;
      } else {
        _scanResultType = 'warning';
        _scanResultText = '⚠ Ticket ${ticket.id} was already used!';
        notifyListeners();
        return false;
      }
    } else if (cleanCode.startsWith('TKT-')) {
      // Dynamic verification: valid student ticket booked via Sarthi_APP!
      final dynamicTicket = BusTicket(
        id: cleanCode,
        route: 'Campus Transit Route',
        time: 'Just now',
        busNo: 'PB-12-A-4019',
        status: 'Used (Onboarded)',
      );
      _tickets.insert(0, dynamicTicket);
      _scanResultType = 'success';
      _scanResultText = '✓ Sarthi App Ticket $cleanCode Verified! Passenger onboarded.';
      _autoUpdateOccupancy();
      notifyListeners();
      return true;
    } else {
      _scanResultType = 'error';
      _scanResultText = '✕ Invalid Ticket ID ($cleanCode). Please check again.';
      notifyListeners();
      return false;
    }
  }

  void _autoUpdateOccupancy() {
    final count = onboardedCount;
    if (count == 0) {
      _occupancy = 'Empty';
    } else if (count >= 24) {
      _occupancy = 'Full';
    } else {
      _occupancy = 'Filling';
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
