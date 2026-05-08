import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dutch_lanka_shared/dutch_lanka_shared.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/firestore_provider.dart';
import '../providers/products_provider.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  const ProductEditScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _threshold = TextEditingController();
  bool _available = true;
  bool _saving = false;
  bool _uploading = false;
  String? _hydratedFor;
  String? _localImagePath;
  String? _imagePath; // Firebase Storage path
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _category.dispose();
    _price.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _hydrate(Map<String, dynamic>? p) {
    if (p == null) return;
    final id = p['id'] as String?;
    if (id == null || id == _hydratedFor) return;
    _hydratedFor = id;
    _name.text = (p['name'] as String?) ?? '';
    _description.text = (p['description'] as String?) ?? '';
    _category.text = (p['category'] as String?) ?? '';
    final priceCents = (p['priceCents'] as int?) ?? 0;
    _price.text = priceCents == 0 ? '' : (priceCents / 100).toStringAsFixed(2);
    _stock.text = ((p['stock'] as int?) ?? 0).toString();
    _threshold.text =
        ((p['lowStockThreshold'] as int?) ?? 0).toString();
    _available = (p['available'] as bool?) ?? true;
    _imagePath = p['imagePath'] as String?;
  }

  Future<void> _pickImage(String productId) async {
    setState(() {
      _error = null;
      _uploading = true;
    });
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (xfile == null) return;
      _localImagePath = xfile.path;
      final path = 'products/$productId/main.jpg';
      await FirebaseStorage.instance.ref(path).putFile(File(xfile.path));
      _imagePath = path;
    } catch (e) {
      setState(() => _error = 'Could not upload image: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _category.text.trim().isEmpty) {
      setState(() => _error = 'Name and category are required.');
      return;
    }
    final priceCents =
        ((double.tryParse(_price.text.trim()) ?? 0) * 100).round();
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final threshold = int.tryParse(_threshold.text.trim()) ?? 0;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final col = ref.read(firestoreProvider).collection('products');
      final doc = widget.productId == null
          ? col.doc()
          : col.doc(widget.productId);
      await doc.set({
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'category': _category.text.trim().toLowerCase(),
        'priceCents': priceCents,
        'stock': stock,
        'lowStockThreshold': threshold,
        'available': _available,
        if (_imagePath != null) 'imagePath': _imagePath,
        'updatedAt': FieldValue.serverTimestamp(),
        if (widget.productId == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;
    if (isEdit) {
      final productAsync = ref.watch(productByIdProvider(widget.productId!));
      _hydrate(productAsync.valueOrNull);
    }

    final productId = widget.productId ?? 'new-${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: TwoToneTitle(
          black: isEdit ? 'Edit' : 'New',
          orange: 'product',
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.xl),
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploading ? null : () => _pickImage(productId),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    image: _localImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_localImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _uploading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary)
                      : (_localImagePath == null && _imagePath == null
                          ? const Icon(
                              LucideIcons.camera,
                              color: AppColors.primary,
                              size: 32,
                            )
                          : null),
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            AppTextField(controller: _name, label: 'Name'),
            const SizedBox(height: Space.md),
            AppTextField(
              controller: _description,
              label: 'Description',
              hint: 'Short, customer-facing copy',
            ),
            const SizedBox(height: Space.md),
            AppTextField(
              controller: _category,
              label: 'Category',
              hint: 'pastry, cake, savoury…',
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _price,
                    label: 'Price (LKR)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: AppTextField(
                    controller: _stock,
                    label: 'Stock',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            AppTextField(
              controller: _threshold,
              label: 'Low-stock threshold',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Space.md),
            SwitchListTile(
              value: _available,
              onChanged: (v) => setState(() => _available = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.onPrimary,
              activeTrackColor: AppColors.primary,
              title: Text(
                'Available to customers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.md),
              Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: Space.xl),
            PrimaryButton(
              label: isEdit ? 'Save changes' : 'Create product',
              icon: LucideIcons.check,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
