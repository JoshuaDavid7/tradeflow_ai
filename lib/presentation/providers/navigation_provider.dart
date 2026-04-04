import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected bottom-nav tab index app-wide.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// When set to a non-zero value, HistoryScreen will animate to that
/// inner tab index (0=All, 1=Draft, 2=Sent, 3=Paid) then reset to 0.
final historyInitialTabProvider = StateProvider<int>((ref) => 0);

/// When true, the Sent tab in HistoryScreen only shows invoices with
/// remaining balance > 0 (outstanding). Reset to false after use.
final historyOutstandingFilterProvider = StateProvider<bool>((ref) => false);
