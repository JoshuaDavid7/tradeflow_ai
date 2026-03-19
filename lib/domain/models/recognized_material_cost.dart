/// Source of a recognized material cost.
enum CostSource {
  /// Created from an invoice material line (provisional until linked).
  invoice,
  /// Created from a standalone expense (no invoice line).
  expense,
  /// Linked to both an invoice material line and an expense/receipt.
  both;

  static CostSource fromString(String s) => CostSource.values.firstWhere(
        (v) => v.name == s,
        orElse: () => CostSource.invoice,
      );
}

/// Lifecycle status of a recognized material cost.
enum CostStatus {
  /// Active — counted in analytics.
  active,
  /// Superseded — replaced by a revision invoice's costs.
  superseded,
  /// Cancelled — no longer valid.
  cancelled;

  static CostStatus fromString(String s) => CostStatus.values.firstWhere(
        (v) => v.name == s,
        orElse: () => CostStatus.active,
      );
}
