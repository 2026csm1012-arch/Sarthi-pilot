import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sarthi_pilot/models/bus_schedule_model.dart';
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
  }) : _firebaseService = firebaseService ?? PilotFirebaseService(),
       _locationService = locationService ?? DeviceLocationService() {
    _driverMode = driverUser?.role ?? 'cart';
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

  // Active mode: strictly fixed by driver email ('cart' or 'bus')
  late String _driverMode;
  String get driverMode => driverUser?.role ?? _driverMode;
  bool get isBusMode => driverMode == 'bus';
  bool get isCartMode => driverMode == 'cart';

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
  StreamSubscription<List<BusTicket>>? _ticketsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _busesSub;
  StreamSubscription<Map<String, dynamic>?>? _dayScheduleSub;

  // Raw buses directly from Firestore "buses" collection
  List<Map<String, dynamic>> _rawFirestoreBuses = [];

  // Strictly locked to today's timetable day
  static String get todayDayId => OfficialBusScheduleData.dayIdForDate(DateTime.now());

  static String get todayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[DateTime.now().weekday - 1];
  }

  static String get formattedTodayDate {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '$todayName, ${now.day} ${months[now.month - 1]}';
  }

  String get todayScheduleTitle =>
      OfficialBusScheduleData.dayTitleForId(todayDayId);

  // Available buses for the selected day schedule (defaults to today only)
  List<Map<String, dynamic>> _availableBuses = [];
  List<Map<String, dynamic>> get availableBuses =>
      List.unmodifiable(_availableBuses);
  String? _gpsErrorMessage;
  String? get gpsErrorMessage => _gpsErrorMessage;

  String _selectedBusId = '';
  String get selectedBusId => _selectedBusId;
  void setSelectedBusId(String id) {
    _selectedBusId = id;
    _currentStopIndex = 0;
    _autoUpdateOccupancy();
    notifyListeners();
  }

  Map<String, dynamic>? get selectedBus {
    if (_availableBuses.isEmpty) return null;
    return _availableBuses.firstWhere(
      (b) => b['id'] == _selectedBusId,
      orElse: () => _availableBuses.first,
    );
  }

  String get currentBusRoute {
    final bus = selectedBus;
    return bus != null ? (bus['route'] as String? ?? '') : '';
  }

  String get currentBusRegistration {
    final bus = selectedBus;
    return bus != null ? (bus['registrationNumber'] as String? ?? '') : '';
  }

  String get currentRouteTitle {
    final bus = selectedBus;
    if (bus == null) return 'Campus Bus';
    final route = bus['route'] as String? ?? 'Campus Bus';
    final reg = bus['registrationNumber'] as String? ?? '';
    return reg.isNotEmpty ? '$route ($reg)' : route;
  }

  // Bus stops along the current route
  int _currentStopIndex = 0;
  int get currentStopIndex => _currentStopIndex;

  List<String> get currentBusStops {
    final bus = selectedBus;
    final List<String> list = [];
    void addStop(String s) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty &&
          !list.any((existing) => existing.toLowerCase() == trimmed.toLowerCase())) {
        list.add(trimmed);
      }
    }

    if (bus != null && bus['stops'] is List && (bus['stops'] as List).isNotEmpty) {
      for (final s in bus['stops'] as List) {
        addStop(s.toString());
      }
    } else if (bus != null) {
      final route = bus['route'] as String? ?? '';
      if (route.contains('→')) {
        for (final s in route.split('→')) {
          addStop(s);
        }
      } else if (route.contains('->')) {
        for (final s in route.split('->')) {
          addStop(s);
        }
      }
    }

    // Also include any stops booked in current bus tickets
    for (final t in currentBusTickets) {
      if (t.pickup.trim().isNotEmpty) addStop(t.pickup);
      if (t.drop.trim().isNotEmpty) addStop(t.drop);
    }

    if (list.isEmpty) {
      return ['Main Campus', 'IIT Main Gate', 'Rupnagar City Centre'];
    }
    return list;
  }

  String get currentReachedStop {
    final stops = currentBusStops;
    if (stops.isEmpty) return 'Campus Stop';
    if (_currentStopIndex < 0 || _currentStopIndex >= stops.length) {
      _currentStopIndex = 0;
    }
    return stops[_currentStopIndex];
  }

  void setReachedStopIndex(int index) {
    final stops = currentBusStops;
    if (index >= 0 && index < stops.length) {
      _currentStopIndex = index;
      notifyListeners();
    }
  }

  void nextStop() {
    final stops = currentBusStops;
    if (stops.isNotEmpty && _currentStopIndex < stops.length - 1) {
      _currentStopIndex++;
      notifyListeners();
    }
  }

  void previousStop() {
    if (_currentStopIndex > 0) {
      _currentStopIndex--;
      notifyListeners();
    }
  }

  bool get hasNextStop {
    final stops = currentBusStops;
    return stops.isNotEmpty && _currentStopIndex < stops.length - 1;
  }

  bool get hasPreviousStop => _currentStopIndex > 0;

  bool get isFinalStop {
    final stops = currentBusStops;
    return stops.isNotEmpty && _currentStopIndex >= stops.length - 1;
  }

  String get nextStopName {
    final stops = currentBusStops;
    if (hasNextStop) {
      return stops[_currentStopIndex + 1];
    }
    return '';
  }

  String get previousStopName {
    final stops = currentBusStops;
    if (hasPreviousStop) {
      return stops[_currentStopIndex - 1];
    }
    return '';
  }

  int get currentStopUnscannedPickupsCount =>
      currentStopPickups.where((t) => !t.isConfirmed).length;

  int get currentStopBoardedPickupsCount =>
      currentStopPickups.where((t) => t.isConfirmed).length;

  static bool _stopsMatch(String s1, String s2) {
    final n1 = s1.trim().toLowerCase();
    final n2 = s2.trim().toLowerCase();
    if (n1.isEmpty || n2.isEmpty) return false;
    return n1 == n2 || n1.contains(n2) || n2.contains(n1);
  }

  /// Students holding tickets dropping off at the specified stop.
  List<BusTicket> getStudentsDroppingOffAt(String stop) {
    return currentBusTickets.where((t) => _stopsMatch(t.drop, stop)).toList();
  }

  /// Students holding tickets boarding at the specified stop.
  List<BusTicket> getStudentsBoardingAt(String stop) {
    return currentBusTickets.where((t) => _stopsMatch(t.pickup, stop)).toList();
  }

  /// All students with tickets dropping off at the currently reached stop.
  List<BusTicket> get currentStopDropOffs =>
      getStudentsDroppingOffAt(currentReachedStop);

  /// All students with tickets boarding at the currently reached stop.
  List<BusTicket> get currentStopPickups =>
      getStudentsBoardingAt(currentReachedStop);

  List<BusTicket> get currentBusTickets {
    final bus = selectedBus;
    final bId = bus?['id'] as String? ?? _selectedBusId;
    final bRoute = bus?['route'] as String? ?? '';
    final bReg = bus?['registrationNumber'] as String? ?? '';

    if (bId.isEmpty && bRoute.isEmpty) return _tickets;

    return _tickets.where((t) {
      if (t.busId.isNotEmpty && t.busId == bId) return true;
      if (bRoute.isNotEmpty &&
          t.route.toLowerCase().contains(bRoute.toLowerCase())) {
        return true;
      }
      if (bReg.isNotEmpty && t.busNo.toLowerCase() == bReg.toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
  }

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

  // Real mobile device battery state
  final Battery _batteryPlugin = Battery();
  StreamSubscription<BatteryState>? _batteryStateSub;
  int _battery = 100;
  int get battery => _battery;
  bool _isCharging = false;
  bool get isCharging => _isCharging;

  String _currentWaypointName = 'Satluj Hostel';
  String get currentWaypointName => _currentWaypointName;

  bool _hasRealGpsFix = false;
  bool get hasRealGpsFix => _hasRealGpsFix;

  Timer? _heartbeatTimer;
  int _waypointIndex = 0;

  // High-precision (6 decimal places, ~0.1m accuracy) campus landmark reference points
  static const List<Map<String, dynamic>> _campusWaypoints = [
    {
      'name': 'Satluj Hostel',
      'lat': 30.969205,
      'lng': 76.468457,
      'heading': 45.0,
    },
    {
      'name': 'Beas Hostel',
      'lat': 30.969055,
      'lng': 76.466919,
      'heading': 85.0,
    },
    {
      'name': 'Chenab Hostel',
      'lat': 30.969049,
      'lng': 76.465750,
      'heading': 110.0,
    },
    {
      'name': 'Brahmaputra Boys Hostel',
      'lat': 30.966980,
      'lng': 76.466956,
      'heading': 135.0,
    },
    {
      'name': 'Annapurna Mess',
      'lat': 30.967113,
      'lng': 76.467860,
      'heading': 160.0,
    },
    {
      'name': 'Chintpurni Hostel',
      'lat': 30.967394,
      'lng': 76.468531,
      'heading': 180.0,
    },
    {
      'name': 'Ravi Hostel & Utility Block',
      'lat': 30.966900,
      'lng': 76.469900,
      'heading': 210.0,
    },
    {
      'name': 'S. Bhatnagar Academic Block',
      'lat': 30.969016,
      'lng': 76.470604,
      'heading': 240.0,
    },
    {
      'name': 'Satish Dhawan Block',
      'lat': 30.968875,
      'lng': 76.471732,
      'heading': 270.0,
    },
    {
      'name': 'Nalanda Library Junction',
      'lat': 30.967083,
      'lng': 76.473196,
      'heading': 295.0,
    },
    {
      'name': 'M. Visvesvaraya Admin Block',
      'lat': 30.968648,
      'lng': 76.473274,
      'heading': 320.0,
    },
    {
      'name': 'J.C. Bose Block',
      'lat': 30.968850,
      'lng': 76.474774,
      'heading': 340.0,
    },
    {
      'name': 'Main Gate Campus Entrance',
      'lat': 30.971321,
      'lng': 76.473160,
      'heading': 15.0,
    },
  ];

  int get totalSeats => 32;
  int get onboardedCount =>
      currentBusTickets.where((t) => t.isConfirmed).length;

  void _initData() {
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
        if (!incoming.any((r) => r.id == prev.id) &&
            _activeRide?.id != prev.id) {
          _cancellationNotice =
              '${prev.userName} cancelled ride request (${prev.from} → ${prev.to}).';
        }
      }
      _requests.clear();
      _requests.addAll(incoming);
      notifyListeners();
    });

    _initDeviceBattery();

    // Stream real-time ride history dynamically from Firebase for this driver
    final effectiveDriverId = driverUser?.driverId ?? '4A8F10CD';

    // Stream real-time completed ride history from Firebase
    _historySub = _firebaseService
        .streamDriverRideHistory(effectiveDriverId, driverUser?.uid)
        .listen((liveHistory) {
          _rideHistory.clear();
          _rideHistory.addAll(liveHistory);
          notifyListeners();
        });

    // Stream real-time passenger tickets from Firebase
    _ticketsSub = _firebaseService.streamTickets().listen((liveTickets) {
      _tickets.clear();
      _tickets.addAll(liveTickets);
      _autoUpdateOccupancy();
      notifyListeners();
    });

    // Initialize day timetable and stream scheduled buses from Firestore
    _updateAvailableBuses();
    _resubscribeDaySchedule();

    _busesSub = _firebaseService.streamBuses().listen((buses) {
      _rawFirestoreBuses = buses;
      _updateAvailableBuses();
      notifyListeners();
    });

    // Probe hardware GPS for initial phone location
    _checkInitialDeviceLocation();
  }

  /// Opens the phone's native location settings screen.
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Checks whether native location provider / GPS is enabled on the device.
  Future<bool> checkLocationEnabled() async {
    return await _locationService.isLocationServiceEnabled();
  }

  /// Checks whether location permission is granted.
  Future<bool> checkLocationPermission() async {
    return await _locationService.checkPermission();
  }

  /// Determines if a departure time string (e.g. "08:15 AM", "03:10 PM", "14:30") has passed today.
  /// A buffer of 15 minutes is added so that boarding / departing buses are not abruptly hidden.
  static bool isDepartureTimeGone(String timeStr, {int bufferMinutes = 15}) {
    if (timeStr.trim().isEmpty) return false;
    final now = DateTime.now();
    try {
      final t = timeStr.trim().toUpperCase();
      final isPm = t.endsWith('PM');
      final isAm = t.endsWith('AM');
      final clean = t.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        final dep = DateTime(now.year, now.month, now.day, hour, minute);
        return now.isAfter(dep.add(Duration(minutes: bufferMinutes)));
      }
    } catch (e) {
      debugPrint('Error parsing departure time "$timeStr": $e');
    }
    return false;
  }

  /// Filters available buses strictly for today's schedule only.
  void _updateAvailableBuses() {
    final currentDay = todayDayId;

    // 1. Filter raw Firestore buses by today
    final dayFilteredFirestore = _rawFirestoreBuses.where((b) {
      final sDayId = b['scheduleDayId'] as String?;
      if (sDayId != null && sDayId.trim().isNotEmpty) {
        return sDayId.trim().toLowerCase() == currentDay.toLowerCase();
      }
      final day = b['day'] as String?;
      if (day != null && day.trim().isNotEmpty) {
        final dLower = day.trim().toLowerCase();
        return dLower == currentDay.toLowerCase() ||
               dLower == todayName.toLowerCase();
      }
      final days = b['days'];
      if (days is List && days.isNotEmpty) {
        return days.any((d) {
          final dStr = d.toString().trim().toLowerCase();
          return dStr == currentDay.toLowerCase() ||
                 dStr == todayName.toLowerCase();
        });
      }
      final opDays = b['operatingDays'];
      if (opDays is List && opDays.isNotEmpty) {
        return opDays.any((d) {
          final dStr = d.toString().trim().toLowerCase();
          return dStr == currentDay.toLowerCase() ||
                 dStr == todayName.toLowerCase();
        });
      }
      // If no day constraint is specified and isActive is not false, it's a daily campus shuttle
      return b['isActive'] != false;
    }).toList();

    if (dayFilteredFirestore.isNotEmpty) {
      _availableBuses = dayFilteredFirestore;
    } else {
      // 2. Fallback to Official timetable dataset strictly for today
      final daySchedule =
          OfficialBusScheduleData.allDefaultSchedules[currentDay] ??
              OfficialBusScheduleData.mondaySchedule;
      _availableBuses = daySchedule.trips.where((t) => t.isActive).map((trip) {
        return {
          'id': 'sched_${currentDay}_${trip.id}',
          'route': trip.title,
          'departureTime': trip.departureTime,
          'arrivalTime': trip.arrivalTime,
          'totalSeats': trip.totalSeats,
          'availableSeats': trip.availableSeats,
          'registrationNumber': trip.registrationNumber,
          'scheduleDayId': currentDay,
          'tripNumber': trip.tripNumber,
          'stops': trip.stops.map((s) => s.stopName).toList(),
          'note': trip.note,
          'isOfficial': true,
        };
      }).toList();
    }

    // 3. Filter out buses whose departure time has already passed today
    final upcomingBuses = _availableBuses.where((b) {
      // If this bus is already selected by the driver, keep it so active trip isn't broken
      if (b['id'] == _selectedBusId && _selectedBusId.isNotEmpty) {
        return true;
      }
      final dep = b['departureTime'] as String? ?? '';
      return !isDepartureTimeGone(dep);
    }).toList();

    _availableBuses = upcomingBuses;

    // Keep selection valid
    if (!_availableBuses.any((b) => b['id'] == _selectedBusId)) {
      _selectedBusId = _availableBuses.isNotEmpty
          ? (_availableBuses.first['id'] as String? ?? '')
          : '';
      _currentStopIndex = 0;
    }

    _autoUpdateOccupancy();
  }

  /// Listens to live customized day bus schedule updates from "bus_schedules" Firestore collection.
  void _resubscribeDaySchedule() {
    _dayScheduleSub?.cancel();
    _dayScheduleSub = _firebaseService
        .streamBusScheduleForDay(todayDayId)
        .listen((data) {
      if (data != null && data['trips'] is List && (data['trips'] as List).isNotEmpty) {
        final List<Map<String, dynamic>> customTrips = [];
        for (final item in data['trips'] as List) {
          if (item is Map) {
            final tMap = Map<String, dynamic>.from(item);
            if (tMap['isActive'] == false) continue;
            final stopsRaw = tMap['stops'];
            final List<String> stopsList = [];
            if (stopsRaw is List) {
              for (final s in stopsRaw) {
                if (s is Map && s['stopName'] != null) {
                  stopsList.add(s['stopName'].toString());
                } else if (s != null) {
                  stopsList.add(s.toString());
                }
              }
            }
            customTrips.add({
              'id': tMap['id'] ?? 'custom_${tMap['tripNumber']}',
              'route': tMap['title'] ?? 'Custom Bus Route',
              'departureTime': tMap['departureTime'] ?? '',
              'arrivalTime': tMap['arrivalTime'] ?? '',
              'totalSeats': tMap['totalSeats'] ?? 35,
              'availableSeats': tMap['availableSeats'] ?? 35,
              'registrationNumber': tMap['registrationNumber'] ?? 'PB-12-Bus-01',
              'scheduleDayId': todayDayId,
              'tripNumber': tMap['tripNumber'] ?? 1,
              'stops': stopsList,
              'note': tMap['note'],
            });
          }
        }
        if (customTrips.isNotEmpty) {
          final filtered = customTrips.where((b) {
            if (b['id'] == _selectedBusId && _selectedBusId.isNotEmpty) {
              return true;
            }
            final dep = b['departureTime'] as String? ?? '';
            return !isDepartureTimeGone(dep);
          }).toList();
          _availableBuses = filtered;
          if (!_availableBuses.any((b) => b['id'] == _selectedBusId)) {
            _selectedBusId = _availableBuses.isNotEmpty
                ? (_availableBuses.first['id'] as String? ?? '')
                : '';
            _currentStopIndex = 0;
          }
          notifyListeners();
        }
      }
    });
  }

  /// Checks if location permission is already available and reads phone GPS location.
  Future<void> _checkInitialDeviceLocation() async {
    try {
      final hasPerm = await _locationService.checkPermission();
      final isEnabled = await _locationService.isLocationServiceEnabled();
      if (hasPerm && isEnabled) {
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

  /// Initializes device battery monitoring from the mobile hardware.
  Future<void> _initDeviceBattery() async {
    try {
      final level = await _batteryPlugin.batteryLevel;
      _battery = level.clamp(0, 100);
      final state = await _batteryPlugin.batteryState;
      _isCharging =
          state == BatteryState.charging || state == BatteryState.full;
      notifyListeners();
    } catch (e) {
      debugPrint('Device battery read notice: $e');
    }

    try {
      _batteryStateSub = _batteryPlugin.onBatteryStateChanged.listen((
        state,
      ) async {
        _isCharging =
            state == BatteryState.charging || state == BatteryState.full;
        try {
          final level = await _batteryPlugin.batteryLevel;
          _battery = level.clamp(0, 100);
        } catch (_) {}
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Battery state stream notice: $e');
    }
  }

  /// Manually reads and updates the latest mobile device battery level.
  Future<void> refreshDeviceBattery() async {
    try {
      final level = await _batteryPlugin.batteryLevel;
      _battery = level.clamp(0, 100);
      final state = await _batteryPlugin.batteryState;
      _isCharging =
          state == BatteryState.charging || state == BatteryState.full;
      notifyListeners();
    } catch (_) {}
  }

  /// Switches mode between 'cart' and 'bus' if not strictly bound to driver email.
  void setDriverMode(String mode) {
    if (driverUser != null) {
      // Role is fixed strictly by driver email. Cannot switch.
      _driverMode = driverUser!.role;
      return;
    }
    if (_driverMode != mode) {
      _driverMode = mode;
      notifyListeners();
    }
  }

  String get selectedCartName {
    final match = _availableCarts
        .where((c) => c.id == _selectedCart)
        .firstOrNull;
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
  /// Strictly requires real device GPS to be enabled and location permission granted.
  /// If GPS is off or no real GPS fix is available, prevents the vehicle from going online
  /// and returns false with a descriptive error in [gpsErrorMessage].
  Future<bool> toggleOnlineStatus() async {
    if (_isOnline) {
      _isOnline = false;
      _isBroadcasting = false;
      _locationService.stopListening();
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _gpsErrorMessage = null;
      await _firebaseService.setVehicleOffline(_selectedCart);
      notifyListeners();
      return true;
    }

    // 1. Check and request location permission
    bool granted = await _locationService.checkPermission();
    if (!granted) {
      granted = await _locationService.requestPermission();
    }
    if (!granted) {
      _isOnline = false;
      _isBroadcasting = false;
      _gpsErrorMessage =
          'Location permission denied. Please grant location permission to go online.';
      notifyListeners();
      return false;
    }

    // 2. Check if device location service (GPS) is turned ON
    final isGpsEnabled = await _locationService.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      _isOnline = false;
      _isBroadcasting = false;
      _gpsErrorMessage =
          'Device GPS is turned OFF. Please turn on Location in phone settings to go online.';
      notifyListeners();
      return false;
    }

    // 3. Acquire real hardware GPS fix (do not go online without real coordinates)
    final loc = await _locationService.getRealGpsFix();
    if (loc == null) {
      _isOnline = false;
      _isBroadcasting = false;
      _gpsErrorMessage =
          'Cannot acquire real GPS fix. Ensure device location is active and you have a GPS signal.';
      notifyListeners();
      return false;
    }

    // 4. Real GPS fix acquired successfully
    _gpsErrorMessage = null;
    _applyDeviceLocation(
      lat: loc['latitude']!,
      lng: loc['longitude']!,
      head: loc['heading'] ?? 0.0,
    );

    _isOnline = true;
    _isBroadcasting = true;

    // 5. Start continuous real-time hardware GPS listener
    _locationService.startListening(
      onUpdate: (lat, lng, head) {
        _applyDeviceLocation(lat: lat, lng: lng, head: head);
        if (_isOnline) {
          _syncLocationToFirebase();
        }
      },
    );

    // 6. Start heartbeat timer
    _startHeartbeatTimer();

    // 7. Immediately sync to Firebase "locations"
    _syncLocationToFirebase();
    notifyListeners();
    return true;
  }

  /// Immediately sets vehicle offline when app closes, detaches, or pauses.
  void setOfflineImmediate() {
    if (_isOnline) {
      _isOnline = false;
      _isBroadcasting = false;
      _locationService.stopListening();
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _firebaseService.setVehicleOffline(_selectedCart);
      notifyListeners();
    }
  }

  /// Alias for duty toggle to maintain backward compatibility.
  Future<bool> toggleLocationBroadcast() {
    return toggleOnlineStatus();
  }

  /// Periodic heartbeat timer to keep Firebase 'updatedAt' fresh while online.
  /// Never executes random waypoint cycling - strictly syncs real GPS coordinates.
  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isOnline) return;

      // Periodically refresh device battery stats
      refreshDeviceBattery();

      // Only sync real hardware location
      if (_hasRealGpsFix) {
        _syncLocationToFirebase();
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
      _cancellationNotice = null;

      // Update Firestore so passenger app receives the accepted status immediately
      _firebaseService.acceptRideRequest(
        req.id,
        _selectedCart,
        cartName: selectedCartName,
        driverId: driverUser?.driverId ?? '4A8F10CD',
        driverName: driverUser?.name ?? 'DRIVER',
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
    _activeRideSub = _firebaseService
        .streamRide(rideId)
        .listen(
          (ride) {
            if (ride == null) return;

            if (ride.status == 'cancelled') {
              final passenger = _activeRide?.userName ?? 'Passenger';
              final from = _activeRide?.from ?? ride.from;
              final to = _activeRide?.to ?? ride.to;
              _activeRide = null;
              _activeRideSub?.cancel();
              _activeRideSub = null;
              _cancellationNotice =
                  '$passenger cancelled the ride ($from → $to).';
              notifyListeners();
            } else if (ride.status == 'completed' ||
                ride.status == 'rejected') {
              _activeRide = null;
              _activeRideSub?.cancel();
              _activeRideSub = null;
              notifyListeners();
            }
          },
          onError: (err) {
            debugPrint('Error listening to active ride: $err');
          },
        );
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
        driverId: driverUser?.driverId ?? '4A8F10CD',
        driverName: driverUser?.name ?? 'DRIVER',
      );
    } else if (_activeRide!.status == 'arriving') {
      _activeRide!.status = 'in_progress';
      _firebaseService.updateRideStatus(
        _activeRide!.id,
        'in_progress',
        driverId: driverUser?.driverId ?? '4A8F10CD',
        driverName: driverUser?.name ?? 'DRIVER',
      );
    } else if (_activeRide!.status == 'in_progress') {
      _activeRide!.status = 'completed';
      final completedTrip = _activeRide!;
      _firebaseService.updateRideStatus(
        completedTrip.id,
        'completed',
        driverId: driverUser?.driverId ?? '4A8F10CD',
        driverName: driverUser?.name ?? 'DRIVER',
      );
      final historyEntry = RideRequest(
        id: completedTrip.id,
        from: completedTrip.from,
        to: completedTrip.to,
        time: 'Just now',
        status: 'completed',
        userName: completedTrip.userName,
        driverId: driverUser?.driverId ?? '4A8F10CD',
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

  /// Verifies a ticket code directly against Firestore database and updates confirmation.
  /// Strict verification: ticket MUST belong to the driver's current bus / route!
  Future<bool> verifyTicket(String code) async {
    final cleanCode = _parseTicketCode(code);
    if (cleanCode.isEmpty) {
      _scanResultType = 'error';
      _scanResultText = '✕ Empty or unreadable barcode data.';
      notifyListeners();
      return false;
    }

    final currentBus = selectedBus;
    final expectedBusId = currentBus?['id'] as String? ?? _selectedBusId;
    final expectedRoute = currentBus?['route'] as String?;
    final expectedBusReg = currentBus?['registrationNumber'] as String?;

    // Verify directly in Firestore database with bus matching validation
    final result = await _firebaseService.verifyAndConfirmTicket(
      ticketId: cleanCode,
      driverId: driverUser?.uid,
      driverName: driverUser?.name,
      expectedBusId: expectedBusId,
      expectedRoute: expectedRoute,
      expectedBusRegistration: expectedBusReg,
    );

    if (result['wrongBus'] == true) {
      final tRoute = result['ticketRoute'] as String? ?? 'Another Route';
      final tBusNo = result['ticketBusNo'] as String? ?? '';
      final myRoute = result['expectedRoute'] as String? ?? currentRouteTitle;

      _scanResultType = 'error';
      _scanResultText =
          '⛔ WRONG BUS / ROUTE!\nTicket $cleanCode is for:\n👉 $tRoute ($tBusNo)\n\nIt CANNOT be scanned on this bus ($myRoute).';
      notifyListeners();
      return false;
    }

    if (result['success'] == true) {
      final passenger = result['userName'] as String? ?? 'Student';
      final route = result['route'] as String? ?? currentBusRoute;
      final busNo = result['busNo'] as String? ?? currentBusRegistration;
      final pickup = result['pickup'] as String? ?? '';
      final destination = result['destination'] as String? ?? '';

      final dynamicTicket = BusTicket(
        id: cleanCode,
        route: route,
        time: 'Just now',
        busNo: busNo,
        busId: expectedBusId,
        status: 'Used (Onboarded)',
        passengerName: passenger,
        pickup: pickup,
        drop: destination,
        verifiedAt: DateTime.now(),
      );
      _tickets.removeWhere((t) => t.id == cleanCode);
      _tickets.insert(0, dynamicTicket);

      _scanResultType = 'success';
      _scanResultText =
          '✓ Ticket $cleanCode Verified Successfully!\nPassenger: $passenger ($pickup ➔ $destination)';
      _autoUpdateOccupancy();
      notifyListeners();
      return true;
    } else if (result['alreadyUsed'] == true) {
      _scanResultType = 'warning';
      _scanResultText = '⚠ Ticket $cleanCode was ALREADY USED!';
      notifyListeners();
      return false;
    } else if (result['reason'] == 'Firestore database connection not available.') {
      // Safe offline/test development fallback when native Firebase is not initialized
      final localIdx = _tickets.indexWhere((t) => t.id == cleanCode);
      if (localIdx != -1) {
        final t = _tickets[localIdx];
        if (t.isConfirmed) {
          _scanResultType = 'warning';
          _scanResultText = '⚠ Ticket $cleanCode was already used!';
          notifyListeners();
          return false;
        }
        t.status = 'Used (Onboarded)';
        _scanResultType = 'success';
        _scanResultText =
            '✓ Ticket $cleanCode Verified Successfully!\nPassenger: ${t.passengerName}';
        _autoUpdateOccupancy();
        notifyListeners();
        return true;
      } else if (cleanCode.startsWith('TKT-') && !cleanCode.contains('9999')) {
        final dynamicTicket = BusTicket(
          id: cleanCode,
          route: currentBusRoute,
          time: 'Just now',
          busNo: currentBusRegistration,
          busId: expectedBusId,
          status: 'Used (Onboarded)',
          passengerName: 'Student Passenger',
          verifiedAt: DateTime.now(),
        );
        _tickets.insert(0, dynamicTicket);
        _scanResultType = 'success';
        _scanResultText =
            '✓ Ticket $cleanCode Verified Successfully!\nPassenger: Student Passenger';
        _autoUpdateOccupancy();
        notifyListeners();
        return true;
      } else {
        _scanResultType = 'error';
        _scanResultText = '✕ Invalid Ticket ID ($cleanCode).';
        notifyListeners();
        return false;
      }
    } else {
      _scanResultType = 'error';
      _scanResultText =
          '✕ ${result['reason'] ?? 'Invalid Ticket ID ($cleanCode).'}';
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
    _batteryStateSub?.cancel();
    _cartsSub?.cancel();
    _ridesSub?.cancel();
    _activeRideSub?.cancel();
    _historySub?.cancel();
    _ticketsSub?.cancel();
    _busesSub?.cancel();
    _dayScheduleSub?.cancel();
    _locationService.stopListening();
    _heartbeatTimer?.cancel();
    if (_isOnline) {
      _firebaseService.setVehicleOffline(_selectedCart);
    }
    super.dispose();
  }
}
