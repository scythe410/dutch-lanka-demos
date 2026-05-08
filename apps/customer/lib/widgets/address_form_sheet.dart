import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/addresses_provider.dart';

const _defaultCenter = LatLng(6.9271, 79.8612);

/// Bottom-sheet form for creating or editing a delivery address. Tap-on-map
/// picker for lat/lng, plus the standard line1 / line2 / city / postal
/// fields. The "Save as default" checkbox triggers `setDefault` after the
/// upsert so we never end up with two defaults — see `AddressRepository`.
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({
    super.key,
    required this.repo,
    this.initial,
  });

  final AddressRepository repo;
  final Address? initial;

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _postalCode;
  late LatLng? _picked;
  late bool _isDefault;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _label = TextEditingController(text: a?.label ?? '');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _line2 = TextEditingController(text: a?.line2 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _postalCode = TextEditingController(text: a?.postalCode ?? '');
    _picked = (a?.lat != null && a?.lng != null) ? LatLng(a!.lat!, a.lng!) : null;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty || _line1.text.trim().isEmpty ||
        _city.text.trim().isEmpty) {
      setState(() => _error = 'Label, address line, and city are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = Address(
        id: widget.initial?.id ?? '',
        label: _label.text.trim(),
        line1: _line1.text.trim(),
        line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        city: _city.text.trim(),
        postalCode:
            _postalCode.text.trim().isEmpty ? null : _postalCode.text.trim(),
        lat: _picked?.latitude,
        lng: _picked?.longitude,
        isDefault: _isDefault,
      );
      final id = await widget.repo.upsert(draft);
      if (_isDefault) await widget.repo.setDefault(id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(AppRadius.dragHandle),
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              Text(
                widget.initial == null ? 'Add address' : 'Edit address',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Space.lg),
              AppTextField(
                controller: _label,
                label: 'Label',
                hint: 'e.g. Home, Office',
              ),
              const SizedBox(height: Space.md),
              AppTextField(
                controller: _line1,
                label: 'Address line 1',
                hint: 'Street, number',
              ),
              const SizedBox(height: Space.md),
              AppTextField(
                controller: _line2,
                label: 'Address line 2 (optional)',
                hint: 'Apartment, unit',
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _city,
                      label: 'City',
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: AppTextField(
                      controller: _postalCode,
                      label: 'Postal code',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Text(
                'Drop a pin',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Space.sm),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _picked ?? _defaultCenter,
                      zoom: 14,
                    ),
                    onTap: (latLng) => setState(() => _picked = latLng),
                    markers: _picked == null
                        ? const {}
                        : {
                            Marker(
                              markerId: const MarkerId('picked'),
                              position: _picked!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange,
                              ),
                            ),
                          },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                  ),
                ),
              ),
              if (_picked != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  'Pinned at ${_picked!.latitude.toStringAsFixed(5)}, '
                  '${_picked!.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: Space.md),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: const Text('Set as default'),
              ),
              if (_error != null) ...[
                const SizedBox(height: Space.sm),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: Space.md),
              PrimaryButton(
                label: widget.initial == null ? 'Save address' : 'Update address',
                icon: LucideIcons.check,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: Space.lg),
            ],
          ),
        );
      },
    );
  }
}
