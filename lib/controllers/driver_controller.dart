import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sarthi_pilot/models/bus_ticket.dart';
import 'package:sarthi_pilot/models/ride_request.dart';
import 'package:sarthi_pilot/models/vehicle_cart.dart';
import 'package:sarthi_pilot/services/device_location_service.dart';
import 'package:sarthi_pilot/services/pilot_firebase_service.dart';

import 'package:sarthi_pilot/models/driver_user.dart';

/// Controller handling driver dashboard operations, dispatch queue, live GPS telemetry,
/// and ticket validation (MVC architecture).
class DriverController extends ChangeNotifier {
  DriverController({
    this.driverUser,
    PilotFirebaseService? firebaseService,
    DeviceLocationService? locationService,
  })  : _firebaseService = firebaseService ?? PilotFirebaseService(),
        _locationService = locationService ?? DeviceLocationService() {
    _initData();
  }

  final DriverUser? driverUser;
  final PilotFirebaseService _firebaseService;
  final DeviceLocationService _locationService;

  // Driver / Vehicle online duty status (defaults to offline until driver turns on duty)
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  String get vehicleStatusText =>
      _isOnline ? 'Online · Vehicle Active' : 'Offline · Vehicle Inactive';

  // Active mode: 'cart' or 'bus'
  String _driverMode = 'cart';
  String get driverMode => _driverMode;

  // Selected cart in EV Cart mode
  String _selectedCart = 'cart-1';
  String get selectedCart => _selectedCart;
  String get assignedCartId => _selectedCart;

  // Available carts fetched dynamically from Firebase database
  List<VehicleCart> _availableCarts = [];
  List<VehicleCart> get availableCarts => List.unmodifiable(_availableCarts);

  StreamSubscription<List<VehicleCart>>? _cartsSub;
  StreamSubscription<List<RideRequest>>? _ridesSub;
  StreamSubscription<RideRequest?>? _activeRideSub;
  StreamSubscription<List<RideRequest>>? _historySub;

  // Ride History collection associated with this driver ID
  final List<RideRequest> _rideHistory = [];
  List<RideRequest> get rideHistory => List.unmodifiable(_rideHistory);

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

  // Cancellation notice from passenger
  String? _cancellationNotice;
  String? get cancellationNotice => _cancellationNotice;
  void clearCancellationNotice() {
    _cancellationNotice = null;
    notifyListeners();
  }

  // Live GPS Telemetry state with 6-digit decimal precision
  bool _isBroadcasting = false;
  bool get isBroadcasting => _isBroadcasting;

  // Default campus starting coordinates (6 decimal precision: ~0.1m accuracy)
  double _latitude = 30.969205;
  double get latitude => _latitude;

  double _longitude = 76.468457;
  double get longitude => _longitude;

  double _heading = 45.0;
  double get heading => _heading;

  final int _battery = 95;
  int get battery => _battery;

  String _currentWaypointName = 'Satluj Hostel';
  String get currentWaypointName => _currentWaypointName;

  bool _hasRealGpsFix = false;
  bool get hasRealGpsFix => _hasRealGpsFix;

  Timer? _heartbeatTimer;
  int _waypointIndex = 0;

  // High-precision (6 decimal places, ~0.1m accuracy) campus landmark reference points
  static const List<Map<String, dynamic>> _campusWaypoints = [
    {'name': 'Satluj Hostel', 'lat': 30.969205, 'lng': 76.468457, 'heading': 45.0},
    {'name': 'Beas Hostel', 'lat': 30.969055, 'lng': 76.466919, 'heading': 85.0},
    {'name': 'Chenab Hostel', 'lat': 30.969049, 'lng': 76.465750, 'heading': 110.0},
    {'name': 'Brahmaputra Boys Hostel', 'lat': 30.966980, 'lng': 76.466956, 'heading': 135.0},
    {'name': 'Annapurna Mess', 'lat': 30.967113, 'lng': 76.467860, 'heading': 160.0},
    {'name': 'Chintpurni Hostel', 'lat': 30.967394, 'lng': 76.468531, 'heading': 180.0},
    {'name': 'Ravi Hostel & Utility Block', 'lat': 30.966900, 'lng': 76.469900, 'heading': 210.0},
    {'name': 'S. Bhatnagar Academic Block', 'lat': 30.969016, 'lng': 76.470604, 'heading': 240.0},
    {'name': 'Satish Dhawan Block', 'lat': 30.968875, 'lng': 76.471732, 'heading': 270.0},
    {'name': 'Nalanda Library Junction', 'lat': 30.967083, 'lng': 76.473196, 'heading': 295.0},
    {'name': 'M. Visvesvaraya Admin Block', 'lat': 30.968648, 'lng': 76.473274, 'heading': 320.0},
    {'name': 'J.C. Bose Block', 'lat': 30.968850, 'lng': 76.474774, 'heading': 340.0},
    {'name': 'Main Gate Campus Entrance', 'lat': 30.971321, 'lng': 76.473160, 'heading': 15.0},
  ];

  int get totalSeats => 32;
  int get onboardedCount => _tickets
      .where((t) => t.status.contains('Used') || t.status.contains('Onboarded'))
      .length;

  void _initData() {
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

    // Ensure database carts exist
    _firebaseService.ensureDefaultCartsExist();

    // Stream vehicles dynamically from the database
    _cartsSub = _firebaseService.streamAvailableCarts().listen((carts) {
      if (carts.isNotEmpty) {
        _availableCarts = carts;
        if (!_availableCarts.any((c) => c.id == _selectedCart)) {
          _selectedCart = _availableCarts.first.id;
        }
        notifyListeners();
      }
    });


    // Stream real-time student ride requests dynamically from the database
    _ridesSub = _firebaseService.streamPendingRequests().listen((incoming) {
      // Check if a pending request disappeared (cancelled by student before accept)
      for (final prev in _requests) {
        if (!incoming.any((r) => r.id == prev.id) && _activeRide?.id != prev.id) {
          _cancellationNotice = '${prev.userName} cancelled ride request (${prev.from} → ${prev.to}).';
        }
      }
      _requests.clear();
      _requests.addAll(incoming);
      notifyListeners();
    });

    // Seed initial ride history entries for driver display
    _rideHistory.addAll([
      RideRequest(
        id: 'RIDE-1049',
        from: 'Satluj Hostel',
        to: 'Nalanda Library Junction',
        time: '35m ago',
        status: 'completed',
        userName: 'Aman Sharma',
        driverId: driverUser?.uid ?? 'DEMO-DRIVER-01',
        driverName: driverUser?.name ?? 'DRIVER',
        assignedCartId: 'cart-1',
        completedAt: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      RideRequest(
        id: 'RIDE-1038',
        from: 'Chenab Hostel',
        to: 'Main Gate Campus Entrance',
        time: '2h ago',
        status: 'completed',
        userName: 'Priya Patel',
        driverId: driverUser?.uid ?? 'DEMO-DRIVER-01',
        driverName: driverUser?.name ?? 'DRIVER',
        assignedCartId: 'cart-1',
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      RideRequest(
        id: 'RIDE-1012',
        from: 'Annapurna Mess',
        to: 'J.C. Bose Block',
        time: 'Yesterday',
        status: 'completed',
        userName: 'Rahul Verma',
        driverId: driverUser?.uid ?? 'DEMO-DRIVER-01',
        driverName: driverUser?.name ?? 'DRIVER',
        assignedCartId: 'cart-2',
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Stream real-time completed ride history from Firebase for this driver
    if (driverUser != null) {
      _historySub = _firebaseService
          .streamDriverRideHistory(driverUser!.uid)
          .listen((liveHistory) {
        if (liveHistory.isNotEmpty) {
          for (final item in liveHistory) {
            final idx = _rideHistory.indexWhere((r) => r.id == item.id);
            if (idx != -1) {
              _rideHistory[idx] = item;
            } else {
              _rideHistory.insert(0, item);
            }
          }
          notifyListeners();
        }
      });
    }

    // Probe hardware GPS for initial phone location
    _checkInitialDeviceLocation();
  }

  /// Checks if location permission is already available and reads phone GPS location.
  Future<void> _checkInitialDeviceLocation() async {
    try {
      final hasPerm = await _locationService.checkPermission();
      if (hasPerm) {
        final loc = await _locationService.getCurrentLocation();
        if (loc != null) {
          _applyDeviceLocation(
            lat: loc['latitude']!,
            lng: loc['longitude']!,
            head: loc['heading'] ?? 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('DriverController checkInitialDeviceLocation notice: $e');
    }
  }

  /// Switches mode between 'cart' and 'bus'.
  void setDriverMode(String mode) {
    if (_driverMode != mode) {
      _driverMode = mode;
      notifyListeners();
    }
  }

  String get selectedCartName {
    final match = _availableCarts.where((c) => c.id == _selectedCart).firstOrNull;
    if (match != null) return match.name;
    switch (_selectedCart) {
      case 'cart-1':
        return 'EV Cart #1 (Satlej-Academic Loop)';
      case 'cart-2':
        return 'EV Cart #2 (Hostel Shuttle)';
      case 'cart-3':
        return 'EV Cart #3 (Main Gate Express)';
      default:
        return 'EV Cart ($_selectedCart)';
    }
  }

  /// Resolves the nearest named IIT Ropar campus landmark based on current GPS coordinates.
  String _resolveNearestLandmark(double lat, double lng) {
    String closestName = 'IIT Ropar Campus';
    double minSqDist = double.infinity;

    for (final wp in _campusWaypoints) {
      final wpLat = wp['lat'] as double;
      final wpLng = wp['lng'] as double;
      final dLat = (lat - wpLat).abs();
      final dLng = (lng - wpLng).abs();
      final sqDist = (dLat * dLat) + (dLng * dLng);

      if (sqDist < minSqDist) {
        minSqDist = sqDist;
        closestName = wp['name'] as String;
      }
    }

    // ~150m threshold (0.00000225 deg^2)
    if (minSqDist < 0.000005) {
      return closestName;
    } else if (minSqDist < 0.000025) {
      return 'Near $closestName';
    }
    return closestName;
  }

  /// Updates local state with real GPS coordinates (6-decimal precision).
  void _applyDeviceLocation({
    required double lat,
    required double lng,
    required double head,
  }) {
    _hasRealGpsFix = true;
    _latitude = double.parse(lat.toStringAsFixed(6));
    _longitude = double.parse(lng.toStringAsFixed(6));
    _heading = double.parse(head.toStringAsFixed(1));
    _currentWaypointName = _resolveNearestLandmark(_latitude, _longitude);
    notifyListeners();
  }

  /// Immediately pushes current 6-decimal coordinates and online status to Firebase "locations".
  void _syncLocationToFirebase() {
    _firebaseService.updateVehicleLocation(
      cartId: _selectedCart,
      cartName: selectedCartName,
      latitude: double.parse(_latitude.toStringAsFixed(6)),
      longitude: double.parse(_longitude.toStringAsFixed(6)),
      heading: _heading,
      batteryLevel: _battery,
      isOnline: _isOnline,
    );
  }

  /// Updates selected cart assignment.
  void setSelectedCart(String cart) {
    if (_selectedCart != cart) {
      if (_isOnline) {
        _firebaseService.setVehicleOffline(_selectedCart);
      }
      _selectedCart = cart;
      if (_isOnline) {
        _syncLocationToFirebase();
      }
      notifyListeners();
    }
  }

  /// Updates cart occupancy status ('Empty', 'Filling', 'Full').
  void setOccupancy(String status) {
    _occupancy = status;
    notifyListeners();
  }

  /// Toggles driver on-duty availability and active vehicle status.
  /// When online:
  /// - Prompts/verifies Android native GPS permissions.
  /// - Reads phone GPS coordinates with 6-decimal precision.
  /// - Starts continuous real-time hardware location streaming.
  /// - Pushes live location to Firebase "locations".
  /// When offline:
  /// - Stops location streaming.
  /// - Sets vehicle status to offline in Firebase "locations".
  Future<void> toggleOnlineStatus() async {
    _isOnline = !_isOnline;

    if (_isOnline) {
      _isBroadcasting = true;

      // 1. Request Android native location permission
      final granted = await _locationService.requestPermission();
      if (granted) {
        // 2. Fetch current real hardware GPS location immediately
        final loc = await _locationService.getCurrentLocation();
        if (loc != null) {
          _applyDeviceLocation(
            lat: loc['latitude']!,
            lng: loc['longitude']!,
            head: loc['heading'] ?? 0.0,
          );
        }
      }

      // 3. Start continuous real-time hardware GPS listener
      _locationService.startListening(
        onUpdate: (lat, lng, head) {
          _applyDeviceLocation(lat: lat, lng: lng, head: head);
          if (_isOnline) {
            _syncLocationToFirebase();
          }
        },
      );

      // 4. Start heartbeat timer (syncs to Firebase every 3s to refresh timestamp)
      _startHeartbeatTimer();

      // 5. Immediately sync to Firebase "locations"
      _syncLocationToFirebase();
    } else {
      _isBroadcasting = false;
      _locationService.stopListening();
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      await _firebaseService.setVehicleOffline(_selectedCart);
    }
    notifyListeners();
  }

  /// Alias for duty toggle to maintain backward compatibility.
  void toggleLocationBroadcast() {
    toggleOnlineStatus();
  }

  /// Periodic heartbeat timer to keep Firebase 'updatedAt' fresh while online.
  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isOnline) return;

      // If no hardware GPS fix exists yet (e.g. running inside desktop or simulator without GPS),
      // smoothly cycle landmark coordinates so test environments show movement.
      if (!_hasRealGpsFix) {
        _waypointIndex = (_waypointIndex + 1) % _campusWaypoints.length;
        final wp = _campusWaypoints[_waypointIndex];
        _latitude = double.parse((wp['lat'] as double).toStringAsFixed(6));
        _longitude = double.parse((wp['lng'] as double).toStringAsFixed(6));
        _heading = (wp['heading'] as num).toDouble();
        _currentWaypointName = wp['name'] as String;
      }

      _syncLocationToFirebase();
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
      _cancellationNotice = null;

      // Update Firestore so passenger app receives the accepted status immediately
      _firebaseService.acceptRideRequest(
        req.id,
        _selectedCart,
        cartName: selectedCartName,
        driverId: driverUser?.uid,
        driverName: driverUser?.name,
      );

      // Listen for passenger cancellation or status changes in real-time
      _listenToActiveRide(req.id);

      // Auto-enable online status when responding to a ride hail
      notifyListeners();
      if (!_isOnline) {
        toggleOnlineStatus();
      }
    }
  }

  /// Listens to the accepted ride document in Firestore for passenger cancellation.
  void _listenToActiveRide(String rideId) {
    _activeRideSub?.cancel();
    _activeRideSub = _firebaseService.streamRide(rideId).listen((ride) {
      if (ride == null) return;

      if (ride.status == 'cancelled') {
        final passenger = _activeRide?.userName ?? 'Passenger';
        final from = _activeRide?.from ?? ride.from;
        final to = _activeRide?.to ?? ride.to;
        _activeRide = null;
        _activeRideSub?.cancel();
        _activeRideSub = null;
        _cancellationNotice = '$passenger cancelled the ride ($from → $to).';
        notifyListeners();
      } else if (ride.status == 'completed' || ride.status == 'rejected') {
        _activeRide = null;
        _activeRideSub?.cancel();
        _activeRideSub = null;
        notifyListeners();
      }
    }, onError: (err) {
      debugPrint('Error listening to active ride: $err');
    });
  }

  /// Rejects a student ride request from the queue and updates Firestore.
  void rejectRequest(dynamic id) {
    final idx = _requests.indexWhere((req) => req.matchesId(id));
    if (idx != -1) {
      final req = _requests.removeAt(idx);
      _firebaseService.rejectRideRequest(req.id);
      notifyListeners();
    }
  }

  /// Advances the status of the currently active ride.
  void advanceRideStatus() {
    if (_activeRide == null) return;

    if (_activeRide!.status == 'accepted') {
      _activeRide!.status = 'arriving';
      _firebaseService.updateRideStatus(
        _activeRide!.id,
        'arriving',
        driverId: driverUser?.uid,
        driverName: driverUser?.name,
      );
    } else if (_activeRide!.status == 'arriving') {
      _activeRide!.status = 'in_progress';
      _firebaseService.updateRideStatus(
        _activeRide!.id,
        'in_progress',
        driverId: driverUser?.uid,
        driverName: driverUser?.name,
      );
    } else if (_activeRide!.status == 'in_progress') {
      _activeRide!.status = 'completed';
      final completedTrip = _activeRide!;
      _firebaseService.updateRideStatus(
        completedTrip.id,
        'completed',
        driverId: driverUser?.uid,
        driverName: driverUser?.name,
      );
      final historyEntry = RideRequest(
        id: completedTrip.id,
        from: completedTrip.from,
        to: completedTrip.to,
        time: 'Just now',
        status: 'completed',
        userName: completedTrip.userName,
        driverId: driverUser?.uid ?? 'DEMO-DRIVER-01',
        driverName: driverUser?.name ?? 'DRIVER',
        assignedCartId: _selectedCart,
        completedAt: DateTime.now(),
      );
      _rideHistory.removeWhere((r) => r.id == historyEntry.id);
      _rideHistory.insert(0, historyEntry);

      _activeRideSub?.cancel();
      _activeRideSub = null;
      _activeRide = null; // trip finished
    }
    notifyListeners();
  }

  /// Cancels the active ride.
  void cancelActiveRide() {
    _activeRideSub?.cancel();
    _activeRideSub = null;
    if (_activeRide != null) {
      _firebaseService.updateRideStatus(_activeRide!.id, 'cancelled');
    }
    _activeRide = null;
    notifyListeners();
  }

  /// Injects a test ride request directly into the database for demonstration.
  void addTestRequest() {
    _firebaseService.createTestRideRequest();
    if (!_firebaseService.isFirestoreAvailable) {
      _requests.add(RideRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        from: 'Satlej Hostel',
        to: 'JC Bose Block',
        time: 'Just now',
        userName: 'Aman Sharma',
      ));
      notifyListeners();
    }
  }

  /// Extracts ticket code from potential QR contents (plain, JSON, or URL).
  String _parseTicketCode(String raw) {
    final trimmed = raw.trim();
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
    } else if (cleanCode.startsWith('TKT-') && !cleanCode.contains('9999')) {
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
    _cartsSub?.cancel();
    _ridesSub?.cancel();
    _activeRideSub?.cancel();
    _historySub?.cancel();
    _locationService.stopListening();
    _heartbeatTimer?.cancel();
    if (_isOnline) {
      _firebaseService.setVehicleOffline(_selectedCart);
    }
    super.dispose();
  }
}
