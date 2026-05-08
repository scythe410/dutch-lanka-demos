import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_prefs_provider.dart';
import '../providers/products_provider.dart';
import '../providers/user_provider.dart';

/// Notification tap callback. The router uses this to push
/// `/order/:id` (or wherever the data payload directs) when the user
/// opens a notification while the app is in the background.
typedef FcmRouter = void Function(Map<String, dynamic> data);

class FcmService {
  FcmService(this._ref, {FcmRouter? router}) : _router = router;

  final Ref _ref;
  FcmRouter? _router;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'dutch_lanka_default',
    'Order updates',
    description: 'Order status, delivery, and account notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;
  String? _registeredToken;
  ProviderSubscription<AsyncValue<User?>>? _authSub;

  void setRouter(FcmRouter router) => _router = router;

  /// Wires foreground display + background-tap routing + reacts to
  /// auth-state changes so tokens follow the signed-in user.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          _route(_decode(payload));
        }
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _route(m.data));

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Defer until the app's first frame has rendered so the router exists.
      Future<void>.delayed(const Duration(milliseconds: 200))
          .then((_) => _route(initialMessage.data));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user != null) await _writeToken(user.uid, token);
    });

    // React to login/logout to (de)register tokens.
    _authSub = _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) async {
        final prev = previous?.valueOrNull;
        final cur = next.valueOrNull;
        if (prev?.uid == cur?.uid) return;
        if (prev != null && prev.uid != cur?.uid) {
          await _removeToken(prev.uid);
        }
        if (cur != null) {
          await _registerForUser(cur);
        }
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
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        appLogger.w('FCM permission denied');
        return;
      }
      // Make sure /users/{uid} exists before we arrayUnion the token.
      await ensureUserDoc(
        auth: _ref.read(firebaseAuthProvider),
        firestore: _ref.read(firestoreProvider),
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _writeToken(user.uid, token);
    } catch (e, st) {
      appLogger.w('FCM registerForUser failed', error: e, stackTrace: st);
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
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _ref.read(firestoreProvider).collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (_) {
      // Token cleanup is best-effort; a stale token at worst sends a push
      // to a signed-out device, which the OS drops.
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final prefs = _ref.read(notificationPrefsProvider);
    final type = (message.data['type'] as String?) ?? '';
    if (type == 'order_status' && !prefs.orderUpdates) return;
    if (type == 'promotion' && !prefs.promotions) return;

    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
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
    final router = _router;
    if (router == null) return;
    router(data);
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
