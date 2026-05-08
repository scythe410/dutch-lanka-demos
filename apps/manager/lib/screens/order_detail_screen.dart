import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/users_provider.dart';
import '../services/driver_ping_service.dart';
import '../widgets/order_row.dart';

const _statusFlow = ['paid', 'preparing', 'dispatched', 'delivered'];

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _setStatus(String next) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final patch = <String, dynamic>{'status': next};
      if (next == 'dispatched') {
        patch['dispatchedAt'] = FieldValue.serverTimestamp();
      }
      if (next == 'delivered') {
        patch['deliveredAt'] = FieldValue.serverTimestamp();
        // Stop driver pings the moment the order is delivered, regardless
        // of which driver still has the toggle on. Idempotent.
        await ref.read(driverPingServiceProvider).stop();
      }
      await ref
          .read(firestoreProvider)
          .collection('orders')
          .doc(widget.orderId)
          .update(patch);
    } catch (e) {
      setState(() => _error = 'Could not update status: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignDriver(String? uid) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(firestoreProvider)
          .collection('orders')
          .doc(widget.orderId)
          .update({'assignedDeliveryUid': uid});
    } catch (e) {
      setState(() => _error = 'Could not assign: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final staffAsync = ref.watch(staffUsersProvider);
    final me = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const TwoToneTitle(black: 'Order', orange: 'detail'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, _) => _Error(),
        data: (order) {
          if (order == null) return _Error(message: 'Order not found.');
          final status = (order['status'] as String?) ?? 'paid';
          final assigned = order['assignedDeliveryUid'] as String?;
          final youAreDriver = me != null && assigned == me.uid;
          return ListView(
            padding: const EdgeInsets.all(Space.xl),
            children: [
              _CustomerCard(order: order),
              const SizedBox(height: Space.lg),
              _ItemsCard(order: order),
              const SizedBox(height: Space.lg),
              _AddressCard(order: order),
              const SizedBox(height: Space.lg),
              _StatusCard(
                status: status,
                busy: _busy,
                onSet: _setStatus,
              ),
              const SizedBox(height: Space.lg),
              _AssignCard(
                assigned: assigned,
                staff: staffAsync.valueOrNull ?? const [],
                busy: _busy,
                onAssign: _assignDriver,
              ),
              if (youAreDriver && status != 'delivered') ...[
                const SizedBox(height: Space.lg),
                _DriverModeCard(orderId: widget.orderId, status: status),
              ],
              if (_error != null) ...[
                const SizedBox(height: Space.md),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Error extends StatelessWidget {
  // ignore: unused_element_parameter
  const _Error({this.message = "We couldn't load this order."});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.md),
          child,
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final name = (order['customerName'] as String?) ?? 'Customer';
    final phone = (order['customerPhone'] as String?) ?? '—';
    return _Card(
      title: 'Customer',
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.user),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  phone,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusPill(status: (order['status'] as String?) ?? 'paid'),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? const [];
    final subtotal = (order['subtotalCents'] as int?) ?? 0;
    final delivery = (order['deliveryFeeCents'] as int?) ?? 0;
    final total = (order['totalCents'] as int?) ?? 0;
    return _Card(
      title: 'Items',
      child: Column(
        children: [
          for (final raw in items)
            if (raw is Map) _ItemLine(item: Map<String, dynamic>.from(raw)),
          const Divider(),
          _LineTotal(label: 'Subtotal', cents: subtotal),
          _LineTotal(label: 'Delivery', cents: delivery),
          _LineTotal(label: 'Total', cents: total, emphasis: true),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = (item['name'] as String?) ?? 'Item';
    final qty = (item['quantity'] as int?) ?? 1;
    final unit = (item['unitPriceCents'] as int?) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('$name × $qty')),
          Text('LKR ${(unit * qty / 100).toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class _LineTotal extends StatelessWidget {
  const _LineTotal({
    required this.label,
    required this.cents,
    this.emphasis = false,
  });
  final String label;
  final int cents;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final style = emphasis
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AppColors.primary)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('LKR ${(cents / 100).toStringAsFixed(2)}', style: style),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final addr = order['deliveryAddress'];
    if (addr is! Map) {
      return const _Card(
        title: 'Delivery address',
        child: Text('No address on file.'),
      );
    }
    final m = Map<String, dynamic>.from(addr);
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    final hasCoords = lat != null && lng != null;
    final lines = [
      m['line1'] as String?,
      m['line2'] as String?,
      m['city'] as String?,
      m['postalCode'] as String?,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    return _Card(
      title: 'Delivery address',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lines.join(', '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (hasCoords) ...[
            const SizedBox(height: Space.md),
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('dest'),
                      position: LatLng(lat, lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  },
                  liteModeEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.busy,
    required this.onSet,
  });

  final String status;
  final bool busy;
  final ValueChanged<String> onSet;

  @override
  Widget build(BuildContext context) {
    final idx = _statusFlow.indexOf(status);
    final next = idx < 0 || idx >= _statusFlow.length - 1
        ? null
        : _statusFlow[idx + 1];
    final terminal = status == 'delivered' || status == 'cancelled';
    return _Card(
      title: 'Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Space.sm,
            children: [
              for (final s in _statusFlow)
                StatusPill(status: s),
            ],
          ),
          const SizedBox(height: Space.md),
          if (next != null)
            PrimaryButton(
              label: 'Mark as ${orderStatusLabels[next] ?? next}',
              icon: LucideIcons.check,
              onPressed: busy ? null : () => onSet(next),
            )
          else if (terminal)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text(
                status == 'delivered'
                    ? 'Order delivered.'
                    : 'Order cancelled.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (status == 'paid' || status == 'preparing') ...[
            const SizedBox(height: Space.sm),
            TextButton(
              onPressed: busy ? null : () => onSet('cancelled'),
              child: const Text(
                'Cancel order',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignCard extends StatelessWidget {
  const _AssignCard({
    required this.assigned,
    required this.staff,
    required this.busy,
    required this.onAssign,
  });

  final String? assigned;
  final List<Map<String, dynamic>> staff;
  final bool busy;
  final ValueChanged<String?> onAssign;

  @override
  Widget build(BuildContext context) {
    final value = assigned ?? '';
    return _Card(
      title: 'Assign delivery',
      child: DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: '',
            child: Text('Unassigned'),
          ),
          for (final s in staff)
            DropdownMenuItem<String>(
              value: s['uid'] as String? ?? s['id'] as String,
              child: Text(
                '${s['name'] ?? s['email'] ?? '—'}'
                ' · ${s['role'] ?? 'staff'}',
              ),
            ),
        ],
        onChanged: busy
            ? null
            : (v) => onAssign(v == null || v.isEmpty ? null : v),
      ),
    );
  }
}

class _DriverModeCard extends ConsumerStatefulWidget {
  const _DriverModeCard({required this.orderId, required this.status});
  final String orderId;
  final String status;

  @override
  ConsumerState<_DriverModeCard> createState() => _DriverModeCardState();
}

class _DriverModeCardState extends ConsumerState<_DriverModeCard> {
  bool _busy = false;
  String? _error;

  Future<void> _toggle(bool on) async {
    final svc = ref.read(driverPingServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (on) {
        await svc.start(widget.orderId);
      } else {
        await svc.stop();
      }
    } on DriverPingException catch (e) {
      setState(() => _error = _humanize(e));
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanize(DriverPingException e) {
    switch (e.kind) {
      case DriverPingError.serviceDisabled:
        return 'Turn on Location Services.';
      case DriverPingError.permissionDenied:
        return 'Location permission denied.';
      case DriverPingError.permissionDeniedForever:
        return 'Location permission permanently denied — enable in Settings.';
      case DriverPingError.unknown:
        return 'Could not start: ${e.cause}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(driverPingServiceProvider);
    final running = svc.isRunning && svc.activeOrderId == widget.orderId;
    return _Card(
      title: 'Driver mode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            running
                ? 'Sharing your location every 15 seconds.'
                : "You're assigned to this order. Turn on driver mode to share your location with the customer.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          SwitchListTile(
            value: running,
            onChanged: _busy ? null : _toggle,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            title: Text(
              running ? 'On' : 'Off',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
