import 'package:flutter/foundation.dart';
import 'package:sarthi_pilot/models/bus_ticket.dart';
import 'package:sarthi_pilot/models/ride_request.dart';

/// Controller handling driver dashboard operations, dispatch queue, and ticket validation (MVC).
class DriverController extends ChangeNotifier {
  DriverController() {
    _initData();
  }

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

  void _initData() {
    _requests.addAll([
      RideRequest(
        id: 1,
        from: 'Satlej Hostel',
        to: 'JC Bose Block',
        time: 'Just now',
      ),
      RideRequest(
        id: 2,
        from: 'Beas Hostel',
        to: 'Central Library',
        time: '2 mins ago',
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

  /// Accepts and removes a student ride request from the dispatch queue.
  void acceptRequest(int id) {
    _requests.removeWhere((req) => req.id == id);
    notifyListeners();
  }

  /// Injects a test ride request for demonstration.
  void addTestRequest() {
    _requests.insert(
      0,
      RideRequest(
        id: DateTime.now().millisecondsSinceEpoch,
        from: 'Chenab Hostel',
        to: 'Student Activity Center (SAC)',
        time: 'Just now',
      ),
    );
    notifyListeners();
  }

  /// Extracts ticket code from potential QR contents (plain, JSON, or URL).
  String _parseTicketCode(String raw) {
    final trimmed = raw.trim();
    final regExp = RegExp(r'TKT-\d+', caseSensitive: false);
    final match = regExp.firstMatch(trimmed);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  /// Verifies a ticket code against the manifest.
  bool verifyTicket(String code) {
    final cleanCode = _parseTicketCode(code);
    if (cleanCode.isEmpty) return false;

    final index = _tickets.indexWhere((t) => t.id == cleanCode);

    if (index != -1) {
      final ticket = _tickets[index];
      if (ticket.status == 'Valid') {
        ticket.status = 'Used (Onboarded)';
        _scanResultType = 'success';
        _scanResultText = '✓ Ticket ${ticket.id} Verified Successfully! Passenger checked in.';
        notifyListeners();
        return true;
      } else {
        _scanResultType = 'warning';
        _scanResultText = '⚠ Ticket ${ticket.id} was already used!';
        notifyListeners();
        return false;
      }
    } else {
      _scanResultType = 'error';
      _scanResultText = '✕ Invalid Ticket ID ($cleanCode). Please check again.';
      notifyListeners();
      return false;
    }
  }
}
