import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

class DailyTotal {
  const DailyTotal(this.date, this.cents);
  final DateTime date;
  final int cents;
}

class ProductTotal {
  const ProductTotal(this.name, this.qty);
  final String name;
  final int qty;
}

/// Last 7 days of paid revenue, bucketed by day. Reads from
/// `orders where paidAt >= start` and aggregates client-side. The dataset
/// is small enough that a real aggregation Function is not yet needed.
final dailySalesProvider = StreamProvider<List<DailyTotal>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 6));
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .snapshots()
      .map((snap) {
    final byDay = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      byDay[_key(d)] = 0;
    }
    for (final doc in snap.docs) {
      final paidAt = doc.data()['paidAt'];
      if (paidAt is! Timestamp) continue;
      final d = paidAt.toDate();
      final key = _key(DateTime(d.year, d.month, d.day));
      if (byDay.containsKey(key)) {
        byDay[key] = byDay[key]! + ((doc.data()['totalCents'] as int?) ?? 0);
      }
    }
    final out = <DailyTotal>[];
    for (var i = 0; i < 7; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      out.add(DailyTotal(d, byDay[_key(d)] ?? 0));
    }
    return out;
  });
});

/// Top 5 products by quantity sold across the last 30 days. Same client-
/// side aggregation pattern.
final topProductsProvider = StreamProvider<List<ProductTotal>>((ref) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 30));
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .snapshots()
      .map((snap) {
    final byName = <String, int>{};
    for (final doc in snap.docs) {
      final items = doc.data()['items'];
      if (items is! List) continue;
      for (final raw in items) {
        if (raw is! Map) continue;
        final name = (raw['name'] as String?) ?? 'Item';
        final qty = (raw['quantity'] as int?) ?? 0;
        byName[name] = (byName[name] ?? 0) + qty;
      }
    }
    final out = byName.entries
        .map((e) => ProductTotal(e.key, e.value))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    return out.take(5).toList();
  });
});

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
