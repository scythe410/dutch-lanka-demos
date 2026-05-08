import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_provider.dart';
import '../services/driver_ping_service.dart';

/// Stub Driver mode screen. Lets a manager paste an order ID and toggle
/// "I'm delivering this" — flips on a 15s GPS ping loop. Step 11 replaces
/// the manual order-ID input with a real assigned-orders list and adds a
/// foreground service so the heartbeat survives screen lock.
class DriverModeScreen extends ConsumerStatefulWidget {
  const DriverModeScreen({super.key});

  @override
  ConsumerState<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends ConsumerState<DriverModeScreen> {
  final _orderIdController = TextEditingController();
  bool _busy = false;
  String? _runningOrderId;
  String? _errorMessage;

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final svc = ref.read(driverPingServiceProvider);
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      if (_runningOrderId != null) {
        await svc.stop();
        setState(() => _runningOrderId = null);
      } else {
        final orderId = _orderIdController.text.trim();
        if (orderId.isEmpty) {
          setState(() => _errorMessage = 'Enter an order ID first.');
          return;
        }
        await svc.start(orderId);
        setState(() => _runningOrderId = orderId);
      }
    } on DriverPingException catch (e) {
      setState(() => _errorMessage = _messageFor(e));
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(DriverPingException e) {
    switch (e.kind) {
      case DriverPingError.serviceDisabled:
        return 'Turn on Location Services to share your position.';
      case DriverPingError.permissionDenied:
        return 'Location permission was denied — Driver mode needs it to send pings.';
      case DriverPingError.permissionDeniedForever:
        return 'Location permission is permanently denied. Enable it in Settings.';
      case DriverPingError.unknown:
        return 'Could not start Driver mode: ${e.cause}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = _runningOrderId != null;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const TwoToneTitle(
          black: 'Driver',
          orange: 'mode',
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Paste the order you're out delivering. We'll send a GPS "
              'ping every 15 seconds so the customer can watch you on '
              'the map.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.xl),
            AppTextField(
              controller: _orderIdController,
              label: 'Order ID',
              hint: 'Paste the order you are delivering',
              enabled: !running && !_busy,
            ),
            const SizedBox(height: Space.lg),
            if (running) _StatusBanner(orderId: _runningOrderId!),
            if (_errorMessage != null) ...[
              const SizedBox(height: Space.md),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Spacer(),
            PrimaryButton(
              label: running ? 'Stop sharing location' : 'Start Driver mode',
              icon: running ? LucideIcons.square : LucideIcons.navigation,
              onPressed: _busy ? null : _toggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.navigation,
            color: AppColors.onPrimary,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'Sharing location for order #${orderId.substring(0, orderId.length.clamp(0, 6))}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
