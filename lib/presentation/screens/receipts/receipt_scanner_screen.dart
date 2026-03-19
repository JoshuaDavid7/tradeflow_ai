import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tradeflow_ai/domain/models/receipt.dart' as domain_receipt;
import 'package:tradeflow_ai/data/services/receipt_ai_service.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  String? _imagePath;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    // Defer reset to after the first frame to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(receiptProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: _isLoadingImage
          ? _buildLoadingImage()
          : _imagePath == null
          ? _buildCaptureOptions()
          : receiptState.hasError
              ? _buildError(receiptState.error)
              : receiptState.isProcessing
                  ? _buildProcessing(receiptState.progress)
                  : receiptState.isComplete &&
                          receiptState.currentReceipt != null
                      ? _buildSuccess(receiptState.currentReceipt!, currencySymbol)
                      : _buildPreview(),
    );
  }

  Widget _buildCaptureOptions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 100, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 32),
          Text('Scan Your Receipt',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'AI will extract all items and prices',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _capture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _capture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading image...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
            child: Center(
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _imagePath == null ? null : () async {
                  await ref
                      .read(receiptProvider.notifier)
                      .processReceipt(_imagePath!);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Process Receipt'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(receiptProvider.notifier).reset();
                  setState(() => _imagePath = null);
                },
                child: const Text('Retake'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing(double? progress) {
    final stage = switch (progress) {
      double p when p < 0.35 => 'Creating record...',
      double p when p < 0.55 => 'Backing up image...',
      double p when p < 0.65 => 'Reading text (OCR)...',
      double p when p < 0.8 => 'AI extracting items...',
      _ => 'Finalizing...',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(strokeWidth: 6, value: progress),
          ),
          const SizedBox(height: 32),
          const Text('Processing...', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(stage,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 64),
            const SizedBox(height: 12),
            Text(
              message ?? 'Could not process this receipt.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(receiptProvider.notifier).reset();
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(receiptProvider.notifier).reset();
                setState(() => _imagePath = null);
              },
              child: const Text('Pick Different Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(domain_receipt.Receipt receipt, String cs) {
    final hasCloudCopy = receipt.imageUrl?.trim().isNotEmpty ?? false;

    // Parse AI-extracted items
    ReceiptAiResult? aiResult;
    if (receipt.hasExtractedItems) {
      try {
        aiResult = ReceiptAiResult.fromJsonString(receipt.extractedItemsJson!);
      } catch (_) {}
    }
    final hasItems = aiResult != null && aiResult.items.isNotEmpty;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Success header
          Center(
            child: Column(
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.paid(context), size: 72),
                const SizedBox(height: 10),
                const Text(
                  'Receipt processed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                if (hasItems)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Text(
                        '${aiResult.items.length} item${aiResult.items.length == 1 ? '' : 's'} extracted',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Store name
          if (aiResult?.storeName != null &&
              aiResult!.storeName!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.store, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiResult.storeName!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Itemized table
          if (hasItems) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text('ITEM',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        SizedBox(
                            width: 40,
                            child: Text('QTY',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: 70,
                            child: Text('PRICE',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
                      ],
                    ),
                  ),
                  // Item rows
                  ...aiResult.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == aiResult!.items.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom:
                                    BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.name,
                                style: const TextStyle(fontSize: 14)),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('${item.quantity}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              '$cs${item.totalPrice.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Totals
                  if (aiResult.subtotal != null ||
                      aiResult.tax != null ||
                      aiResult.total != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(11)),
                        border:
                            Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                      ),
                      child: Column(
                        children: [
                          if (aiResult.subtotal != null)
                            _totalRow('Subtotal',
                                '$cs${aiResult.subtotal!.toStringAsFixed(2)}'),
                          if (aiResult.tax != null)
                            _totalRow('Tax',
                                '$cs${aiResult.tax!.toStringAsFixed(2)}'),
                          if (aiResult.total != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: _totalRow(
                                'TOTAL',
                                '$cs${aiResult.total!.toStringAsFixed(2)}',
                                bold: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Legacy summary (amount, vendor, date)
          if (!hasItems) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (receipt.extractedAmount != null)
                    Text(
                      'Amount: $cs${receipt.extractedAmount!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  if (receipt.extractedVendor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Vendor: ${receipt.extractedVendor}',
                          style: const TextStyle(fontSize: 15)),
                    ),
                  if (receipt.extractedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                          'Date: ${receipt.extractedDate!.toLocal().toString().split(' ').first}',
                          style: const TextStyle(fontSize: 15)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Storage indicator
          Row(
            children: [
              Icon(
                hasCloudCopy ? Icons.cloud_done : Icons.phone_iphone,
                size: 16,
                color: hasCloudCopy
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                hasCloudCopy
                    ? 'Backed up securely to cloud storage'
                    : 'Stored on this device',
                style: TextStyle(
                  fontSize: 12,
                  color: hasCloudCopy
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, receipt),
            icon: const Icon(Icons.auto_awesome),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            label: const Text('Use Receipt'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              ref.read(receiptProvider.notifier).reset();
              setState(() => _imagePath = null);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Scan Another'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Future<void> _capture(ImageSource source) async {
    final image = await ImagePicker()
        .pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (image != null) {
      setState(() => _isLoadingImage = true);
      ref.read(receiptProvider.notifier).reset();
      // Allow the loading UI to render before setting the image path
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _imagePath = image.path;
          _isLoadingImage = false;
        });
      }
    }
  }
}
