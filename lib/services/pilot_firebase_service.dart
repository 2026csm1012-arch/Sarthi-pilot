import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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


  CollectionReference<Map<String, dynamic>>? get _ridesRef =>
      _firestore?.collection(ridesCollection);

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

  /// Streams ride history specifically associated with this driver ID.
  Stream<List<RideRequest>> streamDriverRideHistory(String driverId) {
    final ref = _ridesRef;
    if (ref == null) return Stream.value([]);

    return ref
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final rides = snapshot.docs.map((doc) => RideRequest.fromDoc(doc)).toList();
      rides.sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.completedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return rides;
    });
  }

  /// Generates a test student request directly in Firestore for end-to-end verification.
  Future<void> createTestRideRequest() async {
    try {
      final ref = _ridesRef;
      if (ref == null) return;

      final stops = [
        'Satluj Hostel',
        'Beas Hostel',
        'Chenab Hostel',
        'Brahmaputra Boys Hostel',
        'Nalanda Library Junction',
        'J.C. Bose Block',
        'Main Gate',
      ];
      final random = Random();
      final from = stops[random.nextInt(stops.length)];
      var to = stops[random.nextInt(stops.length)];
      while (to == from) {
        to = stops[random.nextInt(stops.length)];
      }

      final studentNames = [
        'Aman Sharma',
        'Priya Patel',
        'Rahul Verma',
        'Sneha Gupta',
        'Harpreet Singh'
      ];
      final name = studentNames[random.nextInt(studentNames.length)];

      await ref.add({
        'pickup': from,
        'drop': to,
        'userName': name,
        'userEmail': '${name.toLowerCase().replaceAll(' ', '.')}@iitrpr.ac.in',
        'userId': 'test-student-${random.nextInt(900) + 100}',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('createTestRideRequest notice: $e');
    }
  }
}
