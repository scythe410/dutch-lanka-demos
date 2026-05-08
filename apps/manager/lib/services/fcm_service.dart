import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';

typedef FcmRouter = void Function(Map<String, dynamic> data);

/// Manager-side FCM. Mirrors `apps/customer/lib/services/fcm_service.dart`
/// but writes the token to the *signed-in manager's* `/users/{uid}.fcmTokens`
/// so the existing `onOrderCreate` / low-stock / complaint pushes can
/// land on this device. The customer-side helper-doc creation is not
/// needed — managers always have a `/users/{uid}` doc (created by
/// `setManagerRole` which mirrors role into the doc).
class FcmService {
  FcmService(this._ref, {FcmRouter? router}) : _router = router;

  final Ref _ref;
  FcmRouter? _router;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'dutch_lanka_manager_default',
    'Manager alerts',
    description: 'New orders, low stock, complaints, staff updates.',
    importance: Importance.high,
  );

  bool _initialized = false;
  String? _registeredToken;
  ProviderSubscription<AsyncValue<User?>>? _authSub;

  void setRouter(FcmRouter r) => _router = r;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final p = resp.payload;
        if (p != null && p.isNotEmpty) _route(_decode(p));
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _route(m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      Future<void>.delayed(const Duration(milliseconds: 200))
          .then((_) => _route(initial.data));
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      final u = _ref.read(firebaseAuthProvider).currentUser;
      if (u != null) await _writeToken(u.uid, t);
    });

    _authSub = _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (prev, next) async {
        final p = prev?.valueOrNull;
        final c = next.valueOrNull;
        if (p?.uid == c?.uid) return;
        if (p != null && p.uid != c?.uid) await _removeToken(p.uid);
        if (c != null) await _registerForUser(c);
      },
      fireImmediately: true,
    );
  }

  Future<void> dispose() async {
    _authSub?.close();
    _authSub = null;
  }

  Future<void> _registerForUser(User user) async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _writeToken(user.uid, token);
    } catch (e, st) {
      appLogger.w('Manager FCM register failed', error: e, stackTrace: st);
    }
  }

  Future<void> _writeToken(String uid, String token) async {
    if (_registeredToken == token) return;
    _registeredToken = token;
    await _ref.read(firestoreProvider).collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  Future<void> _removeToken(String uid) async {
    final t = _registeredToken;
    _registeredToken = null;
    if (t == null) return;
    try {
      await _ref.read(firestoreProvider).collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([t]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encode(message.data),
    );
  }

  void _route(Map<String, dynamic> data) {
    final r = _router;
    if (r != null) r(data);
  }

  static String _encode(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('|');

  static Map<String, dynamic> _decode(String payload) {
    final out = <String, dynamic>{};
    for (final part in payload.split('|')) {
      final i = part.indexOf('=');
      if (i <= 0) continue;
      out[part.substring(0, i)] = part.substring(i + 1);
    }
    return out;
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final svc = FcmService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});
