import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/order_provider.dart';
import '../services/map_markers.dart';

const _statusLabels = {
  'pending_payment': 'Waiting for payment',
  'paid': 'Payment confirmed',
  'preparing': 'Preparing',
  'dispatched': 'Dispatched',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

const _paymentLabels = {
  'pending': 'Processing payment…',
  'paid': 'Payment received',
  'failed': 'Payment failed',
  'refunded': 'Refunded',
};

/// Pill-row stages displayed over the map. `cancelled` falls back to a
/// single-pill state so the row doesn't lie about progress.
const _stages = ['preparing', 'dispatched', 'delivered'];

/// Bakery origin (Colombo). Architecture says the bakery is single-location;
/// hardcoded here until we move it to a `/config/bakery` doc.
const _bakeryLatLng = LatLng(6.9271, 79.8612);

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _controller;
  BitmapDescriptor? _bakeryIcon;
  BitmapDescriptor? _courierIcon;
  LatLng? _animatedCourier;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final bakery = await MapMarkers.bakery();
    final courier = await MapMarkers.courier();
    if (!mounted) return;
    setState(() {
      _bakeryIcon = bakery;
      _courierIcon = courier;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onCourierUpdate(LatLng next) {
    // GoogleMap rebuilds the marker on each setState, which the platform
    // view animates between positions over ~250ms by default. Smooth
    // enough for a 15s ping cadence — no need for a custom Tween.
    setState(() => _animatedCourier = next);
    _controller?.animateCamera(CameraUpdate.newLatLng(next));
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final pingAsync = ref.watch(latestCourierPingProvider(widget.orderId));

    ref.listen<AsyncValue<CourierPing?>>(
      latestCourierPingProvider(widget.orderId),
      (_, next) {
        final ping = next.valueOrNull;
        if (ping != null) _onCourierUpdate(LatLng(ping.lat, ping.lng));
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => _ErrorView(onBack: () => context.go('/home')),
        data: (order) {
          if (order == null) {
            return _ErrorView(
              onBack: () => context.go('/home'),
              message: 'Order not found.',
            );
          }
          return _TrackingBody(
            orderId: widget.orderId,
            order: order,
            bakeryIcon: _bakeryIcon,
            courierIcon: _courierIcon,
            courierLatLng: _animatedCourier ??
                (pingAsync.valueOrNull == null
                    ? null
                    : LatLng(
                        pingAsync.value!.lat,
                        pingAsync.value!.lng,
                      )),
            onMapCreated: (c) => _controller = c,
          );
        },
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.orderId,
    required this.order,
    required this.bakeryIcon,
    required this.courierIcon,
    required this.courierLatLng,
    required this.onMapCreated,
  });

  final String orderId;
  final Map<String, dynamic> order;
  final BitmapDescriptor? bakeryIcon;
  final BitmapDescriptor? courierIcon;
  final LatLng? courierLatLng;
  final ValueChanged<GoogleMapController> onMapCreated;

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String?) ?? 'pending_payment';
    final paymentStatus = (order['paymentStatus'] as String?) ?? 'pending';
    final isProcessing =
        status == 'pending_payment' && paymentStatus == 'pending';

    final destination = _addressLatLng(order['deliveryAddress']);

    final markers = <Marker>{
      if (bakeryIcon != null)
        Marker(
          markerId: const MarkerId('bakery'),
          position: _bakeryLatLng,
          icon: bakeryIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      if (destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      if (courierLatLng != null && courierIcon != null)
        Marker(
          markerId: const MarkerId('courier'),
          position: courierLatLng!,
          icon: courierIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = constraints.maxHeight * 0.65;
        return Stack(
          children: [
            SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: courierLatLng ?? destination ?? _bakeryLatLng,
                  zoom: 13,
                ),
                markers: markers,
                onMapCreated: onMapCreated,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + Space.sm,
              left: Space.lg,
              child: _BackButton(onTap: () => context.go('/orders')),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + Space.sm,
              left: 64,
              right: Space.lg,
              child: _StatusPills(currentStatus: status),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(
                orderId: orderId,
                order: order,
                isProcessing: isProcessing,
                paymentStatus: paymentStatus,
                status: status,
              ),
            ),
          ],
        );
      },
    );
  }

  static LatLng? _addressLatLng(dynamic raw) {
    if (raw is! Map) return null;
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onPrimary,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: const Padding(
          padding: EdgeInsets.all(Space.sm),
          child: Icon(
            LucideIcons.arrow_left,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _StatusPills extends StatelessWidget {
  const _StatusPills({required this.currentStatus});
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _stages.indexOf(currentStatus);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _stages.length; i++) ...[
          _Pill(
            label: _statusLabels[_stages[i]] ?? _stages[i],
            active: i <= activeIndex,
          ),
          if (i < _stages.length - 1) const SizedBox(width: Space.xs),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.buttonPill),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: AppColors.shadow, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.orderId,
    required this.order,
    required this.isProcessing,
    required this.paymentStatus,
    required this.status,
  });

  final String orderId;
  final Map<String, dynamic> order;
  final bool isProcessing;
  final String paymentStatus;
  final String status;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  _paymentLabels[paymentStatus] ?? paymentStatus,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final address = order['deliveryAddress'];
    final addressLine = address is Map
        ? [address['line1'], address['city']]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(', ')
        : 'Delivery address';
    final etaLabel = _etaLabel(status);
    final courierName =
        (order['assignedDeliveryUid'] as String?) != null ? 'Courier' : 'Bakery team';

    return DeliveryTrackingCard(
      courierName: courierName,
      etaLabel: etaLabel,
      locationLabel: addressLine.isEmpty ? 'En route' : addressLine,
      onCallPressed: () {
        // Driver phone numbers aren't exposed yet — wired up in Step 11
        // when the driver app surfaces a verified contact channel.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calling the courier will be available soon.'),
          ),
        );
      },
    );
  }

  String _etaLabel(String status) {
    switch (status) {
      case 'preparing':
        return 'Estimated 25–35 min';
      case 'dispatched':
        return 'Arriving shortly';
      case 'delivered':
        final ts = order['deliveredAt'];
        if (ts is Timestamp) {
          final t = ts.toDate();
          return 'Delivered at ${t.hour.toString().padLeft(2, '0')}:'
              '${t.minute.toString().padLeft(2, '0')}';
        }
        return 'Delivered';
      default:
        return _statusLabels[status] ?? status;
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onBack,
    this.message = "We couldn't load your order.",
  });

  final VoidCallback onBack;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.lg),
            PrimaryButton(label: 'Back to home', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
