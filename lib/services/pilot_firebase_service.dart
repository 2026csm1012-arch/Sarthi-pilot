import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sarthi_pilot/models/bus_ticket.dart';
import 'package:sarthi_pilot/models/ride_request.dart';
import 'package:sarthi_pilot/models/vehicle_cart.dart';

/// Service managing real-time vehicle location, duty status, and live student ride requests
/// between Sarthi-pilot and the shared Firebase Firestore database.
class PilotFirebaseService {
  PilotFirebaseService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance notice: $e');
      return null;
    }
  }

  bool get isFirestoreAvailable => _firestore != null;

  // Primary collection: "locations"
  static const String primaryCartCollection = 'locations';
  static const List<String> allCartCollections = [
    'locations',
    'Cart Location',
    'cart location',
    'cart_locations',
  ];
  static const String ridesCollection = 'rides';
  static const String ticketsCollection = 'tickets';
  static const String busesCollection = 'buses';
  static const String busSchedulesCollection = 'bus_schedules';

  CollectionReference<Map<String, dynamic>>? get _ridesRef =>
      _firestore?.collection(ridesCollection);

  CollectionReference<Map<String, dynamic>>? get _ticketsRef =>
      _firestore?.collection(ticketsCollection);

  CollectionReference<Map<String, dynamic>>? get _busesRef =>
      _firestore?.collection(busesCollection);

  CollectionReference<Map<String, dynamic>>? get _busSchedulesRef =>
      _firestore?.collection(busSchedulesCollection);

  /// Streams available campus vehicles dynamically from Firebase "locations".
  Stream<List<VehicleCart>> streamAvailableCarts() {
    final fs = _firestore;
    if (fs == null) return Stream.value([]);

    return fs.collection(primaryCartCollection).snapshots().map((snap) {
      return snap.docs.map((doc) => VehicleCart.fromDoc(doc)).toList();
    });
  }

  /// Ensures default vehicle documents exist in "locations" if empty.
  Future<void> ensureDefaultCartsExist() async {
    try {
      final fs = _firestore;
      if (fs == null) return;

      final initialCarts = [
        {
          'name': 'EV Cart #1 (Satlej-Academic Loop)',
          'status': 'offline',
          'driverOnline': false,
          'batteryLevel': 95,
          'latitude': 30.969205,
          'longitude': 76.468457,
          'heading': 45.0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'EV Cart #2 (Hostel Shuttle)',
          'status': 'offline',
          'driverOnline': false,
          'batteryLevel': 90,
          'latitude': 30.969055,
          'longitude': 76.466919,
          'heading': 85.0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'EV Cart #3 (Main Gate Express)',
          'status': 'offline',
          'driverOnline': false,
          'batteryLevel': 88,
          'latitude': 30.971321,
          'longitude': 76.473160,
          'heading': 270.0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      final colRef = fs.collection(primaryCartCollection);
      final snap = await colRef.limit(1).get();
      if (snap.docs.isEmpty) {
        for (int i = 0; i < initialCarts.length; i++) {
          final id = 'cart-${i + 1}';
          await colRef.doc(id).set(initialCarts[i]);
        }
      }
      debugPrint('ensureDefaultCartsExist: locations ready');
    } catch (e) {
      debugPrint('ensureDefaultCartsExist notice: $e');
    }
  }

  /// Streams live pending student ride requests from the Firestore `rides` collection.
  Stream<List<RideRequest>> streamPendingRequests() {
    final ref = _ridesRef;
    if (ref == null) return Stream.value([]);

    return ref
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RideRequest.fromDoc(doc)).toList();
    });
  }

  /// Real-time stream of a specific ride's document by [rideId].
  Stream<RideRequest?> streamRide(String rideId) {
    final ref = _ridesRef;
    if (ref == null) return Stream.value(null);

    return ref.doc(rideId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RideRequest.fromDoc(doc);
    });
  }

  /// Broadcasts live vehicle location and status to Firestore "locations" with 6-decimal precision.
  Future<void> updateVehicleLocation({
    required String cartId,
    required String cartName,
    required double latitude,
    required double longitude,
    required double heading,
    required int batteryLevel,
    required bool isOnline,
  }) async {
    try {
      final fs = _firestore;
      if (fs == null) return;

      final data = <String, dynamic>{
        'name': cartName,
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
        'heading': double.parse(heading.toStringAsFixed(1)),
        'batteryLevel': batteryLevel,
        'status': isOnline ? 'active' : 'offline',
        'driverOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final col in allCartCollections) {
        await fs.collection(col).doc(cartId).set(data, SetOptions(merge: true));
      }
      debugPrint('Pilot location updated in locations: ($latitude, $longitude)');
    } catch (e) {
      debugPrint('updateVehicleLocation notice: $e');
    }
  }

  /// Marks a vehicle as offline in "locations" so it disappears from the passenger map.
  Future<void> setVehicleOffline(String cartId) async {
    try {
      final fs = _firestore;
      if (fs == null) return;

      final data = <String, dynamic>{
        'status': 'offline',
        'driverOnline': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final col in allCartCollections) {
        await fs.collection(col).doc(cartId).set(data, SetOptions(merge: true));
      }
      debugPrint('Pilot vehicle $cartId marked offline in locations');
    } catch (e) {
      debugPrint('setVehicleOffline notice: $e');
    }
  }

  /// Accepts a student ride in Firestore and assigns it to this vehicle cart.
  Future<void> acceptRideRequest(
    String rideId,
    String cartId, {
    String? cartName,
    String? driverId,
    String? driverName,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': 'accepted',
        'assignedCartId': cartId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (cartName != null) {
        data['assignedCartName'] = cartName;
      }
      if (driverId != null) {
        data['driverId'] = driverId;
      }
      if (driverName != null) {
        data['driverName'] = driverName;
      }
      await _ridesRef?.doc(rideId).update(data);
      debugPrint('Pilot accepted ride $rideId for cart $cartId ($cartName, driver $driverName)');
    } catch (e) {
      debugPrint('acceptRideRequest notice: $e');
    }
  }

  /// Rejects a student ride in Firestore.
  Future<void> rejectRideRequest(String rideId) async {
    try {
      await _ridesRef?.doc(rideId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Pilot rejected ride $rideId');
    } catch (e) {
      debugPrint('rejectRideRequest notice: $e');
    }
  }

  /// Updates status of an active trip (arriving, in_progress, completed).
  Future<void> updateRideStatus(
    String rideId,
    String newStatus, {
    String? driverId,
    String? driverName,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (driverId != null) updateData['driverId'] = driverId;
      if (driverName != null) updateData['driverName'] = driverName;
      if (newStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }
      await _ridesRef?.doc(rideId).update(updateData);
    } catch (e) {
      debugPrint('updateRideStatus notice: $e');
    }
  }

  /// Streams available scheduled bus routes from Firebase "buses".
  Stream<List<Map<String, dynamic>>> streamBuses() {
    final ref = _busesRef;
    if (ref == null) return Stream.value([]);
    return ref.snapshots().map((snap) {
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Streams customized day bus schedule from "bus_schedules" for a specific dayId.
  Stream<Map<String, dynamic>?> streamBusScheduleForDay(String dayId) {
    final ref = _busSchedulesRef;
    if (ref == null) return Stream.value(null);
    return ref.doc(dayId).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return {'id': snap.id, ...snap.data()!};
      }
      return null;
    });
  }

  /// Static normalizer for departure times (e.g. "05:05 AM" -> "5:05AM", "05:05" -> "5:05").
  static String normalizeTime(String? timeStr) {
    if (timeStr == null) return '';
    String t = timeStr.trim().toUpperCase().replaceAll(' ', '');
    if (t.startsWith('0') && t.length > 1 && RegExp(r'^0[0-9]:').hasMatch(t)) {
      t = t.substring(1);
    }
    return t;
  }

  /// Normalizes strings for alphanumeric comparison (strips spacing, punctuation, case).
  static String normalizeStr(String? s) {
    if (s == null) return '';
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Extracts the destination stop from a route string formatted with arrows.
  static String extractDestination(String route) {
    if (route.contains('→')) {
      return route.split('→').last.trim();
    }
    if (route.contains('->')) {
      return route.split('->').last.trim();
    }
    if (route.contains(' to ')) {
      return route.split(' to ').last.trim();
    }
    return route.trim();
  }

  /// Extracts the origin stop from a route string formatted with arrows.
  static String extractOrigin(String route) {
    if (route.contains('→')) {
      return route.split('→').first.trim();
    }
    if (route.contains('->')) {
      return route.split('->').first.trim();
    }
    if (route.contains(' to ')) {
      return route.split(' to ').first.trim();
    }
    return route.trim();
  }

  /// Verifies a student ticket code directly on Firestore and updates its status to 'Used'.
  /// Enforces that the ticket MUST strictly match the driver's current bus or route.
  Future<Map<String, dynamic>> verifyAndConfirmTicket({
    required String ticketId,
    String? driverId,
    String? driverName,
    String? expectedBusId,
    String? expectedRoute,
    String? expectedBusRegistration,
    String? expectedDepartureTime,
  }) async {
    final ref = _ticketsRef;
    if (ref == null) {
      return {
        'success': false,
        'reason': 'Firestore database connection not available.',
      };
    }

    try {
      // 1. Try directly by doc ID (standard format 'TKT-xxxxxx')
      final docSnapshot = await ref.doc(ticketId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return await _processTicketConfirmation(
          ref.doc(ticketId),
          docSnapshot.data()!,
          driverId,
          driverName,
          expectedBusId: expectedBusId,
          expectedRoute: expectedRoute,
          expectedBusRegistration: expectedBusRegistration,
          expectedDepartureTime: expectedDepartureTime,
        );
      }

      // 2. Query by 'id' field if docId differs
      final query = await ref.where('id', isEqualTo: ticketId).limit(1).get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return await _processTicketConfirmation(
          doc.reference,
          doc.data(),
          driverId,
          driverName,
          expectedBusId: expectedBusId,
          expectedRoute: expectedRoute,
          expectedBusRegistration: expectedBusRegistration,
          expectedDepartureTime: expectedDepartureTime,
        );
      }

      return {
        'success': false,
        'reason': 'Ticket $ticketId not found in database.',
      };
    } catch (e) {
      debugPrint('verifyAndConfirmTicket error: $e');
      return {
        'success': false,
        'reason': 'Verification error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _processTicketConfirmation(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data,
    String? driverId,
    String? driverName, {
    String? expectedBusId,
    String? expectedRoute,
    String? expectedBusRegistration,
    String? expectedDepartureTime,
  }) async {
    final isUsed = data['isUsed'] == true || data['status'] == 'Used';
    final ticketId = data['id'] as String? ?? docRef.id;
    final userName = data['userName'] as String? ?? 'Student';

    final busData = data['bus'] as Map<String, dynamic>? ?? {};
    final ticketBusId = data['busId'] as String? ?? busData['id'] as String? ?? '';
    final ticketRoute = data['busRoute'] as String? ??
        busData['route'] as String? ??
        '';
    final ticketBusNo = data['busRegistration'] as String? ??
        busData['registrationNumber'] as String? ??
        '';
    final ticketDepTime = data['departureTime'] as String? ??
        busData['departureTime'] as String? ??
        '';
    final ticketPickup = data['pickup'] as String? ?? '';
    final ticketDrop = data['destination'] as String? ??
        data['drop'] as String? ??
        '';

    final assignedTitle = (expectedRoute != null && expectedRoute.isNotEmpty)
        ? expectedRoute
        : (expectedBusId ?? 'Current Bus');
    final assignedTimeStr = (expectedDepartureTime != null && expectedDepartureTime.isNotEmpty)
        ? ' ($expectedDepartureTime)'
        : '';
    final fullAssignedName = '$assignedTitle$assignedTimeStr';

    // STRICT ROUTE / BUS MATCHING CHECK
    // Ensure the ticket belongs strictly to the driver's current bus and trip schedule
    if (expectedBusId != null && expectedBusId.isNotEmpty) {
      // 1. Departure Time Mismatch Check
      final normTicketTime = normalizeTime(ticketDepTime);
      final normExpectedTime = normalizeTime(expectedDepartureTime);
      if (normTicketTime.isNotEmpty &&
          normExpectedTime.isNotEmpty &&
          normTicketTime != normExpectedTime) {
        return {
          'success': false,
          'wrongBus': true,
          'ticketId': ticketId,
          'userName': userName,
          'ticketRoute': ticketRoute,
          'ticketBusNo': ticketBusNo,
          'ticketDepartureTime': ticketDepTime,
          'expectedRoute': fullAssignedName,
          'reason':
              'Wrong Bus Trip!\nTicket is for $ticketDepTime departure, not for your $expectedDepartureTime trip.',
        };
      }

      // 2. Destination Mismatch Check
      final ticketDest = ticketDrop.isNotEmpty ? ticketDrop : extractDestination(ticketRoute);
      final expectedDest = extractDestination(expectedRoute ?? '');
      if (ticketDest.isNotEmpty && expectedDest.isNotEmpty) {
        if (normalizeStr(ticketDest) != normalizeStr(expectedDest)) {
          return {
            'success': false,
            'wrongBus': true,
            'ticketId': ticketId,
            'userName': userName,
            'ticketRoute': ticketRoute,
            'ticketBusNo': ticketBusNo,
            'ticketDepartureTime': ticketDepTime,
            'expectedRoute': fullAssignedName,
            'reason':
                'Wrong Bus Route!\nTicket is for destination "$ticketDest", not for this bus ("$expectedDest").',
          };
        }
      }

      // 3. Origin Mismatch Check
      final ticketOrig = ticketPickup.isNotEmpty ? ticketPickup : extractOrigin(ticketRoute);
      final expectedOrig = extractOrigin(expectedRoute ?? '');
      if (ticketOrig.isNotEmpty && expectedOrig.isNotEmpty) {
        if (normalizeStr(ticketOrig) != normalizeStr(expectedOrig)) {
          return {
            'success': false,
            'wrongBus': true,
            'ticketId': ticketId,
            'userName': userName,
            'ticketRoute': ticketRoute,
            'ticketBusNo': ticketBusNo,
            'ticketDepartureTime': ticketDepTime,
            'expectedRoute': fullAssignedName,
            'reason':
                'Wrong Bus Route!\nTicket origin is "$ticketOrig", not for this route ("$expectedOrig").',
          };
        }
      }

      // 4. Conflicting Bus ID Check (e.g. bus-1 vs bus-2, or m-1 vs m-2)
      if (ticketBusId.isNotEmpty && expectedBusId.isNotEmpty) {
        final normTicketId = normalizeStr(ticketBusId);
        final normExpectedId = normalizeStr(expectedBusId);
        if (normTicketId != normExpectedId &&
            !normExpectedId.endsWith(normTicketId) &&
            !normTicketId.endsWith(normExpectedId)) {
          final ticketNum = RegExp(r'\d+').firstMatch(normTicketId)?.group(0);
          final expectedNum = RegExp(r'\d+').firstMatch(normExpectedId)?.group(0);
          if (ticketNum != null && expectedNum != null && ticketNum != expectedNum) {
            return {
              'success': false,
              'wrongBus': true,
              'ticketId': ticketId,
              'userName': userName,
              'ticketRoute': ticketRoute,
              'ticketBusNo': ticketBusNo,
              'ticketDepartureTime': ticketDepTime,
              'expectedRoute': fullAssignedName,
              'reason':
                  'Wrong Bus!\nTicket is for bus $ticketBusId, not for your bus ($expectedBusId).',
            };
          }
        }
      }

      // 5. Positive Confirmation Check: Ensure positive alignment with this bus
      bool hasPositiveMatch = false;
      if (ticketBusId.isNotEmpty &&
          (normalizeStr(ticketBusId) == normalizeStr(expectedBusId) ||
           normalizeStr(expectedBusId).endsWith(normalizeStr(ticketBusId)))) {
        hasPositiveMatch = true;
      }
      if (!hasPositiveMatch &&
          ticketRoute.isNotEmpty &&
          expectedRoute != null &&
          normalizeStr(extractDestination(ticketRoute)) == normalizeStr(extractDestination(expectedRoute))) {
        hasPositiveMatch = true;
      }
      if (!hasPositiveMatch &&
          ticketDest.isNotEmpty &&
          expectedDest.isNotEmpty &&
          normalizeStr(ticketDest) == normalizeStr(expectedDest)) {
        hasPositiveMatch = true;
      }

      if (!hasPositiveMatch) {
        return {
          'success': false,
          'wrongBus': true,
          'ticketId': ticketId,
          'userName': userName,
          'ticketRoute': ticketRoute,
          'ticketBusNo': ticketBusNo,
          'ticketDepartureTime': ticketDepTime,
          'expectedRoute': fullAssignedName,
          'reason':
              'Wrong Bus!\nTicket ($ticketRoute ${ticketDepTime.isNotEmpty ? "· $ticketDepTime" : ""}) does not belong to your bus ($fullAssignedName).',
        };
      }
    }

    if (isUsed) {
      return {
        'success': false,
        'alreadyUsed': true,
        'reason': 'Ticket $ticketId was ALREADY USED!',
        'ticketId': ticketId,
        'userName': userName,
        'ticketRoute': ticketRoute,
        'ticketBusNo': ticketBusNo,
      };
    }

    // Update database status
    final now = FieldValue.serverTimestamp();
    await docRef.update({
      'isUsed': true,
      'status': 'Used',
      'confirmedByDriverId': driverId ?? 'DEMO-DRIVER',
      'confirmedByDriverName': driverName ?? 'Driver',
      'confirmedAt': now,
      'updatedAt': now,
    });

    return {
      'success': true,
      'ticketId': ticketId,
      'userName': userName,
      'route': ticketRoute,
      'busNo': ticketBusNo,
      'departureTime': ticketDepTime,
      'pickup': ticketPickup,
      'destination': ticketDrop,
    };
  }

  /// Real-time stream of booked & verified student tickets from the Firestore `tickets` collection.
  Stream<List<BusTicket>> streamTickets({String? busRoute}) {
    final ref = _ticketsRef;
    if (ref == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = ref;
    if (busRoute != null && busRoute.isNotEmpty) {
      query = query.where('busRoute', isEqualTo: busRoute);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => BusTicket.fromDoc(doc)).toList();
      list.sort((a, b) {
        final aDate = a.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.verifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Streams ride history from Firestore filtered for the given driver ID.
  Stream<List<RideRequest>> streamDriverRideHistory([String? driverId, String? uid]) {
    final ref = _ridesRef;
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      final rides = snapshot.docs
          .map((doc) => RideRequest.fromDoc(doc))
          .where((r) {
            final isFinished = r.status == 'completed' ||
                r.status == 'cancelled' ||
                r.status == 'rejected';
            if (!isFinished) return false;

            // When a driver ID is provided, strictly show history for that given ID
            if (driverId != null && driverId.isNotEmpty) {
              final match = r.driverId == driverId ||
                  (uid != null && uid.isNotEmpty && r.driverId == uid);
              return match;
            }
            return true;
          })
          .toList();
      rides.sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.completedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return rides;
    });
  }
}
