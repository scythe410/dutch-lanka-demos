import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/orders_provider.dart';
import '../widgets/order_row.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(black: 'All', orange: 'orders'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ordersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Center(
            child: Text(
              "We couldn't load orders.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No orders yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Space.xl),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
            itemBuilder: (_, i) => OrderRow(
              order: orders[i],
              onTap: () => context.push('/orders/${orders[i]['id']}'),
            ),
          );
        },
      ),
    );
  }
}
