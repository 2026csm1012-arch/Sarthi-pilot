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

  /// Synchronizes live bus stop progress, active stop names, and stops array to the Firestore "buses" collection.
  /// This ensures passenger apps tracking this bus route see the live stop status (Departed, Approaching, On Time) in real time.
  Future<void> syncBusStopProgress({
    required String busId,
    String? busRoute,
    String? busRegistration,
    required int currentStopIndex,
    required String currentStopName,
    String? nextStopName,
    List<String>? allStopNames,
    int? onboardedCount,
    String? speed,
    double? latitude,
    double? longitude,
    bool isCompleted = false,
  }) async {
    final ref = _busesRef;
    if (ref == null) return;

    try {
      final updateData = <String, dynamic>{
        'currentStopIndex': currentStopIndex,
        'currentStop': currentStopName,
        'nextStop': nextStopName ?? '',
        'currentLocation': currentStopName,
        'lastUpdated': 'Just now',
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (speed != null) {
        updateData['speed'] = speed;
      }
      if (latitude != null && longitude != null) {
        updateData['latitude'] = double.parse(latitude.toStringAsFixed(6));
        updateData['longitude'] = double.parse(longitude.toStringAsFixed(6));
      }

      void updateStopsStatus(Map<String, dynamic> docData, Map<String, dynamic> target) {
        if (onboardedCount != null) {
          final total = (docData['totalSeats'] as num?)?.toInt() ?? 30;
          target['availableSeats'] = (total - onboardedCount).clamp(0, total);
        }

        final existingStops = docData['stops'];
        if (existingStops is List && existingStops.isNotEmpty) {
          final updatedStops = <dynamic>[];
          for (int i = 0; i < existingStops.length; i++) {
            final item = existingStops[i];
            final isDeparted = i < currentStopIndex;
            final isNext = i == currentStopIndex;
            if (item is Map) {
              final sMap = Map<String, dynamic>.from(item);
              sMap['isDeparted'] = isDeparted;
              sMap['isNext'] = isNext;
              if (isDeparted) {
                sMap['status'] = 'Departed';
                sMap['statusText'] = 'Departed';
              } else if (isNext) {
                sMap['status'] = 'Approaching';
                sMap['statusText'] = 'Approaching';
              } else {
                sMap['status'] = 'On Time';
                sMap['statusText'] = 'On Time';
              }
              updatedStops.add(sMap);
            } else {
              final stopName = item.toString();
              updatedStops.add({
                'name': stopName,
                'isDeparted': isDeparted,
                'isNext': isNext,
                'status': isDeparted ? 'Departed' : (isNext ? 'Approaching' : 'On Time'),
                'statusText': isDeparted ? 'Departed' : (isNext ? 'Approaching' : 'On Time'),
              });
            }
          }
          target['stops'] = updatedStops;
        } else if (allStopNames != null && allStopNames.isNotEmpty) {
          final generatedStops = <Map<String, dynamic>>[];
          for (int i = 0; i < allStopNames.length; i++) {
            final isDeparted = i < currentStopIndex;
            final isNext = i == currentStopIndex;
            generatedStops.add({
              'name': allStopNames[i],
              'isDeparted': isDeparted,
              'isNext': isNext,
              'status': isDeparted ? 'Departed' : (isNext ? 'Approaching' : 'On Time'),
              'statusText': isDeparted ? 'Departed' : (isNext ? 'Approaching' : 'On Time'),
            });
          }
          target['stops'] = generatedStops;
        }
      }

      // 1. Direct doc reference by busId
      if (busId.isNotEmpty) {
        final docRef = ref.doc(busId);
        final snap = await docRef.get();
        if (snap.exists && snap.data() != null) {
          final target = Map<String, dynamic>.from(updateData);
          updateStopsStatus(snap.data()!, target);
          await docRef.set(target, SetOptions(merge: true));
          debugPrint('Synced bus $busId stop progress in buses to stop $currentStopIndex ($currentStopName)');
          return;
        }
      }

      // 2. Query by route
      if (busRoute != null && busRoute.isNotEmpty) {
        final q = await ref.where('route', isEqualTo: busRoute).limit(1).get();
        if (q.docs.isNotEmpty) {
          final doc = q.docs.first;
          final target = Map<String, dynamic>.from(updateData);
          updateStopsStatus(doc.data(), target);
          await doc.reference.set(target, SetOptions(merge: true));
          debugPrint('Synced bus by route "$busRoute" stop $currentStopIndex to Firestore.');
          return;
        }

        // Fuzzy/normalized route matching fallback
        final allDocs = await ref.get();
        final cExpected = cleanRoute(busRoute);
        for (final doc in allDocs.docs) {
          final docRoute = cleanRoute(doc.data()['route'] as String?);
          if (docRoute == cExpected || docRoute.contains(cExpected) || cExpected.contains(docRoute)) {
            final target = Map<String, dynamic>.from(updateData);
            updateStopsStatus(doc.data(), target);
            await doc.reference.set(target, SetOptions(merge: true));
            debugPrint('Synced bus by normalized route match to Firestore.');
            return;
          }
        }
      }

      // 3. Query by registrationNumber
      if (busRegistration != null && busRegistration.isNotEmpty) {
        final q = await ref.where('registrationNumber', isEqualTo: busRegistration).limit(1).get();
        if (q.docs.isNotEmpty) {
          final doc = q.docs.first;
          final target = Map<String, dynamic>.from(updateData);
          updateStopsStatus(doc.data(), target);
          await doc.reference.set(target, SetOptions(merge: true));
          debugPrint('Synced bus by registration "$busRegistration" stop $currentStopIndex to Firestore.');
          return;
        }
      }

      // 4. If busId is given and doc didn't exist yet, create or merge directly
      if (busId.isNotEmpty) {
        final target = Map<String, dynamic>.from(updateData);
        updateStopsStatus({}, target);
        await ref.doc(busId).set(target, SetOptions(merge: true));
        debugPrint('Synced bus $busId directly to Firestore buses collection.');
      }
    } catch (e) {
      debugPrint('syncBusStopProgress notice: $e');
    }
  }

  /// Cleans and standardizes route strings for comparison.
  static String cleanRoute(String? r) {
    if (r == null) return '';
    return r
        .toLowerCase()
        .replaceAll('→', '->')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

  /// Checks if two departure times conflict. Returns true ONLY if both are non-empty and clearly differ.
  static bool isTimeConflict(String? t1, String? t2) {
    if (t1 == null || t2 == null) return false;
    final c1 = normalizeTime(t1);
    final c2 = normalizeTime(t2);
    if (c1.isEmpty || c2.isEmpty) return false;
    return c1 != c2;
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
  /// Enforces that the ticket MUST match the driver's current bus or route.
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
    final rawStatus = (data['status'] as String? ?? '').trim();
    final isCompleted = data['isCompleted'] == true ||
        rawStatus.toLowerCase() == 'completed' ||
        data['tripStatus'] == 'Completed';
    final isUsed = data['isUsed'] == true ||
        rawStatus == 'Used' ||
        rawStatus.contains('Onboarded') ||
        rawStatus.contains('Boarded') ||
        isCompleted;
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

    // ROUTE / BUS MATCHING CHECK
    // Ensure the ticket belongs strictly to the driver's current bus
    if (expectedBusId != null && expectedBusId.isNotEmpty) {
      bool isMatch = false;

      // 1. Direct Bus ID match (exact or normalized)
      if (ticketBusId.isNotEmpty &&
          (ticketBusId == expectedBusId ||
           normalizeStr(ticketBusId) == normalizeStr(expectedBusId) ||
           normalizeStr(expectedBusId).contains(normalizeStr(ticketBusId)) ||
           normalizeStr(ticketBusId).contains(normalizeStr(expectedBusId)))) {
        isMatch = true;
      }

      // 2. Route string match (normalized route title or route destination)
      if (!isMatch && ticketRoute.isNotEmpty && expectedRoute != null && expectedRoute.isNotEmpty) {
        final tClean = cleanRoute(ticketRoute);
        final eClean = cleanRoute(expectedRoute);
        if (tClean == eClean || tClean.contains(eClean) || eClean.contains(tClean)) {
          isMatch = true;
        } else {
          final tDest = cleanRoute(extractDestination(ticketRoute));
          final eDest = cleanRoute(extractDestination(expectedRoute));
          if (tDest.isNotEmpty && eDest.isNotEmpty && tDest == eDest) {
            isMatch = true;
          }
        }
      }

      // 3. Vehicle Registration Number match (if route destinations do not conflict)
      if (!isMatch &&
          expectedBusRegistration != null &&
          expectedBusRegistration.isNotEmpty &&
          ticketBusNo.isNotEmpty) {
        if (normalizeStr(ticketBusNo) == normalizeStr(expectedBusRegistration)) {
          final tDest = cleanRoute(extractDestination(ticketRoute));
          final eDest = cleanRoute(extractDestination(expectedRoute ?? ''));
          if (tDest.isEmpty || eDest.isEmpty || tDest == eDest) {
            isMatch = true;
          }
        }
      }

      // 4. Departure Time Conflict Validation:
      // If route or registration matched, verify that departure time does not conflict
      if (isMatch && isTimeConflict(ticketDepTime, expectedDepartureTime)) {
        if (ticketBusId.isEmpty || ticketBusId != expectedBusId) {
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
                'Wrong Bus Trip!\nTicket is for $ticketDepTime departure, not for this $expectedDepartureTime trip.',
          };
        }
      }

      if (!isMatch) {
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
              'Wrong Bus!\nTicket is for "${ticketRoute.isNotEmpty ? ticketRoute : ticketBusNo}"${ticketDepTime.isNotEmpty ? " ($ticketDepTime)" : ""}, not for your bus ($fullAssignedName).',
        };
      }
    }

    if (isCompleted) {
      return {
        'success': false,
        'alreadyUsed': true,
        'isCompleted': true,
        'reason': 'Ticket $ticketId has ALREADY BEEN COMPLETED / CONSUMED and cannot be used again.',
        'ticketId': ticketId,
        'userName': userName,
        'ticketRoute': ticketRoute,
        'ticketBusNo': ticketBusNo,
      };
    }

    if (isUsed) {
      return {
        'success': false,
        'alreadyUsed': true,
        'isCompleted': false,
        'reason': 'Ticket $ticketId was ALREADY USED (Onboarded)!',
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

  /// Manually unboards a passenger: marks their ticket status in Firestore as 'Completed' (isUsed: true, isCompleted: true).
  /// This updates the student's app, consuming the ticket so it cannot be used further.
  Future<bool> unboardTicket({
    required String ticketId,
  }) async {
    final ref = _ticketsRef;
    if (ref == null) return false;

    try {
      final updateData = <String, dynamic>{
        'isUsed': true,
        'status': 'Completed',
        'tripStatus': 'Completed',
        'isCompleted': true,
        'unboardedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Direct doc reference
      final docSnap = await ref.doc(ticketId).get();
      if (docSnap.exists) {
        await ref.doc(ticketId).update(updateData);
        debugPrint('Ticket $ticketId marked as Completed in Firestore.');
        return true;
      }

      // 2. Query by 'id' field
      final query = await ref.where('id', isEqualTo: ticketId).limit(1).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(updateData);
        debugPrint('Ticket $ticketId marked as Completed in Firestore by id query.');
        return true;
      }

      final queryUpper = await ref.where('id', isEqualTo: ticketId.toUpperCase()).limit(1).get();
      if (queryUpper.docs.isNotEmpty) {
        await queryUpper.docs.first.reference.update(updateData);
        debugPrint('Ticket ${ticketId.toUpperCase()} marked as Completed in Firestore by uppercase id query.');
        return true;
      }

      // Fallback: check documents matching ignoring case
      final allDocs = await ref.limit(100).get();
      for (final doc in allDocs.docs) {
        final dId = doc.id.trim().toUpperCase();
        final fId = (doc.data()['id'] as String? ?? '').trim().toUpperCase();
        final target = ticketId.trim().toUpperCase();
        if (dId == target || fId == target) {
          await doc.reference.update(updateData);
          debugPrint('Ticket $target marked as Completed via fallback match in doc ${doc.id}.');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('unboardTicket notice: $e');
      return false;
    }
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
