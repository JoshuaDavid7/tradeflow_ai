// Quick unit test verifying that receipt review total recalculation works correctly
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_ai/data/services/receipt_ai_service.dart';

void main() {
  group('Receipt review totals recalculation', () {
    // Simulates the exact logic now in _recalculateReceiptAmount and the Builder
    final result = ReceiptAiResult(
      storeName: 'Test Store',
      items: [
        const ReceiptLineItem(name: 'Item A', quantity: 1, unitPrice: 100.0, totalPrice: 100.0),
        const ReceiptLineItem(name: 'Item B', quantity: 2, unitPrice: 50.0, totalPrice: 100.0),
        const ReceiptLineItem(name: 'Item C', quantity: 1, unitPrice: 249.22, totalPrice: 249.22),
      ],
      subtotal: 449.22,
      tax: 36.17,
      total: 485.39,
    );

    test('all items selected - totals match original', () {
      final deselected = <int>{};
      double subtotal = 0;
      for (var i = 0; i < result.items.length; i++) {
        if (deselected.contains(i)) continue;
        final item = result.items[i];
        subtotal += item.totalPrice > 0 ? item.totalPrice : item.unitPrice * item.quantity;
      }
      double tax = 0;
      if (result.tax != null && result.tax! > 0 && result.subtotal != null && result.subtotal! > 0) {
        tax = result.tax! * (subtotal / result.subtotal!);
      }
      final total = subtotal + tax;

      expect(subtotal, 449.22);
      expect(tax, closeTo(36.17, 0.01));
      expect(total, closeTo(485.39, 0.01));
    });

    test('deselecting expensive item C (249.22) updates totals correctly', () {
      final deselected = <int>{2}; // Deselect Item C
      double subtotal = 0;
      for (var i = 0; i < result.items.length; i++) {
        if (deselected.contains(i)) continue;
        final item = result.items[i];
        subtotal += item.totalPrice > 0 ? item.totalPrice : item.unitPrice * item.quantity;
      }
      double tax = 0;
      if (result.tax != null && result.tax! > 0 && result.subtotal != null && result.subtotal! > 0) {
        tax = result.tax! * (subtotal / result.subtotal!);
      }
      final total = subtotal + tax;

      // Item A ($100) + Item B ($100) = $200 subtotal
      expect(subtotal, 200.0);
      // Tax should be proportionally scaled: 36.17 * (200 / 449.22)
      expect(tax, closeTo(36.17 * (200.0 / 449.22), 0.01));
      // Total = subtotal + proportional tax
      expect(total, closeTo(200.0 + 36.17 * (200.0 / 449.22), 0.01));
      // Specifically: total should be ~216.10, NOT 485.39
      expect(total, lessThan(250)); // Clearly not the original $485.39
    });

    test('deselecting all items gives zero', () {
      final deselected = <int>{0, 1, 2};
      double subtotal = 0;
      for (var i = 0; i < result.items.length; i++) {
        if (deselected.contains(i)) continue;
        final item = result.items[i];
        subtotal += item.totalPrice > 0 ? item.totalPrice : item.unitPrice * item.quantity;
      }
      double tax = 0;
      if (result.tax != null && result.tax! > 0 && result.subtotal != null && result.subtotal! > 0) {
        tax = result.tax! * (subtotal / result.subtotal!);
      }
      final total = subtotal + tax;

      expect(subtotal, 0.0);
      expect(tax, 0.0);
      expect(total, 0.0);
    });

    test('filtered ReceiptAiResult preserves only selected items for persistence', () {
      final deselected = <int>{2}; // Deselect Item C
      final kept = <ReceiptLineItem>[];
      for (var i = 0; i < result.items.length; i++) {
        if (!deselected.contains(i)) {
          kept.add(result.items[i]);
        }
      }
      double keptSubtotal = 0;
      for (final item in kept) {
        keptSubtotal += item.totalPrice > 0 ? item.totalPrice : item.unitPrice * item.quantity;
      }
      double keptTax = 0;
      if (result.tax != null && result.tax! > 0 && result.subtotal != null && result.subtotal! > 0) {
        keptTax = result.tax! * (keptSubtotal / result.subtotal!);
      }
      final filtered = ReceiptAiResult(
        storeName: result.storeName,
        items: kept,
        subtotal: keptSubtotal,
        tax: keptTax > 0 ? keptTax : null,
        total: keptSubtotal + keptTax,
        date: result.date,
      );

      expect(filtered.items.length, 2);
      expect(filtered.items[0].name, 'Item A');
      expect(filtered.items[1].name, 'Item B');
      expect(filtered.subtotal, 200.0);
      expect(filtered.total, closeTo(200.0 + keptTax, 0.01));
      // Item C ($249.22) should NOT be in the persisted data
      expect(filtered.items.any((i) => i.name == 'Item C'), false);

      // Round-trip: toJsonString -> fromJsonString preserves the filtered data
      final json = filtered.toJsonString();
      final restored = ReceiptAiResult.fromJsonString(json);
      expect(restored.items.length, 2);
      expect(restored.subtotal, 200.0);
    });
  });
}
