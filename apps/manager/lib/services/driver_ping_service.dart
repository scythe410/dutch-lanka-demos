import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:geolocator/geolocator.dart';

/// Ping cadence. Architecture.md §4.4 says 10–30 seconds; 15 is the
/// midpoint and matches the value the customer app's tracking subscription
/// is tuned for. If a manager keeps the screen open for 30 minutes that's
/// 120 docs — well within the cost budget.
const _pingInterval = Duration(seconds: 15);

enum DriverPingError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class DriverPingException implements Exception {
  const DriverPingException(this.kind, [this.cause]);
  final DriverPingError kind;
  final Object? cause;

  @override
  String toString() => 'DriverPingException($kind, $cause)';
}

/// Stub driver ping service — writes the device's GPS to
/// `/orders/{orderId}/tracking/{auto}` every 15s. Step 11 will replace
/// this with: route assignment, foreground service, retry/backoff, and
/// optional offline buffering.
///
/// The Firestore Rules enforce that only staff can write here, so the
/// signed-in user's custom claim must be `manager` or `staff`.
class DriverPingService {
  DriverPingService(this._firestore);

  final FirebaseFirestore _firestore;

  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  String? _activeOrderId;
  Position? _lastPosition;

  bool get isRunning => _timer != null;
  String? get activeOrderId => _activeOrderId;

  Future<void> start(String orderId) async {
    if (_timer != null) {
      await stop();
    }
    await _ensurePermission();
    _activeOrderId = orderId;

    // Subscribe to position updates so we always have a recent fix to
    // flush; geolocator's `getCurrentPosition` on a 15s tick can take
    // several seconds itself on cold starts.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((p) => _lastPosition = p);

    // Send an initial ping immediately so the customer's listener doesn't
    // have to wait the full interval for the first marker.
    await _flushOnce();
    _timer = Timer.periodic(_pingInterval, (_) => _flushOnce());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _activeOrderId = null;
    _lastPosition = null;
  }

  Future<void> _flushOnce() async {
    final orderId = _activeOrderId;
    if (orderId == null) return;
    try {
      final pos = _lastPosition ?? await Geolocator.getCurrentPosition();
      _lastPosition = pos;
      await _firestore
          .collection('orders')
          .doc(orderId)
          .collection('tracking')
          .add({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'recordedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      // PII-free log per CLAUDE.md rule 6 — coordinates are not logged.
      appLogger.w('DriverPingService flush failed', error: e, stackTrace: st);
    }
  }

  Future<void> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const DriverPingException(DriverPingError.serviceDisabled);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw const DriverPingException(DriverPingError.permissionDenied);
    }
    if (perm == LocationPermission.deniedForever) {
      throw const DriverPingException(
        DriverPingError.permissionDeniedForever,
      );
    }
  }
}
