import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/driver_ping_service.dart';
import 'firestore_provider.dart';

final driverPingServiceProvider = Provider<DriverPingService>((ref) {
  final svc = DriverPingService(ref.watch(firestoreProvider));
  ref.onDispose(svc.stop);
  return svc;
});
