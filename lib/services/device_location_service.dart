import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native device GPS hardware to retrieve
/// high-precision (6 decimal places) real-time coordinates.
class DeviceLocationService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.sarthi.pilot/location');
  static const EventChannel _eventChannel =
      EventChannel('com.sarthi.pilot/location_stream');

  StreamSubscription? _subscription;

  /// Requests native location permission on Android.
  Future<bool> requestPermission() async {
    try {
      final granted =
          await _methodChannel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('DeviceLocationService requestPermission: $e');
      return false;
    }
  }

  /// Checks if location permission has already been granted.
  Future<bool> checkPermission() async {
    try {
      final granted =
          await _methodChannel.invokeMethod<bool>('checkPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('DeviceLocationService checkPermission: $e');
      return false;
    }
  }

  /// Queries the most recent GPS location fix from the phone.
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final data = await _methodChannel
          .invokeMapMethod<String, dynamic>('getCurrentLocation');
      if (data != null) {
        return {
          'latitude': (data['latitude'] as num).toDouble(),
          'longitude': (data['longitude'] as num).toDouble(),
          'heading': (data['heading'] as num?)?.toDouble() ?? 0.0,
          'accuracy': (data['accuracy'] as num?)?.toDouble() ?? 0.0,
        };
      }
    } catch (e) {
      debugPrint('DeviceLocationService getCurrentLocation: $e');
    }
    return null;
  }

  /// Starts listening to real-time continuous GPS hardware stream from the phone.
  void startListening({
    required void Function(double lat, double lng, double heading) onUpdate,
  }) {
    _subscription?.cancel();
    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          if (data is Map) {
            final lat = (data['latitude'] as num?)?.toDouble();
            final lng = (data['longitude'] as num?)?.toDouble();
            final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
            if (lat != null && lng != null) {
              onUpdate(lat, lng, heading);
            }
          }
        },
        onError: (dynamic err) {
          debugPrint('DeviceLocationService stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('DeviceLocationService startListening: $e');
    }
  }

  /// Cancels live GPS subscription.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}

