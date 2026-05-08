import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only notification toggles. Real per-channel server-side filtering
/// would need a Cloud Function read of these keys; for MVP we just gate
/// foreground display + silence the local notification when off.
class NotificationPrefs {
  const NotificationPrefs({
    this.orderUpdates = true,
    this.promotions = true,
  });

  final bool orderUpdates;
  final bool promotions;

  NotificationPrefs copyWith({bool? orderUpdates, bool? promotions}) =>
      NotificationPrefs(
        orderUpdates: orderUpdates ?? this.orderUpdates,
        promotions: promotions ?? this.promotions,
      );
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs()) {
    _load();
  }

  static const _kOrderUpdates = 'notif.order_updates';
  static const _kPromotions = 'notif.promotions';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPrefs(
      orderUpdates: prefs.getBool(_kOrderUpdates) ?? true,
      promotions: prefs.getBool(_kPromotions) ?? true,
    );
  }

  Future<void> setOrderUpdates(bool v) async {
    state = state.copyWith(orderUpdates: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOrderUpdates, v);
  }

  Future<void> setPromotions(bool v) async {
    state = state.copyWith(promotions: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPromotions, v);
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
  (_) => NotificationPrefsNotifier(),
);
